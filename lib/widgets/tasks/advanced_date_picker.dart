// lib/widgets/tasks/advanced_date_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';

class AdvancedDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;

  const AdvancedDatePicker({
    super.key,
    required this.initialDate,
    this.initialStartTime,
    this.initialEndTime,
  });

  static Future<Map<String, dynamic>?> show(
      BuildContext context, {
        required DateTime initialDate,
        TimeOfDay? initialStartTime,
        TimeOfDay? initialEndTime,
      }) {
    return showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedDatePicker(
        initialDate: initialDate,
        initialStartTime: initialStartTime,
        initialEndTime: initialEndTime,
      ),
    );
  }

  @override
  State<AdvancedDatePicker> createState() => _AdvancedDatePickerState();
}

class _AdvancedDatePickerState extends State<AdvancedDatePicker> {
  bool _isDurationTab = false;
  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;

  String _selectedReminder = 'None';
  String _selectedRepeat = 'None';

  final List<String> _reminders = [
    'None',
    'On time',
    '5 mins early',
    '30 mins early',
    '1 hour early',
    '1 day early',
  ];

  final List<String> _repeats = [
    'None',
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
    'Every Weekday',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
  }

  String get _durationText {
    if (_startTime == null || _endTime == null) return 'Duration: 1 hour';
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    int diff = endMinutes - startMinutes;
    if (diff < 0) diff += 24 * 60;
    final h = diff ~/ 60;
    final m = diff % 60;
    if (h == 0) return 'Duration: $m mins';
    if (m == 0) return 'Duration: $h hour${h > 1 ? 's' : ''}';
    return 'Duration: $h h $m m';
  }

  String get _timeRangeText {
    if (_startTime == null && _endTime == null) return '08:00 - 09:00';
    if (_startTime != null && _endTime == null) {
      return '${_startTime!.format(context)} - --:--';
    }
    return '${_startTime!.format(context)} - ${_endTime!.format(context)}';
  }

  // Shared theming so every native picker (date + time) matches Quill AI's
  // own palette instead of falling back to Material's default purple/blue.
  Widget _themedPicker(BuildContext context, Widget? child) {
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.teal,
          onPrimary: AppColors.white,
          onSurface: AppColors.deepNavy,
          surface: AppColors.white,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.teal),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.white,
          dialBackgroundColor: AppColors.subtleGray,
          dialHandColor: AppColors.teal,
          hourMinuteShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          hourMinuteColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.lightTeal
                  : AppColors.subtleGray),
          hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.teal
                  : AppColors.deepNavy),
          dialTextColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.white
                  : AppColors.deepNavy),
          dayPeriodShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.border),
          ),
          dayPeriodBorderSide: const BorderSide(color: AppColors.border),
          dayPeriodColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.lightTeal
                  : AppColors.white),
          dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.teal
                  : AppColors.slateGray),
          entryModeIconColor: AppColors.slateGray,
          helpTextStyle: const TextStyle(
              color: AppColors.deepNavy, fontWeight: FontWeight.w600),
        ),
      ),
      child: child!,
    );
  }

  Future<void> _pickTimeRange() async {
    final start = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: _themedPicker,
    );
    if (start == null) return;
    if (!mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: _endTime ??
          TimeOfDay(hour: start.hour + 1, minute: start.minute),
      builder: _themedPicker,
    );
    if (end == null) return;

    setState(() {
      _startTime = start;
      _endTime = end;
      _isAllDay = false;
    });
  }

  Future<void> _showMiniCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: _themedPicker,
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showOptionsModal(
      String title,
      List<String> options,
      String currentValue,
      ValueChanged<String> onSelect,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepNavy)),
                ),
              ),
              const SizedBox(height: 8),
              ...options.map((r) => InkWell(
                onTap: () {
                  onSelect(r);
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: currentValue == r
                                  ? AppColors.teal
                                  : AppColors.deepNavy)),
                      if (currentValue == r)
                        const Icon(Icons.check,
                            color: AppColors.teal, size: 20),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.slateGray),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
                _buildTab('Date', !_isDurationTab),
                const SizedBox(width: 24),
                _buildTab('Duration', _isDurationTab),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.teal),
                  onPressed: () {
                    Navigator.pop(context, {
                      'date': _selectedDate,
                      'startTime': _startTime,
                      'endTime': _endTime,
                      'isAllDay': _isAllDay,
                      'reminder': _selectedReminder,
                      'repeat': _selectedRepeat,
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _isDurationTab ? _buildDurationView() : _buildDateView(),
            ),
          ),

          // Clear button
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _startTime = null;
                  _endTime = null;
                  _isAllDay = false;
                  _selectedReminder = 'None';
                  _selectedRepeat = 'None';
                  _selectedDate = DateTime.now();
                });
              },
              child: const Text('Clear',
                  style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _isDurationTab = title == 'Duration'),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.deepNavy : AppColors.slateGray,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 24,
            decoration: BoxDecoration(
              color: isActive ? AppColors.deepNavy : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDurationView() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _showMiniCalendar,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.subtleGray,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date',
                          style: TextStyle(
                              color: AppColors.slateGray,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text('Selected',
                          style: TextStyle(
                              color: AppColors.slateGray, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _pickTimeRange,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.subtleGray,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Time',
                          style: TextStyle(
                              color: AppColors.slateGray,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        _isAllDay ? '--:-- - --:--' : _timeRangeText,
                        style: TextStyle(
                            color: _isAllDay
                                ? AppColors.slateGray
                                : AppColors.deepNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          _isAllDay ? 'Duration: All day' : _durationText,
                          style: const TextStyle(
                              color: AppColors.slateGray, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('All day',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepNavy)),
              Switch(
                value: _isAllDay,
                activeColor: AppColors.teal,
                onChanged: (val) {
                  setState(() {
                    _isAllDay = val;
                    if (val) {
                      _startTime = null;
                      _endTime = null;
                    }
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildActionRow(Icons.alarm, 'Reminder', _selectedReminder, () {
          _showOptionsModal('Reminder', _reminders, _selectedReminder,
                  (v) => setState(() => _selectedReminder = v));
        }),
        const Divider(height: 1, color: AppColors.border),
        _buildActionRow(Icons.repeat, 'Repeat', _selectedRepeat, () {
          _showOptionsModal('Repeat', _repeats, _selectedRepeat,
                  (v) => setState(() => _selectedRepeat = v));
        }),
      ],
    );
  }

  Widget _buildDateView() {
    return Column(
      children: [
        Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal,
              onSurface: AppColors.deepNavy,
            ),
          ),
          child: CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            onDateChanged: (date) => setState(() => _selectedDate = date),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.subtleGray,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildActionRow(
                Icons.access_time,
                'Time',
                _startTime != null ? _startTime!.format(context) : 'None',
                    () async {
                  final start = await showTimePicker(
                    context: context,
                    initialTime:
                    _startTime ?? const TimeOfDay(hour: 8, minute: 0),
                    builder: _themedPicker,
                  );
                  if (start != null) setState(() => _startTime = start);
                },
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildActionRow(Icons.alarm, 'Reminder', _selectedReminder,
                      () {
                    _showOptionsModal('Reminder', _reminders, _selectedReminder,
                            (v) => setState(() => _selectedReminder = v));
                  }),
              const Divider(height: 1, color: AppColors.border),
              _buildActionRow(Icons.repeat, 'Repeat', _selectedRepeat, () {
                _showOptionsModal('Repeat', _repeats, _selectedRepeat,
                        (v) => setState(() => _selectedRepeat = v));
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(
      IconData icon, String title, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.slateGray, size: 20),
            const SizedBox(width: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy)),
            const Spacer(),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: AppColors.slateGray, size: 20),
          ],
        ),
      ),
    );
  }
}