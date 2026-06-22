/// Integration tests for SyncService against a real Supabase instance.
///
/// ## How to run
///
/// 1. Start a local Supabase stack:
///      supabase start
///
/// 2. Apply all migrations:
///      supabase db push
///
/// 3. Set environment variables with the local credentials
///    printed by `supabase start`:
///      SUPABASE_TEST_URL=http://localhost:54321
///      SUPABASE_TEST_KEY=(local anon key)
///
/// 4. Run:
///      flutter test integration_test/sync_integration_test.dart
///
/// The tests skip automatically when those variables are absent.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:doro/core/constants/app_constants.dart';
import 'package:doro/models/session.dart' as app_models;
import 'package:doro/models/task.dart';
import 'package:doro/services/database_service.dart';
import 'package:doro/services/sync_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Guard: skip all tests when no local Supabase is configured.
  // ---------------------------------------------------------------------------
  final supabaseUrl = Platform.environment['SUPABASE_TEST_URL'] ?? '';
  final supabaseKey = Platform.environment['SUPABASE_TEST_KEY'] ?? '';
  final supabaseAvailable = supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Setup helpers
  // ---------------------------------------------------------------------------

  late SupabaseClient supabaseClient;
  late DatabaseService localDb;
  late SyncService syncService;
  late String testUserId;

  Future<void> signInAnonymously() async {
    final response = await supabaseClient.auth.signInAnonymously();
    testUserId = response.user!.id;

    // Insert the matching row in public.users so RLS policies resolve.
    await supabaseClient.from('users').insert({
      'id': testUserId,
      'email': '$testUserId@test.local',
      'is_premium': true,
    });
  }

  Future<void> cleanRemote() async {
    await supabaseClient
        .from('sessions')
        .delete()
        .eq('user_id', testUserId);
    await supabaseClient
        .from('tasks')
        .delete()
        .eq('user_id', testUserId);
    await supabaseClient
        .from('users')
        .delete()
        .eq('id', testUserId);
    await supabaseClient.auth.signOut();
  }

  setUpAll(() async {
    if (!supabaseAvailable) return;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
    supabaseClient = Supabase.instance.client;
  });

  setUp(() async {
    if (!supabaseAvailable) return;

    SharedPreferences.setMockInitialValues({
      AppConstants.prefIsPremium: true,
    });

    // Fresh in-memory SQLite for each test.
    localDb = await DatabaseService.openInMemory();
    syncService = SyncService(
      db: localDb,
      supabaseClient: supabaseClient,
    );

    await signInAnonymously();
  });

  tearDown(() async {
    if (!supabaseAvailable) return;
    await cleanRemote();
    await localDb.close();
  });

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  group('SyncService — integration', () {
    testWidgets('syncToSupabase uploads local tasks and sessions to Supabase',
        (tester) async {
      if (!supabaseAvailable) {
        markTestSkipped(
          'SUPABASE_TEST_URL / SUPABASE_TEST_KEY not set — skipping',
        );
        return;
      }

      // Arrange: 2 tasks, 1 completed session in local DB.
      final task1 = Task(
        id: 'itask-1',
        name: 'Integration Task 1',
        colorHex: '#6C63FF',
        createdAt: DateTime(2025, 1, 1),
      );
      final task2 = Task(
        id: 'itask-2',
        name: 'Integration Task 2',
        colorHex: '#FF6584',
        createdAt: DateTime(2025, 1, 2),
      );
      final session = app_models.Session(
        id: 'isession-1',
        taskId: task1.id,
        startTime: DateTime(2025, 6, 1, 9),
        endTime: DateTime(2025, 6, 1, 10),
        durationSeconds: 3600,
        comment: 'Integration sync test',
      );

      await localDb.insertTask(task1);
      await localDb.insertTask(task2);
      await localDb.insertSession(session);

      // Act.
      await syncService.syncToSupabase();

      // Assert: both tasks are in Supabase.
      final remoteTasks = await supabaseClient
          .from('tasks')
          .select()
          .eq('user_id', testUserId);
      expect(remoteTasks, hasLength(2));

      // Assert: session is in Supabase.
      final remoteSessions = await supabaseClient
          .from('sessions')
          .select()
          .eq('user_id', testUserId);
      expect(remoteSessions, hasLength(1));
      expect(remoteSessions.first['id'], equals(session.id));

      // Assert: last_sync timestamp is persisted.
      final lastSync = await syncService.getLastSyncTime();
      expect(lastSync, isNotNull);
    });

    testWidgets('syncFromSupabase downloads remote tasks and sessions locally',
        (tester) async {
      if (!supabaseAvailable) {
        markTestSkipped(
          'SUPABASE_TEST_URL / SUPABASE_TEST_KEY not set — skipping',
        );
        return;
      }

      // Arrange: insert directly into Supabase.
      await supabaseClient.from('tasks').insert({
        'id': 'rtask-1',
        'user_id': testUserId,
        'name': 'Remote Task',
        'color_hex': '#43B89C',
        'created_at': DateTime(2025, 3, 1).toIso8601String(),
      });
      await supabaseClient.from('sessions').insert({
        'id': 'rsession-1',
        'user_id': testUserId,
        'task_id': 'rtask-1',
        'start_time': DateTime(2025, 3, 1, 8).toIso8601String(),
        'end_time': DateTime(2025, 3, 1, 9).toIso8601String(),
        'duration_seconds': 3600,
      });

      // Act.
      await syncService.syncFromSupabase();

      // Assert: task and session now exist in local DB.
      final localTasks = await localDb.getTasks();
      expect(localTasks.any((t) => t.id == 'rtask-1'), isTrue);

      final localSessions = await localDb.getSessions();
      expect(localSessions.any((s) => s.id == 'rsession-1'), isTrue);
    });

    testWidgets(
        'syncToSupabase is idempotent — upsert does not create duplicates',
        (tester) async {
      if (!supabaseAvailable) {
        markTestSkipped(
          'SUPABASE_TEST_URL / SUPABASE_TEST_KEY not set — skipping',
        );
        return;
      }

      final task = Task(
        id: 'itask-dup',
        name: 'Duplicate Test',
        colorHex: '#6C63FF',
        createdAt: DateTime(2025, 1, 1),
      );
      await localDb.insertTask(task);

      // Sync twice.
      await syncService.syncToSupabase();
      await syncService.syncToSupabase();

      final remoteTasks = await supabaseClient
          .from('tasks')
          .select()
          .eq('user_id', testUserId)
          .eq('id', task.id);

      expect(remoteTasks, hasLength(1),
          reason: 'Upsert must not create duplicate rows');
    });

    testWidgets('syncToSupabase is no-op when user is not premium',
        (tester) async {
      if (!supabaseAvailable) {
        markTestSkipped(
          'SUPABASE_TEST_URL / SUPABASE_TEST_KEY not set — skipping',
        );
        return;
      }

      // Override premium flag to false.
      SharedPreferences.setMockInitialValues({
        AppConstants.prefIsPremium: false,
      });
      final nonPremiumService = SyncService(
        db: localDb,
        supabaseClient: supabaseClient,
      );

      final task = Task(
        id: 'itask-np',
        name: 'Non-premium Task',
        colorHex: '#6C63FF',
        createdAt: DateTime(2025, 1, 1),
      );
      await localDb.insertTask(task);

      await nonPremiumService.syncToSupabase();

      final remoteTasks = await supabaseClient
          .from('tasks')
          .select()
          .eq('user_id', testUserId);

      expect(remoteTasks, isEmpty,
          reason: 'Non-premium users must not sync to Supabase');
    });
  });
}
