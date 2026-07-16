// lib/services/local_storage_service.dart
//
// Everything the app previously kept only in memory (tasks, focus sessions,
// avatar, and whether the user has an account) now round-trips through
// SharedPreferences so it survives an app restart. This is the one place
// that talks to on-device storage — AppShell and FlowController just call
// these static methods instead of touching SharedPreferences directly.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/focus_session.dart';

class LocalStorageService {
  static const _kTasksKey = 'quill_tasks_v1';
  static const _kSessionsKey = 'quill_sessions_v1';
  static const _kAvatarKey = 'quill_avatar_path_v1';

  // Login/profile persistence — lets a returning user skip the onboarding
  // wizard and land straight on Home instead of redoing it every launch.
  static const _kLoggedInKey = 'quill_logged_in_v1';
  static const _kFullNameKey = 'quill_full_name_v1';
  static const _kEmailKey = 'quill_email_v1';
  static const _kRoleKey = 'quill_role_v1';

  // ============================================================
  // TASKS
  // ============================================================

  /// Null means "never saved before" (first-ever launch) — the caller should
  /// seed mock data. An empty (non-null) list means the user genuinely has
  /// zero tasks and should see the real empty state, not the mock seed.
  static Future<List<Task>?> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTasksKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt/old data shouldn't crash the app — treat as first launch.
      return null;
    }
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_kTasksKey, raw);
  }

  // ============================================================
  // FOCUS SESSIONS
  // ============================================================

  static Future<List<FocusSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSessionsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => FocusSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSessions(List<FocusSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_kSessionsKey, raw);
  }

  // ============================================================
  // AVATAR
  // ============================================================

  static Future<String?> loadAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAvatarKey);
  }

  static Future<void> saveAvatarPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_kAvatarKey);
    } else {
      await prefs.setString(_kAvatarKey, path);
    }
  }

  // ============================================================
  // LOGIN / PROFILE (so onboarding isn't repeated every launch)
  // ============================================================

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedInKey) ?? false;
  }

  static Future<Map<String, String>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fullName': prefs.getString(_kFullNameKey) ?? '',
      'email': prefs.getString(_kEmailKey) ?? '',
      'role': prefs.getString(_kRoleKey) ?? 'student',
    };
  }

  /// Called on successful sign-up / sign-in. Marks the device as logged in
  /// and caches the profile fields AppShell needs (name, email, role).
  static Future<void> saveLoggedInProfile({
    required String fullName,
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedInKey, true);
    await prefs.setString(_kFullNameKey, fullName);
    await prefs.setString(_kEmailKey, email);
    await prefs.setString(_kRoleKey, role);
  }

  /// Sign out — stays a local-only flag flip, so tasks/sessions/avatar are
  /// left untouched and the next sign-in (even without a real backend)
  /// picks the same data back up.
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedInKey, false);
  }
}
