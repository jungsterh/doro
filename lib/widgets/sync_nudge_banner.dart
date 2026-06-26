import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../pages/onboarding/onboarding_page.dart';

/// Shows a dismissible banner when the user is a premium subscriber but has
/// not signed in, prompting them to sign in to enable cross-device sync.
///
/// Hides permanently once dismissed.
class SyncNudgeBanner extends ConsumerStatefulWidget {
  const SyncNudgeBanner({super.key});

  @override
  ConsumerState<SyncNudgeBanner> createState() => _SyncNudgeBannerState();
}

class _SyncNudgeBannerState extends ConsumerState<SyncNudgeBanner> {
  bool _dismissed = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dismissed = prefs.getBool(AppConstants.prefSyncNudgeDismissed) ?? false;
        _loaded = true;
      });
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefSyncNudgeDismissed, true);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed) return const SizedBox.shrink();

    final isPremium = ref.watch(premiumProvider);
    final isSignedIn = ref.watch(authProvider).isAuthenticated;

    // Only show when premium and not signed in
    if (!isPremium || isSignedIn) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: const ValueKey('sync_nudge'),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_sync_outlined, color: accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sign in to sync your data across devices',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkText
                          : AppColors.lightText,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingPage()),
                );
              },
              child: Text(
                'Sign in',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _dismiss,
              child: Icon(
                Icons.close,
                size: 16,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
