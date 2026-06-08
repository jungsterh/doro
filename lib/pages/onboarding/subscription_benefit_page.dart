import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/premium_provider.dart';
import '../../widgets/glass_button.dart';

class SubscriptionBenefitPage extends ConsumerStatefulWidget {
  const SubscriptionBenefitPage({super.key});

  @override
  ConsumerState<SubscriptionBenefitPage> createState() =>
      _SubscriptionBenefitPageState();
}

class _SubscriptionBenefitPageState
    extends ConsumerState<SubscriptionBenefitPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final cardBg = isDark ? AppColors.darkCard : const Color(0xFFF5F5F5);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const SizedBox(height: 16),
                Text(
                  'Try Premium Free',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'for 14 days',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                ),
                const SizedBox(height: 32),

                // Benefits list
                _BenefitItem(
                  icon: Icons.history,
                  title: 'Full History',
                  description: 'Access all your sessions with no 30-day limit',
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                _BenefitItem(
                  icon: Icons.cloud_sync,
                  title: 'Cloud Sync',
                  description: 'Keep your data in sync across all devices',
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                _BenefitItem(
                  icon: Icons.calendar_today,
                  title: 'Flexible Date Ranges',
                  description: 'Filter sessions by custom date ranges',
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                _BenefitItem(
                  icon: Icons.lock,
                  title: 'Focus Lock Mode',
                  description: 'Track and prevent distractions during sessions',
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),
                _BenefitItem(
                  icon: Icons.devices,
                  title: 'Multi-Device Access',
                  description: 'Use Doro on all your devices',
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 40),

                // Pricing section
                _PricingCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 32),

                // Start free trial button
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    onPressed: _isLoading ? null : _startFreeTrial,
                    child: Text(
                      _isLoading ? 'Starting...' : 'Start Free Trial',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Continue to app button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                    child: const Text('Continue to App'),
                  ),
                ),
                const SizedBox(height: 16),

                // Disclaimer
                Text(
                  'Cancel anytime. Trial auto-renews unless cancelled.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startFreeTrial() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(premiumProvider.notifier).setPremium(true);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;
  final Color primaryColor;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: primaryColor,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.lightText,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color primaryColor;

  const _PricingCard({
    required this.isDark,
    required this.cardBg,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : AppColors.lightText,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$2.99',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                  ),
                  Text(
                    '/month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'or',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        'Yearly',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightText,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'BEST VALUE',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$23.88',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                  ),
                  Text(
                    '\$1.99/month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
