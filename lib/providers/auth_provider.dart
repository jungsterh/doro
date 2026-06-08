import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../core/constants/app_constants.dart';
import '../models/user.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Supabase? _supabase;

  AuthNotifier(Supabase supabase) : _supabase = supabase, super(AuthState()) {
    _initializeAuthState();
  }

  @visibleForTesting
  AuthNotifier.unauthenticated() : _supabase = null, super(AuthState());

  /// Initialize auth state from Supabase session
  Future<void> _initializeAuthState() async {
    if (_supabase == null) return;
    try {
      final session = _supabase.client.auth.currentSession;
      if (session != null) {
        await _loadUserFromSupabase(session.user.id);
      }
      // Also listen for auth state changes
      _supabase.client.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final supabaseUser = data.session?.user;

        if (event == AuthChangeEvent.signedIn && supabaseUser != null) {
          await _loadUserFromSupabase(supabaseUser.id);
        } else if (event == AuthChangeEvent.signedOut) {
          state = AuthState();
        }
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    }
  }

  /// Load user data from Supabase users table.
  /// Detects premium expiry and records [subscription_ended_at] when needed.
  Future<void> _loadUserFromSupabase(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase!.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      var user = User.fromJson(response);

      // Detect transition from premium-active → premium-expired.
      // A user is considered expired when isPremium is true in the DB but
      // neither the trial nor the subscription is still active, AND we have
      // not yet recorded an end date.
      if (user.isPremium &&
          !user.isTrialActive &&
          !user.isSubscriptionActive &&
          user.subscriptionEndedAt == null) {
        final endedAt = DateTime.now().toUtc();
        debugPrint(
          'Premium expired for user $userId — recording subscription_ended_at',
        );
        await _supabase.client.from('users').update({
          'is_premium': false,
          'subscription_ended_at': endedAt.toIso8601String(),
        }).eq('id', userId);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.prefIsPremium, false);

        user = user.copyWith(
          isPremium: false,
          subscriptionEndedAt: endedAt,
        );
      }

      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load user: $e',
      );
      debugPrint('Error loading user: $e');
    }
  }

  /// Create initial user record in Supabase after OAuth
  Future<void> _createUserRecord(
    String userId,
    String email,
    String? displayName,
  ) async {
    try {
      final trialEndsAt = DateTime.now().add(Duration(days: 14));

      await _supabase!.client.from('users').insert({
        'id': userId,
        'email': email,
        'display_name': displayName,
        'is_premium': true, // Trial is considered premium
        'trial_ends_at': trialEndsAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating user record: $e');
      rethrow;
    }
  }

  /// Sign in with Google using the native Google Sign-In SDK.
  /// Gets an ID token from Google, then exchanges it for a Supabase session.
  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the picker
        state = state.copyWith(isLoading: false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('No ID token from Google');

      final response = await _supabase!.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      final supabaseUser = response.user;
      if (supabaseUser != null) {
        final existingUser = await _supabase.client
            .from('users')
            .select()
            .eq('id', supabaseUser.id)
            .maybeSingle();

        if (existingUser == null) {
          await _createUserRecord(
            supabaseUser.id,
            supabaseUser.email ?? '',
            supabaseUser.userMetadata?['name'] as String?,
          );
        }

        await _loadUserFromSupabase(supabaseUser.id);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign-in failed: $e',
      );
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase!.client.auth.signInWithOAuth(
        OAuthProvider.apple,
      );

      if (!response) {
        throw Exception('Apple sign-in failed');
      }

      await Future.delayed(Duration(milliseconds: 500));

      final session = _supabase.client.auth.currentSession;
      if (session != null) {
        final supabaseUser = session.user;
        final existingUser = await _supabase.client
            .from('users')
            .select()
            .eq('id', supabaseUser.id)
            .maybeSingle();

        if (existingUser == null) {
          await _createUserRecord(
            supabaseUser.id,
            supabaseUser.email ?? '',
            supabaseUser.userMetadata?['name'] as String?,
          );
        }

        await _loadUserFromSupabase(supabaseUser.id);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Apple sign-in failed: $e',
      );
      debugPrint('Apple sign-in error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _supabase!.client.auth.signOut();
      await GoogleSignIn().disconnect().catchError((_) => null);
      state = AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign out failed: $e',
      );
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Continue as guest (no authentication)
  void continueAsGuest() {
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabase = Supabase.instance;
  return AuthNotifier(supabase);
});
