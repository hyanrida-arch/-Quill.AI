// lib/screens/flashcards/review_session_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/flashcard.dart';
import '../../models/notebook.dart';

/// One review pass over whatever due cards were handed in. Flip -> mark
/// Correct/Incorrect -> Leitner box transition applies immediately via
/// Flashcard.withOutcome. On a miss, if the card is linked to a note, the
/// end-of-session summary offers a plain "reread the source note" link —
/// not an AI suggestion, just a direct navigational hint from the existing
/// noteId reference, closing the loop the design notes describe without
/// pretending it's something it isn't.
class ReviewSessionScreen extends StatefulWidget {
  final List<Flashcard> dueCards;
  final List<Note> notes;
  final ValueChanged<Flashcard> onReview;
  final void Function(String cardId, bool correct) onRecordReview;

  const ReviewSessionScreen({
    super.key,
    required this.dueCards,
    required this.notes,
    required this.onReview,
    required this.onRecordReview,
  });

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  late List<Flashcard> _queue;
  int _index = 0;
  bool _showAnswer = false;
  int _correctCount = 0;
  final List<Flashcard> _missed = [];

  @override
  void initState() {
    super.initState();
    _queue = List<Flashcard>.from(widget.dueCards);
  }

  bool get _finished => _index >= _queue.length;

  Note? _noteFor(String? noteId) {
    if (noteId == null) return null;
    final matches = widget.notes.where((n) => n.id == noteId);
    return matches.isEmpty ? null : matches.first;
  }

  void _reveal() => setState(() => _showAnswer = true);

  void _answer(bool correct) {
    final card = _queue[_index];
    final updated = card.withOutcome(correct);
    widget.onReview(updated);
    widget.onRecordReview(card.id, correct);
    if (correct) {
      _correctCount++;
    } else {
      _missed.add(card);
    }
    setState(() {
      _index++;
      _showAnswer = false;
    });
  }

  void _showSourceNote(Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.trim().isEmpty ? 'Untitled note' : note.title,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
              ),
              const SizedBox(height: 12),
              ...note.blocks
                  .where((b) => b.type != NoteBlockType.image && b.text.trim().isNotEmpty)
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(b.text, style: const TextStyle(fontSize: 14, color: AppColors.deepNavy, height: 1.5)),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.deepNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _finished ? 'Session Complete' : 'Card ${_index + 1} of ${_queue.length}',
          style: const TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      body: SafeArea(child: _finished ? _buildSummary() : _buildCard()),
    );
  }

  Widget _buildCard() {
    final card = _queue[_index];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _queue.isEmpty ? 0 : _index / _queue.length,
            minHeight: 6,
            backgroundColor: AppColors.subtleGray,
            valueColor: const AlwaysStoppedAnimation(AppColors.teal),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GestureDetector(
              onTap: _showAnswer ? null : _reveal,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.subtleGray,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('QUESTION',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.slateGray)),
                      const SizedBox(height: 10),
                      Text(card.question,
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.deepNavy, height: 1.4)),
                      if (_showAnswer) ...[
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 20),
                        const Text('ANSWER',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.teal)),
                        const SizedBox(height: 10),
                        Text(card.answer, style: const TextStyle(fontSize: 16, color: AppColors.deepNavy, height: 1.5)),
                      ] else ...[
                        const SizedBox(height: 20),
                        const Text('Tap to reveal the answer', style: TextStyle(fontSize: 12.5, color: AppColors.slateGray)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_showAnswer)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _answer(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Incorrect', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _answer(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Correct', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _reveal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Show Answer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 44, color: AppColors.amber),
          const SizedBox(height: 12),
          Text('$_correctCount / ${_queue.length} correct',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          const SizedBox(height: 20),
          if (_missed.isNotEmpty) ...[
            const Text('Cards to revisit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _missed.length,
                itemBuilder: (context, i) {
                  final c = _missed[i];
                  final note = _noteFor(c.noteId);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.subtleGray, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
                        if (note != null) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showSourceNote(note),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.menu_book_outlined, size: 14, color: AppColors.teal),
                                const SizedBox(width: 6),
                                const Text('Reread source note',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.teal)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else
            const Expanded(
              child: Center(child: Text('Perfect session — nothing to revisit.', style: TextStyle(color: AppColors.slateGray))),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
