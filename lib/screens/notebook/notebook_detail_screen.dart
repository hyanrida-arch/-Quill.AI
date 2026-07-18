// lib/screens/notebook/notebook_detail_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/notebook.dart';
import '../../models/task.dart';
import '../../models/flashcard.dart';
import '../../widgets/notebook/create_notebook_sheet.dart';
import 'note_editor_screen.dart';

/// Lists the notes inside one Notebook. Same "own a local working copy,
/// bubble every change up" pattern as ClassroomDetailScreen — this is a
/// separate pushed route, not a descendant of AppShell, so it can't just
/// read AppShell's live lists.
class NotebookDetailScreen extends StatefulWidget {
  final Notebook notebook;
  final List<Note> notes;
  final List<Task> tasks;
  final ValueChanged<Notebook> onUpdate;
  final ValueChanged<Notebook> onDelete;
  final ValueChanged<Note> onAddNote;
  final ValueChanged<Note> onUpdateNote;
  final ValueChanged<Note> onDeleteNote;
  final ValueChanged<Flashcard> onAddFlashcard;

  const NotebookDetailScreen({
    super.key,
    required this.notebook,
    required this.notes,
    required this.tasks,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddNote,
    required this.onUpdateNote,
    required this.onDeleteNote,
    required this.onAddFlashcard,
  });

  @override
  State<NotebookDetailScreen> createState() => _NotebookDetailScreenState();
}

class _NotebookDetailScreenState extends State<NotebookDetailScreen> {
  late Notebook _notebook;
  late List<Note> _localNotes;

  @override
  void initState() {
    super.initState();
    _notebook = widget.notebook;
    _localNotes = List<Note>.from(widget.notes);
  }

  List<Note> get _notesHere {
    final list = _localNotes.where((n) => n.notebookId == _notebook.id).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  void _openNewNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          notebookId: _notebook.id,
          tasks: widget.tasks,
          onSave: (note) {
            setState(() => _localNotes.add(note));
            widget.onAddNote(note);
          },
          onAddFlashcard: widget.onAddFlashcard,
        ),
      ),
    );
  }

  void _openEditNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          note: note,
          notebookId: _notebook.id,
          tasks: widget.tasks,
          onSave: (updated) {
            setState(() {
              final i = _localNotes.indexWhere((n) => n.id == updated.id);
              if (i != -1) _localNotes[i] = updated;
            });
            widget.onUpdateNote(updated);
          },
          onDelete: (deleted) {
            setState(() => _localNotes.removeWhere((n) => n.id == deleted.id));
            widget.onDeleteNote(deleted);
          },
          onAddFlashcard: widget.onAddFlashcard,
        ),
      ),
    );
  }

  Future<void> _editNotebook() async {
    await CreateNotebookSheet.show(
      context,
      editing: _notebook,
      onSave: (updated) {
        setState(() => _notebook = updated);
        widget.onUpdate(updated);
      },
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete notebook?', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700)),
        content: Text(
          'This removes "${_notebook.title}" and all ${_notesHere.length} note(s) in it. Any flashcards already generated stay in your deck.',
          style: const TextStyle(color: AppColors.slateGray),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.onDelete(_notebook);
      Navigator.pop(context);
    }
  }

  String _dateLabel(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final notes = _notesHere;
    final color = _notebook.color;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(_notebook.icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(_notebook.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w800, fontSize: 17)),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.deepNavy),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'edit') _editNotebook();
              if (value == 'delete') _confirmDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18, color: AppColors.deepNavy),
                  SizedBox(width: 10),
                  Text('Edit notebook'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                  SizedBox(width: 10),
                  Text('Delete', style: TextStyle(color: AppColors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: notes.isEmpty ? _buildEmptyState() : _buildList(notes),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewNote,
        backgroundColor: color,
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
            const Icon(Icons.note_alt_outlined, size: 48, color: AppColors.slateGray),
            const SizedBox(height: 16),
            const Text('No notes yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to write your first note in this notebook.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppColors.slateGray, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Note> notes) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final n = notes[index];
        return GestureDetector(
          onTap: () => _openEditNote(n),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title.trim().isEmpty ? 'Untitled note' : n.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
                      ),
                    ),
                    Text(_dateLabel(n.updatedAt), style: const TextStyle(fontSize: 11.5, color: AppColors.slateGray)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  n.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.slateGray, height: 1.4),
                ),
                if (n.taskId != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link, size: 12, color: _notebook.color),
                      const SizedBox(width: 4),
                      Text('Linked to task',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _notebook.color)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
