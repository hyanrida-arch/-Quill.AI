// lib/widgets/focus/focus_history_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class FocusHistoryScreen extends StatelessWidget {
  const FocusHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const Icon(Icons.menu, color: AppColors.deepNavy),
        title: const Text('Focus History',
            style: TextStyle(
                color: AppColors.deepNavy, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none,
                  color: AppColors.deepNavy),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.school_outlined,
                  color: AppColors.teal),
              onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero stats card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppColors.deepNavy,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeroStat('4', 'POMOS TODAY'),
                  _buildHeroStat('2h 35m', 'FOCUSED', isLarge: true),
                  _buildHeroStat('8', 'DAY STREAK'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grid stats
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildGridStatCard("Today's Pomo", '4', isUp: true),
                _buildGridStatCard("Today's Focus", '2h 35m', isUp: true),
                _buildGridStatCard('Total Pomos', '35'),
                _buildGridStatCard('Total Duration', '25h 26m'),
              ],
            ),
            const SizedBox(height: 24),

            // Mystro insight banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightTeal,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: AppColors.teal, size: 16),
                      SizedBox(width: 8),
                      Text('PATTERN DETECTED',
                          style: TextStyle(
                              color: AppColors.teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your most productive time is 9–11 AM (78% completion rate). Want me to suggest tasks for that window?',
                    style: TextStyle(
                        color: AppColors.deepNavy,
                        fontSize: 14,
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Today section
            const Text('Today, May 30',
                style: TextStyle(
                    color: AppColors.deepNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildHistoryItem(
                '9:00 — 9:25 AM', 'Read Chapter 4', '0 pauses', '25m', true),
            _buildHistoryItem('9:35 — 10:00 AM', 'Read Chapter 4',
                '1 pause', '25m', true),
            _buildHistoryItem('11:10 — 11:28 AM', 'Problem set #3',
                '2 pauses · 1 interruption', '18m', false),
            const SizedBox(height: 24),

            // Yesterday section
            const Text('Yesterday, May 29',
                style: TextStyle(
                    color: AppColors.deepNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildHistoryItem(
                '8:50 — 9:15 AM', 'Essay outline', '0 pauses', '25m', true),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(String value, String label,
      {bool isLarge = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: isLarge ? 32 : 24,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.teal,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
      ],
    );
  }

  Widget _buildGridStatCard(String title, String value,
      {bool isUp = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.slateGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              if (isUp) ...[
                const SizedBox(width: 4),
                const Icon(Icons.arrow_upward,
                    size: 12, color: AppColors.teal)
              ]
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppColors.deepNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String time, String title, String subtitle,
      String duration, bool isSuccess) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time,
                  style: const TextStyle(
                      color: AppColors.deepNavy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.slateGray, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      color:
                      AppColors.slateGray.withValues(alpha: 0.7),
                      fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: isSuccess
                    ? AppColors.lightTeal
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    isSuccess
                        ? Icons.check
                        : Icons.warning_amber_rounded,
                    size: 14,
                    color: isSuccess
                        ? AppColors.teal
                        : const Color(0xFFF97316)),
                const SizedBox(width: 4),
                Text(duration,
                    style: TextStyle(
                        color: isSuccess
                            ? AppColors.teal
                            : const Color(0xFFF97316),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}