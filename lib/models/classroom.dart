// lib/models/classroom.dart
//
// Classroom v1 — an honest LOCAL-ONLY approximation. This app has no
// backend/auth, so there's no real multi-device sync: a classroom, its
// roster, and its join code live entirely in this device's local storage.
// "Joining by code" only works if that classroom was already created on
// this same device/session. That's a known, explicit limitation — surfaced
// in the UI (see JoinClassroomSheet / ClassroomDetailScreen), not hidden.
//
// Named ClassroomType (not "ClassType") to sidestep the reserved word
// `class`. "Assigning a task" reuses the existing Task tag system
// (tagLabel/tagColorValue) instead of building new broadcast infrastructure
// — an assigned task is just a normal Task tagged with the classroom's name
// and color, which is why progress here is computed from real Task.isDone
// state rather than any fabricated per-member data.

import 'dart:math';
import 'package:flutter/material.dart';

enum ClassroomType { peer, teacherClass }

extension ClassroomTypeExtension on ClassroomType {
  String get label {
    switch (this) {
      case ClassroomType.peer:
        return 'Study Group';
      case ClassroomType.teacherClass:
        return 'Class';
    }
  }
}

const List<int> kClassroomColorPresets = [
  0xFF14B8A6, // teal
  0xFF6366F1, // indigo
  0xFFEC4899, // pink
  0xFFF59E0B, // amber
  0xFF10B981, // emerald
  0xFF3B82F6, // blue
  0xFFEF4444, // red
  0xFF8B5CF6, // violet
];

const String _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I

String generateClassroomJoinCode() {
  final rnd = Random();
  return List.generate(6, (_) => _codeAlphabet[rnd.nextInt(_codeAlphabet.length)]).join();
}

class Classroom {
  final String id;
  final String name;
  final ClassroomType type;
  final int colorValue;
  final String joinCode;
  final String ownerName;
  final DateTime createdAt;
  // Plain names, not real accounts — there's no auth/backend, so members
  // can't have real per-device identities. This is a manual roster the
  // owner types in, same spirit as a paper attendance sheet.
  final List<String> roster;
  final List<String> assignedTaskIds;

  const Classroom({
    required this.id,
    required this.name,
    this.type = ClassroomType.peer,
    this.colorValue = 0xFF14B8A6,
    required this.joinCode,
    required this.ownerName,
    required this.createdAt,
    this.roster = const [],
    this.assignedTaskIds = const [],
  });

  Color get color => Color(colorValue);

  Classroom copyWith({
    String? id,
    String? name,
    ClassroomType? type,
    int? colorValue,
    String? joinCode,
    String? ownerName,
    DateTime? createdAt,
    List<String>? roster,
    List<String>? assignedTaskIds,
  }) {
    return Classroom(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      joinCode: joinCode ?? this.joinCode,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt ?? this.createdAt,
      roster: roster ?? this.roster,
      assignedTaskIds: assignedTaskIds ?? this.assignedTaskIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'colorValue': colorValue,
        'joinCode': joinCode,
        'ownerName': ownerName,
        'createdAt': createdAt.toIso8601String(),
        'roster': roster,
        'assignedTaskIds': assignedTaskIds,
      };

  factory Classroom.fromJson(Map<String, dynamic> json) => Classroom(
        id: json['id'] as String,
        name: json['name'] as String,
        type: ClassroomType.values.byName(json['type'] as String? ?? 'peer'),
        colorValue: json['colorValue'] as int? ?? 0xFF14B8A6,
        joinCode: json['joinCode'] as String? ?? '------',
        ownerName: json['ownerName'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        roster: ((json['roster'] as List<dynamic>?) ?? const []).map((e) => e as String).toList(),
        assignedTaskIds:
            ((json['assignedTaskIds'] as List<dynamic>?) ?? const []).map((e) => e as String).toList(),
      );
}
