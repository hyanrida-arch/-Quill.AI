// lib/screens/profile/account_screen.dart
//
// Opened by tapping the avatar/name in the side drawer. Structure mirrors
// the reference design (hero + Badges + Achievement Score + Focus Stats +
// Weekly Habit Status), but restyled in Quill.AI's own light palette rather
// than the reference's dark theme. Badges / Achievement Score / Weekly Habit
// Status have no real data model behind them yet (Habits is still a "SOON"
// stub elsewhere in the app), so those numbers are static placeholders —
// Focus Statistics reuses the same mock totals already shown in
// FocusHistoryScreen so the two screens don't contradict each other.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';

class AccountScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? avatarPath;
  final ValueChanged<String?> onAvatarChanged;
  final VoidCallback onSignOut;

  const AccountScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.avatarPath,
    required this.onAvatarChanged,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final name = userName.trim().isEmpty ? 'Your Account' : userName.trim();
    final email = userEmail.trim();
    final initial = name == 'Your Account'
        ? (email.isNotEmpty ? email[0].toUpperCase() : 'U')
        : name[0].toUpperCase();

    final today = DateTime.now();
    final scoreDayLabels = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return i == 6 ? 'Today' : _ordinal(d.day);
    });

    return Scaffold(
      backgroundColor: AppColors.subtleGray,
      appBar: AppBar(
        backgroundColor: AppColors.subtleGray,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.deepNavy),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: AppColors.white,
            position: PopupMenuPosition.under,
            onSelected: (value) {
              if (value == 'signout') {
                onSignOut();
              } else {
                _comingSoon(context, 'Account settings');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'account', child: Text('Account')),
              const PopupMenuItem(
                value: 'signout',
                child: Text('Sign Out', style: TextStyle(color: AppColors.red)),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _buildHero(context, name, initial),
          const SizedBox(height: 16),
          _buildCard(
            title: 'My Badges',
            trailing: '13',
            onTap: () => _comingSoon(context, 'Badges'),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  _badge(Icons.shield, AppColors.red, '5'),
                  _badge(Icons.shield, AppColors.amber, '4'),
                  _badge(Icons.emoji_events, AppColors.slateGray, '3'),
                  _badge(Icons.stars_rounded, AppColors.teal, '3'),
                  _badge(Icons.shield, AppColors.amber, '3'),
                  _badge(Icons.military_tech, AppColors.slateGray, '2'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'My Achievement Score',
            onTap: () => _comingSoon(context, 'Achievement Score'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statBlock('Achievement Score', '356'),
                    const SizedBox(width: 32),
                    _statBlock('Level Lv.3', 'Hardworker'),
                  ],
                ),
                const SizedBox(height: 20),
                _noDataChart(scoreDayLabels),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Focus Statistics',
            onTap: () => _comingSoon(context, 'Focus Statistics'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statBlock('Total Pomos', '35'),
                    const SizedBox(width: 32),
                    _statBlock('Total Focus Duration', '25h 26m'),
                  ],
                ),
                const SizedBox(height: 20),
                _noDataChart(const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Daily Average',
                        style: TextStyle(fontSize: 13, color: AppColors.slateGray, fontWeight: FontWeight.w600)),
                    Text('3h 38m',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Weekly Habit Status',
            onTap: () => _comingSoon(context, 'Habits'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Weekly Check-in',
                        style: TextStyle(fontSize: 13, color: AppColors.slateGray, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('0',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HabitDay(label: 'Mon'),
                    _HabitDay(label: 'Tue'),
                    _HabitDay(label: 'Wed'),
                    _HabitDay(label: 'Thu'),
                    _HabitDay(label: 'Fri'),
                    _HabitDay(label: 'Sat'),
                    _HabitDay(label: 'Sun'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, String name, String initial) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(color: AppColors.deepNavy, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showAvatarOptions(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildAvatar(initial),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.deepNavy, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 13, color: AppColors.deepNavy),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _comingSoon(context, 'Premium'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.teal),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Upgrade to Premium', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                Row(
                  children: [
                    if (trailing != null)
                      Text(trailing,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slateGray)),
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.slateGray),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String initial) {
    final path = avatarPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return ClipOval(
        child: Image.file(File(path), width: 76, height: 76, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.teal, width: 2),
        color: AppColors.white.withValues(alpha: 0.08),
      ),
      child: Text(initial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.white)),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('Profile Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
              const SizedBox(height: 12),
              _avatarOptionTile(
                icon: Icons.camera_alt_outlined,
                label: 'Take a photo',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              _avatarOptionTile(
                icon: Icons.photo_library_outlined,
                label: 'Choose from gallery',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              if (avatarPath != null && avatarPath!.isNotEmpty)
                _avatarOptionTile(
                  icon: Icons.delete_outline,
                  label: 'Remove photo',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onAvatarChanged(null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.red : AppColors.deepNavy;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 85);
      if (picked != null) onAvatarChanged(picked.path);
    } catch (_) {
      if (context.mounted) {
        _showError(context, "Couldn't access ${source == ImageSource.camera ? 'the camera' : 'your photos'}.");
      }
    }
  }

  Widget _statBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.slateGray, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
      ],
    );
  }

  Widget _badge(IconData icon, Color color, String count) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.deepNavy,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: Text(count,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noDataChart(List<String> labels) {
    return Column(
      children: [
        Container(
          height: 90,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.subtleGray, borderRadius: BorderRadius.circular(12)),
          child: Text('No Data',
              style: TextStyle(fontSize: 13, color: AppColors.slateGray.withValues(alpha: 0.7))),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in labels)
              Text(l, style: const TextStyle(fontSize: 10, color: AppColors.slateGray)),
          ],
        ),
      ],
    );
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  static void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.red),
    );
  }
}

class _HabitDay extends StatelessWidget {
  final String label;
  const _HabitDay({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slateGray, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
