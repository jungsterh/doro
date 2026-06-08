import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../models/session.dart' as app_models;
import '../models/task.dart' as app_models;
import 'database_service.dart';

class SyncService {
  final DatabaseService _db;
  final SupabaseClient? _supabaseOverride;

  SyncService({DatabaseService? db, SupabaseClient? supabaseClient})
      : _db = db ?? DatabaseService.instance,
        _supabaseOverride = supabaseClient;

  /// Returns null when Supabase credentials have not been configured yet.
  /// An injected [supabaseClient] takes precedence (used in tests).
  SupabaseClient? get _supabase =>
      _supabaseOverride ??
      (SupabaseConfig.isConfigured ? Supabase.instance.client : null);

  Future<bool> get isPremium async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefIsPremium) ?? false;
  }

  Future<void> syncToSupabase() async {
    final client = _supabase;
    if (client == null) return;
    if (!await isPremium) return;
    if (client.auth.currentUser == null) return;

    final userId = client.auth.currentUser!.id;

    final tasks = await _db.getTasks();
    for (final task in tasks) {
      final json = task.toJson()..['user_id'] = userId;
      await client.from(AppConstants.supabaseTasksTable).upsert(json);
    }

    final sessions = await _db.getSessions();
    final completedSessions = sessions.where((s) => s.isCompleted).toList();
    for (final session in completedSessions) {
      final json = session.toJson()..['user_id'] = userId;
      await client.from(AppConstants.supabaseSessionsTable).upsert(json);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefLastSync,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> syncFromSupabase() async {
    final client = _supabase;
    if (client == null) return;
    if (!await isPremium) return;
    if (client.auth.currentUser == null) return;

    final userId = client.auth.currentUser!.id;

    final remoteTasks = await client
        .from(AppConstants.supabaseTasksTable)
        .select()
        .eq('user_id', userId);

    for (final taskData in remoteTasks as List<dynamic>) {
      final task =
          app_models.Task.fromJson(taskData as Map<String, dynamic>);
      await _db.insertTask(task);
    }

    final remoteSessions = await client
        .from(AppConstants.supabaseSessionsTable)
        .select()
        .eq('user_id', userId);

    for (final sessionData in remoteSessions as List<dynamic>) {
      final session =
          app_models.Session.fromJson(sessionData as Map<String, dynamic>);
      await _db.insertSession(session);
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(AppConstants.prefLastSync);
    if (lastSync == null) return null;
    return DateTime.tryParse(lastSync);
  }

  Future<bool> signIn(String email, String password) async {
    final client = _supabase;
    if (client == null) return false;
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase?.auth.signOut();
  }

  bool get isSignedIn => _supabase?.auth.currentUser != null;

  String? get currentUserEmail => _supabase?.auth.currentUser?.email;

  bool get isConfigured => SupabaseConfig.isConfigured;
}
