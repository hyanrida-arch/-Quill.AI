// lib/widgets/classroom/create_classroom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/classroom.dart';

/// Same "create or edit" sheet handles both flows, mirroring
/// AddHabitSheet's editing?/onSave pattern. Only teacher accounts (or a
/// classroom that's already a Class) can pick the "Class" type — students
/// only ever create Study Groups.
class CreateClassroomSheet extends StatefulWidget {
  final Classroom? editing;
  final bool isTeacher;
  final String ownerName;
  final ValueChanged<Classroom> onSave;

  const CreateClassroomSheet({
    super.key,
    this.editing,
    required this.isTeacher,
    required this.ownerName,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    Classroom? editing,
    required bool isTeacher,
    required String ownerName,
    required ValueChanged<Classroom> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateClassroomSheet(
        editing: editing,
        isTeacher: isTeacher,
        ownerName: ownerName,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CreateClassroomSheet> createState() => _CreateClassroomSheetState();
}

class _CreateClassroomSheetState extends State<CreateClassroomSheet> {
  late final TextEditingController _nameController;
  late ClassroomType _type;
  late int _colorValue;

  bool get _canPickClass => widget.isTeacher || widget.editing?.type == ClassroomType.teacherClass;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _type = e?.type ?? ClassroomType.peer;
    _colorValue = e?.colorValue ?? kClassroomColorPresets.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    HapticFeedback.mediumImpact();
    final result = (widget.editing ??
            Classroom(
              id: 'classroom_${DateTime.now().microsecondsSinceEpoch}',
              name: name,
              type: _type,
              colorValue: _colorValue,
              joinCode: generateClassroomJoinCode(),
              ownerName: widget.ownerName,
              createdAt: DateTime.now(),
            ))
        .copyWith(
      name: name,
      type: _type,
      colorValue: _colorValue,
    );
    widget.onSave(result);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.editing != null;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slateGray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isEditing ? 'Edit Classroom' : 'New Classroom',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            autofocus: !isEditing,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.deepNavy),
            decoration: const InputDecoration(
              hintText: 'e.g. ECON 301, or "Study Squad"',
              hintStyle: TextStyle(color: AppColors.slateGray, fontSize: 15, fontWeight: FontWeight.w500),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border, width: 1.5)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.teal, width: 2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 10),
          Row(
            children: [
              _typeChip('Study Group', ClassroomType.peer),
              if (_canPickClass) ...[
                const SizedBox(width: 10),
                _typeChip('Class', ClassroomType.teacherClass),
              ],
            ],
          ),
          if (!_canPickClass) ...[
            const SizedBox(height: 8),
            const Text(
              'Only teacher accounts can create a Class. Study groups are open to everyone.',
              style: TextStyle(fontSize: 11.5, color: AppColors.slateGray),
            ),
          ],
          const SizedBox(height: 20),
          const Text('Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kClassroomColorPresets.map((c) {
              final selected = c == _colorValue;
              return GestureDetector(
                onTap: () => setState(() => _colorValue = c),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: selected ? Border.all(color: AppColors.deepNavy, width: 2.5) : null,
                  ),
                  child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                isEditing ? 'Save Changes' : 'Create Classroom',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, ClassroomType type) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepNavy : AppColors.white,
          border: Border.all(color: selected ? AppColors.deepNavy : AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.deepNavy,
          ),
        ),
      ),
    );
  }
}
