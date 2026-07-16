// lib/widgets/common/side_drawer.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Sections the AppShell can switch between.
enum AppSection { home, tasks, calendar, pomodoro }

class SideDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? avatarPath;
  final AppSection current;
  final ValueChanged<AppSection> onSelect;
  final ValueChanged<String> onComingSoon;
  final VoidCallback onOpenAccount;

  const SideDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.avatarPath,
    required this.current,
    required this.onSelect,
    required this.onComingSoon,
    required this.onOpenAccount,
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
            // Profile header (فيه الإشعارات والإعدادات حدا السمية)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 12, 20),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onOpenAccount,
                      child: Row(
                        children: [
                          _Avatar(avatarPath: avatarPath, initial: initial, size: 48),
                          const SizedBox(width: 12),
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
                  ),
                  // 1. زر الإشعارات (الناقوس)
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: AppColors.deepNavy, size: 22),
                    onPressed: () => onComingSoon('Notifications'),
                  ),
                  // 2. زر الإعدادات (الترس)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.deepNavy, size: 22),
                    onPressed: () => onComingSoon('Settings'),
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
                      icon: Icons.track_changes_outlined,
                      label: 'Habits',
                      isSoon: true,
                      onTap: () => onComingSoon('Habits'),
                    ),
                    _DrawerRow(
                      icon: Icons.timer_outlined,
                      label: 'Pomodoro',
                      isActive: current == AppSection.pomodoro,
                      onTap: () => onSelect(AppSection.pomodoro),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Divider(height: 1, color: AppColors.border),
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
                    _DrawerRow(
                      icon: Icons.bar_chart_outlined,
                      label: 'Statistics',
                      isSoon: true,
                      onTap: () => onComingSoon('Statistics'),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: AppColors.border),
            _AddMenuControl(onComingSoon: onComingSoon),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Small circular avatar — shows the picked profile photo if one exists,
/// otherwise falls back to the user's initial on a deepNavy circle.
class _Avatar extends StatelessWidget {
  final String? avatarPath;
  final String initial;
  final double size;

  const _Avatar({required this.avatarPath, required this.initial, required this.size});

  @override
  Widget build(BuildContext context) {
    final path = avatarPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return ClipOval(
        child: Image.file(File(path), width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.deepNavy, shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w700, color: AppColors.white),
      ),
    );
  }
}

/// Bottom "+ Add" control — expands in place to offer List / Filter / Tag,
/// matching the shape of the reference design but in Quill.AI's own colors.
/// The three options aren't built yet, so they route through the same
/// onComingSoon(feature) stub used elsewhere in this drawer.
class _AddMenuControl extends StatefulWidget {
  final ValueChanged<String> onComingSoon;

  const _AddMenuControl({required this.onComingSoon});

  @override
  State<_AddMenuControl> createState() => _AddMenuControlState();
}

class _AddMenuControlState extends State<_AddMenuControl> {
  bool _isOpen = false;

  void _toggle() => setState(() => _isOpen = !_isOpen);

  void _selectOption(String option) {
    setState(() => _isOpen = false);
    widget.onComingSoon(option);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepNavy.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AddMenuItem(icon: Icons.list, label: 'List', onTap: () => _selectOption('List')),
                  const Divider(height: 1, color: AppColors.border),
                  _AddMenuItem(icon: Icons.filter_list, label: 'Filter', onTap: () => _selectOption('Filter')),
                  const Divider(height: 1, color: AppColors.border),
                  _AddMenuItem(icon: Icons.label_outline, label: 'Tag', onTap: () => _selectOption('Tag')),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(_isOpen ? Icons.close : Icons.add_circle_outline,
                        size: 22, color: AppColors.slateGray),
                    const SizedBox(width: 16),
                    const Text('Add',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.slateGray)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.tune, size: 20, color: AppColors.slateGray),
                      onPressed: () => widget.onComingSoon('Sort options'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddMenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.deepNavy),
            const SizedBox(width: 16),
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.deepNavy)),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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