// lib/screens/home/app_shell.dart
import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/side_drawer.dart';
import '../chat/mystro_chat_screen.dart';
import 'home_screen.dart';
import 'coming_soon_screen.dart';
import '../tasks/tasks_body.dart';

/// The main app container shown AFTER auth (FlowController -> Routes.home).
class AppShell extends StatefulWidget {
  final String userName;
  final String userEmail;
  final bool isTeacher;
  final VoidCallback onSignOut;

  const AppShell({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.isTeacher,
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
        setState(() => _comingSoon = 'Calendar');
        break;
      case AppSection.pomodoro:
        setState(() => _comingSoon = 'Pomodoro');
        break;
    }
  }

  void _openComingSoon(String feature) {
    _closeDrawer();
    setState(() => _comingSoon = feature);
  }

  void _backToHome() => setState(() => _comingSoon = null);

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
    final showComingSoon = _comingSoon != null;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      onDrawerChanged: (open) => setState(() => _drawerOpen = open),
      drawer: SideDrawer(
        userName: widget.userName,
        userEmail: widget.userEmail,
        current: _section,
        onSelect: _selectSection,
        onComingSoon: _openComingSoon,
        onSignOut: _confirmSignOut,
      ),
      body: SafeArea(
        child: showComingSoon
            ? ComingSoonScreen(
                feature: _comingSoon!,
                onBack: _backToHome,
                onNotify: () {},
              )
            : Column(
                children: [
                  AppHeader(
                    onMenuTap: _openDrawer,
                    onClassroomTap: () => _openComingSoon('Classroom'),
                    onNotificationTap: () => _openComingSoon('Notifications'),
                  ),
                  Expanded(child: _sectionBody()),
                ],
              ),
      ),
      floatingActionButton: (!showComingSoon && !_drawerOpen)
          ? _MystroFab(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MystroChatScreen()),
                );
              },
            )
          : null,
    );
  }

  Widget _sectionBody() {
    if (_section == AppSection.tasks) {
      return TasksBody(isTeacher: widget.isTeacher);
    }
    return HomeBody(
      userName: widget.userName,
      isTeacher: widget.isTeacher,
      onSeeAllTasks: () => setState(() => _section = AppSection.tasks),
      onStartPomodoro: (Task _) => setState(() => _comingSoon = 'Pomodoro'),
    );
  }
}

// ─── Mystro floating button ───
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
        child: const Icon(Icons.auto_awesome,
            color: AppColors.teal, size: 24),
      ),
    );
  }
}

// ─── Sign Out dialog ───
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
              child:
                  const Icon(Icons.logout, color: AppColors.red, size: 26),
            ),
            const SizedBox(height: 18),
            const Text(
              'Sign Out?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Are you sure you want to sign out? You'll need to sign in again "
              "to access your tasks and progress.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.slateGray,
                height: 1.5,
              ),
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
                        border: Border.all(
                            color: AppColors.border, width: 1.5),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepNavy,
                        ),
                      ),
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
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
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