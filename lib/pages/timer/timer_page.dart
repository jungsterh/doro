import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/display_provider.dart';
import '../../providers/lock_mode_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/sound_service.dart';
import '../summary/summary_page.dart';
import 'widgets/control_drawer.dart';
import 'widgets/flip_clock.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage>
    with WidgetsBindingObserver {
  bool _edgeHintVisible = false;
  final _sound = SoundService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future(() => ref.read(lockModeProvider.notifier).onSessionStart());
    // Defer orientation lock until after the navigation transition finishes
    // to avoid the gray-overlay freeze on Android (Samsung One UI in particular).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });
    // Show edge hint briefly then fade
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _edgeHintVisible = true);
    });
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => _edgeHintVisible = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sound.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final sessionState = ref.read(activeSessionProvider);
    if (!sessionState.isRunning) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(lockModeProvider.notifier).onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(lockModeProvider.notifier).onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(activeSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<ActiveSessionState>(activeSessionProvider, (_, next) {
      if (next.isCountdownComplete && mounted) {
        _autoComplete();
      }
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: GestureDetector(
        onTap: () => setState(() => _edgeHintVisible = true),
        child: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (sessionState.task != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: sessionState.task!.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sessionState.task!.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  FlipClock(
                    elapsed: sessionState.remaining ?? sessionState.elapsed,
                    useFlip: ref.watch(displayModeProvider) == DisplayMode.flip,
                  ),

                  const SizedBox(height: 24),

                  _LockModeIndicator(ref: ref),

                  if (sessionState.isPaused)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.warning, width: 1),
                      ),
                      child: const Text(
                        'PAUSED',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Edge hint indicator
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: _edgeHintVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  width: 28,
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.darkAccent
                            : AppColors.lightAccent)
                        .withValues(alpha: 0.15),
                  ),
                  child: const Center(
                    child: Icon(Icons.chevron_left,
                        color: Colors.white54, size: 20),
                  ),
                ),
              ),
            ),

            // Control drawer
            Positioned.fill(
              child: ControlDrawer(
                onStop: _confirmStop,
                onCancel: _confirmCancel,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _autoComplete() async {
    unawaited(_sound.playDone());
    final session =
        await ref.read(activeSessionProvider.notifier).stopSession('');
    ref.read(lastCompletedSessionProvider.notifier).state = session;
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SummaryPage(session: session)),
      );
    }
  }

  Future<void> _confirmStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Session?'),
        content: const Text(
            'This will end the current session and take you to the summary.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Stop',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final session =
          await ref.read(activeSessionProvider.notifier).stopSession('');
      ref.read(lastCompletedSessionProvider.notifier).state = session;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SummaryPage(session: session)),
        );
      }
    }
  }

  void _confirmCancel() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Session?'),
        content: const Text(
            'This session will be discarded and not saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Discard',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        ref.read(activeSessionProvider.notifier).cancelSession();
        Navigator.pop(context);
      }
    });
  }
}

/// Shows a pill when lock mode is enabled, turning red when a distraction is
/// detected (app went to background).
class _LockModeIndicator extends ConsumerWidget {
  final WidgetRef ref;
  const _LockModeIndicator({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef watchRef) {
    final lock = watchRef.watch(lockModeProvider);
    if (!lock.enabled) return const SizedBox.shrink();

    final isDistracted = lock.isDistracted;
    final count = lock.distractionCount;
    final color = isDistracted ? AppColors.error : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDistracted ? Icons.phone_android : Icons.do_not_disturb_on,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              isDistracted
                  ? 'Phone in use!'
                  : 'Focus lock${count > 0 ? '  ·  $count ${count == 1 ? 'slip' : 'slips'}' : ''}',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
