import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/session_provider.dart';
import '../../../widgets/glass_card.dart';

class ControlDrawer extends ConsumerStatefulWidget {
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const ControlDrawer({
    super.key,
    required this.onStop,
    required this.onCancel,
  });

  @override
  ConsumerState<ControlDrawer> createState() => _ControlDrawerState();
}

class _ControlDrawerState extends ConsumerState<ControlDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    // Auto-slide in on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      show();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void show() {
    setState(() => _isVisible = true);
    _controller.forward();
  }

  void hide() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _isVisible = false);
    });
  }

  void toggle() {
    if (_isVisible) {
      hide();
    } else {
      show();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(activeSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Edge strip (always visible as a hint)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: toggle,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < -200) {
                show();
              } else if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 200) {
                hide();
              }
            },
            child: Container(
              width: 24,
              color: Colors.transparent,
              child: Center(
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isVisible ? 0.5 : 0,
                  child: Icon(
                    Icons.chevron_left,
                    color: (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary)
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Slide-in panel
        if (_isVisible)
          Positioned(
            right: 24,
            top: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! > 200) {
                    hide();
                  }
                },
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pause / Resume toggle
                      _ControlButton(
                        icon: sessionState.isPaused
                            ? Icons.play_arrow
                            : Icons.pause,
                        label: sessionState.isPaused
                            ? 'Continue'
                            : 'Pause',
                        color: Theme.of(context).colorScheme.primary,
                        onTap: () {
                          if (sessionState.isPaused) {
                            ref
                                .read(activeSessionProvider.notifier)
                                .resumeSession();
                          } else {
                            ref
                                .read(activeSessionProvider.notifier)
                                .pauseSession();
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Stop button
                      _ControlButton(
                        icon: Icons.stop,
                        label: 'Stop',
                        color: AppColors.error,
                        onTap: () {
                          hide();
                          widget.onStop();
                        },
                      ),
                      const SizedBox(height: 24),

                      // Cancel button
                      _ControlButton(
                        icon: Icons.close,
                        label: 'Cancel',
                        color: AppColors.darkTextSecondary,
                        onTap: () {
                          hide();
                          widget.onCancel();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
