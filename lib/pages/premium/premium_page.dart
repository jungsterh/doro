import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/premium_provider.dart';
import '../../services/purchase_service.dart';
import '../../widgets/glass_card.dart';

class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  List<ProductDetails> _products = [];
  bool _loadingProducts = true;
  String? _purchasingId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final service = ref.read(purchaseServiceProvider);
    final products = await service.loadProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _loadingProducts = false;
      });
    }
  }

  Future<void> _purchase(ProductDetails product) async {
    setState(() => _purchasingId = product.id);
    final service = ref.read(purchaseServiceProvider);
    await service.purchase(product);
    if (mounted) setState(() => _purchasingId = null);
  }

  Future<void> _restore() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restoring purchases…')),
    );
    await ref.read(purchaseServiceProvider).restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restore complete'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doro Premium'),
        actions: [
          TextButton(
            onPressed: _restore,
            child: Text('Restore', style: TextStyle(color: accent)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero banner
            _HeroBanner(isDark: isDark, accent: accent),
            const SizedBox(height: 28),

            // Feature list
            Text(
              'Everything in Premium',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ..._features(accent),
            const SizedBox(height: 28),

            if (isPremium)
              _ActiveBadge(accent: accent)
            else if (_loadingProducts)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else
              ..._buildPurchaseOptions(accent),

            const SizedBox(height: 20),
            Center(
              child: Text(
                'Subscriptions renew automatically. Cancel any time in\nGoogle Play → Subscriptions.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  List<Widget> _features(Color accent) {
    const items = [
      (Icons.history, 'Full history', 'See all your past sessions — weeks, months, years'),
      (Icons.date_range, 'Flexible date ranges', 'Filter by week, month, year-to-date, or custom range'),
      (Icons.cloud_sync, 'Cloud sync', 'Back up all data to Supabase — never lose a session'),
      (Icons.devices, 'Multi-device access', 'Sign in on any device and pick up where you left off'),
      (Icons.do_not_disturb_on, 'Focus lock mode', 'Track distractions when you leave the app mid-session'),
    ];
    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.$1, color: accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$2,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        item.$3,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildPurchaseOptions(Color accent) {
    if (_products.isEmpty) {
      return [
        GlassCard(
          child: Column(
            children: [
              const Icon(Icons.store_outlined, size: 36, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Store unavailable',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Make sure Play Store subscriptions are set up in the Google Play Console.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }

    return _products.map((product) {
      final isLoading = _purchasingId == product.id;
      final isMonthly = product.id.contains('monthly');
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          backgroundColor: accent.withValues(alpha: 0.06),
          borderColor: accent.withValues(alpha: 0.3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isMonthly ? 'Monthly' : 'Yearly',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (!isMonthly) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'BEST VALUE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.price,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                child: FilledButton(
                  onPressed: isLoading ? null : () => _purchase(product),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Subscribe'),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _HeroBanner extends StatelessWidget {
  final bool isDark;
  final Color accent;

  const _HeroBanner({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: accent.withValues(alpha: 0.07),
      borderColor: accent.withValues(alpha: 0.3),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.workspace_premium, color: accent, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'Doro Premium',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock your full productivity history, cloud backup,\nand distraction tracking.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final Color accent;
  const _ActiveBadge({required this.accent});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: AppColors.success.withValues(alpha: 0.1),
      borderColor: AppColors.success.withValues(alpha: 0.4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Premium Active',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
                Text(
                  'You have full access to all premium features.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
