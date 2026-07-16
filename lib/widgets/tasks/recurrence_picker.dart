// lib/widgets/tasks/recurrence_picker.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';

/// Picks a RecurrenceRule — daily / weekly (specific weekdays) / monthly,
/// with an optional end date. Returns null if cancelled.
class RecurrencePicker {
  static Future<RecurrenceRule?> show(
    BuildContext context, {
    required RecurrenceRule current,
    required DateTime baseDate,
  }) {
    return showModalBottomSheet<RecurrenceRule?>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _RecurrencePickerSheet(current: current, baseDate: baseDate),
    );
  }
}

class _RecurrencePickerSheet extends StatefulWidget {
  final RecurrenceRule current;
  final DateTime baseDate;

  const _RecurrencePickerSheet({required this.current, required this.baseDate});

  @override
  State<_RecurrencePickerSheet> createState() => _RecurrencePickerSheetState();
}

class _RecurrencePickerSheetState extends State<_RecurrencePickerSheet> {
  late RecurrenceType _type;
  late Set<int> _weekdays;
  DateTime? _endDate;

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _type = widget.current.type;
    _weekdays = Set<int>.from(
      widget.current.weekdays.isEmpty && widget.current.type == RecurrenceType.weekly
          ? {widget.baseDate.weekday}
          : widget.current.weekdays,
    );
    _endDate = widget.current.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Repeat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            _typeOption(RecurrenceType.none, 'Does not repeat'),
            _typeOption(RecurrenceType.daily, 'Daily'),
            _typeOption(RecurrenceType.weekly, 'Weekly'),
            if (_type == RecurrenceType.weekly) _weekdaySelector(),
            _typeOption(RecurrenceType.monthly, 'Monthly (same date)'),
            const SizedBox(height: 12),
            if (_type != RecurrenceType.none) _endDateRow(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    RecurrenceRule(
                      type: _type,
                      weekdays: _type == RecurrenceType.weekly ? _weekdays : {},
                      endDate: _endDate,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepNavy,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeOption(RecurrenceType type, String label) {
    final isSelected = _type == type;
    return InkWell(
      onTap: () => setState(() {
        _type = type;
        if (type == RecurrenceType.weekly && _weekdays.isEmpty) {
          _weekdays = {widget.baseDate.weekday};
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.teal : AppColors.slateGray, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.deepNavy)),
          ],
        ),
      ),
    );
  }

  Widget _weekdaySelector() {
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8, top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(7, (i) {
          final day = i + 1; // 1=Mon..7=Sun, matches DateTime.weekday
          final isSelected = _weekdays.contains(day);
          return GestureDetector(
            onTap: () => setState(() {
              if (isSelected) {
                _weekdays.remove(day);
              } else {
                _weekdays.add(day);
              }
            }),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.teal : AppColors.subtleGray,
              ),
              child: Text(_weekdayLabels[i],
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.white : AppColors.slateGray)),
            ),
          );
        }),
      ),
    );
  }

  Widget _endDateRow() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _endDate ?? widget.baseDate.add(const Duration(days: 30)),
          firstDate: widget.baseDate,
          lastDate: widget.baseDate.add(const Duration(days: 365 * 3)),
          builder: (context, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.teal, onSurface: AppColors.deepNavy),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _endDate = picked);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Ends', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
            Row(
              children: [
                Text(_endDate == null ? 'Never' : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                    style: const TextStyle(fontSize: 14, color: AppColors.teal, fontWeight: FontWeight.w600)),
                if (_endDate != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppColors.slateGray),
                    onPressed: () => setState(() => _endDate = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
