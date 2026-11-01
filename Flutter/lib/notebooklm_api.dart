import 'dart:convert';
import 'package:http/http.dart' as http;

class NotebookLMApiClient {
  final String baseUrl;
  final String? apiKey;

  NotebookLMApiClient({
    this.baseUrl = 'http://localhost:8000',
    this.apiKey,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      };

  /// Notizbücher auflisten
  Future<List<dynamic>> listNotebooks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/v1/notebooks'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['notebooks'] ?? [];
    } else {
      throw Exception('Fehler beim Laden der Notizbücher: ${response.statusCode}');
    }
  }

  /// Frage an ein Notizbuch stellen (RAG Chat)
  Future<Map<String, dynamic>> askQuestion({
    required String notebookId,
    required String prompt,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/notebooks/$notebookId/chat/ask'),
      headers: _headers,
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('API-Fehler (${response.statusCode}): ${response.body}');
    }
  }

  /// Studio-Artefakt (Podcast, Slide Deck, Quiz) generieren
  Future<Map<String, dynamic>> generateArtifact({
    required String notebookId,
    required String artifactType,
    String? focus,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/notebooks/$notebookId/artifacts/generate'),
      headers: _headers,
      body: jsonEncode({
        'artifact_type': artifactType,
        if (focus != null) 'focus': focus,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Artefakt-Generierung fehlgeschlagen: ${response.body}');
    }
  }
}
