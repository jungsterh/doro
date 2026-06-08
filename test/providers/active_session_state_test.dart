import 'package:flutter_test/flutter_test.dart';
import 'package:doro/models/session.dart';
import 'package:doro/models/task.dart';
import 'package:doro/providers/session_provider.dart';
import 'package:doro/services/session_service.dart';

void main() {
  final task = Task(
    id: 'task-1',
    name: 'Deep Work',
    colorHex: '#000000',
    createdAt: DateTime(2024),
  );

  final session = Session(
    id: 'session-1',
    taskId: 'task-1',
    startTime: DateTime(2024),
    durationSeconds: 0,
  );

  // ---------------------------------------------------------------------------
  group('ActiveSessionState defaults', () {
    test('default sessionState is idle', () {
      const state = ActiveSessionState();
      expect(state.sessionState, SessionState.idle);
    });

    test('default elapsed is Duration.zero', () {
      const state = ActiveSessionState();
      expect(state.elapsed, Duration.zero);
    });

    test('default session is null', () {
      expect(const ActiveSessionState().session, isNull);
    });

    test('default task is null', () {
      expect(const ActiveSessionState().task, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  group('ActiveSessionState boolean getters', () {
    test('idle: isActive=false, isRunning=false, isPaused=false', () {
      const state = ActiveSessionState();
      expect(state.isActive, isFalse);
      expect(state.isRunning, isFalse);
      expect(state.isPaused, isFalse);
    });

    test('running: isActive=true, isRunning=true, isPaused=false', () {
      const state = ActiveSessionState(sessionState: SessionState.running);
      expect(state.isActive, isTrue);
      expect(state.isRunning, isTrue);
      expect(state.isPaused, isFalse);
    });

    test('paused: isActive=true, isRunning=false, isPaused=true', () {
      const state = ActiveSessionState(sessionState: SessionState.paused);
      expect(state.isActive, isTrue);
      expect(state.isRunning, isFalse);
      expect(state.isPaused, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  group('ActiveSessionState.copyWith', () {
    test('updates sessionState', () {
      const state = ActiveSessionState();
      final updated = state.copyWith(sessionState: SessionState.running);
      expect(updated.sessionState, SessionState.running);
    });

    test('updates elapsed', () {
      const state = ActiveSessionState();
      final updated = state.copyWith(elapsed: const Duration(seconds: 42));
      expect(updated.elapsed, const Duration(seconds: 42));
    });

    test('updates task', () {
      const state = ActiveSessionState();
      final updated = state.copyWith(task: task);
      expect(updated.task, task);
    });

    test('updates session', () {
      const state = ActiveSessionState();
      final updated = state.copyWith(session: session);
      expect(updated.session, session);
    });

    test('no-arg copyWith preserves all fields', () {
      final state = ActiveSessionState(
        session: session,
        task: task,
        elapsed: const Duration(seconds: 30),
        sessionState: SessionState.running,
      );
      final copy = state.copyWith();
      expect(copy.session, session);
      expect(copy.task, task);
      expect(copy.elapsed, const Duration(seconds: 30));
      expect(copy.sessionState, SessionState.running);
    });

    test('updating one field does not affect others', () {
      final state = ActiveSessionState(
        task: task,
        session: session,
        sessionState: SessionState.running,
        elapsed: const Duration(seconds: 10),
      );
      final updated = state.copyWith(elapsed: const Duration(seconds: 99));
      expect(updated.task, task);
      expect(updated.session, session);
      expect(updated.sessionState, SessionState.running);
      expect(updated.elapsed, const Duration(seconds: 99));
    });
  });
}
