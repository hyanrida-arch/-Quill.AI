// lib/widgets/habits/add_habit_sheet.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/themed_time_picker.dart';
import '../../models/habit.dart';

/// Create or edit a Habit. Pass [editing] to prefill for an edit; omit it
/// (or pass null) to create a new one. Returns nothing directly — saves
/// happen through [onSave] so the caller (HabitsBody) owns the single
/// source-of-truth list, same pattern as AddTaskSheet/onAdd.
class AddHabitSheet extends StatefulWidget {
  final Habit? editing;
  final ValueChanged<Habit> onSave;

  const AddHabitSheet({super.key, this.editing, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    Habit? editing,
    required ValueChanged<Habit> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddHabitSheet(editing: editing, onSave: onSave),
    );
  }

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  late final TextEditingController _titleController;
  late String _iconKey;
  late int _colorValue;
  late HabitType _type;
  late int _targetCount;
  late HabitFrequencyType _frequencyType;
  late Set<int> _weekdays;
  late int _timesPerWeek;
  TimeOfDay? _reminderTime;

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.editing;
    _titleController = TextEditingController(text: h?.title ?? '');
    _iconKey = h?.iconKey ?? kHabitIconPresets.keys.first;
    _colorValue = h?.colorValue ?? kHabitColorPresets.first;
    _type = h?.type ?? HabitType.yesNo;
    _targetCount = h?.targetCount ?? 1;
    _frequencyType = h?.frequency.type ?? HabitFrequencyType.daily;
    _weekdays = Set<int>.from(h?.frequency.weekdays ?? const <int>{});
    _timesPerWeek = h?.frequency.timesPerWeek ?? 3;
    _reminderTime = h?.reminderTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final frequency = HabitFrequency(
      type: _frequencyType,
      weekdays: _frequencyType == HabitFrequencyType.weekdays ? _weekdays : const {},
      timesPerWeek: _timesPerWeek,
    );
    final habit = (widget.editing ??
            Habit(
              id: 'habit_${DateTime.now().microsecondsSinceEpoch}',
              title: title,
              createdAt: DateTime.now(),
            ))
        .copyWith(
      title: title,
      iconKey: _iconKey,
      colorValue: _colorValue,
      type: _type,
      targetCount: _type == HabitType.count ? _targetCount : 1,
      frequency: frequency,
      reminderTime: _reminderTime,
      clearReminder: _reminderTime == null,
    );
    widget.onSave(habit);
    Navigator.pop(context);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: themedTimePickerBuilder,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(_colorValue);
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            Text(_isEditing ? 'Edit Habit' : 'New Habit',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              autofocus: !_isEditing,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.deepNavy),
              decoration: InputDecoration(
                hintText: 'e.g. Drink water, Meditate, Read',
                hintStyle: const TextStyle(color: AppColors.slateGray, fontWeight: FontWeight.w500),
                filled: true,
                fillColor: AppColors.subtleGray,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 22),

            _sectionLabel('Icon'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kHabitIconPresets.entries.map((entry) {
                final isSelected = entry.key == _iconKey;
                return GestureDetector(
                  onTap: () => setState(() => _iconKey = entry.key),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? accent.withValues(alpha: 0.15) : AppColors.subtleGray,
                      border: isSelected ? Border.all(color: accent, width: 1.6) : null,
                    ),
                    child: Icon(entry.value, size: 20, color: isSelected ? accent : AppColors.slateGray),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            _sectionLabel('Color'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: kHabitColorPresets.map((c) {
                final isSelected = c == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = c),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: AppColors.deepNavy, width: 3) : null,
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            _sectionLabel('Type'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _choiceChip('Yes / No', _type == HabitType.yesNo, () => setState(() => _type = HabitType.yesNo))),
                const SizedBox(width: 10),
                Expanded(child: _choiceChip('Count', _type == HabitType.count, () => setState(() => _type = HabitType.count))),
              ],
            ),
            if (_type == HabitType.count) ...[
              const SizedBox(height: 14),
              _stepperRow(
                label: 'Target per day',
                value: _targetCount,
                suffix: _targetCount == 1 ? 'time' : 'times',
                onDecrement: _targetCount > 1 ? () => setState(() => _targetCount--) : null,
                onIncrement: _targetCount < 50 ? () => setState(() => _targetCount++) : null,
              ),
            ],
            const SizedBox(height: 22),

            _sectionLabel('Frequency'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _choiceChip('Every day', _frequencyType == HabitFrequencyType.daily,
                    () => setState(() => _frequencyType = HabitFrequencyType.daily)),
                _choiceChip('Specific days', _frequencyType == HabitFrequencyType.weekdays, () {
                  setState(() {
                    _frequencyType = HabitFrequencyType.weekdays;
                    if (_weekdays.isEmpty) _weekdays = {DateTime.now().weekday};
                  });
                }),
                _choiceChip('X times a week', _frequencyType == HabitFrequencyType.timesPerWeek,
                    () => setState(() => _frequencyType = HabitFrequencyType.timesPerWeek)),
              ],
            ),
            if (_frequencyType == HabitFrequencyType.weekdays) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final day = i + 1;
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
                        color: isSelected ? accent : AppColors.subtleGray,
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
            ],
            if (_frequencyType == HabitFrequencyType.timesPerWeek) ...[
              const SizedBox(height: 14),
              _stepperRow(
                label: 'Times per week',
                value: _timesPerWeek,
                suffix: '',
                onDecrement: _timesPerWeek > 1 ? () => setState(() => _timesPerWeek--) : null,
                onIncrement: _timesPerWeek < 7 ? () => setState(() => _timesPerWeek++) : null,
              ),
            ],
            const SizedBox(height: 22),

            _sectionLabel('Reminder'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickReminderTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _reminderTime != null ? accent.withValues(alpha: 0.12) : AppColors.subtleGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_none, size: 18, color: _reminderTime != null ? accent : AppColors.slateGray),
                    const SizedBox(width: 10),
                    Text(
                      _reminderTime == null ? 'No reminder' : _reminderTime!.format(context),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _reminderTime != null ? accent : AppColors.deepNavy),
                    ),
                    const Spacer(),
                    if (_reminderTime != null)
                      GestureDetector(
                        onTap: () => setState(() => _reminderTime = null),
                        child: const Icon(Icons.close, size: 18, color: AppColors.slateGray),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepNavy,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(_isEditing ? 'Save Changes' : 'Create Habit',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) =>
      Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy));

  Widget _choiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepNavy : AppColors.subtleGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.white : AppColors.deepNavy)),
      ),
    );
  }

  Widget _stepperRow({
    required String label,
    required int value,
    required String suffix,
    required VoidCallback? onDecrement,
    required VoidCallback? onIncrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
        Row(
          children: [
            _stepperButton(Icons.remove, onDecrement),
            SizedBox(
              width: 56,
              child: Text('$value${suffix.isEmpty ? '' : ' $suffix'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            ),
            _stepperButton(Icons.add, onIncrement),
          ],
        ),
      ],
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap == null ? AppColors.subtleGray : AppColors.deepNavy,
        ),
        child: Icon(icon, size: 16, color: onTap == null ? AppColors.slateGray : AppColors.white),
      ),
    );
  }
}
