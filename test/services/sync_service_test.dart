import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doro/core/constants/app_constants.dart';
import 'package:doro/models/session.dart';
import 'package:doro/models/task.dart';
import 'package:doro/services/database_service.dart';
import 'package:doro/services/sync_service.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeDatabaseService extends Fake implements DatabaseService {
  final List<Task> tasks;
  final List<Session> sessions;
  final List<Task> insertedTasks = [];
  final List<Session> insertedSessions = [];

  FakeDatabaseService({List<Task>? tasks, List<Session>? sessions})
      : tasks = tasks ?? [],
        sessions = sessions ?? [];

  @override
  Future<List<Task>> getTasks() async => tasks;

  @override
  Future<List<Session>> getSessions() async => sessions;

  @override
  Future<void> insertTask(Task task) async => insertedTasks.add(task);

  @override
  Future<void> insertSession(Session session) async =>
      insertedSessions.add(session);
}

// ---------------------------------------------------------------------------

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final sampleTask = Task(
    id: 'task-1',
    name: 'Deep Work',
    colorHex: '#6C63FF',
    createdAt: DateTime(2025, 1, 1),
  );

  final sampleSession = Session(
    id: 'session-1',
    taskId: 'task-1',
    startTime: DateTime(2025, 6, 1, 9),
    endTime: DateTime(2025, 6, 1, 10),
    durationSeconds: 3600,
    comment: 'Solid hour',
  );

  // -------------------------------------------------------------------------
  group('isPremium', () {
    test('returns false when SharedPreferences has no value', () async {
      final service = SyncService(db: FakeDatabaseService());
      expect(await service.isPremium, isFalse);
    });

    test('returns true when SharedPreferences has true', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefIsPremium: true,
      });
      final service = SyncService(db: FakeDatabaseService());
      expect(await service.isPremium, isTrue);
    });

    test('returns false when SharedPreferences has false', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefIsPremium: false,
      });
      final service = SyncService(db: FakeDatabaseService());
      expect(await service.isPremium, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  group('syncToSupabase — no-op paths', () {
    test('returns without error when no Supabase client is configured',
        () async {
      // supabaseClient omitted → _supabase is null → returns early
      final service = SyncService(db: FakeDatabaseService());
      await expectLater(service.syncToSupabase(), completes);
    });

    test('returns without error and does not write last_sync when not premium',
        () async {
      // Supabase client is null (not configured), non-premium user.
      final service = SyncService(db: FakeDatabaseService());
      await service.syncToSupabase();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.prefLastSync), isNull);
    });

    test('last_sync is not written when premium=false even with local data',
        () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefIsPremium: false,
      });
      final db = FakeDatabaseService(
        tasks: [sampleTask],
        sessions: [sampleSession],
      );
      final service = SyncService(db: db);
      await service.syncToSupabase();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.prefLastSync), isNull);
    });
  });

  // -------------------------------------------------------------------------
  group('syncFromSupabase — no-op paths', () {
    test('returns without error when no Supabase client is configured',
        () async {
      final service = SyncService(db: FakeDatabaseService());
      await expectLater(service.syncFromSupabase(), completes);
    });

    test('does not insert any local data when not premium', () async {
      final db = FakeDatabaseService();
      final service = SyncService(db: db);
      await service.syncFromSupabase();

      expect(db.insertedTasks, isEmpty);
      expect(db.insertedSessions, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  group('getLastSyncTime()', () {
    test('returns null when never synced', () async {
      final service = SyncService(db: FakeDatabaseService());
      expect(await service.getLastSyncTime(), isNull);
    });

    test('returns the persisted timestamp', () async {
      final ts = DateTime(2025, 6, 15, 12, 30);
      SharedPreferences.setMockInitialValues({
        AppConstants.prefLastSync: ts.toIso8601String(),
      });
      final service = SyncService(db: FakeDatabaseService());
      final result = await service.getLastSyncTime();

      expect(result, isNotNull);
      expect(result!.year, ts.year);
      expect(result.month, ts.month);
      expect(result.day, ts.day);
    });

    test('returns null for a malformed timestamp string', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefLastSync: 'not-a-date',
      });
      final service = SyncService(db: FakeDatabaseService());
      // DateTime.tryParse returns null for invalid strings.
      expect(await service.getLastSyncTime(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  group('isConfigured', () {
    test('returns false in test environment (no .env configured)', () {
      final service = SyncService(db: FakeDatabaseService());
      // SupabaseConfig.isConfigured is false when .env is not loaded.
      expect(service.isConfigured, isFalse);
    });
  });
}
