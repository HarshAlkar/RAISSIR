import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/mentor_models.dart';
import '../exceptions/auth_exception.dart';
import '../utils/auth_helper.dart';

class MentorApiService {
  final String baseUrl = ApiConfig.mentorBase;

  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<MentorDashboardData> fetchDashboard() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/dashboard'), headers: await getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return MentorDashboardData.fromJson(decoded);
        }
        throw Exception('Invalid dashboard response format');
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      throw Exception(
        'Failed to load mentor dashboard (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Network error: Unable to connect to mentor dashboard.');
    } on TimeoutException {
      throw Exception('Dashboard fetch timed out.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  Future<MentorProfile> fetchMentorProfile() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/profile'), headers: await getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return MentorProfile.fromJson(decoded);
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      final msg = _extractMsg(response.body) ?? 'Failed to load mentor profile';
      throw Exception(msg);
    } on SocketException {
      throw Exception('Network error: Cannot reach server for profile.');
    } on TimeoutException {
      throw Exception('Profile load timed out.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  Future<List<MentorActivityItem>> fetchActivity() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/activity'), headers: await getHeaders())
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = (decoded is Map<String, dynamic>)
            ? decoded['activity']
            : null;
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => MentorActivityItem.fromJson(e))
              .toList();
        }
        return [];
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<MentorStudent>> fetchStudents() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/students'), headers: await getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = (decoded is Map<String, dynamic>)
            ? decoded['students']
            : null;
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => MentorStudent.fromJson(e))
              .toList();
        }
        return [];
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      throw Exception('Failed to load students (${response.statusCode})');
    } on SocketException {
      throw Exception('Network error while fetching students list.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  Future<MentorReviewCertificate> fetchCertificate(int certificateId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/certificate/$certificateId'),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return MentorReviewCertificate.fromJson(decoded['certificate']);
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      throw Exception('Certificate fetch failed (${response.statusCode})');
    } on SocketException {
      throw Exception('Network error: Cannot load certificate details.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  Future<void> approveCertificate(int certificateId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/approve-certificate'),
            headers: await getHeaders(),
            body: json.encode({"certificate_id": certificateId}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) return;
      if (response.statusCode == 401) throw UnauthorizedException();

      final msg = _extractMsg(response.body) ?? 'Approve failed';
      throw Exception(msg);
    } on SocketException {
      throw Exception('Network error: Failed to approve certificate.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  Future<void> rejectCertificate(int certificateId, String remark) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/reject-certificate'),
            headers: await getHeaders(),
            body: json.encode({
              "certificate_id": certificateId,
              "remark": remark,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) return;
      if (response.statusCode == 401) throw UnauthorizedException();

      final msg = _extractMsg(response.body) ?? 'Reject failed';
      throw Exception(msg);
    } on SocketException {
      throw Exception('Network error: Failed to reject certificate.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  // ── Analytics & History ────────────────────────────────────────────────────

  Future<MentorVerificationStats> fetchVerificationAnalytics() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/verification-analytics'),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return MentorVerificationStats.fromJson(decoded);
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      throw Exception('Failed to load analytics');
    } catch (_) {
      throw Exception('Could not load analytics data.');
    }
  }

  Future<List<MentorWeeklySummary>> fetchMonthlyVerification() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/monthly-verification'),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = (decoded is Map<String, dynamic>)
            ? decoded['weekly']
            : null;
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => MentorWeeklySummary.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<MentorRecentDecision>> fetchRecentDecisions() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/recent-activity'),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = (decoded is Map<String, dynamic>)
            ? decoded['activity']
            : null;
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => MentorRecentDecision.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<MentorStudentCertificate>> fetchStudentCertificates(
    int studentId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/student-certificates/$studentId'),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = (decoded is Map<String, dynamic>)
            ? decoded['certificates']
            : null;
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => MentorStudentCertificate.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String? _extractMsg(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map) {
        return decoded['msg']?.toString() ?? decoded['error']?.toString();
      }
    } catch (_) {}
    return null;
  }
}
