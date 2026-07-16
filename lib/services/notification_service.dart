// lib/services/notification_service.dart
//
// Wraps flutter_local_notifications so the rest of the app just deals in
// Task objects. One notification per Task, keyed off a stable id derived
// from Task.id, so scheduling a task again (edit, recurrence advancing to
// its next occurrence, toggling done/undone) always replaces rather than
// stacks duplicate reminders.
//
// No device/simulator is available to test this against in this build
// environment — the plugin API calls below were checked against the
// version-pinned API docs for the exact resolved version (21.0.0), not just
// assumed from memory, after an earlier pass got initialize()/cancel()'s
// named-vs-positional args and the Darwin plugin class name wrong. A real
// device run is still the only way to confirm permission prompts and
// delivery actually fire correctly.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'task_reminders';
  static const String _channelName = 'Task reminders';
  static const String _channelDescription =
      'Reminders for upcoming tasks and deadlines';

  /// Call once, early (before scheduling anything). Safe to call more than
  /// once — subsequent calls are a no-op.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tzdata.initializeTimeZones();
    try {
      final localName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      // Platform reported an abbreviation (e.g. "PST") the IANA database
      // doesn't recognize by that exact string — fall back to whatever
      // timezone package already had it defaulted to, rather than crash.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Permissions are requested explicitly later via requestPermission(),
    // not as a side effect of initialize() — so every "request*" flag here
    // stays false/off at init time.
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: darwinInit, macOS: darwinInit),
    );

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ));
    }
  }

  /// Prompts for whatever permission the platform actually requires
  /// (Android 13+ POST_NOTIFICATIONS + Android 12+ exact-alarm access,
  /// iOS/macOS alert+badge+sound). Best-effort — a denied permission just
  /// means reminders silently won't fire, same as any other app.
  ///
  /// iOS and macOS are separate plugin classes in this package (there's no
  /// shared "Darwin" implementation class to resolve against), so each is
  /// requested individually.
  static Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isMacOS) {
      final macImpl = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      await macImpl?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static int _idFor(String taskId) => taskId.hashCode & 0x7fffffff;

  /// Cancels whatever reminder was previously scheduled for this task, then
  /// schedules a fresh one from its current reminderMinutesBefore/dueDate —
  /// or leaves it cancelled if there's nothing to schedule (no reminder
  /// set, no due date, task already done, or the fire time is in the past).
  static Future<void> scheduleForTask(Task task) async {
    final id = _idFor(task.id);
    await _plugin.cancel(id: id);

    final fireAt = task.reminderFireAt;
    if (fireAt == null) return;
    if (!task.recurrence.isRecurring && task.isDone) return;
    if (fireAt.isBefore(DateTime.now())) return;

    final subjectSuffix = task.subject.trim().isEmpty ? '' : ' · ${task.subject}';
    final body = task.hasTime
        ? 'Due at ${_fmtHM(task.dueDate!)}$subjectSuffix'
        : 'Due today$subjectSuffix';

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: task.title,
        body: body,
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // Exact-alarm permission can be denied/revoked independently of the
      // base notification permission — don't crash the task flow over it.
      debugPrint('NotificationService: failed to schedule "${task.title}": $e');
    }
  }

  static Future<void> cancelForTask(Task task) => _plugin.cancel(id: _idFor(task.id));

  /// Re-schedules every task's reminder. Meant to run once at app
  /// bootstrap so reminders set on a previous run are honored on this one
  /// (AlarmManager entries don't outlive their app data being reloaded
  /// into a fresh in-memory task list).
  static Future<void> rescheduleAll(List<Task> tasks) async {
    for (final t in tasks) {
      await scheduleForTask(t);
    }
  }

  static String _fmtHM(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
