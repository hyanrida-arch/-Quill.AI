// lib/widgets/flashcards/generated_cards_review_sheet.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/flashcard.dart';

/// Shown after Mystro (Gemini) proposes flashcards from a note's text.
/// Nothing is created until "Add Cards" is tapped — every proposed card
/// can be edited or removed first, per the design notes' "human validates
/// before accepting" rule.
class GeneratedCardsReviewSheet extends StatefulWidget {
  final List<Map<String, String>> generated;
  final String? noteId;
  final ValueChanged<List<Flashcard>> onAccept;

  const GeneratedCardsReviewSheet({
    super.key,
    required this.generated,
    required this.noteId,
    required this.onAccept,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Map<String, String>> generated,
    required String? noteId,
    required ValueChanged<List<Flashcard>> onAccept,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GeneratedCardsReviewSheet(generated: generated, noteId: noteId, onAccept: onAccept),
    );
  }

  @override
  State<GeneratedCardsReviewSheet> createState() => _GeneratedCardsReviewSheetState();
}

class _GeneratedCardsReviewSheetState extends State<GeneratedCardsReviewSheet> {
  late List<TextEditingController> _questionControllers;
  late List<TextEditingController> _answerControllers;
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.generated.length;
    _questionControllers = widget.generated.map((c) => TextEditingController(text: c['question'])).toList();
    _answerControllers = widget.generated.map((c) => TextEditingController(text: c['answer'])).toList();
  }

  @override
  void dispose() {
    for (final c in _questionControllers) {
      c.dispose();
    }
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _removeAt(int index) {
    setState(() {
      _questionControllers.removeAt(index).dispose();
      _answerControllers.removeAt(index).dispose();
      _count--;
    });
  }

  void _acceptAll() {
    final now = DateTime.now();
    final cards = <Flashcard>[];
    for (var i = 0; i < _count; i++) {
      final q = _questionControllers[i].text.trim();
      final a = _answerControllers[i].text.trim();
      if (q.isEmpty || a.isEmpty) continue;
      cards.add(Flashcard(
        id: 'card_${now.microsecondsSinceEpoch}_$i',
        noteId: widget.noteId,
        question: q,
        answer: a,
        box: 1,
        nextReviewAt: now,
        createdAt: now,
      ));
    }
    widget.onAccept(cards);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Review $_count Generated Card${_count == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          const SizedBox(height: 4),
          const Text(
            'Edit or remove anything before adding these to your deck.',
            style: TextStyle(fontSize: 12.5, color: AppColors.slateGray),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: _count == 0
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No cards left — everything was removed.', style: TextStyle(color: AppColors.slateGray)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _count,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.subtleGray,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('QUESTION',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.slateGray)),
                                ),
                                GestureDetector(
                                  onTap: () => _removeAt(index),
                                  child: const Icon(Icons.close, size: 18, color: AppColors.slateGray),
                                ),
                              ],
                            ),
                            TextField(
                              controller: _questionControllers[index],
                              maxLines: null,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                            ),
                            const SizedBox(height: 10),
                            const Text('ANSWER',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.slateGray)),
                            TextField(
                              controller: _answerControllers[index],
                              maxLines: null,
                              style: const TextStyle(fontSize: 13.5, color: AppColors.deepNavy),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _count == 0 ? null : _acceptAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.subtleGray,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('Add $_count Card${_count == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
