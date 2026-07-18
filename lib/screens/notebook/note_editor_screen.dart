// lib/screens/notebook/note_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../theme/app_colors.dart';
import '../../models/notebook.dart';
import '../../models/task.dart';
import '../../models/flashcard.dart';
import '../../services/mystro_ai_service.dart';
import '../../widgets/flashcards/generated_cards_review_sheet.dart';

/// Block editor — heading / paragraph / checklist / bullet / photo blocks,
/// reorderable via drag handle. This is deliberately NOT a full Notion
/// clone (no nested pages, no databases, no slash-command menu) — see the
/// header comment on lib/models/notebook.dart for why.
///
/// Like HabitDetailScreen/ClassroomDetailScreen, this is a separate pushed
/// route: it owns a local working copy (_blocks/_title/_taskId) and only
/// calls widget.onSave when the user backs out, rather than persisting on
/// every keystroke.
class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final String notebookId;
  final List<Task> tasks;
  final ValueChanged<Note> onSave;
  final ValueChanged<Note>? onDelete;
  final ValueChanged<Flashcard> onAddFlashcard;

  const NoteEditorScreen({
    super.key,
    this.note,
    required this.notebookId,
    required this.tasks,
    required this.onSave,
    this.onDelete,
    required this.onAddFlashcard,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late List<NoteBlock> _blocks;
  final Map<String, TextEditingController> _controllers = {};
  String? _taskId;
  bool _generating = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _titleController = TextEditingController(text: n?.title ?? '');
    _blocks = List<NoteBlock>.from(n?.blocks ?? const []);
    _taskId = n?.taskId;
    for (final b in _blocks) {
      if (b.type != NoteBlockType.image) {
        _controllers[b.id] = TextEditingController(text: b.text);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _generateBlockId() => 'block_${DateTime.now().microsecondsSinceEpoch}_${_blocks.length}';

  void _addBlock(NoteBlockType type) {
    if (type == NoteBlockType.image) {
      _pickImageBlock();
      return;
    }
    final block = NoteBlock(id: _generateBlockId(), type: type);
    setState(() {
      _blocks.add(block);
      _controllers[block.id] = TextEditingController();
    });
  }

  Future<void> _pickImageBlock() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.deepNavy),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.deepNavy),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (picked == null) return;
      setState(() {
        _blocks.add(NoteBlock(id: _generateBlockId(), type: NoteBlockType.image, imagePath: picked.path));
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't access that photo source.")),
        );
      }
    }
  }

  void _removeBlock(int index) {
    final block = _blocks[index];
    setState(() {
      _blocks.removeAt(index);
      _controllers.remove(block.id)?.dispose();
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, item);
    });
  }

  void _toggleChecklist(int index) {
    setState(() {
      _blocks[index] = _blocks[index].copyWith(isChecked: !_blocks[index].isChecked);
    });
  }

  List<NoteBlock> _syncedBlocks() {
    return _blocks.map((b) {
      final controller = _controllers[b.id];
      return controller != null ? b.copyWith(text: controller.text) : b;
    }).toList();
  }

  bool _hasContent() {
    if (_titleController.text.trim().isNotEmpty) return true;
    return _syncedBlocks().any((b) => b.type == NoteBlockType.image || b.text.trim().isNotEmpty);
  }

  void _saveAndPop() {
    if (!_isEditing && !_hasContent()) {
      Navigator.pop(context);
      return;
    }
    final now = DateTime.now();
    final note = (widget.note ??
            Note(
              id: 'note_${now.microsecondsSinceEpoch}',
              notebookId: widget.notebookId,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
      title: _titleController.text.trim(),
      blocks: _syncedBlocks(),
      taskId: _taskId,
      clearTask: _taskId == null,
      updatedAt: now,
    );
    widget.onSave(note);
    Navigator.pop(context);
  }

  Future<void> _pickLinkedTask() async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
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
                child: Text('Link a Task', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
              ),
              ListTile(
                leading: const Icon(Icons.close, color: AppColors.slateGray),
                title: const Text('No task'),
                onTap: () => Navigator.pop(context, ''),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.tasks.length,
                  itemBuilder: (context, i) {
                    final t = widget.tasks[i];
                    return ListTile(
                      leading: Icon(Icons.check_box_outlined, color: t.displayColor),
                      title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(t.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pop(context, t.id),
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
    setState(() => _taskId = selected.isEmpty ? null : selected);
  }

  Future<void> _generateCards() async {
    final text = _syncedBlocks()
        .where((b) => b.type != NoteBlockType.image && b.text.trim().isNotEmpty)
        .map((b) => b.text.trim())
        .join('\n');
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some text to this note first.')),
      );
      return;
    }
    setState(() => _generating = true);
    try {
      final generated = await MystroAiService.generateFlashcards(noteText: text);
      if (!mounted) return;
      final noteId = widget.note?.id ?? 'note_${DateTime.now().microsecondsSinceEpoch}';
      await GeneratedCardsReviewSheet.show(
        context,
        generated: generated,
        noteId: noteId,
        onAccept: (cards) {
          for (final c in cards) {
            widget.onAddFlashcard(c);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${cards.length} card${cards.length == 1 ? '' : 's'} added')),
            );
          }
        },
      );
    } on MystroAiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete note?', style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700)),
        content: const Text("This can't be undone. Any flashcards generated from it stay in your deck.",
            style: TextStyle(color: AppColors.slateGray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && widget.note != null && mounted) {
      widget.onDelete?.call(widget.note!);
      Navigator.pop(context);
    }
  }

  Task? _linkedTask() {
    if (_taskId == null) return null;
    final matches = widget.tasks.where((t) => t.id == _taskId);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Widget build(BuildContext context) {
    final linkedTask = _linkedTask();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.deepNavy, size: 20),
          onPressed: _saveAndPop,
        ),
        actions: [
          IconButton(
            icon: _generating
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal))
                : const Icon(Icons.auto_awesome, color: AppColors.teal),
            tooltip: 'Generate flashcards',
            onPressed: _generating ? null : _generateCards,
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.slateGray),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
              decoration: const InputDecoration(
                hintText: 'Note title',
                hintStyle: TextStyle(color: AppColors.slateGray, fontWeight: FontWeight.w700),
                border: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _pickLinkedTask,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: linkedTask != null ? AppColors.lightTeal.withValues(alpha: 0.4) : AppColors.subtleGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, size: 14, color: linkedTask != null ? AppColors.teal : AppColors.slateGray),
                    const SizedBox(width: 6),
                    Text(
                      linkedTask?.title ?? 'Link a task',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: linkedTask != null ? AppColors.teal : AppColors.slateGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _blocks.isEmpty
                ? Center(
                    child: Text('Tap a block below to start writing',
                        style: TextStyle(fontSize: 13.5, color: AppColors.slateGray.withValues(alpha: 0.8))),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: _blocks.length,
                    onReorder: _reorder,
                    itemBuilder: (context, index) => _buildBlockRow(index),
                  ),
          ),
          const Divider(height: 1, color: AppColors.border),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildBlockRow(int index) {
    final block = _blocks[index];
    return Container(
      key: ValueKey(block.id),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildBlockContent(index, block)),
          GestureDetector(
            onTap: () => _removeBlock(index),
            child: const Padding(
              padding: EdgeInsets.only(left: 8, top: 4),
              child: Icon(Icons.close, size: 16, color: AppColors.slateGray),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(left: 4, top: 4),
              child: Icon(Icons.drag_handle, size: 18, color: AppColors.slateGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockContent(int index, NoteBlock block) {
    switch (block.type) {
      case NoteBlockType.heading:
        return TextField(
          controller: _controllers[block.id],
          maxLines: null,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
          decoration: const InputDecoration(hintText: 'Heading', border: InputBorder.none, isDense: true),
        );
      case NoteBlockType.text:
        return TextField(
          controller: _controllers[block.id],
          maxLines: null,
          style: const TextStyle(fontSize: 14.5, color: AppColors.deepNavy, height: 1.4),
          decoration: const InputDecoration(hintText: 'Write something…', border: InputBorder.none, isDense: true),
        );
      case NoteBlockType.checklist:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _toggleChecklist(index),
              child: Container(
                margin: const EdgeInsets.only(top: 4, right: 10),
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: block.isChecked ? AppColors.teal : Colors.transparent,
                  border: Border.all(color: block.isChecked ? AppColors.teal : AppColors.border, width: 1.6),
                ),
                child: block.isChecked ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controllers[block.id],
                maxLines: null,
                style: TextStyle(
                  fontSize: 14.5,
                  color: AppColors.deepNavy,
                  decoration: block.isChecked ? TextDecoration.lineThrough : null,
                ),
                decoration: const InputDecoration(hintText: 'To-do', border: InputBorder.none, isDense: true),
              ),
            ),
          ],
        );
      case NoteBlockType.bullet:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6, right: 10),
              child: Text('•', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.deepNavy)),
            ),
            Expanded(
              child: TextField(
                controller: _controllers[block.id],
                maxLines: null,
                style: const TextStyle(fontSize: 14.5, color: AppColors.deepNavy),
                decoration: const InputDecoration(hintText: 'List item', border: InputBorder.none, isDense: true),
              ),
            ),
          ],
        );
      case NoteBlockType.image:
        final path = block.imagePath;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: path != null && File(path).existsSync()
              ? Image.file(File(path), fit: BoxFit.cover, height: 180, width: double.infinity)
              : Container(
                  height: 100,
                  color: AppColors.subtleGray,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, color: AppColors.slateGray),
                ),
        );
    }
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolbarButton(Icons.title, 'Heading', () => _addBlock(NoteBlockType.heading)),
          _toolbarButton(Icons.notes, 'Text', () => _addBlock(NoteBlockType.text)),
          _toolbarButton(Icons.checklist, 'Check', () => _addBlock(NoteBlockType.checklist)),
          _toolbarButton(Icons.format_list_bulleted, 'Bullet', () => _addBlock(NoteBlockType.bullet)),
          _toolbarButton(Icons.image_outlined, 'Photo', () => _addBlock(NoteBlockType.image)),
        ],
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.deepNavy),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.slateGray, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
