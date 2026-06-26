import 'dart:convert';
import 'package:http/http.dart' as http;

// ← غيّر الـ IP ده لـ IP الـ PC بتاعك على الشبكة
// لو بتجرب على emulator: 10.0.2.2
// لو على موبايل حقيقي: 192.168.1.X (IP الـ PC بتاعك)
const String kFlaskUrl = 'http://10.0.2.2:5000';

class GameApiService {
  static final _client = http.Client();

  static Map<String, String> get _h => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
  static Future<http.Response> getDashboard(int patientId) {
    return _client.get(
      Uri.parse('$kFlaskUrl/api/dashboard/$patientId'),
    );
  }

  // ── Caregiver ─────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getPeople(int patientId) async {
    final res =
        await _client.get(Uri.parse('$kFlaskUrl/api/get_people/$patientId'));
    final data = jsonDecode(res.body);
    return data['people'] ?? [];
  }

  static Future<void> deletePerson(int personId) async {
    await _client.delete(Uri.parse('$kFlaskUrl/api/delete_person/$personId'));
  }

  // ── Game ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> startGame(int patientId) async {
    final res = await _client.post(
      Uri.parse('$kFlaskUrl/api/game/start'),
      headers: _h,
      body: jsonEncode({'patient_id': patientId}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getQuestion(int patientId) async {
    final res = await _client.get(
      Uri.parse('$kFlaskUrl/api/game/question/$patientId'),
      headers: _h,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> submitAnswer({
    required int patientId,
    required String answer,
    required double responseTime,
  }) async {
    final res = await _client.post(
      Uri.parse('$kFlaskUrl/api/game/answer'),
      headers: _h,
      body: jsonEncode({
        'patient_id': patientId,
        'answer': answer,
        'response_time': responseTime,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getHint(int patientId) async {
    final res = await _client.post(
      Uri.parse('$kFlaskUrl/api/game/hint'),
      headers: _h,
      body: jsonEncode({'patient_id': patientId}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getResult(int patientId) async {
    final res = await _client.get(
      Uri.parse('$kFlaskUrl/api/game/result/$patientId'),
      headers: _h,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> restartGame(int patientId) async {
    await _client.post(
      Uri.parse('$kFlaskUrl/api/game/restart'),
      headers: _h,
      body: jsonEncode({'patient_id': patientId}),
    );
  }

  // cache-bust عشان الصورة تتحدث كل مرة
  static String imageUrl(String path) => '$kFlaskUrl/static/$path';
}

// ─────────────────────────────────────────────────────────────────────────────
//  Models
// ─────────────────────────────────────────────────────────────────────────────
