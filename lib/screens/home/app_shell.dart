import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';
import '../../models/habit.dart';
import '../../models/classroom.dart';
import '../../models/notebook.dart';
import '../../models/flashcard.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/side_drawer.dart';
import 'home_screen.dart';
import 'coming_soon_screen.dart';
import '../tasks/tasks_body.dart';
import '../calendar/calendar_body.dart';
import '../habits/habits_body.dart';
import '../classroom/classrooms_list_screen.dart';
import '../notebook/notebooks_list_screen.dart';
import '../flashcards/flashcards_home_screen.dart';
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
  // Bubbles a saved name change (from EditProfileScreen, via AccountScreen)
  // back up to FlowController so widget.userName reflects it immediately —
  // same pattern as onAvatarChanged already uses for the avatar.
  final ValueChanged<String> onNameChanged;

  const AppShell({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.isTeacher,
    required this.avatarPath,
    required this.onAvatarChanged,
    required this.onSignOut,
    required this.onNameChanged,
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
  List<Habit> _habits = [];
  List<Classroom> _classrooms = [];
  List<Notebook> _notebooks = [];
  List<Note> _notes = [];
  List<Flashcard> _flashcards = [];
  List<CardReview> _cardReviews = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final savedTasks = await LocalStorageService.loadTasks();
    final savedSessions = await LocalStorageService.loadSessions();
    final savedHabits = await LocalStorageService.loadHabits();
    final savedClassrooms = await LocalStorageService.loadClassrooms();
    final savedNotebooks = await LocalStorageService.loadNotebooks();
    final savedNotes = await LocalStorageService.loadNotes();
    final savedFlashcards = await LocalStorageService.loadFlashcards();
    final savedCardReviews = await LocalStorageService.loadCardReviews();
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
      _habits = savedHabits;
      _classrooms = savedClassrooms;
      _notebooks = savedNotebooks;
      _notes = savedNotes;
      _flashcards = savedFlashcards;
      _cardReviews = savedCardReviews;
      _loading = false;
    });
    // Reminders are scheduled with the OS's alarm manager, not kept alive by
    // the app process — re-arm every task's reminder against this session's
    // in-memory list so edits made on a previous run are still honored.
    await NotificationService.init();
    await NotificationService.requestPermission();
    await NotificationService.rescheduleAll(_tasks);
    await NotificationService.rescheduleAllHabits(_habits);
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

  void _addHabit(Habit habit) {
    setState(() => _habits.insert(0, habit));
    LocalStorageService.saveHabits(_habits);
    NotificationService.scheduleHabitReminder(habit);
  }

  void _updateHabit(Habit updated) {
    setState(() {
      final index = _habits.indexWhere((h) => h.id == updated.id);
      if (index != -1) _habits[index] = updated;
    });
    LocalStorageService.saveHabits(_habits);
    NotificationService.scheduleHabitReminder(updated);
  }

  void _deleteHabit(Habit habit) {
    setState(() => _habits.removeWhere((h) => h.id == habit.id));
    LocalStorageService.saveHabits(_habits);
    NotificationService.cancelHabitReminder(habit);
  }

  // Classrooms are local-only organizational containers (no backend to
  // sync to) — persistence is the only side effect these need, unlike
  // Tasks/Habits which also touch NotificationService.
  void _addClassroom(Classroom classroom) {
    setState(() => _classrooms.insert(0, classroom));
    LocalStorageService.saveClassrooms(_classrooms);
  }

  void _updateClassroom(Classroom updated) {
    setState(() {
      final index = _classrooms.indexWhere((c) => c.id == updated.id);
      if (index != -1) _classrooms[index] = updated;
    });
    LocalStorageService.saveClassrooms(_classrooms);
  }

  void _deleteClassroom(Classroom classroom) {
    setState(() => _classrooms.removeWhere((c) => c.id == classroom.id));
    LocalStorageService.saveClassrooms(_classrooms);
  }

  // ============================================================
  // NOTEBOOK (notebooks + notes)
  // ============================================================

  void _addNotebook(Notebook notebook) {
    setState(() => _notebooks.insert(0, notebook));
    LocalStorageService.saveNotebooks(_notebooks);
  }

  void _updateNotebook(Notebook updated) {
    setState(() {
      final index = _notebooks.indexWhere((n) => n.id == updated.id);
      if (index != -1) _notebooks[index] = updated;
    });
    LocalStorageService.saveNotebooks(_notebooks);
  }

  // Deleting a notebook cascades to its notes — an orphaned note with no
  // notebook to live in isn't useful. Any flashcards already generated
  // from those notes are left alone (their noteId just stops resolving,
  // handled gracefully wherever a source note is looked up).
  void _deleteNotebook(Notebook notebook) {
    setState(() {
      _notebooks.removeWhere((n) => n.id == notebook.id);
      _notes.removeWhere((n) => n.notebookId == notebook.id);
    });
    LocalStorageService.saveNotebooks(_notebooks);
    LocalStorageService.saveNotes(_notes);
  }

  void _addNote(Note note) {
    setState(() => _notes.add(note));
    LocalStorageService.saveNotes(_notes);
  }

  void _updateNote(Note updated) {
    setState(() {
      final index = _notes.indexWhere((n) => n.id == updated.id);
      if (index != -1) _notes[index] = updated;
    });
    LocalStorageService.saveNotes(_notes);
  }

  void _deleteNote(Note note) {
    setState(() => _notes.removeWhere((n) => n.id == note.id));
    LocalStorageService.saveNotes(_notes);
  }

  // ============================================================
  // FLASHCARDS (cards + review history)
  // ============================================================

  void _addFlashcard(Flashcard card) {
    setState(() => _flashcards.add(card));
    LocalStorageService.saveFlashcards(_flashcards);
  }

  void _updateFlashcard(Flashcard updated) {
    setState(() {
      final index = _flashcards.indexWhere((c) => c.id == updated.id);
      if (index != -1) _flashcards[index] = updated;
    });
    LocalStorageService.saveFlashcards(_flashcards);
  }

  void _recordCardReview(String cardId, bool correct) {
    final review = CardReview(
      id: 'review_${DateTime.now().microsecondsSinceEpoch}',
      cardId: cardId,
      correct: correct,
      reviewedAt: DateTime.now(),
    );
    setState(() => _cardReviews.add(review));
    LocalStorageService.saveCardReviews(_cardReviews);
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
      case AppSection.habits:
        setState(() {
          _section = AppSection.habits;
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

  // "Classroom", "Notebook" and "Flashcards" are the drawer entries that
  // are actually built (the rest are still real coming-soon stubs) — so
  // they're special-cased here to push the real screen instead of setting
  // _comingSoon. Every existing call site (SideDrawer's rows, and every
  // header's onClassroomTap) already calls onComingSoon('<feature>'), so
  // none of them needed to change.
  void _openComingSoon(String feature) {
    if (feature == 'Classroom') {
      _closeDrawer();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClassroomsListScreen(
            classrooms: _classrooms,
            isTeacher: widget.isTeacher,
            userName: widget.userName,
            tasks: _tasks,
            onCreate: _addClassroom,
            onUpdate: _updateClassroom,
            onDelete: _deleteClassroom,
            onAddTask: _addTask,
            onToggleTask: _toggleTaskDone,
          ),
        ),
      );
      return;
    }
    if (feature == 'Notebook') {
      _closeDrawer();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotebooksListScreen(
            notebooks: _notebooks,
            notes: _notes,
            tasks: _tasks,
            onCreate: _addNotebook,
            onUpdate: _updateNotebook,
            onDelete: _deleteNotebook,
            onAddNote: _addNote,
            onUpdateNote: _updateNote,
            onDeleteNote: _deleteNote,
            onAddFlashcard: _addFlashcard,
          ),
        ),
      );
      return;
    }
    if (feature == 'Flashcards') {
      _closeDrawer();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlashcardsHomeScreen(
            cards: _flashcards,
            notes: _notes,
            notebooks: _notebooks,
            onAddCard: _addFlashcard,
            onUpdateCard: _updateFlashcard,
            onRecordReview: _recordCardReview,
          ),
        ),
      );
      return;
    }
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
          habits: _habits,
          tasks: _tasks,
          sessions: _sessions,
          flashcards: _flashcards,
          onAvatarChanged: widget.onAvatarChanged,
          onSignOut: _confirmSignOut,
          onOpenHabits: () {
            Navigator.pop(context);
            _selectSection(AppSection.habits);
          },
          onProfileUpdated: widget.onNameChanged,
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
    final isHabits = _section == AppSection.habits;
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
                        onDelete: _deleteTask,
                        onSessionComplete: _recordSession,
                        onMenuTap: _openDrawer,
                        onClassroomTap: () => _openComingSoon('Classroom'),
                      )
                    : isHabits
                        // HabitsBody also owns its header (menu + add).
                        ? HabitsBody(
                            habits: _habits,
                            onAdd: _addHabit,
                            onUpdate: _updateHabit,
                            onDelete: _deleteHabit,
                            onMenuTap: _openDrawer,
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
