// lib/screens/focus/focus_history_screen.dart
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Focus History',
          style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Badge(
              backgroundColor: AppColors.teal,
              smallSize: 8,
              child: Icon(Icons.notifications_none, color: AppColors.deepNavy),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Badge(
              backgroundColor: AppColors.teal,
              smallSize: 8,
              child: Icon(Icons.school_outlined, color: AppColors.deepNavy),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. Top Stats Card ───
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.deepNavy,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepNavy.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildStatColumn('4', 'POMOS TODAY'),
                  _buildDivider(),
                  _buildMainStatColumn('2h', '35m', 'FOCUSED'),
                  _buildDivider(),
                  _buildStatColumn('8', 'DAY STREAK'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── 2. Links ───
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'View weekly stats →',
                style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),

            // ─── 3. AI Insight Pattern ───
            Container(
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                    ),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: AppColors.teal, size: 14),
                              SizedBox(width: 8),
                              Text(
                                'PATTERN DETECTED',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.teal, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your most productive time is 9–11 AM (78% completion rate). Want me to suggest tasks for that window?',
                            style: TextStyle(fontSize: 13.5, color: AppColors.deepNavy, height: 1.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ─── 4. History List ───
            const Text(
              'Today, May 30',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
            ),
            const SizedBox(height: 12),

            _buildSessionCard(
              time: '9:00 — 9:25 AM',
              title: 'Read Chapter 4',
              subtitle: '0 pauses',
              duration: '25m',
              isSuccess: true,
            ),
            const SizedBox(height: 10),
            _buildSessionCard(
              time: '9:35 — 10:00 AM',
              title: 'Read Chapter 4',
              subtitle: '1 pause',
              duration: '25m',
              isSuccess: true,
            ),
            const SizedBox(height: 10),
            _buildSessionCard(
              time: '11:10 — 11:28 AM',
              title: 'Problem set #3',
              subtitle: '2 pauses · 1 interruption',
              duration: '18m',
              isSuccess: false,
            ),

            const SizedBox(height: 32),
            const Text(
              'Yesterday, May 29',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
            ),
            const SizedBox(height: 12),
            _buildSessionCard(
              time: '4:15 — 4:40 PM',
              title: 'Write Essay Draft',
              subtitle: '0 pauses',
              duration: '25m',
              isSuccess: true,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.teal, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _buildMainStatColumn(String hrs, String mins, String label) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(hrs, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.white, height: 1)),
            const SizedBox(width: 4),
            Text(mins, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.white, height: 1)),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.teal, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.slateGray.withValues(alpha: 0.3),
    );
  }

  Widget _buildSessionCard({
    required String time,
    required String title,
    required String subtitle,
    required String duration,
    required bool isSuccess,
  }) {
    final badgeColor = isSuccess ? AppColors.teal : AppColors.amber;
    final badgeIcon = isSuccess ? Icons.check : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 14, color: AppColors.slateGray)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                Icon(badgeIcon, size: 14, color: badgeColor),
                const SizedBox(width: 4),
                Text(duration, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: badgeColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
