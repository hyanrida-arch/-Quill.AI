// lib/models/notebook.dart
//
// Notebook v1 — a lightweight block editor, NOT a real Notion clone. Blocks
// cover the handful of shapes an actual student note needs (heading,
// paragraph, checklist, bullet, photo) with drag-to-reorder — no nested
// pages, no databases, no slash-command marketplace. Anything beyond that
// is exactly the "6-month dev trap" the app's own design notes warn about.
//
// One Notebook per subject/topic (title + icon + color); Notes live inside
// a Notebook and can optionally be linked to an existing Task (taskId) so
// Mystro could eventually reason about "3 notes on ch.4, 0 review
// sessions" — that reasoning isn't built yet, only the link itself.

import 'package:flutter/material.dart';

enum NoteBlockType { heading, text, checklist, bullet, image }

class NoteBlock {
  final String id;
  final NoteBlockType type;
  // Label text for heading/text/checklist/bullet blocks; unused (empty) for
  // image blocks.
  final String text;
  // Checklist blocks only.
  final bool isChecked;
  // Image blocks only — a local file path (picked via image_picker, same
  // as the account avatar picker elsewhere in the app).
  final String? imagePath;

  const NoteBlock({
    required this.id,
    required this.type,
    this.text = '',
    this.isChecked = false,
    this.imagePath,
  });

  NoteBlock copyWith({String? text, bool? isChecked, String? imagePath}) => NoteBlock(
        id: id,
        type: type,
        text: text ?? this.text,
        isChecked: isChecked ?? this.isChecked,
        imagePath: imagePath ?? this.imagePath,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'text': text,
        'isChecked': isChecked,
        'imagePath': imagePath,
      };

  factory NoteBlock.fromJson(Map<String, dynamic> json) => NoteBlock(
        id: json['id'] as String,
        type: NoteBlockType.values.byName(json['type'] as String? ?? 'text'),
        text: json['text'] as String? ?? '',
        isChecked: json['isChecked'] as bool? ?? false,
        imagePath: json['imagePath'] as String?,
      );
}

const Map<String, IconData> kNotebookIconPresets = {
  'book': Icons.menu_book,
  'science': Icons.science_outlined,
  'calculate': Icons.calculate_outlined,
  'language': Icons.language,
  'history': Icons.history_edu,
  'globe': Icons.public,
  'code': Icons.code,
  'art': Icons.palette_outlined,
  'music': Icons.music_note,
  'psychology': Icons.psychology_outlined,
  'law': Icons.gavel,
  'medicine': Icons.local_hospital_outlined,
  'finance': Icons.attach_money,
  'sports': Icons.sports_soccer,
  'folder': Icons.folder_outlined,
};

IconData notebookIconFor(String key) => kNotebookIconPresets[key] ?? Icons.menu_book;

const List<int> kNotebookColorPresets = [
  0xFF14B8A6, // teal
  0xFF6366F1, // indigo
  0xFFEC4899, // pink
  0xFFF59E0B, // amber
  0xFF10B981, // emerald
  0xFF3B82F6, // blue
  0xFFEF4444, // red
  0xFF8B5CF6, // violet
];

class Notebook {
  final String id;
  final String title;
  final String iconKey;
  final int colorValue;
  final DateTime createdAt;

  const Notebook({
    required this.id,
    required this.title,
    this.iconKey = 'book',
    this.colorValue = 0xFF14B8A6,
    required this.createdAt,
  });

  Color get color => Color(colorValue);
  IconData get icon => notebookIconFor(iconKey);

  Notebook copyWith({String? title, String? iconKey, int? colorValue}) => Notebook(
        id: id,
        title: title ?? this.title,
        iconKey: iconKey ?? this.iconKey,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'iconKey': iconKey,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Notebook.fromJson(Map<String, dynamic> json) => Notebook(
        id: json['id'] as String,
        title: json['title'] as String,
        iconKey: json['iconKey'] as String? ?? 'book',
        colorValue: json['colorValue'] as int? ?? 0xFF14B8A6,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class Note {
  final String id;
  final String notebookId;
  // Optional link to an existing Task — lets a note say "this is about
  // that assignment" without duplicating any task data.
  final String? taskId;
  final String title;
  final List<NoteBlock> blocks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.notebookId,
    this.taskId,
    this.title = '',
    this.blocks = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Short plain-text preview for list rows — first non-empty text-bearing
  /// block, truncated. Falls back to a placeholder for image-only/empty
  /// notes.
  String get preview {
    for (final b in blocks) {
      if (b.type == NoteBlockType.image) continue;
      final t = b.text.trim();
      if (t.isNotEmpty) return t.length > 90 ? '${t.substring(0, 90)}…' : t;
    }
    return blocks.any((b) => b.type == NoteBlockType.image) ? '📷 Photo note' : 'Empty note';
  }

  Note copyWith({
    String? taskId,
    bool clearTask = false,
    String? title,
    List<NoteBlock>? blocks,
    DateTime? updatedAt,
  }) =>
      Note(
        id: id,
        notebookId: notebookId,
        taskId: clearTask ? null : (taskId ?? this.taskId),
        title: title ?? this.title,
        blocks: blocks ?? this.blocks,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'notebookId': notebookId,
        'taskId': taskId,
        'title': title,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        notebookId: json['notebookId'] as String,
        taskId: json['taskId'] as String?,
        title: json['title'] as String? ?? '',
        blocks: ((json['blocks'] as List<dynamic>?) ?? const [])
            .map((e) => NoteBlock.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
