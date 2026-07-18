// lib/services/mystro_ai_service.dart
//
// Talks to the Google Gemini API (free tier, no credit card required).
//
// SETUP:
//   1. Get a free key at https://aistudio.google.com/apikey (sign in with a
//      Google account — no billing info needed).
//   2. Run the app with the key injected at build time, e.g.:
//        flutter run --dart-define=GEMINI_API_KEY=your_key_here
//      (Never commit the key to source control.)
//
// Free tier (per Google, subject to change): gemini-2.5-flash-lite allows
// ~15 requests/min and ~1,000 requests/day, which is generous for a personal
// study-companion chat. Swap _model to 'gemini-2.5-flash' for higher-quality
// answers if you don't mind a lower daily cap.
import 'dart:convert';
import 'package:http/http.dart' as http;

class MystroAiException implements Exception {
  final String message;
  MystroAiException(this.message);

  @override
  String toString() => message;
}

class MystroAiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-2.5-flash-lite';

  static const _systemPrompt =
      'You are Mystro, a friendly and encouraging AI study companion inside '
      'the Quill.AI app. Give concise, practical, student-focused answers. '
      'Use short paragraphs or bullet points when it helps clarity. Avoid '
      'filler — get to the useful part quickly.';

  /// True once a key has been supplied via --dart-define=GEMINI_API_KEY=...
  static bool get isConfigured => _apiKey.isNotEmpty;

  /// Sends [userMessage] plus prior [history] (list of
  /// {'isAi': bool, 'text': String} maps, oldest first) to Gemini and
  /// returns the reply text. Throws [MystroAiException] on any failure,
  /// with a message safe to show directly in the chat UI.
  static Future<String> sendMessage({
    required String userMessage,
    required List<Map<String, dynamic>> history,
  }) async {
    if (!isConfigured) {
      throw MystroAiException(
        "Mystro needs a free Gemini API key to answer questions.\n\n"
        "Get one at aistudio.google.com/apikey, then run the app with:\n"
        "flutter run --dart-define=GEMINI_API_KEY=your_key_here",
      );
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final contents = [
      for (final m in history)
        {
          'role': (m['isAi'] == true) ? 'model' : 'user',
          'parts': [
            {'text': m['text']}
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      },
    ];

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': contents,
              'systemInstruction': {
                'parts': [
                  {'text': _systemPrompt}
                ],
              },
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw MystroAiException("Couldn't reach Mystro — check your internet connection.");
    }

    if (response.statusCode == 429) {
      throw MystroAiException('Mystro hit its free-tier rate limit. Try again in a minute.');
    }
    if (response.statusCode == 400 || response.statusCode == 403) {
      throw MystroAiException(
        "Mystro's API key was rejected (${response.statusCode}). Double-check the "
        "GEMINI_API_KEY you passed in.",
      );
    }
    if (response.statusCode != 200) {
      throw MystroAiException("Mystro couldn't answer that (error ${response.statusCode}).");
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw MystroAiException("Mystro didn't return a response — try rephrasing.");
      }
      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw MystroAiException("Mystro didn't return a response — try rephrasing.");
      }
      final text = parts.map((p) => p['text']?.toString() ?? '').join().trim();
      if (text.isEmpty) {
        throw MystroAiException("Mystro didn't return a response — try rephrasing.");
      }
      return text;
    } on MystroAiException {
      rethrow;
    } catch (_) {
      throw MystroAiException('Mystro sent back something unexpected.');
    }
  }

  /// Reads a note's plain text and asks Gemini for a set of Q/A flashcard
  /// pairs, returned as {'question': ..., 'answer': ...} maps. The caller
  /// (GeneratedCardsReviewSheet) always shows these to the user for
  /// edit/delete before they become real Flashcard rows — this method never
  /// writes anything itself, it only proposes.
  static Future<List<Map<String, String>>> generateFlashcards({
    required String noteText,
    int count = 8,
  }) async {
    if (!isConfigured) {
      throw MystroAiException(
        "Mystro needs a free Gemini API key to generate flashcards.\n\n"
        "Get one at aistudio.google.com/apikey, then run the app with:\n"
        "flutter run --dart-define=GEMINI_API_KEY=your_key_here",
      );
    }
    final trimmed = noteText.trim();
    if (trimmed.isEmpty) {
      throw MystroAiException('This note has no text to generate flashcards from yet.');
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final prompt =
        'Read the study note below and produce up to $count flashcards that test '
        'the key facts/concepts in it. Respond with ONLY a raw JSON array (no '
        'markdown fences, no commentary) of objects shaped exactly like '
        '{"question": "...", "answer": "..."}. Keep each question and answer '
        'short and specific — one fact per card, not a whole paragraph.\n\n'
        'NOTE:\n$trimmed';

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt}
                  ],
                },
              ],
              'generationConfig': {'responseMimeType': 'application/json'},
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw MystroAiException("Couldn't reach Mystro — check your internet connection.");
    }

    if (response.statusCode == 429) {
      throw MystroAiException('Mystro hit its free-tier rate limit. Try again in a minute.');
    }
    if (response.statusCode == 400 || response.statusCode == 403) {
      throw MystroAiException(
        "Mystro's API key was rejected (${response.statusCode}). Double-check the "
        "GEMINI_API_KEY you passed in.",
      );
    }
    if (response.statusCode != 200) {
      throw MystroAiException("Mystro couldn't generate cards (error ${response.statusCode}).");
    }

    String text;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      final content = candidates?.isNotEmpty == true ? candidates!.first['content'] as Map<String, dynamic>? : null;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw MystroAiException("Mystro didn't return any cards — try again.");
      }
      text = parts.map((p) => p['text']?.toString() ?? '').join().trim();
    } on MystroAiException {
      rethrow;
    } catch (_) {
      throw MystroAiException('Mystro sent back something unexpected.');
    }

    // responseMimeType: application/json should already give us clean JSON,
    // but models occasionally still wrap it in ```json fences — strip those
    // defensively rather than trust the config alone.
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '').replaceFirst(RegExp(r'```\s*$'), '').trim();
    }

    List<dynamic> raw;
    try {
      raw = jsonDecode(cleaned) as List<dynamic>;
    } catch (_) {
      throw MystroAiException("Mystro's response wasn't valid — try generating again.");
    }

    final cards = <Map<String, String>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final q = item['question']?.toString().trim() ?? '';
      final a = item['answer']?.toString().trim() ?? '';
      if (q.isEmpty || a.isEmpty) continue;
      cards.add({'question': q, 'answer': a});
    }
    if (cards.isEmpty) {
      throw MystroAiException("Mystro couldn't find anything to make cards from in this note.");
    }
    return cards;
  }
}
