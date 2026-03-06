import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  String get baseUrl => ApiConfig.authBase;

  // ── Token storage keys ────────────────────────────────────────────────────
  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'user_role';

  // ── Auth APIs ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    // Return real server message
    final msg = _extractMsg(response.body) ?? 'Registration failed';
    throw Exception(msg);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    final msg = _extractMsg(response.body) ?? 'Invalid email or password';
    throw Exception(msg);
  }

  // ── Token storage ─────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
  }

  // ── Token verification (startup check) ───────────────────────────────────

  /// Returns true if the stored token is still valid on the backend.
  Future<bool> verifyToken() async {
    final result = await verifyTokenAndGetRole();
    return result != null;
  }

  /// Verifies token AND returns the role from the backend response.
  /// Returns role string ("student"/"mentor") on success.
  /// Returns null on invalid token (also clears storage).
  /// On network error: returns locally stored role (offline tolerance, no logout).
  Future<String?> verifyTokenAndGetRole() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/verify-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['valid'] == true) {
          // Read the role from the backend response (trusted, always lowercase)
          final role = (decoded['user']?['role'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          return role.isEmpty ? null : role;
        }
      }
      // Token invalid / expired → clear everything
      await logout();
      return null;
    } catch (_) {
      // Network error / timeout: do NOT clear credentials
      // Fall back to locally stored role so offline navigation still works
      return await getRole();
    }
  }

  // ── Mentor signup ─────────────────────────────────────────────────────────

  Future<void> mentorSignup({
    required String name,
    required String email,
    required String department,
    required String employeeId,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mentor-signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'department': department,
        'employee_id': employeeId,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) return;

    final msg = _extractMsg(response.body) ?? 'Failed to create mentor account';
    throw Exception(msg);
  }

  // ── Mentor list ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchMentors() async {
    final response = await http.get(
      Uri.parse(ApiConfig.mentorsList),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final list = decoded['mentors'] as List;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load mentors');
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String? _extractMsg(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map) {
        return decoded['msg']?.toString() ??
            decoded['message']?.toString() ??
            decoded['error']?.toString();
      }
    } catch (_) {}
    return null;
  }
}
