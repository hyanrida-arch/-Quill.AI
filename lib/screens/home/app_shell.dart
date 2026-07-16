import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/side_drawer.dart';
import 'home_screen.dart';
import 'coming_soon_screen.dart';
import '../tasks/tasks_body.dart';
import '../calendar/calendar_body.dart';
import '../focus/pomodoro_dashboard.dart';
import '../../widgets/focus/pomodoro_active_screen.dart';
import '../chat/mystro_chat_screen.dart';
import '../profile/account_screen.dart';

/// Post-auth container. Owns the Scaffold, Drawer and Mystro FAB, and swaps
/// Home / Tasks sections with setState.
///
/// Note: the new TasksBody renders its OWN header (menu + classroom), so for
/// the Tasks section we do NOT add the shared AppHeader.
class AppShell extends StatefulWidget {
  final String userName;
  final String userEmail;
  final bool isTeacher;
  final String? avatarPath;
  final ValueChanged<String?> onAvatarChanged;
  final VoidCallback onSignOut;

  const AppShell({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.isTeacher,
    required this.avatarPath,
    required this.onAvatarChanged,
    required this.onSignOut,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  AppSection _section = AppSection.home;
  bool _drawerOpen = false;
  String? _comingSoon;
  bool _loading = true;

  // ⭐ Single source of truth. Task = the plan. FocusSession = reality.
  // TasksBody, CalendarBody, PomodoroDashboard, and HomeBody all read from
  // these two lists instead of keeping their own mock copies, and write
  // back through the callbacks below. When this moves to Supabase, these
  // two lists become the `tasks` and `focus_sessions` tables. Persisted to
  // on-device storage on every mutation so nothing resets on app restart.
  List<Task> _tasks = [];
  List<FocusSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final savedTasks = await LocalStorageService.loadTasks();
    final savedSessions = await LocalStorageService.loadSessions();
    // null means this device has never saved a task list before — seed the
    // mock starter tasks exactly once and persist them immediately so they
    // don't get silently regenerated (with "Today" labels re-dated) on the
    // next launch. A non-null (possibly empty) list means the user's real
    // data should be shown as-is, even if they've deleted everything.
    final tasks = savedTasks ?? List<Task>.from(Task.mockTasks(widget.isTeacher));
    if (savedTasks == null) {
      await LocalStorageService.saveTasks(tasks);
    }
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _sessions = savedSessions;
      _loading = false;
    });
    // Reminders are scheduled with the OS's alarm manager, not kept alive by
    // the app process — re-arm every task's reminder against this session's
    // in-memory list so edits made on a previous run are still honored.
    await NotificationService.init();
    await NotificationService.requestPermission();
    await NotificationService.rescheduleAll(_tasks);
  }

  void _addTask(Task task) {
    setState(() => _tasks.insert(0, task));
    LocalStorageService.saveTasks(_tasks);
    NotificationService.scheduleForTask(task);
  }

  void _updateTask(Task updated) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == updated.id);
      if (index != -1) _tasks[index] = updated;
    });
    LocalStorageService.saveTasks(_tasks);
    NotificationService.scheduleForTask(updated);
  }

  void _deleteTask(Task task) {
    setState(() => _tasks.removeWhere((t) => t.id == task.id));
    LocalStorageService.saveTasks(_tasks);
    NotificationService.cancelForTask(task);
  }

  void _toggleTaskDone(Task task) {
    late Task result;
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index == -1) return;
      _tasks[index] = _tasks[index].copyWith(
        status: task.isDone ? TaskStatus.pending : TaskStatus.completed,
      );
      result = _tasks[index];
    });
    LocalStorageService.saveTasks(_tasks);
    // Completed tasks shouldn't still buzz a reminder — scheduleForTask
    // already no-ops for done, non-recurring tasks, and re-arms the
    // reminder if it was just marked pending again.
    NotificationService.scheduleForTask(result);
  }

  void _recordSession(FocusSession session) {
    setState(() => _sessions.add(session));
    LocalStorageService.saveSessions(_sessions);
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();
  void _closeDrawer() => _scaffoldKey.currentState?.closeDrawer();

  void _selectSection(AppSection s) {
    _closeDrawer();
    switch (s) {
      case AppSection.home:
        setState(() {
          _section = AppSection.home;
          _comingSoon = null;
        });
        break;
      case AppSection.tasks:
        setState(() {
          _section = AppSection.tasks;
          _comingSoon = null;
        });
        break;
      case AppSection.calendar:
        setState(() {
          _section = AppSection.calendar;
          _comingSoon = null;
        });
        break;
      case AppSection.pomodoro:
        setState(() {
          _section = AppSection.pomodoro;
          _comingSoon = null;
        });
        break;
    }
  }

  void _openComingSoon(String feature) {
    _closeDrawer();
    setState(() => _comingSoon = feature);
  }

  void _openAccount() {
    _closeDrawer();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountScreen(
          userName: widget.userName,
          userEmail: widget.userEmail,
          avatarPath: widget.avatarPath,
          onAvatarChanged: widget.onAvatarChanged,
          onSignOut: _confirmSignOut,
        ),
      ),
    );
  }

  void _backToHome() => setState(() => _comingSoon = null);

  // Reached via the Account screen's 3-dot menu (Sign Out), not the drawer
  // directly anymore — the drawer's own Sign Out row was removed earlier.
  Future<void> _confirmSignOut() async {
    _closeDrawer();
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => const _SignOutDialog(),
    );
    if (yes == true) widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.teal,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final showComingSoon = _comingSoon != null;
    final isTasks = _section == AppSection.tasks;
    final isCalendar = _section == AppSection.calendar;
    final isPomodoro = _section == AppSection.pomodoro;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      onDrawerChanged: (open) => setState(() => _drawerOpen = open),
      drawer: SideDrawer(
        userName: widget.userName,
        userEmail: widget.userEmail,
        avatarPath: widget.avatarPath,
        current: _section,
        onSelect: _selectSection,
        onComingSoon: _openComingSoon,
        onOpenAccount: _openAccount,
      ),
      body: SafeArea(
        child: showComingSoon
            ? ComingSoonScreen(
                feature: _comingSoon!,
                onBack: _backToHome,
                onNotify: () {},
              )
            : isTasks
                // TasksBody has its own header (menu + classroom).
                ? TasksBody(
                    isTeacher: widget.isTeacher,
                    userName: widget.userName,
                    tasks: _tasks,
                    onAdd: _addTask,
                    onToggleDone: _toggleTaskDone,
                    onDelete: _deleteTask,
                    onUpdate: _updateTask,
                    onSessionComplete: _recordSession,
                    onMenuTap: _openDrawer,
                    onClassroomTap: () => _openComingSoon('Classroom'),
                  )
                : isCalendar
                    // CalendarBody also owns its header (menu + classroom).
                    ? CalendarBody(
                        tasks: _tasks,
                        sessions: _sessions,
                        onUpdate: _updateTask,
                        onAdd: _addTask,
                        onSessionComplete: _recordSession,
                        onMenuTap: _openDrawer,
                        onClassroomTap: () => _openComingSoon('Classroom'),
                      )
                    : isPomodoro
                        // PomodoroDashboard also owns its header (menu + history + classroom).
                        ? PomodoroDashboard(
                            tasks: _tasks,
                            sessions: _sessions,
                            onSessionComplete: _recordSession,
                            onMenuTap: _openDrawer,
                            onClassroomTap: () => _openComingSoon('Classroom'),
                          )
                        : Column(
                            children: [
                              AppHeader(
                                onMenuTap: _openDrawer,
                                onClassroomTap: () => _openComingSoon('Classroom'),
                                onNotificationTap: () =>
                                    _openComingSoon('Notifications'),
                              ),
                              Expanded(
                                child: HomeBody(
                                  userName: widget.userName,
                                  isTeacher: widget.isTeacher,
                                  tasks: _tasks,
                                  sessions: _sessions,
                                  onAddTask: _addTask,
                                  onSeeAllTasks: () =>
                                      setState(() => _section = AppSection.tasks),
                                  onStartPomodoro: (Task t) => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PomodoroActiveScreen(
                                        task: t,
                                        durationMinutes: t.estimatedMinutes > 0 ? t.estimatedMinutes : 25,
                                        onSessionComplete: _recordSession,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
      ),
      floatingActionButton: (!showComingSoon && !_drawerOpen)
          ? _MystroFab(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MystroChatScreen()),
              ),
            )
          : null,
    );
  }
}

class _MystroFab extends StatelessWidget {
  final VoidCallback onTap;
  const _MystroFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.deepNavy,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.teal, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepNavy.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.auto_awesome, color: AppColors.teal, size: 24),
      ),
    );
  }
}

class _SignOutDialog extends StatelessWidget {
  const _SignOutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: AppColors.red, size: 26),
            ),
            const SizedBox(height: 18),
            const Text('Sign Out?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            const Text(
              "Are you sure you want to sign out? You'll need to sign in again "
              "to access your tasks and progress.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, color: AppColors.slateGray, height: 1.5),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepNavy)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Sign Out',
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
