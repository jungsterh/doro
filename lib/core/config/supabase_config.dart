import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase project credentials loaded from the .env file.
class SupabaseConfig {
  SupabaseConfig._();

  static String get url => dotenv.get('SUPABASE_APP_URL');

  static String get anonKey => dotenv.get('ANON_KEY');

  /// Returns true only when both values are present in .env.
  static bool get isConfigured =>
      dotenv.isEveryDefined(['SUPABASE_APP_URL', 'ANON_KEY']);
}
