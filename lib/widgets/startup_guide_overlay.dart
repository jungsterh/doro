import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_guide_provider.dart';

/// One-time overlay on [HomePage] that hints at the swipe gesture and the
/// settings gear. Disappears permanently once the user taps "Got it".
class StartupGuideOverlay extends ConsumerWidget {
  const StartupGuideOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideState = ref.watch(appGuideProvider);
    // null = still loading prefs; true = already seen — both cases hide overlay
    if (guideState != false) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      // Tapping anywhere on the backdrop also dismisses
      onTap: () => ref.read(appGuideProvider.notifier).markDone(),
      child: Container(
        width: size.width,
        height: size.height,
        color: Colors.black.withValues(alpha: 0.55),
        child: Stack(
          children: [
            // ── Swipe hint — bottom-center, above page dots ──────────────
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HintChip(
                    icon: Icons.swipe_outlined,
                    label: 'Swipe for analytics',
                    accent: accent,
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.keyboard_arrow_down,
                      color: accent.withValues(alpha: 0.8), size: 22),
                ],
              ),
            ),

            // ── Settings hint — top-right, pointing at gear ──────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_arrow_up,
                      color: accent.withValues(alpha: 0.8), size: 22),
                  const SizedBox(height: 4),
                  _HintChip(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    accent: accent,
                  ),
                ],
              ),
            ),

            // ── Got it button — centered ─────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome to Doro',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here\'s how to get around',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () =>
                        ref.read(appGuideProvider.notifier).markDone(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Got it',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkBackground
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _HintChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
