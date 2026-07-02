import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Google OAuth client IDs loaded from the .env file (project 895140321046).
///
/// [iosClientId] identifies the native iOS app; [serverClientId] is the
/// web/server client whose ID becomes the token's `aud` — it must match the
/// Client ID configured in Supabase's Google provider.
class GoogleConfig {
  GoogleConfig._();

  static String get iosClientId => dotenv.get('GOOGLE_IOS_CLIENT_ID');

  static String get serverClientId => dotenv.get('GOOGLE_SERVER_CLIENT_ID');
}
