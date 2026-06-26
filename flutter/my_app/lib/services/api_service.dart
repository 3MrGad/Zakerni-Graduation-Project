import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Local testing: Edge / Chrome on same PC → 127.0.0.1 works with php artisan serve
  // Real phone on Wi‑Fi → use your PC IP, e.g. http://192.168.1.5:8000/api
  // Android Emulator → use 10.0.2.2
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // ─── Auth headers ──────────────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Save / clear session ──────────────────────────────────────────────────
  static Future<void> saveSession({
    required String token,
    required String role,
    required int userId,
    required String name,
    int? patientId,
    int? caregiverId,
    String? patientName,
    String? caregiverName,
    String? patientCode, // ✅ مضاف من الأول
    String? expiresAt, // ✅ مضاف من الأول
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_role', role);
    await prefs.setInt('user_id', userId);
    await prefs.setString('user_name', name);
    if (patientId != null) await prefs.setInt('patient_id', patientId);
    if (caregiverId != null) await prefs.setInt('caregiver_id', caregiverId);
    if (patientName != null) await prefs.setString('patient_name', patientName);
    if (caregiverName != null)
      await prefs.setString('caregiver_name', caregiverName);
    if (patientCode != null)
      await prefs.setString('patient_code', patientCode); // ✅ مضاف
    if (expiresAt != null)
      await prefs.setString('token_expires_at', expiresAt); // ✅ مضاف
  }

  // ✅ مضاف من الأول
  static Future<String?> getPatientCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('patient_code');
  }

  // ✅ مضاف من الأول
  static Future<String?> getTokenExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token_expires_at');
  }

  // ✅ مضاف من الأول
  static Future<bool> isSessionExpired() async {
    final expires = await getTokenExpiresAt();
    if (expires == null || expires.isEmpty) return false;
    try {
      return DateTime.now().isAfter(DateTime.parse(expires));
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<int?> getPatientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('patient_id');
  }

  static Future<int?> getCaregiverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('caregiver_id');
  }

  static Future<String?> getPatientName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('patient_name');
  }

  static Future<String?> getCaregiverName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('caregiver_name') ?? 'الشخص الموثوق';
  }

  static Future<void> setSelectedPatientId(int patientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_patient_id', patientId);
  }

  static Future<int?> getSelectedPatientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selected_patient_id');
  }

  static Future<int?> resolveCaregiverPatientId(int? patientId) async {
    if (patientId != null) {
      await setSelectedPatientId(patientId);
      return patientId;
    }
    final saved = await getSelectedPatientId();
    if (saved != null) return saved;
    final patients = await getMyPatients();
    if (patients.isEmpty) return null;
    final id = patients.first['patient_id'] as int;
    await setSelectedPatientId(id);
    return id;
  }

  static String _query({int? patientId, Map<String, String>? params}) {
    final parts = <String>[];
    if (patientId != null) parts.add('patient_id=$patientId');
    params?.forEach((k, v) => parts.add('$k=$v'));
    return parts.isEmpty ? '' : '?${parts.join('&')}';
  }

  // ─── Generic request helpers ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> _get(String path) async {
    final headers = await _authHeaders();
    final response =
        await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    return _handle(response);
  }

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: json.encode(body),
    );
    return _handle(response);
  }

  static Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: json.encode(body),
    );
    return _handle(response);
  }

  static Future<Map<String, dynamic>> _delete(String path) async {
    final headers = await _authHeaders();
    final response =
        await http.delete(Uri.parse('$baseUrl$path'), headers: headers);
    return _handle(response);
  }

  static Map<String, dynamic> _handle(http.Response response) {
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      body['_status_code'] = response.statusCode; // ✅ مضاف من الأول
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      }
      final err = ApiException(
        body['message']?.toString() ??
            'Request failed (${response.statusCode})',
        response.statusCode,
      );
      throw err;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> _postMultipart(
    // ✅ مضاف من الأول
    String path,
    Map<String, String> fields,
    String fileField,
    String filePath,
  ) async {
    final headers = await _authHeaders();
    headers.remove('Content-Type');
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    request.headers.addAll(headers);
    fields.forEach((k, v) => request.fields[k] = v);
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handle(response);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> login(
    String email,
    String password, {
    String? fcmToken,
    bool rememberMe = false, // ✅ مضاف من الأول
  }) async {
    final body = {
      'Email': email,
      'password': password,
      'remember_me': rememberMe, // ✅ مضاف من الأول
    };
    if (fcmToken != null) body['fcm_token'] = fcmToken;
    return await _post('/login', body);
  }

  // ✅ مضاف من الأول
  static Future<Map<String, dynamic>> adminLogin(
      String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: json.encode({'username': username, 'password': password}),
    );
    return _handle(response);
  }

  // ✅ مضاف من الأول
  static Future<void> forgotPassword(String email, String role) async {
    final path = role == 'patient'
        ? '/patient/forgot-password'
        : '/caregiver/forgot-password';
    await _post(path, {'email': email});
  }

  // ✅ مضاف من الأول
  static Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String role,
  }) async {
    final path = role == 'patient'
        ? '/patient/reset-password'
        : '/caregiver/reset-password';
    await _post(path, {
      'email': email,
      'token': token,
      'password': password,
      'password_confirmation': password,
    });
  }

  static Future<Map<String, dynamic>> registerPatient({
    required String fname,
    required String lname,
    required String email,
    required String password,
    String? gender,
    String? medicalCondition,
    int? age,
  }) async {
    return await _post('/register/patient', {
      'Fname': fname,
      'Lname': lname,
      'Email': email,
      'password': password,
      'password_confirmation': password,
      if (gender != null) 'Gender': gender,
      if (medicalCondition != null) 'medical_condition': medicalCondition,
      if (age != null) 'age': age,
    });
  }

  static Future<Map<String, dynamic>> registerCaregiver({
    required String fname,
    required String lname,
    required String email,
    required String password,
    String? phone,
    int? patientId,
    String? patientCode, // ✅ مضاف من الأول
  }) async {
    return await _post('/register/caregiver', {
      'Fname': fname,
      'Lname': lname,
      'Email': email,
      'password': password,
      'password_confirmation': password,
      if (phone != null) 'phone': phone,
      if (patientId != null) 'PatientID': patientId,
      if (patientCode != null) 'patient_code': patientCode, // ✅ مضاف من الأول
    });
  }

  static Future<void> logout() async {
    try {
      await _post('/logout', {});
    } catch (_) {}
    await clearSession();
  }

  static Future<void> updateFcmToken(String token) async {
    await _post('/device-token', {'fcm_token': token});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAREGIVER ↔ PATIENT
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> linkPatient(int patientId) async {
    return await _post('/caregiver/link-patient', {'patient_id': patientId});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getMedications({int? patientId}) async {
    final role = await getRole();
    if (role == 'patient') {
      // ✅ مضاف من الأول
      final res = await _get('/patient/medications');
      final data = res['data'];
      if (data is List) return data;
      return (data as Map?)?['medications'] as List<dynamic>? ?? [];
    }
    final resolved = await resolveCaregiverPatientId(patientId);
    final res = await _get('/medications${_query(patientId: resolved)}');
    return res['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> addMedication({
    required String medName,
    String? dosage,
    String? frequency,
    String? reason,
    String? scheduledTime,
    int? patientId,
  }) async {
    final resolved = await resolveCaregiverPatientId(patientId);
    return await _post('/medications', {
      'med_name': medName,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (reason != null) 'reason': reason,
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
      if (resolved != null) 'patient_id': resolved,
    });
  }

  static Future<void> deleteMedication(int medId, {int? patientId}) async {
    final resolved = await resolveCaregiverPatientId(patientId);
    await _delete('/medications/$medId${_query(patientId: resolved)}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDICATION LOGS (today's reminders)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getMedicationLogs({String? date}) async {
    final role = await getRole();
    final path = role == 'caregiver'
        ? '/caregiver/medication-logs'
        : '/medication-logs'; // ✅ مضاف من الأول
    final query = date != null ? '?date=$date' : '';
    final res = await _get('$path$query');
    final data = res['data'];
    if (data is Map && data['logs'] is List)
      return data['logs'] as List<dynamic>; // ✅ مضاف من الأول
    if (data is List) return data;
    return [];
  }

  static Future<void> markMedicationTaken(int logId) async {
    await _post('/medication-logs/$logId/take', {});
  }

  static Future<void> markMedicationMissed(int logId) async {
    await _post('/medication-logs/$logId/miss', {});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TODOS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<dynamic>> getTodos(
      {bool? completed, int? patientId}) async {
    final resolved = await getRole() == 'caregiver'
        ? await resolveCaregiverPatientId(patientId)
        : patientId ?? await getPatientId(); // ✅ مضاف من الأول
    final params = <String, String>{};
    if (completed != null) params['is_completed'] = completed ? '1' : '0';
    final res = await _get(
        '/todos${_query(patientId: resolved, params: params.isEmpty ? null : params)}');
    return res['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> addTodo({
    required String title,
    String? description,
    String priority = 'medium',
    String? dueDate,
    int? patientId,
  }) async {
    final resolved = await resolveCaregiverPatientId(patientId);
    return await _post('/todos', {
      'title': title,
      if (description != null) 'description': description,
      'priority': priority,
      if (dueDate != null) 'due_date': dueDate,
      if (resolved != null) 'patient_id': resolved,
    });
  }

  static Future<void> completeTodo(int todoId) async {
    await _post('/todos/$todoId/complete', {});
  }

  static Future<void> uncompleteTodo(int todoId) async {
    await _post('/todos/$todoId/uncomplete', {});
  }

  static Future<void> deleteTodo(int todoId, {int? patientId}) async {
    final resolved = await resolveCaregiverPatientId(patientId);
    await _delete('/todos/$todoId${_query(patientId: resolved)}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GPS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? homeLat,
    double? homeLng,
  }) async {
    await _post('/gps/location', {
      'latitude': latitude,
      'longitude': longitude,
      if (homeLat != null) 'home_lat': homeLat,
      if (homeLng != null) 'home_lng': homeLng,
    });
  }

  static Future<List<dynamic>> getMyPatients() async {
    final res = await _get('/gps/patients');
    return res['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getPatientLocation(int patientId) async {
    final res = await _get('/gps/patients/$patientId/location');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getPatientLocationHistory(int patientId) async {
    final res = await _get('/gps/patients/$patientId/history');
    return res['data'] as List<dynamic>;
  }

  // ✅ مضاف من الأول
  static Future<void> setHomeLocation({
    required double homeLat,
    required double homeLng,
    int? geofenceRadiusMeters,
  }) async {
    await _post('/caregiver/set-home-location', {
      'home_lat': homeLat,
      'home_lng': homeLng,
      if (geofenceRadiusMeters != null)
        'geofence_radius_meters': geofenceRadiusMeters,
    });
  }

  // ✅ مضاف من الأول
  static Future<Map<String, dynamic>> getCaregiverPatientLocation() async {
    final res = await _get('/caregiver/patient-location');
    return res['data'] as Map<String, dynamic>;
  }

  // ✅ مضاف من الأول
  static Future<void> patientUpdateLocation(
      {required double lat, required double lng}) async {
    await _post('/patient/update-location', {'lat': lat, 'lng': lng});
  }

  // ✅ مضاف من الأول
  static Future<Map<String, dynamic>> savePatientInfo(
      Map<String, dynamic> fields) async {
    return await _post('/patient-info', fields);
  }

  // ✅ مضاف من الأول
  static Future<Map<String, dynamic>> getPatientInfo() async {
    return await _get('/patient-info');
  }

  // ✅ مضاف من الأول
  static Future<Map<String, dynamic>> addMemory({
    required String description,
    String? title,
    String? photoPath,
    int? patientId,
  }) async {
    final resolved = await resolveCaregiverPatientId(patientId);
    final fields = <String, String>{
      'description': description,
      if (title != null) 'title': title,
      if (resolved != null) 'patient_id': '$resolved',
    };
    if (photoPath != null) {
      return await _postMultipart('/memories', fields, 'photo', photoPath);
    }
    return await _post('/memories', fields);
  }

  // ✅ مضاف من الأول
  static Future<List<dynamic>> getMemories(int patientId) async {
    final res = await _get('/patient/$patientId/memories');
    final data = res['data'] as Map<String, dynamic>?;
    return (data?['memories'] as List<dynamic>?) ?? [];
  }

  // ✅ مضاف من الأول
  static Future<List<dynamic>> getReminders({int? patientId}) async {
    final resolved = await getRole() == 'caregiver'
        ? await resolveCaregiverPatientId(patientId)
        : patientId ?? await getPatientId();
    final res = await _get('/reminders${_query(patientId: resolved)}');
    final data = res['data'] as Map<String, dynamic>?;
    return (data?['reminders'] as List<dynamic>?) ?? [];
  }

  // ✅ مضاف من الأول
  static Future<Map<String, dynamic>> addHowToNote({
    required String title,
    required String content,
    int? patientId,
  }) async {
    final resolved = await resolveCaregiverPatientId(patientId);
    return await _post('/caregiver/how-to-notes', {
      'title': title,
      'content': content,
      if (resolved != null) 'patient_id': resolved,
    });
  }

  // ✅ مضاف من الأول
  static Future<List<dynamic>> getHowToNotes(int patientId) async {
    final res = await _get('/patient/$patientId/how-to-notes');
    final data = res['data'] as Map<String, dynamic>?;
    return (data?['notes'] as List<dynamic>?) ?? [];
  }

  // ✅ مضاف من الأول
  static Future<Map<String, dynamic>> addPatientTodo({
    required String title,
    String? description,
  }) async {
    return await _post('/patient/tasks', {
      'title': title,
      if (description != null) 'description': description,
    });
  }

  // ✅ مضاف من الأول
  static Future<void> markMedicationTakenById(int medId) async {
    await _post('/patient/medications/$medId/take', {});
  }

  // ✅ مضاف من الأول
  static Future<List<dynamic>> getPatientTasks() async {
    final res = await _get('/patient/tasks');
    final data = res['data'] as Map<String, dynamic>?;
    return (data?['tasks'] as List<dynamic>?) ?? [];
  }

  // ✅ مضاف من الأول
  static Future<void> markPatientTaskDone(int taskId) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/patient/tasks/$taskId/done'),
      headers: headers,
    );
    _handle(response);
  }

  // ✅ مضاف من الأول
  static Future<List<dynamic>> getCaregiverPatientTasks() async {
    final res = await _get('/caregiver/patient-tasks');
    final data = res['data'] as Map<String, dynamic>?;
    return (data?['tasks'] as List<dynamic>?) ?? [];
  }

  // ✅ مضاف من الأول
  static Future<List<dynamic>> getPatientHowToNotes() async {
    final res = await _get('/patient/how-to-notes');
    final data = res['data'] as Map<String, dynamic>?;
    return (data?['notes'] as List<dynamic>?) ?? [];
  }

  // ✅ مضاف من الأول
  static Future<Map<String, dynamic>> getPatientAccountInfo() async {
    return await _get('/patient/info');
  }

  // ✅ مضاف من الأول
  static Future<Map<String, dynamic>> savePatientAccountInfo(
      Map<String, dynamic> fields) async {
    try {
      return await _put('/patient/info', fields);
    } catch (_) {
      return await _post('/patient/info', fields);
    }
  }

  // ✅ مضاف من الأول
  static Future<void> setGeofenceRadius(int radiusMeters) async {
    await _post('/caregiver/set-geofence', {'radius_meters': radiusMeters});
  }

  // ─── Admin API ─────────────────────────────────────────────────────────────
  // ✅ مضاف من الأول
  //static Future<List<dynamic>> adminGetUsers() async {
  //final res = await _get('/admin/users');
  //final data = res['data'] as Map<String, dynamic>?;
  //return (data?['users'] as List<dynamic>?) ?? [];
  //}
  // static Future<List<dynamic>> adminGetUsers() async {
  // final res = await _get('/admin/users');
  //return res['data']['users'];
  //}

  static Future<List<dynamic>> getUsers() async {
    final headers = await _authHeaders(); // ✅
    final res = await http.get(
      Uri.parse("$baseUrl/admin/users"),
      headers: headers,
    );

    print(res.body);
    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return data["users"];
    }

    throw Exception(data["message"]);
  }

  static Future<void> updateUser(
    String type,
    int id,
    Map<String, dynamic> data,
  ) async {
    final headers = await _authHeaders(); // ✅
    final response = await http.put(
      Uri.parse("$baseUrl/admin/users/$type/$id"),
      headers: headers,
      body: jsonEncode(data),
    );

    print(response.statusCode);
    print(response.body);

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }
  //static Future<void> addUser(
  //Map<String, dynamic> data,
  //String token,
  //) async {
  //await http.post(
  //Uri.parse("$baseUrl/users"),
  //headers: {
  //"Content-Type": "application/json",
  //"Authorization": "Bearer $token",
  //"Accept": "application/json",
  //},
  //body: jsonEncode(data),
  //);
  //}

  //static Future<void> deleteUser(
  //String type,
  //int id,
  //String token,
  //) async {
  //await http.delete(
  //Uri.parse("$baseUrl/users/$type/$id"),
  //headers: {
  //"Authorization": "Bearer $token",
  //"Accept": "application/json",
  //},
  //);

  //adduser
  static Future<void> addUser(Map<String, dynamic> data) async {
    final headers = await _authHeaders(); // ✅ جيبي التوكن أوتوماتيك
    final response = await http.post(
      Uri.parse("$baseUrl/admin/users"),
      headers: headers, // ✅ بدل hardcoded headers
      body: jsonEncode(data),
    );

    print(response.statusCode);
    print(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.body);
    }
  }

  // ✅ مضاف من الأول
  //static Future<Map<String, dynamic>> adminCreateUser(
  //  Map<String, dynamic> body) async {
  //return await _post('/admin/users', body);
  //}

// Add User
  //static Future<Map<String, dynamic>> adminCreateUser(
  //  Map<String, dynamic> body) async {
  //return await _post('/users', body);
  //}

  static Future<void> adminUpdateUser(
      String type, int id, Map<String, dynamic> body) async {
    await _put('/admin/users/$type/$id', body);
  }

  // ✅ مضاف من الأول
  static Future<void> saveAdminSession(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_role', 'admin');
    await prefs.setString('user_name', 'Admin');
  }
}

// ✅ مضاف من الأول
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
