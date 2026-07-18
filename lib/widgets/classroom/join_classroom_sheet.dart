// lib/widgets/classroom/join_classroom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../models/classroom.dart';

/// Joining only works if a classroom with this code already exists in this
/// device's local storage — there's no backend, so a code created on
/// someone else's phone can't be found here. That limitation is spelled
/// out on the sheet itself instead of being a silent, confusing dead end.
class JoinClassroomSheet extends StatefulWidget {
  final List<Classroom> existingClassrooms;
  final String memberName;
  final ValueChanged<Classroom> onJoined;

  const JoinClassroomSheet({
    super.key,
    required this.existingClassrooms,
    required this.memberName,
    required this.onJoined,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Classroom> existingClassrooms,
    required String memberName,
    required ValueChanged<Classroom> onJoined,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JoinClassroomSheet(
        existingClassrooms: existingClassrooms,
        memberName: memberName,
        onJoined: onJoined,
      ),
    );
  }

  @override
  State<JoinClassroomSheet> createState() => _JoinClassroomSheetState();
}

class _JoinClassroomSheetState extends State<JoinClassroomSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;

    Classroom? match;
    for (final c in widget.existingClassrooms) {
      if (c.joinCode == code) {
        match = c;
        break;
      }
    }
    if (match == null) {
      setState(() => _error = 'No classroom found with that code on this device.');
      return;
    }

    HapticFeedback.mediumImpact();
    final name = widget.memberName.trim();
    final updated = (name.isEmpty || match.roster.contains(name))
        ? match
        : match.copyWith(roster: [...match.roster, name]);
    widget.onJoined(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
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
          const Text('Join Classroom',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          const SizedBox(height: 8),
          const Text(
            'Quill.AI stores classrooms on this device only — enter a code from a classroom already created here.',
            style: TextStyle(fontSize: 12.5, color: AppColors.slateGray, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.deepNavy, letterSpacing: 4),
            textAlign: TextAlign.center,
            maxLength: 6,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'CODE',
              hintStyle: const TextStyle(color: AppColors.slateGray, letterSpacing: 4),
              filled: true,
              fillColor: AppColors.subtleGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Join', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
