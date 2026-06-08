import 'package:flutter_test/flutter_test.dart';
import 'package:doro/models/session.dart';
import 'package:doro/models/task.dart';
import 'package:doro/services/database_service.dart';
import 'package:doro/services/session_service.dart';

// Manual fake for DatabaseService
class FakeDatabaseService extends Fake implements DatabaseService {
  List<Session> sessions = [];
  bool insertCalled = false;
  bool updateCalled = false;

  @override
  Future<void> insertSession(Session session) async {
    insertCalled = true;
    sessions.add(session);
  }

  @override
  Future<void> updateSession(Session session) async {
    updateCalled = true;
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) sessions[idx] = session;
  }

  @override
  Future<List<Session>> getSessions() async => sessions;

  @override
  Future<List<Session>> getSessionsByTask(String taskId) async =>
      sessions.where((s) => s.taskId == taskId).toList();

  @override
  Future<List<Session>> getSessionsInRange(
          DateTime from, DateTime to) async =>
      sessions
          .where((s) =>
              s.startTime.isAfter(from) && s.startTime.isBefore(to))
          .toList();
}

void main() {
  late FakeDatabaseService fakeDb;
  late SessionService sessionService;

  final sampleTask = Task(
    id: 'task-1',
    name: 'Deep Work',
    colorHex: '#6C63FF',
    createdAt: DateTime(2025, 1, 1),
  );

  setUp(() {
    fakeDb = FakeDatabaseService();
    sessionService = SessionService(db: fakeDb);
  });

  group('SessionService', () {
    group('initial state', () {
      test('starts in idle state', () {
        expect(sessionService.state, equals(SessionState.idle));
      });

      test('has zero elapsed seconds initially', () {
        expect(sessionService.elapsedSeconds, equals(0));
      });

      test('has no current session initially', () {
        expect(sessionService.currentSession, isNull);
      });
    });

    group('startSession()', () {
      test('returns a session with correct task id', () {
        final session = sessionService.startSession(sampleTask);

        expect(session.taskId, equals(sampleTask.id));
        expect(session.endTime, isNull);
        expect(session.durationSeconds, equals(0));
      });

      test('sets state to running', () {
        sessionService.startSession(sampleTask);

        expect(sessionService.state, equals(SessionState.running));
        expect(sessionService.isRunning, isTrue);
      });

      test('sets current task', () {
        sessionService.startSession(sampleTask);

        expect(sessionService.currentTask, equals(sampleTask));
      });

      test('sets current session', () {
        final session = sessionService.startSession(sampleTask);

        expect(sessionService.currentSession, equals(session));
      });
    });

    group('pauseSession()', () {
      test('sets state to paused after running', () {
        sessionService.startSession(sampleTask);
        sessionService.pauseSession();

        expect(sessionService.state, equals(SessionState.paused));
        expect(sessionService.isPaused, isTrue);
      });

      test('does nothing if not running', () {
        sessionService.pauseSession();

        expect(sessionService.state, equals(SessionState.idle));
      });
    });

    group('resumeSession()', () {
      test('sets state to running after paused', () {
        sessionService.startSession(sampleTask);
        sessionService.pauseSession();
        sessionService.resumeSession();

        expect(sessionService.state, equals(SessionState.running));
      });

      test('does nothing if not paused', () {
        sessionService.startSession(sampleTask);
        sessionService.resumeSession(); // already running

        expect(sessionService.state, equals(SessionState.running));
      });
    });

    group('stopSession()', () {
      test('saves session to database', () async {
        sessionService.startSession(sampleTask);
        await sessionService.stopSession('Great focus session');

        expect(fakeDb.insertCalled, isTrue);
      });

      test('returns completed session with end time', () async {
        sessionService.startSession(sampleTask);
        final completed =
            await sessionService.stopSession('Done!');

        expect(completed.endTime, isNotNull);
        expect(completed.isCompleted, isTrue);
      });

      test('saves comment in completed session', () async {
        sessionService.startSession(sampleTask);
        final completed =
            await sessionService.stopSession('Great session');

        expect(completed.comment, equals('Great session'));
      });

      test('sets null comment when empty string provided', () async {
        sessionService.startSession(sampleTask);
        final completed = await sessionService.stopSession('');

        expect(completed.comment, isNull);
      });

      test('resets state to idle', () async {
        sessionService.startSession(sampleTask);
        await sessionService.stopSession('');

        expect(sessionService.state, equals(SessionState.idle));
        expect(sessionService.currentSession, isNull);
      });

      test('throws if no active session', () async {
        expect(
          () => sessionService.stopSession(''),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('cancelSession()', () {
      test('resets state to idle without saving', () {
        sessionService.startSession(sampleTask);
        sessionService.cancelSession();

        expect(sessionService.state, equals(SessionState.idle));
        expect(sessionService.currentSession, isNull);
        expect(fakeDb.insertCalled, isFalse);
      });
    });

    group('getSessions()', () {
      test('returns sessions from database', () async {
        final session = Session(
          id: 's1',
          taskId: sampleTask.id,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(minutes: 30)),
          durationSeconds: 1800,
        );
        fakeDb.sessions = [session];

        final sessions = await sessionService.getSessions();

        expect(sessions, equals([session]));
      });
    });

    group('getSessionsByTask()', () {
      test('returns only sessions for given task', () async {
        final s1 = Session(
          id: 's1',
          taskId: 'task-1',
          startTime: DateTime.now(),
          durationSeconds: 0,
        );
        final s2 = Session(
          id: 's2',
          taskId: 'task-2',
          startTime: DateTime.now(),
          durationSeconds: 0,
        );
        fakeDb.sessions = [s1, s2];

        final sessions =
            await sessionService.getSessionsByTask('task-1');

        expect(sessions.length, equals(1));
        expect(sessions.first.id, equals('s1'));
      });
    });
  });
}
