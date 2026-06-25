// lib/screens/calendar/calendar_body.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

enum CalendarViewType { agenda, day, week, month }

class CalendarBody extends StatefulWidget {
  const CalendarBody({super.key});

  @override
  State<CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends State<CalendarBody> {
  CalendarViewType _currentView = CalendarViewType.agenda;
  final DateTime _selectedDate = DateTime(2026, 5, 30); // مريكل على ماي 2026 بحال التصميم

  void _switchView(CalendarViewType view) {
    HapticFeedback.selectionClick();
    setState(() => _currentView = view);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header & Tabs ───
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calendar',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.deepNavy, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                _currentView == CalendarViewType.month ? 'May 2026' : 'Your upcoming days',
                style: const TextStyle(fontSize: 15, color: AppColors.slateGray),
              ),
              const SizedBox(height: 20),

              // Custom TickTick-style Segmented Control
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.slateGray.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTab('Agenda', CalendarViewType.agenda),
                    _buildTab('Day', CalendarViewType.day),
                    _buildTab('Week', CalendarViewType.week),
                    _buildTab('Month', CalendarViewType.month),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ─── Body Content ───
        Expanded(
          child: _buildCurrentView(),
        ),
      ],
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case CalendarViewType.agenda:
        return _buildAgendaView();
      case CalendarViewType.month:
        return _buildMonthView();
      case CalendarViewType.day:
      case CalendarViewType.week:
      // دمجناهم مؤقتا فنفس الستيل باش يبان الديزاين النقي
        return _buildDayView();
    }
  }

  // ==========================================
  // 1. AGENDA VIEW (List format)
  // ==========================================
  Widget _buildAgendaView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _buildAgendaDayGroup(
          date: '30',
          dayLabel: 'Today',
          events: [
            _buildEventCard('9:00 - 11:00', 'MicroPython ESP32 Simulation', 'FROM TASKS', AppColors.white, AppColors.teal),
            _buildEventCard('11:00 - 12:00', 'Pomodoro - Arabic Syntax Review', '✓ COMPLETED', AppColors.teal.withValues(alpha: 0.1), AppColors.teal),
            _buildEventCard('14:00 - 15:30', 'AI Sync with Amjad', 'CLASSROOM', AppColors.amber.withValues(alpha: 0.1), AppColors.amber),
          ],
        ),
        const SizedBox(height: 24),
        _buildAgendaDayGroup(
          date: '31',
          dayLabel: 'Tomorrow',
          events: [
            _buildEventCard('10:00 - 13:00', 'JobIntech RapidMiner Prep', 'FROM TASKS', AppColors.white, AppColors.deepNavy),
          ],
        ),
        const SizedBox(height: 80), // مساحة للـ Dock
      ],
    );
  }

  Widget _buildAgendaDayGroup({required String date, required String dayLabel, required List<Widget> events}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Column
        SizedBox(
          width: 50,
          child: Column(
            children: [
              Text(date, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
              Text(dayLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dayLabel == 'Today' ? AppColors.teal : AppColors.slateGray)),
              const SizedBox(height: 8),
              Container(width: 2, height: 100, color: AppColors.slateGray.withValues(alpha: 0.2)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Events Column
        Expanded(
          child: Column(
            children: events.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: e)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(String time, String title, String tag, Color bgColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor == AppColors.white ? AppColors.border : Colors.transparent),
        boxShadow: bgColor == AppColors.white ? [BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))] : [],
      ),
      child: Row(
        children: [
          Container(width: 3, height: 40, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(fontSize: 12, color: AppColors.slateGray, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              ],
            ),
          ),
          Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accentColor, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // ==========================================
  // 2. DAY/WEEK VIEW (Timeline format)
  // ==========================================
  Widget _buildDayView() {
    return Column(
      children: [
        // Horizontal Date Strip
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 7,
            itemBuilder: (context, index) {
              final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
              final dates = ['25', '26', '27', '28', '29', '30', '31'];
              final isSelected = index == 5; // Day 30

              return Container(
                width: 48,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.deepNavy : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(days[index], style: TextStyle(fontSize: 12, color: isSelected ? AppColors.white : AppColors.slateGray)),
                    const SizedBox(height: 4),
                    Text(dates[index], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isSelected ? AppColors.white : AppColors.deepNavy)),
                  ],
                ),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Friday, May 30', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildTimelineRow('9a', _buildEventCard('9:00 - 11:00', 'MicroPython Lab', 'TASKS', AppColors.white, AppColors.teal)),
              _buildTimelineRow('11a', _buildEventCard('11:00 - 12:00', 'Arabic Syntax', 'DONE', AppColors.teal.withValues(alpha: 0.1), AppColors.teal)),
              _buildTimelineRow('1p', const SizedBox(height: 60)), // Empty hour
              _buildTimelineRow('2p', _buildEventCard('14:00 - 15:30', 'AI Project Sync', 'CLASS', AppColors.amber.withValues(alpha: 0.1), AppColors.amber)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow(String time, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(time, style: const TextStyle(fontSize: 12, color: AppColors.slateGray, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  // ==========================================
  // 3. MONTH VIEW (Grid format)
  // ==========================================
  Widget _buildMonthView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.chevron_left, color: AppColors.deepNavy),
                  SizedBox(width: 16),
                  Icon(Icons.chevron_right, color: AppColors.deepNavy),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(100)),
                child: const Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: 35, // 5 weeks
            itemBuilder: (context, index) {
              if (index < 7) {
                // Days of week header
                final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                return Center(child: Text(days[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slateGray)));
              }
              final dayNum = index - 6;
              final isSelected = dayNum == 30;
              final hasEvents = dayNum % 4 == 0;

              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.deepNavy : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$dayNum', style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.white : AppColors.deepNavy)),
                    if (hasEvents) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
                          const SizedBox(width: 2),
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle)),
                        ],
                      )
                    ]
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Shared UI Helpers ───
  Widget _buildTab(String title, CalendarViewType type) {
    final isSel = _currentView == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchView(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.deepNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSel ? [BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
              color: isSel ? AppColors.white : AppColors.slateGray,
            ),
          ),
        ),
      ),
    );
  }
}