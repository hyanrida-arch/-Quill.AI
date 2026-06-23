// lib/widgets/common/side_drawer.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Sections the AppShell can switch between.
enum AppSection { home, tasks, calendar, pomodoro }

class SideDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final AppSection current;
  final ValueChanged<AppSection> onSelect;
  final ValueChanged<String> onComingSoon;
  final VoidCallback onSignOut;

  const SideDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.current,
    required this.onSelect,
    required this.onComingSoon,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final name = userName.trim().isEmpty ? 'Your Account' : userName.trim();
    final email = userEmail.trim();
    final initial = name == 'Your Account'
        ? (email.isNotEmpty ? email[0].toUpperCase() : 'U')
        : name[0].toUpperCase();

    return Drawer(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.deepNavy,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavy,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.slateGray,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _DrawerRow(
                      icon: Icons.home_outlined,
                      label: 'Home',
                      isActive: current == AppSection.home,
                      onTap: () => onSelect(AppSection.home),
                    ),
                    _DrawerRow(
                      icon: Icons.check_box_outlined,
                      label: 'Tasks',
                      isActive: current == AppSection.tasks,
                      onTap: () => onSelect(AppSection.tasks),
                    ),
                    _DrawerRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Calendar',
                      isActive: current == AppSection.calendar,
                      onTap: () => onSelect(AppSection.calendar),
                    ),
                    _DrawerRow(
                      icon: Icons.timer_outlined,
                      label: 'Pomodoro',
                      isActive: current == AppSection.pomodoro,
                      onTap: () => onSelect(AppSection.pomodoro),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    _DrawerRow(
                      icon: Icons.bar_chart_outlined,
                      label: 'Statistics',
                      isSoon: true,
                      onTap: () => onComingSoon('Statistics'),
                    ),
                    _DrawerRow(
                      icon: Icons.track_changes_outlined,
                      label: 'Habits',
                      isSoon: true,
                      onTap: () => onComingSoon('Habits'),
                    ),
                    _DrawerRow(
                      icon: Icons.menu_book_outlined,
                      label: 'Notebook',
                      isSoon: true,
                      onTap: () => onComingSoon('Notebook'),
                    ),
                    _DrawerRow(
                      icon: Icons.layers_outlined,
                      label: 'Flashcards',
                      isSoon: true,
                      onTap: () => onComingSoon('Flashcards'),
                    ),
                    _DrawerRow(
                      icon: Icons.people_outline,
                      label: 'Classroom',
                      isSoon: true,
                      onTap: () => onComingSoon('Classroom'),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),

            _DrawerRow(
              icon: Icons.settings_outlined,
              label: 'Settings',
              isSoon: true,
              onTap: () => onComingSoon('Settings'),
            ),
            _DrawerRow(
              icon: Icons.logout,
              label: 'Sign Out',
              color: AppColors.red,
              onTap: onSignOut,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isSoon;
  final Color? color;
  final VoidCallback onTap;

  const _DrawerRow({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isSoon = false,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor =
        color ?? (isActive ? AppColors.deepNavy : AppColors.slateGray);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            if (isActive)
              Container(
                width: 4,
                height: 24,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.deepNavy,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(width: 20),

            Icon(icon, size: 22, color: displayColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: displayColor,
                ),
              ),
            ),
            if (isSoon)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lightTeal,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.teal, width: 1),
                ),
                child: const Text(
                  'SOON',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}