// lib/screens/flashcards/flashcards_home_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/flashcard.dart';
import '../../models/notebook.dart';
import '../../widgets/flashcards/create_flashcard_sheet.dart';
import 'review_session_screen.dart';

/// Pushed from AppShell's drawer "Flashcards" entry. Same
/// own-a-local-copy pattern as the other pushed list screens in this app.
class FlashcardsHomeScreen extends StatefulWidget {
  final List<Flashcard> cards;
  final List<Note> notes;
  final List<Notebook> notebooks;
  final ValueChanged<Flashcard> onAddCard;
  final ValueChanged<Flashcard> onUpdateCard;
  final void Function(String cardId, bool correct) onRecordReview;

  const FlashcardsHomeScreen({
    super.key,
    required this.cards,
    required this.notes,
    required this.notebooks,
    required this.onAddCard,
    required this.onUpdateCard,
    required this.onRecordReview,
  });

  @override
  State<FlashcardsHomeScreen> createState() => _FlashcardsHomeScreenState();
}

class _FlashcardsHomeScreenState extends State<FlashcardsHomeScreen> {
  late List<Flashcard> _cards;

  @override
  void initState() {
    super.initState();
    _cards = List<Flashcard>.from(widget.cards);
  }

  List<Flashcard> get _dueCards => _cards.where((c) => c.isDue).toList();

  Map<int, int> get _boxCounts {
    final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final c in _cards) {
      counts[c.box] = (counts[c.box] ?? 0) + 1;
    }
    return counts;
  }

  // A card tied to a specific note resolves its deck through that note's
  // own notebook first; a card filed directly under a notebook (no chapter
  // picked) falls back to its own notebookId. Only a card with neither
  // (or pointing at something since deleted) lands in "Manual cards".
  Notebook? _notebookFor(Flashcard c) {
    if (c.noteId != null) {
      final noteMatches = widget.notes.where((n) => n.id == c.noteId);
      if (noteMatches.isNotEmpty) {
        final notebookMatches = widget.notebooks.where((n) => n.id == noteMatches.first.notebookId);
        if (notebookMatches.isNotEmpty) return notebookMatches.first;
      }
    }
    if (c.notebookId != null) {
      final notebookMatches = widget.notebooks.where((n) => n.id == c.notebookId);
      if (notebookMatches.isNotEmpty) return notebookMatches.first;
    }
    return null;
  }

  // Groups cards by their source notebook; cards with no resolvable note
  // (manual cards, or cards whose note/notebook has since been deleted)
  // fall into a single 'manual' bucket keyed by null.
  Map<Notebook?, List<Flashcard>> get _grouped {
    final Map<Notebook?, List<Flashcard>> map = {};
    for (final c in _cards) {
      final nb = _notebookFor(c);
      map.putIfAbsent(nb, () => []).add(c);
    }
    return map;
  }

  void _addCard() {
    CreateFlashcardSheet.show(
      context,
      notebooks: widget.notebooks,
      notes: widget.notes,
      onSave: (c) {
        setState(() => _cards.add(c));
        widget.onAddCard(c);
      },
    );
  }

  void _startReview(List<Flashcard> due) {
    if (due.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing due right now — check back later.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewSessionScreen(
          dueCards: due,
          notes: widget.notes,
          onReview: (updated) {
            setState(() {
              final i = _cards.indexWhere((c) => c.id == updated.id);
              if (i != -1) _cards[i] = updated;
            });
            widget.onUpdateCard(updated);
          },
          onRecordReview: widget.onRecordReview,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final due = _dueCards;
    final boxes = _boxCounts;
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Flashcards', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SafeArea(
        top: false,
        child: _cards.isEmpty
            ? _buildEmptyState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.deepNavy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${due.length}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                              Text('card${due.length == 1 ? '' : 's'} due today',
                                  style: const TextStyle(fontSize: 13, color: Colors.white70)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _startReview(due),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('Start Review', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Leitner Boxes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (i) {
                      final box = i + 1;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: box == 5 ? 0 : 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: AppColors.subtleGray, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              Text('${boxes[box]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                              Text('Box $box', style: const TextStyle(fontSize: 10, color: AppColors.slateGray)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  const Text('Decks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                  const SizedBox(height: 10),
                  ...grouped.entries.map((entry) {
                    final notebook = entry.key;
                    final cards = entry.value;
                    final dueInDeck = cards.where((c) => c.isDue).length;
                    final color = notebook?.color ?? AppColors.slateGray;
                    return GestureDetector(
                      onTap: () => _startReview(cards.where((c) => c.isDue).toList()),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15)),
                              child: Icon(notebook?.icon ?? Icons.style_outlined, size: 18, color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notebook?.title ?? 'Manual cards',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                                  Text('${cards.length} card${cards.length == 1 ? '' : 's'} · $dueInDeck due',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.slateGray)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.slateGray),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        backgroundColor: AppColors.deepNavy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.style_outlined, size: 48, color: AppColors.slateGray),
            const SizedBox(height: 16),
            const Text('No flashcards yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            const Text(
              'Add a card manually, or open a note in your Notebook and tap the ✨ icon to generate some from it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppColors.slateGray, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
