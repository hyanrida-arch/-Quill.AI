// lib/widgets/tasks/tag_picker.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/task.dart';

/// Lets the user set a custom label + color on a task, independent of
/// priority. Returns null if cancelled, {'remove': true} to clear an
/// existing tag, or {'label': String, 'color': int} to set one.
class TagPicker {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? currentLabel,
    int? currentColorValue,
  }) {
    return showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TagPickerSheet(
        currentLabel: currentLabel,
        currentColorValue: currentColorValue,
      ),
    );
  }
}

class _TagPickerSheet extends StatefulWidget {
  final String? currentLabel;
  final int? currentColorValue;

  const _TagPickerSheet({this.currentLabel, this.currentColorValue});

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  late final TextEditingController _controller;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentLabel ?? '');
    _selectedColor = widget.currentColorValue ?? kTagColorPresets.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tag', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(fontSize: 16, color: AppColors.deepNavy),
            decoration: InputDecoration(
              hintText: 'e.g. Work, Gym, Personal',
              hintStyle: const TextStyle(color: AppColors.slateGray),
              filled: true,
              fillColor: AppColors.subtleGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slateGray)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kTagColorPresets.map((c) {
              final isSelected = c == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: AppColors.deepNavy, width: 3) : null,
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.currentLabel != null) ...[
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, {'remove': true}),
                    child: const Text('Remove tag', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final label = _controller.text.trim();
                    if (label.isEmpty) {
                      Navigator.pop(context, null);
                      return;
                    }
                    Navigator.pop(context, {'label': label, 'color': _selectedColor});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepNavy,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
