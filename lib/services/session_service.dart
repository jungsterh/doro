import '../models/session.dart';
import '../models/task.dart';
import 'database_service.dart';

enum SessionState { idle, running, paused }

class SessionService {
  final DatabaseService _db;

  SessionService({DatabaseService? db}) : _db = db ?? DatabaseService.instance;

  Session? _currentSession;
  Task? _currentTask;
  Stopwatch _stopwatch = Stopwatch();
  int _accumulatedSeconds = 0;
  SessionState _state = SessionState.idle;

  Session? get currentSession => _currentSession;
  Task? get currentTask => _currentTask;
  SessionState get state => _state;
  bool get isRunning => _state == SessionState.running;
  bool get isPaused => _state == SessionState.paused;

  int get elapsedSeconds {
    if (_state == SessionState.idle) return 0;
    return _accumulatedSeconds + _stopwatch.elapsed.inSeconds;
  }

  Duration get elapsed => Duration(seconds: elapsedSeconds);

  Session startSession(Task task) {
    final id = _generateId();
    _currentTask = task;
    _accumulatedSeconds = 0;
    _stopwatch = Stopwatch()..start();
    _state = SessionState.running;

    _currentSession = Session(
      id: id,
      taskId: task.id,
      startTime: DateTime.now(),
      durationSeconds: 0,
    );

    return _currentSession!;
  }

  void pauseSession() {
    if (_state != SessionState.running) return;
    _accumulatedSeconds += _stopwatch.elapsed.inSeconds;
    _stopwatch.stop();
    _stopwatch.reset();
    _state = SessionState.paused;
  }

  void resumeSession() {
    if (_state != SessionState.paused) return;
    _stopwatch = Stopwatch()..start();
    _state = SessionState.running;
  }

  Future<Session> stopSession(String comment) async {
    if (_currentSession == null) {
      throw StateError('No active session to stop.');
    }

    if (_state == SessionState.running) {
      _accumulatedSeconds += _stopwatch.elapsed.inSeconds;
      _stopwatch.stop();
    }

    final completed = _currentSession!.copyWith(
      endTime: DateTime.now(),
      durationSeconds: _accumulatedSeconds,
      comment: comment.trim().isEmpty ? null : comment.trim(),
    );

    await _db.insertSession(completed);

    _currentSession = null;
    _currentTask = null;
    _accumulatedSeconds = 0;
    _stopwatch.reset();
    _state = SessionState.idle;

    return completed;
  }

  void cancelSession() {
    _stopwatch.stop();
    _stopwatch.reset();
    _currentSession = null;
    _currentTask = null;
    _accumulatedSeconds = 0;
    _state = SessionState.idle;
  }

  Future<List<Session>> getSessions() async {
    return _db.getSessions();
  }

  Future<List<Session>> getSessionsByTask(String taskId) async {
    return _db.getSessionsByTask(taskId);
  }

  Future<List<Session>> getSessionsInRange(DateTime from, DateTime to) async {
    return _db.getSessionsInRange(from, to);
  }

  Future<void> deleteSession(String id) async {
    return _db.deleteSession(id);
  }

  String _generateId() {
    return '${DateTime.now().microsecondsSinceEpoch}';
  }
}
