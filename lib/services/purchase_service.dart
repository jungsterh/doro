import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../providers/premium_provider.dart';

/// Wraps the in_app_purchase plugin and grants premium on valid purchases.
///
/// NOTE: entitlement is currently decided client-side. Before public launch,
/// purchases should be verified server-side (Play Developer API / App Store
/// Server API via a Supabase Edge Function).
class PurchaseService {
  final Ref _ref;
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _initialized = false;

  /// Set whenever the purchase stream delivers a purchased/restored event.
  /// Used by [_syncEntitlementOnStartup] to detect a lapsed subscription.
  bool _sawEntitlement = false;

  PurchaseService(this._ref);

  static const Set<String> _productIds = {
    AppConstants.iapMonthlyId,
    AppConstants.iapYearlyId,
  };

  SupabaseClient? get _supabase =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  /// Idempotent — called from main.dart, the provider, and settings_page.
  Future<void> initialize() async {
    if (_initialized) return;
    final available = await _iap.isAvailable();
    if (!available) return;
    _initialized = true;
    _sub = _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onError: (Object e) => debugPrint('PurchaseStream error: $e'),
    );
    // Deliberately not awaited: contains a settle delay and must not block
    // app startup (main.dart awaits initialize()).
    unawaited(_syncEntitlementOnStartup());
  }

  /// Returns the product details loaded from the store.
  /// Returns an empty list if the store is unavailable or products not found.
  Future<List<ProductDetails>> loadProducts() async {
    final available = await _iap.isAvailable();
    if (!available) return [];
    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      debugPrint('Product load error: ${response.error}');
    }
    return response.productDetails;
  }

  /// Initiates a purchase for the given [product].
  Future<bool> purchase(ProductDetails product) async {
    final available = await _iap.isAvailable();
    if (!available) return false;
    final param = PurchaseParam(productDetails: product);
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return await _iap.buyNonConsumable(purchaseParam: param);
      }
      return false;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  /// Restores previous purchases (e.g. after reinstall).
  Future<void> restorePurchases() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    await _iap.restorePurchases();
  }

  /// Restores purchases on app start and, on Android, revokes premium when
  /// no active subscription is returned.
  ///
  /// Google Play only reports *active* subscriptions on restore, so an empty
  /// restore on Android means the subscription has lapsed. On iOS, restore
  /// can replay old (possibly expired) transactions, so revocation there
  /// requires server-side receipt validation and is intentionally skipped;
  /// expiry for signed-in users is handled via the users table in
  /// auth_provider.
  Future<void> _syncEntitlementOnStartup() async {
    _sawEntitlement = false;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Restore on startup failed: $e');
      return; // Store unreachable — keep last known state, never revoke.
    }
    if (!Platform.isAndroid) return;
    // Restore results arrive on the purchase stream shortly after the
    // restore future completes; give them a moment to settle.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!_sawEntitlement && _ref.read(premiumProvider)) {
      // Trials, promo codes, and manual grants exist only in the backend
      // and never appear in a Play restore — they must not be revoked here.
      if (await _isPremiumInBackend()) return;
      debugPrint('No active subscription on restore — revoking premium');
      await _ref.read(premiumProvider.notifier).setPremium(false);
      await _recordSubscriptionEnded();
    }
  }

  /// True when the signed-in user's row in the users table says premium.
  /// Fails safe (true) when the backend is unreachable so a flaky network
  /// never revokes premium.
  Future<bool> _isPremiumInBackend() async {
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return false;
    try {
      final row = await client
          .from(AppConstants.supabaseUsersTable)
          .select('is_premium')
          .eq('id', userId)
          .maybeSingle();
      return row?['is_premium'] == true;
    } catch (e) {
      debugPrint('Backend premium check failed: $e');
      return true;
    }
  }

  /// Redeems a promo code via the redeem_promo_code RPC (see migration 015).
  /// Returns null on success, otherwise a user-facing error message.
  Future<String?> redeemPromoCode(String code) async {
    final client = _supabase;
    if (client == null) return 'Service unavailable';
    if (client.auth.currentUser == null) {
      return 'Sign in to redeem a code';
    }
    try {
      final result = await client.rpc(
        AppConstants.supabaseRedeemPromoFn,
        params: {'p_code': code.trim().toUpperCase()},
      );
      if (result is Map && result['success'] == true) {
        await _ref.read(premiumProvider.notifier).setPremium(true);
        return null;
      }
      final error = result is Map ? result['error'] : null;
      return switch (error) {
        'invalid_code' => 'Invalid code',
        'expired' => 'This code has expired',
        'exhausted' => 'This code has reached its redemption limit',
        'already_redeemed' => 'You have already redeemed this code',
        _ => 'Could not redeem code',
      };
    } catch (e) {
      debugPrint('Promo redemption error: $e');
      return 'Could not redeem code — check your connection';
    }
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _processPurchase(purchase);
    }
  }

  Future<void> _processPurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
        _sawEntitlement = true;
        await _ref.read(premiumProvider.notifier).setPremium(true);
        // Only new purchases update the backend; restored events can be
        // stale on iOS and Android restores don't change entitlement dates.
        await _recordSubscriptionStarted(purchase);
      case PurchaseStatus.restored:
        _sawEntitlement = true;
        await _ref.read(premiumProvider.notifier).setPremium(true);
        // Android restores are guaranteed-active, so syncing them to the
        // backend is safe and covers subscriptions bought while signed out.
        // iOS restores can replay expired transactions — skip there.
        if (Platform.isAndroid) {
          await _recordSubscriptionStarted(purchase);
        }
      case PurchaseStatus.error:
        debugPrint('Purchase failed: ${purchase.error}');
      case PurchaseStatus.canceled:
        debugPrint('Purchase canceled by user');
      case PurchaseStatus.pending:
        break;
    }
    // Always complete only when the store asks for it; calling
    // completePurchase on error/canceled events throws on some platforms.
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// Best-effort backend update after a successful purchase so the
  /// auth-level expiry check (auth_provider) has dates to work with.
  /// The renews-at date is a client-side estimate until server-side
  /// verification is in place.
  Future<void> _recordSubscriptionStarted(PurchaseDetails purchase) async {
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    final renewsAt = DateTime.now().toUtc().add(
          purchase.productID == AppConstants.iapYearlyId
              ? const Duration(days: 365)
              : const Duration(days: 30),
        );
    try {
      await client.from(AppConstants.supabaseUsersTable).update({
        'is_premium': true,
        'subscription_renews_at': renewsAt.toIso8601String(),
        'subscription_ended_at': null,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Failed to record subscription start: $e');
    }
  }

  /// Best-effort backend update when premium is revoked, preserving any
  /// previously recorded end date (it anchors the 1-year retention window).
  Future<void> _recordSubscriptionEnded() async {
    final client = _supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      final row = await client
          .from(AppConstants.supabaseUsersTable)
          .select('subscription_ended_at')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return;
      final update = <String, dynamic>{'is_premium': false};
      if (row['subscription_ended_at'] == null) {
        update['subscription_ended_at'] =
            DateTime.now().toUtc().toIso8601String();
      }
      await client
          .from(AppConstants.supabaseUsersTable)
          .update(update)
          .eq('id', userId);
    } catch (e) {
      debugPrint('Failed to record subscription end: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService(ref);
  ref.onDispose(service.dispose);
  Future.microtask(service.initialize);
  return service;
});
