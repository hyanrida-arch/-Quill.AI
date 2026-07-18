// lib/screens/notebook/notebooks_list_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/notebook.dart';
import '../../models/task.dart';
import '../../models/flashcard.dart';
import '../../widgets/notebook/create_notebook_sheet.dart';
import 'notebook_detail_screen.dart';

/// Pushed from AppShell's drawer "Notebook" entry — same
/// own-a-local-copy-and-intercept-callbacks pattern as ClassroomsListScreen,
/// for the same reason: this is a separate route, not a descendant of
/// AppShell, so it won't be rebuilt with fresh props when AppShell's own
/// state changes underneath it.
class NotebooksListScreen extends StatefulWidget {
  final List<Notebook> notebooks;
  final List<Note> notes;
  final List<Task> tasks;
  final ValueChanged<Notebook> onCreate;
  final ValueChanged<Notebook> onUpdate;
  final ValueChanged<Notebook> onDelete;
  final ValueChanged<Note> onAddNote;
  final ValueChanged<Note> onUpdateNote;
  final ValueChanged<Note> onDeleteNote;
  final ValueChanged<Flashcard> onAddFlashcard;

  const NotebooksListScreen({
    super.key,
    required this.notebooks,
    required this.notes,
    required this.tasks,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddNote,
    required this.onUpdateNote,
    required this.onDeleteNote,
    required this.onAddFlashcard,
  });

  @override
  State<NotebooksListScreen> createState() => _NotebooksListScreenState();
}

class _NotebooksListScreenState extends State<NotebooksListScreen> {
  late List<Notebook> _notebooks;
  late List<Note> _notes;

  @override
  void initState() {
    super.initState();
    _notebooks = List<Notebook>.from(widget.notebooks);
    _notes = List<Note>.from(widget.notes);
  }

  int _noteCount(Notebook n) => _notes.where((note) => note.notebookId == n.id).length;

  void _openCreate() {
    CreateNotebookSheet.show(
      context,
      onSave: (n) {
        setState(() => _notebooks.insert(0, n));
        widget.onCreate(n);
      },
    );
  }

  void _openDetail(Notebook n) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotebookDetailScreen(
          notebook: n,
          notes: _notes,
          tasks: widget.tasks,
          onUpdate: (updated) {
            setState(() {
              final i = _notebooks.indexWhere((x) => x.id == updated.id);
              if (i != -1) _notebooks[i] = updated;
            });
            widget.onUpdate(updated);
          },
          onDelete: (deleted) {
            setState(() {
              _notebooks.removeWhere((x) => x.id == deleted.id);
              _notes.removeWhere((note) => note.notebookId == deleted.id);
            });
            widget.onDelete(deleted);
          },
          onAddNote: (note) {
            setState(() => _notes.add(note));
            widget.onAddNote(note);
          },
          onUpdateNote: (note) {
            setState(() {
              final i = _notes.indexWhere((x) => x.id == note.id);
              if (i != -1) _notes[i] = note;
            });
            widget.onUpdateNote(note);
          },
          onDeleteNote: (note) {
            setState(() => _notes.removeWhere((x) => x.id == note.id));
            widget.onDeleteNote(note);
          },
          onAddFlashcard: widget.onAddFlashcard,
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notebook', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SafeArea(
        top: false,
        child: _notebooks.isEmpty ? _buildEmptyState() : _buildGrid(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
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
            const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.slateGray),
            const SizedBox(height: 16),
            const Text('No notebooks yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            const Text(
              'Create one per subject to keep your notes organized — tap + to start.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppColors.slateGray, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.98,
      ),
      itemCount: _notebooks.length,
      itemBuilder: (context, index) {
        final n = _notebooks[index];
        final count = _noteCount(n);
        return GestureDetector(
          onTap: () => _openDetail(n),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: n.color.withValues(alpha: 0.15)),
                  child: Icon(n.icon, color: n.color, size: 22),
                ),
                const Spacer(),
                Text(n.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                const SizedBox(height: 4),
                Text('$count note${count == 1 ? '' : 's'}', style: const TextStyle(fontSize: 11.5, color: AppColors.slateGray)),
              ],
            ),
          ),
        );
      },
    );
  }
}
