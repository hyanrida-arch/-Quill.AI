// lib/widgets/notebook/create_notebook_sheet.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/notebook.dart';

/// Create or edit a Notebook. Same editing?/onSave pattern as
/// AddHabitSheet/CreateClassroomSheet.
class CreateNotebookSheet extends StatefulWidget {
  final Notebook? editing;
  final ValueChanged<Notebook> onSave;

  const CreateNotebookSheet({super.key, this.editing, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    Notebook? editing,
    required ValueChanged<Notebook> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateNotebookSheet(editing: editing, onSave: onSave),
    );
  }

  @override
  State<CreateNotebookSheet> createState() => _CreateNotebookSheetState();
}

class _CreateNotebookSheetState extends State<CreateNotebookSheet> {
  late final TextEditingController _titleController;
  late String _iconKey;
  late int _colorValue;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final n = widget.editing;
    _titleController = TextEditingController(text: n?.title ?? '');
    _iconKey = n?.iconKey ?? kNotebookIconPresets.keys.first;
    _colorValue = n?.colorValue ?? kNotebookColorPresets.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final notebook = (widget.editing ??
            Notebook(
              id: 'notebook_${DateTime.now().microsecondsSinceEpoch}',
              title: title,
              createdAt: DateTime.now(),
            ))
        .copyWith(title: title, iconKey: _iconKey, colorValue: _colorValue);
    widget.onSave(notebook);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(_colorValue);
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
            Text(_isEditing ? 'Edit Notebook' : 'New Notebook',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              autofocus: !_isEditing,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.deepNavy),
              decoration: InputDecoration(
                hintText: 'e.g. Macroeconomics, Physics',
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
              children: kNotebookIconPresets.entries.map((entry) {
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
              children: kNotebookColorPresets.map((c) {
                final isSelected = c == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = c),
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
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
                child: Text(_isEditing ? 'Save Changes' : 'Create Notebook',
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
}
