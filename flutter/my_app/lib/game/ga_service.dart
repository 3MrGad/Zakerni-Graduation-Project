import 'dart:convert';
import 'package:http/http.dart' as http;

/// Change this to your server's IP/hostname when running on a real device.
/// For emulator connecting to your local machine, use 10.0.2.2
const String kBaseUrl = 'http://localhost:5000';
class ApiService {
  static final _client = http.Client();

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String username) async {
    final res = await _client.post(
      Uri.parse('$kBaseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Game ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getQuestion(String username) async {
    final res = await _client.get(
      Uri.parse('$kBaseUrl/api/question?username=$username'),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> submitAnswer({
    required String username,
    required String answer,
    required double responseTime,
  }) async {
    final res = await _client.post(
      Uri.parse('$kBaseUrl/api/answer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'answer': answer,
        'response_time': responseTime,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getHint(String username) async {
    final res = await _client.post(
      Uri.parse('$kBaseUrl/api/hint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getResult(String username) async {
    final res = await _client.get(
      Uri.parse('$kBaseUrl/api/result?username=$username'),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> restart(String username) async {
    await _client.post(
      Uri.parse('$kBaseUrl/api/restart'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboard(String username) async {
    final res = await _client.get(
      Uri.parse('$kBaseUrl/api/dashboard?username=$username'),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> markImportant(String username, String person, bool mark) async {
    await _client.post(
      Uri.parse('$kBaseUrl/api/mark_important'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'person': person,
        'action': mark ? 'mark' : 'unmark',
      }),
    );
  }

  static Future<void> rebuildCache(String username) async {
    await _client.post(
      Uri.parse('$kBaseUrl/api/rebuild_cache'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
  }

  static String imageUrl(String imagePath) => '$kBaseUrl/static/$imagePath';
}
