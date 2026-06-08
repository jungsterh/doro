import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/session.dart';
import '../models/task.dart';
import '../providers/date_range_provider.dart';
import '../providers/premium_provider.dart';
import '../services/session_service.dart';

final sessionServiceProvider =
    Provider<SessionService>((ref) => SessionService());

// Active session state
class ActiveSessionState {
  final Session? session;
  final Task? task;
  final Duration elapsed;
  final SessionState sessionState;

  const ActiveSessionState({
    this.session,
    this.task,
    this.elapsed = Duration.zero,
    this.sessionState = SessionState.idle,
  });

  bool get isActive => sessionState != SessionState.idle;
  bool get isRunning => sessionState == SessionState.running;
  bool get isPaused => sessionState == SessionState.paused;

  ActiveSessionState copyWith({
    Session? session,
    Task? task,
    Duration? elapsed,
    SessionState? sessionState,
  }) {
    return ActiveSessionState(
      session: session ?? this.session,
      task: task ?? this.task,
      elapsed: elapsed ?? this.elapsed,
      sessionState: sessionState ?? this.sessionState,
    );
  }
}

class ActiveSessionNotifier extends StateNotifier<ActiveSessionState> {
  final Ref _ref;
  Timer? _timer;

  ActiveSessionNotifier(this._ref) : super(const ActiveSessionState());

  SessionService get _service => _ref.read(sessionServiceProvider);

  void startSession(Task task) {
    final session = _service.startSession(task);
    state = ActiveSessionState(
      session: session,
      task: task,
      elapsed: Duration.zero,
      sessionState: SessionState.running,
    );
    _startTimer();
  }

  void pauseSession() {
    _service.pauseSession();
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(sessionState: SessionState.paused);
  }

  void resumeSession() {
    _service.resumeSession();
    _startTimer();
    state = state.copyWith(sessionState: SessionState.running);
  }

  Future<Session> stopSession(String comment) async {
    _timer?.cancel();
    _timer = null;
    final completed = await _service.stopSession(comment);
    state = const ActiveSessionState();
    // Refresh sessions list
    return completed;
  }

  void cancelSession() {
    _timer?.cancel();
    _timer = null;
    _service.cancelSession();
    state = const ActiveSessionState();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isActive) {
        state = state.copyWith(elapsed: _service.elapsed);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, ActiveSessionState>(
  (ref) => ActiveSessionNotifier(ref),
);

// Past sessions
final sessionsProvider = FutureProvider<List<Session>>((ref) async {
  final service = ref.read(sessionServiceProvider);
  return service.getSessions();
});


final sessionsByTaskProvider =
    FutureProvider.family<List<Session>, String>((ref, taskId) async {
  final service = ref.read(sessionServiceProvider);
  return service.getSessionsByTask(taskId);
});

// Last completed session (for summary page)
final lastCompletedSessionProvider = StateProvider<Session?>((ref) => null);

/// Sessions filtered by the selected date range.
/// Non-premium users are capped at [AppConstants.freeTierHistoryDays] days.
final filteredSessionsProvider = FutureProvider<List<Session>>((ref) async {
  final service = ref.read(sessionServiceProvider);
  final isPremium = ref.watch(premiumProvider);
  final dateRangeState = ref.watch(dateRangeProvider);

  final (from, to) = isPremium
      ? dateRangeState.bounds
      : (
          DateTime.now()
              .subtract(Duration(days: AppConstants.freeTierHistoryDays)),
          DateTime.now(),
        );

  return service.getSessionsInRange(from, to);
});
