// lib/screens/profile/account_screen.dart
//
// Opened by tapping the avatar/name in the side drawer. Structure mirrors
// the reference design (hero + Badges + Achievement Score + Focus Stats +
// Weekly Habit Status), restyled in Quill.AI's own light palette. Badges,
// Achievement Score and Focus Statistics are all real now — computed from
// the app's actual Task/FocusSession/Habit/Flashcard lists via
// AchievementsService, not the static placeholder numbers this screen used
// to show. Weekly Habit Status was already real (built earlier). The one
// remaining "no data" chart (inside Achievement Score) stays honest on
// purpose — there's no stored day-by-day score history to plot, only a
// live current total, so a real line there would mean inventing history
// that doesn't exist.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../models/habit.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';
import '../../models/flashcard.dart';
import '../../services/achievements_service.dart';
import 'edit_profile_screen.dart';

class AccountScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? avatarPath;
  final List<Habit> habits;
  final List<Task> tasks;
  final List<FocusSession> sessions;
  final List<Flashcard> flashcards;
  final ValueChanged<String?> onAvatarChanged;
  final VoidCallback onSignOut;
  final VoidCallback onOpenHabits;
  // Bubbles a saved name change from EditProfileScreen back up to
  // AppShell -> FlowController, so the header/drawer reflect it without
  // needing a full app restart. Phone/password updates don't need this —
  // nothing else on screen displays them.
  final ValueChanged<String> onProfileUpdated;

  const AccountScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.avatarPath,
    required this.habits,
    required this.tasks,
    required this.sessions,
    required this.flashcards,
    required this.onAvatarChanged,
    required this.onSignOut,
    required this.onOpenHabits,
    required this.onProfileUpdated,
  });

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Total individual habit check-ins across the current week (Mon-Sun) —
  /// summed over every non-archived habit, not just one.
  int _weeklyCheckIns() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    var count = 0;
    for (final h in habits.where((h) => !h.archived)) {
      for (var i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        if (day.isAfter(now)) break;
        if (h.isDoneOn(day)) count++;
      }
    }
    return count;
  }

  /// Whether at least one habit was completed on each day of the current
  /// week — feeds the Mon..Sun dot row.
  List<bool> _weekdayDots() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final active = habits.where((h) => !h.archived).toList();
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      if (active.isEmpty) return false;
      return active.any((h) => h.isDoneOn(day));
    });
  }

  // ============================================================
  // FOCUS STATISTICS — real, current-week numbers from actual
  // FocusSession data (previously hardcoded: "35" pomos, "25h 26m",
  // "3h 38m" daily average, none of it computed from anything).
  // ============================================================
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _weekStart {
    final now = DateTime.now();
    return _dateOnly(now).subtract(Duration(days: now.weekday - 1));
  }

  List<FocusSession> get _weekSessions =>
      sessions.where((s) => s.isSuccessful && !s.completedAt.isBefore(_weekStart)).toList();

  int get _weekPomos => _weekSessions.length;

  Duration get _weekFocusDuration =>
      Duration(seconds: _weekSessions.fold<int>(0, (sum, s) => sum + s.actualSeconds));

  Duration get _dailyAverage => Duration(seconds: _weekFocusDuration.inSeconds ~/ 7);

  String _fmtHm(Duration d) => '${d.inHours}h ${d.inMinutes % 60}m';

  /// Minutes focused per weekday (Mon..Sun) this week — feeds the real bar
  /// chart that replaced the old static "No Data" box.
  List<int> _weekdayMinutes() {
    final start = _weekStart;
    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      final mins = _weekSessions
          .where((s) => _dateOnly(s.completedAt) == day)
          .fold<int>(0, (sum, s) => sum + (s.actualSeconds ~/ 60));
      return mins;
    });
  }

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      currentName: name,
                      currentEmail: email,
                      onSaved: onProfileUpdated,
                    ),
                  ),
                );
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
          Builder(builder: (context) {
            final achievements = AchievementsService.compute(
              tasks: tasks,
              sessions: sessions,
              habits: habits,
              flashcards: flashcards,
            );
            final unlockedBadges = achievements.badges.where((b) => b.tier > 0).length;
            return Column(
              children: [
                _buildCard(
                  title: 'My Badges',
                  trailing: '$unlockedBadges',
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        for (final b in achievements.badges)
                          _badge(b.icon, b.tier > 0 ? b.color : AppColors.border, '${b.tier}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'My Achievement Score',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _statBlock('Achievement Score', '${achievements.score}'),
                          const SizedBox(width: 32),
                          _statBlock('Level Lv.${achievements.level}', achievements.levelTitle),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _noDataChart(scoreDayLabels),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Focus Statistics',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statBlock('Total Pomos', '$_weekPomos'),
                    const SizedBox(width: 32),
                    _statBlock('Total Focus Duration', _fmtHm(_weekFocusDuration)),
                  ],
                ),
                const SizedBox(height: 20),
                _weekBarChart(_weekdayMinutes()),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daily Average',
                        style: TextStyle(fontSize: 13, color: AppColors.slateGray, fontWeight: FontWeight.w600)),
                    Text(_fmtHm(_dailyAverage),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Weekly Habit Status',
            onTap: onOpenHabits,
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
                Text('${_weeklyCheckIns()}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    return _HabitDay(label: _weekdayLabels[i], done: _weekdayDots()[i]);
                  }),
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

  /// Real per-weekday minutes-focused bars — replaces the static "No Data"
  /// box the Focus Statistics card used to show even though real
  /// FocusSession data existed the whole time, just never wired here.
  Widget _weekBarChart(List<int> minutesPerDay) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxMinutes = minutesPerDay.fold<int>(0, (m, v) => v > m ? v : m);
    return Column(
      children: [
        SizedBox(
          height: 90,
          child: minutesPerDay.every((m) => m == 0)
              ? Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.subtleGray, borderRadius: BorderRadius.circular(12)),
                  child: Text('No sessions this week',
                      style: TextStyle(fontSize: 13, color: AppColors.slateGray.withValues(alpha: 0.7))),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final m in minutesPerDay)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Container(
                            height: maxMinutes == 0 ? 4 : 6 + (m / maxMinutes) * 74,
                            decoration: BoxDecoration(
                              color: m > 0 ? AppColors.teal : AppColors.subtleGray,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
  final bool done;
  const _HabitDay({required this.label, this.done = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.teal : Colors.transparent,
            border: Border.all(color: done ? AppColors.teal : AppColors.border, width: 1.5),
          ),
          child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slateGray, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
