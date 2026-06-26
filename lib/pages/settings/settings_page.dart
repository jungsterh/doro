import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/display_provider.dart';
import '../../providers/premium_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/purchase_service.dart';
import '../../widgets/glass_card.dart';
import '../auth/login_page.dart';
import '../premium/premium_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _syncEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Initialize IAP listener
    ref.read(purchaseServiceProvider).initialize();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _syncEnabled = prefs.getBool('sync_enabled') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isPremium = ref.watch(premiumProvider);
    final authState = ref.watch(authProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account section
            _SectionHeader(title: 'Account'),
            if (authState.isAuthenticated) ...[
              GlassCard(
                margin: const EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.person_outline, color: accent),
                      title: const Text('Signed in as'),
                      subtitle: Text(authState.user?.email ?? ''),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.workspace_premium, color: accent),
                      title: const Text('Premium Status'),
                      subtitle: Text(
                        authState.user?.isTrialActive ?? false
                            ? 'Trial (ends ${_formatDate(authState.user?.trialEndsAt)})'
                            : authState.user?.isSubscriptionActive ?? false
                                ? 'Active'
                                : 'Free',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Sign Out'),
                      textColor: AppColors.error,
                      iconColor: AppColors.error,
                      onTap: _showSignOutDialog,
                    ),
                  ],
                ),
              ),
            ] else ...[
              GlassCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign in to enable cloud sync and premium features.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(provider: 'google'),
                        ),
                      ),
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(provider: 'apple'),
                        ),
                      ),
                      icon: const Icon(Icons.apple, size: 18),
                      label: const Text('Continue with Apple'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Appearance
            _SectionHeader(title: 'Appearance'),
            GlassCard(
              margin: const EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: Text(isDark ? 'Dark theme active' : 'Light theme active'),
                value: isDark,
                onChanged: (value) async {
                  await ref.read(themeProvider.notifier).setDark(value);
                },
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: accent,
                ),
              ),
            ),

            const SizedBox(height: 8),
            _SectionHeader(title: 'Display'),
            _DisplayModeCard(),

            // Subscription
            _SectionHeader(title: 'Subscription'),
            if (isPremium)
              _PremiumActiveBadge(accent: accent)
            else
              _PremiumUpsellCard(accent: accent),
            const SizedBox(height: 16),

            // Cloud Sync (premium only)
            if (isPremium) ...[
              _SectionHeader(title: 'Cloud Sync'),
              if (!ref.read(syncServiceProvider).isConfigured)
                GlassCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Add your Supabase credentials in '
                          'lib/core/config/supabase_config.dart to enable sync.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                GlassCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    title: const Text('Cloud Sync'),
                    subtitle: Text(
                        _syncEnabled ? 'Syncing to cloud' : 'Tap to enable'),
                    value: _syncEnabled,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('sync_enabled', value);
                      setState(() => _syncEnabled = value);
                    },
                    secondary: Icon(Icons.cloud_sync, color: accent),
                  ),
                ),
                if (_syncEnabled)
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: Icon(Icons.sync, color: accent),
                      title: const Text('Sync Now'),
                      subtitle: const Text('Upload local data to cloud'),
                      onTap: _syncNow,
                    ),
                  ),
              ],
              const SizedBox(height: 8),
            ],

            // About
            _SectionHeader(title: 'About'),
            GlassCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: accent),
                    title: const Text('Version'),
                    trailing: const Text('1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.timer_outlined, color: accent),
                    title: const Text('Doro'),
                    subtitle:
                        const Text('Track what matters. Make time count.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNow() async {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Syncing…')));
    try {
      await ref.read(syncServiceProvider).syncToSupabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sync complete!'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Sync failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _showSignOutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('You will be signed out of your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(authProvider.notifier).signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _PremiumUpsellCard extends StatelessWidget {
  final Color accent;
  const _PremiumUpsellCard({required this.accent});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      backgroundColor: accent.withValues(alpha: 0.08),
      borderColor: accent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: accent, size: 22),
              const SizedBox(width: 10),
              Text(
                'Doro Premium',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: accent, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FeatureRow(
              icon: Icons.history,
              accent: accent,
              title: 'Full history',
              subtitle: 'Free tier shows last ${AppConstants.freeTierHistoryDays} days'),
          const SizedBox(height: 8),
          _FeatureRow(
              icon: Icons.date_range,
              accent: accent,
              title: 'Flexible date ranges',
              subtitle: 'Week · Month · YTD · Custom'),
          const SizedBox(height: 8),
          _FeatureRow(
              icon: Icons.cloud_outlined,
              accent: accent,
              title: 'Cloud sync',
              subtitle: 'Data stored locally only right now'),
          const SizedBox(height: 8),
          _FeatureRow(
              icon: Icons.do_not_disturb_on,
              accent: accent,
              title: 'Focus lock mode',
              subtitle: 'Track phone pick-ups during sessions'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumPage()),
              ),
              icon: const Icon(Icons.workspace_premium, size: 18),
              label: const Text('See Premium Plans'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: accent.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumActiveBadge extends StatelessWidget {
  final Color accent;
  const _PremiumActiveBadge({required this.accent});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      backgroundColor: AppColors.success.withValues(alpha: 0.08),
      borderColor: AppColors.success.withValues(alpha: 0.35),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium,
                color: AppColors.success, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doro Premium — Active',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Full history, cloud sync & all premium features unlocked',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.6),
                      )),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisplayModeCard extends ConsumerWidget {
  const _DisplayModeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(displayModeProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.timer_outlined, color: accent),
            title: const Text('Timer Style'),
            subtitle: Text(mode == DisplayMode.flip ? 'Flip card' : 'Digital'),
          ),
          const Divider(height: 1),
          RadioGroup<DisplayMode>(
            groupValue: mode,
            onChanged: (v) =>
                ref.read(displayModeProvider.notifier).setMode(v!),
            child: Column(
              children: const [
                RadioListTile<DisplayMode>(
                  value: DisplayMode.digital,
                  title: Text('Digital'),
                  subtitle: Text('Clean numeric display'),
                  secondary: Icon(Icons.looks_one_outlined),
                ),
                RadioListTile<DisplayMode>(
                  value: DisplayMode.flip,
                  title: Text('Flip Card'),
                  subtitle: Text('Animated split-flap cards'),
                  secondary: Icon(Icons.style_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
