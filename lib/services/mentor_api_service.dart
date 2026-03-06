import 'dart:convert';
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
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return MentorDashboardData.fromJson(decoded);
      }
      throw Exception('Invalid dashboard response');
    } else if (response.statusCode == 401) {
      AuthHelper.handleUnauthorized();
      throw UnauthorizedException();
    }

    throw Exception('Failed to load mentor dashboard');
  }

  Future<MentorProfile> fetchMentorProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return MentorProfile.fromJson(decoded);
      }
      throw Exception('Invalid profile response');
    } else if (response.statusCode == 401) {
      AuthHelper.handleUnauthorized();
      throw UnauthorizedException();
    } else if (response.statusCode == 403) {
      throw Exception(
        'Access denied. Please logout and login again as mentor.',
      );
    } else if (response.statusCode == 404) {
      throw Exception('Mentor profile not found in database.');
    } else {
      // Show the actual error from server for debugging
      String msg = 'Server error (${response.statusCode})';
      try {
        final body = json.decode(response.body);
        if (body is Map && body['msg'] != null) msg = body['msg'].toString();
        if (body is Map && body['error'] != null)
          msg = body['error'].toString();
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<List<MentorActivityItem>> fetchActivity() async {
    final response = await http.get(
      Uri.parse('$baseUrl/activity'),
      headers: await getHeaders(),
    );

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

    throw Exception('Failed to load mentor activity');
  }

  Future<MentorVerificationStats> fetchVerificationAnalytics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/verification-analytics'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return MentorVerificationStats.fromJson(decoded);
      }
      throw Exception('Invalid analytics response');
    } else if (response.statusCode == 401) {
      AuthHelper.handleUnauthorized();
      throw UnauthorizedException();
    }

    throw Exception('Failed to load verification analytics');
  }

  Future<List<MentorWeeklySummary>> fetchMonthlyVerification() async {
    final response = await http.get(
      Uri.parse('$baseUrl/monthly-verification'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final list = (decoded is Map<String, dynamic>) ? decoded['weekly'] : null;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => MentorWeeklySummary.fromJson(e))
            .toList();
      }
      return [];
    } else if (response.statusCode == 401) {
      AuthHelper.handleUnauthorized();
      throw UnauthorizedException();
    }

    throw Exception('Failed to load monthly verification');
  }

  Future<List<MentorRecentDecision>> fetchRecentDecisions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/recent-activity'),
      headers: await getHeaders(),
    );

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
      return [];
    } else if (response.statusCode == 401) {
      AuthHelper.handleUnauthorized();
      throw UnauthorizedException();
    }

    throw Exception('Failed to load recent activity');
  }

  Future<List<MentorStudent>> fetchStudents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/students'),
      headers: await getHeaders(),
    );

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

    throw Exception(
      'Failed to load mentor students: ${response.statusCode} - ${response.body}',
    );
  }

  Future<List<MentorStudentCertificate>> fetchStudentCertificates(
    int studentId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student-certificates/$studentId'),
      headers: await getHeaders(),
    );

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
      return [];
    } else if (response.statusCode == 401) {
      AuthHelper.handleUnauthorized();
      throw UnauthorizedException();
    }

    if (response.statusCode == 404) {
      throw Exception('Student not found');
    }
    if (response.statusCode == 403) {
      throw Exception('Access denied');
    }

    throw Exception(
      'Failed to load student certificates: ${response.statusCode} - ${response.body}',
    );
  }

  Future<MentorReviewCertificate> fetchCertificate(int certificateId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/certificate/$certificateId'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return MentorReviewCertificate.fromJson(decoded['certificate']);
    } else if (response.statusCode == 401) {
      AuthHelper.handleUnauthorized();
      throw UnauthorizedException();
    }

    throw Exception(
      'Failed to load certificate: ${response.statusCode} - ${response.body}',
    );
  }

  Future<void> approveCertificate(int certificateId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/approve-certificate'),
      headers: await getHeaders(),
      body: json.encode({"certificate_id": certificateId}),
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to approve certificate: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> rejectCertificate(int certificateId, String remark) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reject-certificate'),
      headers: await getHeaders(),
      body: json.encode({"certificate_id": certificateId, "remark": remark}),
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to reject certificate: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
