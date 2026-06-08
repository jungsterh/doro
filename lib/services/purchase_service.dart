import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/constants/app_constants.dart';
import '../providers/premium_provider.dart';

/// Wraps the in_app_purchase plugin and grants premium on valid purchases.
class PurchaseService {
  final Ref _ref;
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  PurchaseService(this._ref);

  static const Set<String> _productIds = {
    AppConstants.iapMonthlyId,
    AppConstants.iapYearlyId,
  };

  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    _sub = _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onError: (Object e) => debugPrint('PurchaseStream error: $e'),
    );
    // Restore any existing active subscription on app start
    await _iap.restorePurchases();
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

  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _processPurchase(purchase);
    }
  }

  Future<void> _processPurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      // Grant premium
      await _ref.read(premiumProvider.notifier).setPremium(true);
    }
    if (purchase.status != PurchaseStatus.pending) {
      await _iap.completePurchase(purchase);
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
