// lib/widgets/flashcards/create_flashcard_sheet.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/flashcard.dart';
import '../../models/notebook.dart';

/// Manual card creation — the non-AI path the design notes call for
/// alongside Mystro-generated cards. New cards always start in box 1, due
/// immediately, same as a freshly generated card.
///
/// Cards can optionally be filed the same way Notebook is organized:
/// pick a Notebook ("module"), and within it optionally a specific Note
/// ("chapter") — matching how Mystro-generated cards are already tied to
/// the note they came from, so manual cards land in the same deck
/// structure instead of only ever piling into "Manual cards".
class CreateFlashcardSheet extends StatefulWidget {
  final List<Notebook> notebooks;
  final List<Note> notes;
  final ValueChanged<Flashcard> onSave;

  const CreateFlashcardSheet({
    super.key,
    required this.notebooks,
    required this.notes,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Notebook> notebooks,
    required List<Note> notes,
    required ValueChanged<Flashcard> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateFlashcardSheet(notebooks: notebooks, notes: notes, onSave: onSave),
    );
  }

  @override
  State<CreateFlashcardSheet> createState() => _CreateFlashcardSheetState();
}

class _CreateFlashcardSheetState extends State<CreateFlashcardSheet> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  Notebook? _notebook;
  Note? _note;

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  List<Note> get _notesInNotebook =>
      _notebook == null ? const [] : widget.notes.where((n) => n.notebookId == _notebook!.id).toList();

  Future<void> _pickNotebook() async {
    final selected = await showModalBottomSheet<Object?>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Notebook', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
              ),
              ListTile(
                leading: const Icon(Icons.close, color: AppColors.slateGray),
                title: const Text('No notebook'),
                onTap: () => Navigator.pop(context, _NoneMarker.value),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.notebooks.length,
                  itemBuilder: (context, i) {
                    final n = widget.notebooks[i];
                    return ListTile(
                      leading: Icon(n.icon, color: n.color),
                      title: Text(n.title),
                      onTap: () => Navigator.pop(context, n),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      _notebook = selected == _NoneMarker.value ? null : selected as Notebook;
      _note = null; // switching (or clearing) the notebook drops any chapter pick
    });
  }

  Future<void> _pickNote() async {
    final selected = await showModalBottomSheet<Object?>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chapter (note)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
              ),
              ListTile(
                leading: const Icon(Icons.close, color: AppColors.slateGray),
                title: const Text('General (whole notebook)'),
                onTap: () => Navigator.pop(context, _NoneMarker.value),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _notesInNotebook.length,
                  itemBuilder: (context, i) {
                    final n = _notesInNotebook[i];
                    return ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.slateGray),
                      title: Text(n.title.trim().isEmpty ? 'Untitled note' : n.title),
                      onTap: () => Navigator.pop(context, n),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    setState(() => _note = selected == _NoneMarker.value ? null : selected as Note);
  }

  void _save() {
    final q = _questionController.text.trim();
    final a = _answerController.text.trim();
    if (q.isEmpty || a.isEmpty) return;
    final now = DateTime.now();
    widget.onSave(Flashcard(
      id: 'card_${now.microsecondsSinceEpoch}',
      noteId: _note?.id,
      notebookId: _notebook?.id,
      question: q,
      answer: a,
      box: 1,
      nextReviewAt: now,
      createdAt: now,
    ));
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
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('New Flashcard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          const SizedBox(height: 16),

          // Notebook / chapter pills — same "file it like a note" idea as
          // Notebook itself, so manual cards group into real decks.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GestureDetector(
                onTap: _pickNotebook,
                child: _pill(
                  icon: Icons.menu_book_outlined,
                  label: _notebook?.title ?? 'Notebook',
                  color: _notebook?.color,
                ),
              ),
              if (_notebook != null)
                GestureDetector(
                  onTap: _pickNote,
                  child: _pill(
                    icon: Icons.description_outlined,
                    label: _note?.title.trim().isNotEmpty == true ? _note!.title : 'Chapter',
                    color: _note != null ? _notebook?.color : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Question', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slateGray)),
          const SizedBox(height: 6),
          TextField(
            controller: _questionController,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.deepNavy),
            decoration: InputDecoration(
              hintText: "What's the question?",
              filled: true,
              fillColor: AppColors.subtleGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Answer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slateGray)),
          const SizedBox(height: 6),
          TextField(
            controller: _answerController,
            maxLines: 4,
            minLines: 1,
            style: const TextStyle(fontSize: 14.5, color: AppColors.deepNavy),
            decoration: InputDecoration(
              hintText: 'And the answer',
              filled: true,
              fillColor: AppColors.subtleGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
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
              child: const Text('Add Card', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({required IconData icon, required String label, Color? color}) {
    final active = color != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? color!.withValues(alpha: 0.12) : AppColors.subtleGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: active ? color : AppColors.slateGray),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: active ? color : AppColors.slateGray,
              )),
        ],
      ),
    );
  }
}

/// Bottom sheets here return either a real picked object or "explicitly
/// cleared" — both distinct from "dismissed without choosing" (null).
/// A private sentinel keeps that three-way result honest without a whole
/// separate result-wrapper class for two small pickers.
enum _NoneMarker { value }
