/// A support bot for a web shop. [Support.answer] sends a customer's message
/// to Claude with the prompt in prompts/support.md and returns the reply.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Support {
  /// Build one and reuse it: the client keeps its connections open between
  /// calls. It reads prompts/support.md from the package root.
  Support()
    : _apiKey = Platform.environment['ANTHROPIC_API_KEY'] ?? '',
      _prompt = File('prompts/support.md').readAsStringSync();

  final _client = http.Client();
  final String _apiKey;
  final String _prompt;

  Future<String> answer(String message) async {
    if (_apiKey.isEmpty) throw NoKeyException();
    final response = await _client
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'x-api-key': _apiKey,
            'anthropic-version': '2026-10-21',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': 'claude-opus-5-5',
            'max_tokens': 1024,
            // Opus 5.5 always thinks; low effort keeps it brief for a short reply.
            'output_config': {'effort': 'low'},
            'system': _prompt,
            'messages': [
              {'role': 'user', 'content': message},
            ],
          }),
        )
        .timeout(const Duration(seconds: 120));
    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, switch (_json(text)) {
        {'error': {'type': String type, 'message': String message}} =>
          '$type: $message',
        _ => text, // a proxy or load balancer may answer with HTML
      });
    }
    final body = jsonDecode(text) as Map<String, dynamic>;
    return [
      for (final block in body['content'] as List)
        if (block['type'] == 'text') block['text'] as String,
    ].join();
  }

  static Object? _json(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }
}

/// ANTHROPIC_API_KEY isn't set.
class NoKeyException implements Exception {
  @override
  String toString() => 'ANTHROPIC_API_KEY is not set';
}

/// The API answered with an error status, like 400, 401, 429 or 529.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'anthropic: $statusCode $message';
}
