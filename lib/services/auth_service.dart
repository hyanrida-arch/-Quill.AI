// lib/services/auth_service.dart
//
// Thin wrapper around Supabase's real email/password auth. Every method
// returns an AuthResult instead of throwing, so call sites (SignUpScreen /
// SignInScreen via FlowController) can show a plain error message inline
// without a try/catch of their own.
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthResult {
  final bool success;
  final String? error;
  // True when signUp succeeded in creating the account but Supabase's
  // default "confirm your email" flow means there's no session yet — the
  // caller shouldn't treat this as a failed signup, but can't route to
  // Home either until the user confirms and signs in for real.
  final bool needsEmailConfirmation;

  const AuthResult({
    required this.success,
    this.error,
    this.needsEmailConfirmation = false,
  });
}

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static bool get isSignedIn => currentUser != null;

  /// Fires on sign-in / sign-out / token refresh.
  static Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
    required bool isTeacher,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
      if (res.user == null) {
        return const AuthResult(
          success: false,
          error: 'Could not create the account. Try again.',
        );
      }
      if (res.session == null) {
        // Email confirmation is required before this account can sign in
        // (Supabase's default). Turn this off in Auth settings if that
        // friction isn't wanted for a demo.
        return const AuthResult(
          success: false,
          needsEmailConfirmation: true,
          error: 'Account created — check your email to confirm it before signing in.',
        );
      }
      // The handle_new_user() trigger (supabase_schema.sql) already
      // creates the profiles row from raw_user_meta_data.display_name;
      // is_teacher isn't part of that trigger, so it's set here instead.
      await _client
          .from('profiles')
          .update({'is_teacher': isTeacher}).eq('id', res.user!.id);
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (_) {
      return const AuthResult(
        success: false,
        error: 'Network error — check your connection and try again.',
      );
    }
  }

  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth
          .signInWithPassword(email: email, password: password);
      if (res.user == null) {
        return const AuthResult(
          success: false,
          error: 'Invalid email or password.',
        );
      }
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (_) {
      return const AuthResult(
        success: false,
        error: 'Network error — check your connection and try again.',
      );
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Updates the profiles row for the current user — display name and/or
  /// phone. Only the fields actually passed are touched.
  static Future<AuthResult> updateProfile({String? displayName, String? phone}) async {
    final uid = currentUser?.id;
    if (uid == null) {
      return const AuthResult(success: false, error: 'Not signed in.');
    }
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (phone != null) updates['phone'] = phone.isEmpty ? null : phone;
    if (updates.isEmpty) return const AuthResult(success: true);
    try {
      await _client.from('profiles').update(updates).eq('id', uid);
      return const AuthResult(success: true);
    } catch (_) {
      return const AuthResult(
        success: false,
        error: 'Could not save changes — check your connection and try again.',
      );
    }
  }

  /// Changes the password for the currently signed-in user. Supabase
  /// doesn't require the old password here — the active session itself is
  /// the proof of identity, same as most apps' "change password while
  /// logged in" flow (as opposed to the separate forgot-password/reset
  /// flow, which does use an emailed link).
  static Future<AuthResult> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (_) {
      return const AuthResult(
        success: false,
        error: 'Could not update the password — check your connection and try again.',
      );
    }
  }

  /// Reads the profiles row for the current user (display name + teacher
  /// flag) — used right after bootstrap/sign-in so a fresh install on a
  /// second device shows the real name instead of an empty one.
  static Future<Map<String, dynamic>?> fetchProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    try {
      return await _client.from('profiles').select().eq('id', uid).maybeSingle();
    } catch (_) {
      return null;
    }
  }
}
