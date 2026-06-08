import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// A single distraction event (left the app while session was running).
class DistractionEvent {
  final DateTime start;
  final DateTime end;

  const DistractionEvent({required this.start, required this.end});

  Duration get duration => end.difference(start);
}

class LockModeState {
  final bool enabled;
  final bool isDistracted;
  final List<DistractionEvent> sessionDistractions;

  const LockModeState({
    this.enabled = false,
    this.isDistracted = false,
    this.sessionDistractions = const [],
  });

  LockModeState copyWith({
    bool? enabled,
    bool? isDistracted,
    List<DistractionEvent>? sessionDistractions,
  }) {
    return LockModeState(
      enabled: enabled ?? this.enabled,
      isDistracted: isDistracted ?? this.isDistracted,
      sessionDistractions:
          sessionDistractions ?? this.sessionDistractions,
    );
  }

  int get distractionCount => sessionDistractions.length;

  Duration get totalDistractionTime => sessionDistractions.fold(
        Duration.zero,
        (sum, e) => sum + e.duration,
      );
}

class LockModeNotifier extends StateNotifier<LockModeState> {
  LockModeNotifier() : super(const LockModeState()) {
    _load();
  }

  DateTime? _distractionStart;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    Future(() {
      state = state.copyWith(
        enabled: prefs.getBool(AppConstants.prefLockModeEnabled) ?? false,
      );
    });
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefLockModeEnabled, value);
    state = state.copyWith(enabled: value);
  }

  /// Call when a new session starts — clears distraction history.
  void onSessionStart() {
    _distractionStart = null;
    state = state.copyWith(
      sessionDistractions: const [],
      isDistracted: false,
    );
  }

  /// Call when the app goes to the background during an active session.
  void onAppPaused() {
    if (!state.enabled) return;
    _distractionStart = DateTime.now();
    state = state.copyWith(isDistracted: true);
  }

  /// Call when the app returns to the foreground.
  void onAppResumed() {
    if (!state.enabled || !state.isDistracted) return;
    final start = _distractionStart;
    _distractionStart = null;
    if (start == null) {
      state = state.copyWith(isDistracted: false);
      return;
    }
    final event = DistractionEvent(start: start, end: DateTime.now());
    state = state.copyWith(
      isDistracted: false,
      sessionDistractions: [...state.sessionDistractions, event],
    );
  }
}

final lockModeProvider =
    StateNotifierProvider<LockModeNotifier, LockModeState>(
  (ref) => LockModeNotifier(),
);
