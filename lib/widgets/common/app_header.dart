// lib/widgets/common/app_header.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Top app bar used by the AppShell. Burger menu on the left, notification +
/// classroom icons on the right, optional trailing widget (e.g. "+Add").
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onClassroomTap;
  final VoidCallback? onNotificationTap;
  final bool hasClassroomBadge;
  final bool hasNotificationBadge;
  final Widget? trailingExtra;

  const AppHeader({
    super.key,
    this.onMenuTap,
    this.onClassroomTap,
    this.onNotificationTap,
    this.hasClassroomBadge = true,
    this.hasNotificationBadge = true,
    this.trailingExtra,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.menu,
            onTap: onMenuTap,
            size: 24,
          ),
          const Spacer(),
          _HeaderIconButton(
            icon: Icons.notifications_outlined,
            onTap: onNotificationTap,
            size: 22,
            hasBadge: hasNotificationBadge,
          ),
          const SizedBox(width: 16),
          _HeaderIconButton(
            icon: Icons.school_outlined,
            onTap: onClassroomTap,
            size: 22,
            hasBadge: hasClassroomBadge,
          ),
          if (trailingExtra != null) ...[
            const SizedBox(width: 12),
            trailingExtra!,
          ],
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool hasBadge;

  const _HeaderIconButton({
    required this.icon,
    this.onTap,
    this.size = 24,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, size: size, color: AppColors.deepNavy),
            if (hasBadge)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}