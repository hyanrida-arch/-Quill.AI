// lib/models/flashcard.dart
//
// Leitner spaced repetition — 5 boxes, fixed intervals. Deliberately not
// SM-2: explainable in one sentence, implementable in a handful of lines,
// which matters more here than squeezing out extra scheduling efficiency.
//
// Box 1 -> 3 -> 7 -> 21 days; box 5 is "mastered" (still resurfaces, just
// rarely, so a truly forgotten card doesn't vanish from review forever).
// Any incorrect answer drops a card straight back to box 1, same as a
// physical Leitner box system.

const List<int> kLeitnerIntervalsDays = [1, 3, 7, 21]; // box 1..4
const int kMasteredIntervalDays = 60; // box 5

class Flashcard {
  final String id;
  // Optional — set when generated from (or manually linked to) a Note
  // ("chapter"); null for a card not tied to any specific note.
  final String? noteId;
  // Optional — set when a card is filed directly under a Notebook
  // ("module") without picking a specific note inside it. When noteId is
  // set, the card's deck is resolved through the note's own notebookId
  // instead (see FlashcardsHomeScreen._notebookFor) — this field only
  // matters for notebook-level-but-no-specific-note cards.
  final String? notebookId;
  final String question;
  final String answer;
  final int box; // 1..5
  final DateTime nextReviewAt;
  final DateTime createdAt;

  const Flashcard({
    required this.id,
    this.noteId,
    this.notebookId,
    required this.question,
    required this.answer,
    this.box = 1,
    required this.nextReviewAt,
    required this.createdAt,
  });

  bool get isDue => !nextReviewAt.isAfter(DateTime.now());
  bool get isMastered => box >= 5;

  /// Applies a review outcome and returns the updated card — never mutates
  /// in place, same copyWith-and-replace pattern as Task/Habit.
  Flashcard withOutcome(bool correct) {
    if (!correct) {
      return copyWith(box: 1, nextReviewAt: DateTime.now().add(const Duration(days: 1)));
    }
    final newBox = box + 1 > 5 ? 5 : box + 1;
    final days = newBox <= kLeitnerIntervalsDays.length ? kLeitnerIntervalsDays[newBox - 1] : kMasteredIntervalDays;
    return copyWith(box: newBox, nextReviewAt: DateTime.now().add(Duration(days: days)));
  }

  Flashcard copyWith({
    String? question,
    String? answer,
    int? box,
    DateTime? nextReviewAt,
  }) =>
      Flashcard(
        id: id,
        noteId: noteId,
        notebookId: notebookId,
        question: question ?? this.question,
        answer: answer ?? this.answer,
        box: box ?? this.box,
        nextReviewAt: nextReviewAt ?? this.nextReviewAt,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'noteId': noteId,
        'notebookId': notebookId,
        'question': question,
        'answer': answer,
        'box': box,
        'nextReviewAt': nextReviewAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'] as String,
        noteId: json['noteId'] as String?,
        notebookId: json['notebookId'] as String?,
        question: json['question'] as String,
        answer: json['answer'] as String,
        box: json['box'] as int? ?? 1,
        nextReviewAt: DateTime.parse(json['nextReviewAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// A single review event — kept mainly so a per-card or overall history
/// stat is possible later without changing the schema again.
class CardReview {
  final String id;
  final String cardId;
  final bool correct;
  final DateTime reviewedAt;

  const CardReview({
    required this.id,
    required this.cardId,
    required this.correct,
    required this.reviewedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardId': cardId,
        'correct': correct,
        'reviewedAt': reviewedAt.toIso8601String(),
      };

  factory CardReview.fromJson(Map<String, dynamic> json) => CardReview(
        id: json['id'] as String,
        cardId: json['cardId'] as String,
        correct: json['correct'] as bool,
        reviewedAt: DateTime.parse(json['reviewedAt'] as String),
      );
}
