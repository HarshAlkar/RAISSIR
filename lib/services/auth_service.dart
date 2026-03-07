import 'dart:convert';
import 'dart:async';
import 'dart:io';
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
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(userData),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }

      final msg = _extractMsg(response.body) ?? 'Registration failed';
      throw Exception(msg);
    } on SocketException {
      throw Exception('Network error: Please check your internet connection');
    } on TimeoutException {
      throw Exception(
        'Request timed out: Server is taking too long to respond',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool isAdmin = false,
  }) async {
    try {
      final url = isAdmin ? '${ApiConfig.adminBase}/login' : '$baseUrl/login';
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      final msg = _extractMsg(response.body) ?? 'Invalid email or password';
      throw Exception(msg);
    } on SocketException {
      throw Exception(
        'Network error: Unable to reach the server. Please check your internet.',
      );
    } on TimeoutException {
      throw Exception(
        'Connection timed out. Render backend may be waking up, please try again.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Login failed: ${e.toString()}');
    }
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

  Future<bool> verifyToken() async {
    final result = await verifyTokenAndGetRole();
    return result != null;
  }

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
          final role = (decoded['user']?['role'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          return role.isEmpty ? null : role;
        }
      }
      await logout();
      return null;
    } catch (_) {
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
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/mentor-signup'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'name': name,
              'email': email,
              'department': department,
              'employee_id': employeeId,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) return;

      final msg =
          _extractMsg(response.body) ?? 'Failed to create mentor account';
      throw Exception(msg);
    } on SocketException {
      throw Exception('Network error: No internet connection');
    } on TimeoutException {
      throw Exception('Signup timed out. Please try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Signup error: ${e.toString()}');
    }
  }

  // ── Mentor list ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchMentors() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.mentorsList),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Handle both direct array and wrapped object for robustness
        List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded.containsKey('mentors')) {
          list = decoded['mentors'] as List;
        } else {
          throw Exception('Unexpected response format from mentors API');
        }

        return list.cast<Map<String, dynamic>>();
      }
      throw Exception('Server returned ${response.statusCode}');
    } on SocketException {
      throw Exception('Network error: Could not fetch mentors list');
    } on TimeoutException {
      throw Exception('Mentors fetch timed out');
    } catch (e) {
      throw Exception('Failed to load mentors: ${e.toString()}');
    }
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
