class AppConstants {
  AppConstants._();

  static const String appName = 'Doro';
  static const String dbName = 'doro.db';
  static const int dbVersion = 1;

  // Table names
  static const String tasksTable = 'tasks';
  static const String sessionsTable = 'sessions';

  // Supabase table names
  static const String supabaseTasksTable = 'tasks';
  static const String supabaseSessionsTable = 'sessions';
  static const String supabaseUsersTable = 'users';

  // Supabase RPC function names
  static const String supabaseRedeemPromoFn = 'redeem_promo_code';

  // Shared preferences keys
  static const String prefDarkMode = 'dark_mode';
  static const String prefDisplayMode = 'display_mode';
  static const String prefRecentTaskIds = 'recent_task_ids';
  static const int recentTasksLimit = 10;
  static const String prefIsPremium = 'is_premium';
  static const String prefSupabaseUrl = 'supabase_url';
  static const String prefSupabaseKey = 'supabase_anon_key';
  static const String prefLastSync = 'last_sync';
  static const String prefLockModeEnabled = 'lock_mode_enabled';
  static const String prefDateRangeIndex = 'date_range_index';
  static const String prefSyncNudgeDismissed = 'sync_nudge_dismissed';
  static const String prefAppGuideDone = 'app_guide_done';

  // Free tier: sessions visible up to this many days back
  static const int freeTierHistoryDays = 30;

  // Play Store subscription product IDs
  // Create these in Google Play Console → Subscriptions before going live
  static const String iapMonthlyId = 'doro_premium_monthly';
  static const String iapYearlyId = 'doro_premium_yearly';

  // Default task colors
  static const List<String> defaultColors = [
    '#6C63FF',
    '#FF6584',
    '#43B89C',
    '#F9A825',
    '#29B6F6',
    '#EF5350',
    '#AB47BC',
    '#26A69A',
  ];
}
