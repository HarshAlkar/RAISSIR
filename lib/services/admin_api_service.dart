import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../exceptions/auth_exception.dart';
import '../utils/auth_helper.dart';

class AdminApiService {
  final String baseUrl = ApiConfig.adminBase;

  // ── Auth Headers ─────────────────────────────────────────────────────────

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Admin Login ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return json.decode(response.body);
      final msg = _extractMsg(response.body) ?? 'Invalid credentials';
      throw Exception(msg);
    } on SocketException {
      throw Exception('Network error: Cannot reach server.');
    } on TimeoutException {
      throw Exception('Connection timed out. Please try again.');
    }
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  Future<AdminDashboardData> fetchDashboard() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/dashboard'), headers: await _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return AdminDashboardData.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      throw Exception('Dashboard load failed (${response.statusCode})');
    } on SocketException {
      throw Exception('Network error loading dashboard.');
    } on TimeoutException {
      throw Exception('Dashboard timed out.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  // ── Recent Activity ───────────────────────────────────────────────────────

  Future<List<AdminActivityItem>> fetchRecentActivity() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/recent-activity'), headers: await _headers())
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => AdminActivityItem.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Students ──────────────────────────────────────────────────────────────

  Future<List<AdminStudent>> fetchStudents({String? search}) async {
    try {
      final query = search != null && search.isNotEmpty
          ? '?search=$search'
          : '';
      final response = await http
          .get(Uri.parse('$baseUrl/students$query'), headers: await _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['students'] ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => AdminStudent.fromJson(e))
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      throw Exception('Failed to load students');
    } on SocketException {
      throw Exception('Network error loading students.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  Future<void> updateStudentStatus(int id, String status) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/student-status/$id'),
            headers: await _headers(),
            body: json.encode({'status': status}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final msg = _extractMsg(response.body) ?? 'Failed to update status';
        throw Exception(msg);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> assignMentor(int studentId, int mentorId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/assign-mentor'),
            headers: await _headers(),
            body: json.encode({'student_id': studentId, 'mentor_id': mentorId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final msg = _extractMsg(response.body) ?? 'Failed to assign mentor';
        throw Exception(msg);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AdminCertificate>> fetchStudentCertificates(int studentId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/student-certificates/$studentId'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['certificates'] ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => AdminCertificate.fromJson(e))
            .toList();
      }
      throw Exception('Failed to load student certificates');
    } catch (e) {
      rethrow;
    }
  }

  Future<AdminStudentDetail> fetchStudentDetail(int studentId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/student/$studentId'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AdminStudentDetail.fromJson(data['student']);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      throw Exception('Failed to load student details');
    } on SocketException {
      throw Exception('Network error loading student details.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  Future<AdminCertificate> fetchCertificateDetail(int certId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/certificate/$certId'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AdminCertificate.fromJson(data['certificate']);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      throw Exception('Failed to load certificate details');
    } on SocketException {
      throw Exception('Network error loading certificate details.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  // ── Mentors ───────────────────────────────────────────────────────────────

  Future<List<AdminMentor>> fetchMentors({
    String? search,
    String? filter,
  }) async {
    try {
      final queryParams = <String>[];
      if (search != null && search.isNotEmpty)
        queryParams.add('search=$search');
      if (filter != null && filter.isNotEmpty)
        queryParams.add('filter=$filter');

      final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/mentors$query'), headers: await _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['mentors'] ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => AdminMentor.fromJson(e))
            .toList();
      }
      throw Exception('Failed to load mentors');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AdminStudent>> fetchMentorStudents(int mentorId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/mentor-students/$mentorId'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['students'] ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => AdminStudent.fromJson(e))
            .toList();
      }
      throw Exception('Failed to load mentor students');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reassignStudents(int mentorId, List<int> studentIds) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/reassign-students'),
            headers: await _headers(),
            body: json.encode({
              'mentor_id': mentorId,
              'student_ids': studentIds,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final msg = _extractMsg(response.body) ?? 'Failed to reassign';
        throw Exception(msg);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMentorStatus(int id, String status) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/mentor-status/$id'),
            headers: await _headers(),
            body: json.encode({'status': status}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final msg = _extractMsg(response.body) ?? 'Failed to update status';
        throw Exception(msg);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerMentor({
    required String name,
    required String email,
    required String department,
    required String employeeId,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register-mentor'),
            headers: await _headers(),
            body: json.encode({
              'name': name,
              'email': email,
              'department': department,
              'employee_id': employeeId,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final msg = _extractMsg(response.body) ?? 'Failed to register mentor';
        throw Exception(msg);
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Certificates ──────────────────────────────────────────────────────────

  Future<List<AdminCertificate>> fetchCertificates({String? status}) async {
    try {
      final uri = status != null && status.isNotEmpty
          ? Uri.parse('$baseUrl/certificates?status=${status.toLowerCase()}')
          : Uri.parse('$baseUrl/certificates');

      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['certificates'] ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => AdminCertificate.fromJson(e))
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      throw Exception('Failed to load certificates');
    } on SocketException {
      throw Exception('Network error loading certificates.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  Future<AdminAnalytics> fetchAnalytics() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/analytics'), headers: await _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return AdminAnalytics.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      throw Exception('Failed to load analytics');
    } on SocketException {
      throw Exception('Network error loading analytics.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
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

// ─── Data Models ─────────────────────────────────────────────────────────────

class AdminDashboardData {
  final int totalStudents;
  final int totalMentors;
  final int totalCertificates;
  final int pendingVerifications;

  const AdminDashboardData({
    required this.totalStudents,
    required this.totalMentors,
    required this.totalCertificates,
    required this.pendingVerifications,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> j) =>
      AdminDashboardData(
        totalStudents: (j['total_students'] as num?)?.toInt() ?? 0,
        totalMentors: (j['total_mentors'] as num?)?.toInt() ?? 0,
        totalCertificates: (j['total_certificates'] as num?)?.toInt() ?? 0,
        pendingVerifications:
            (j['pending_verifications'] as num?)?.toInt() ?? 0,
      );
}

class AdminActivityItem {
  final String studentName;
  final String eventName;
  final String status;
  final String createdAt;

  const AdminActivityItem({
    required this.studentName,
    required this.eventName,
    required this.status,
    required this.createdAt,
  });

  factory AdminActivityItem.fromJson(Map<String, dynamic> j) =>
      AdminActivityItem(
        studentName: j['student_name']?.toString() ?? '',
        eventName:
            j['event_name']?['event_name']?.toString() ??
            j['event']?.toString() ??
            '',
        status: j['status']?.toString() ?? 'pending',
        createdAt: j['created_at']?.toString() ?? '',
      );
}

class AdminStudent {
  final int id;
  final String name;
  final String rollNumber;
  final String department;
  final String status;
  final String profileImage;
  final int submitted;
  final int approved;
  final int pending;
  final int rejected;

  const AdminStudent({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.department,
    required this.status,
    required this.profileImage,
    required this.submitted,
    required this.approved,
    required this.pending,
    required this.rejected,
  });

  factory AdminStudent.fromJson(Map<String, dynamic> j) => AdminStudent(
    id: (j['id'] as num?)?.toInt() ?? 0,
    name: j['name']?.toString() ?? '',
    rollNumber: j['roll_number']?.toString() ?? '',
    department: j['department']?.toString() ?? '',
    status: j['status']?.toString() ?? 'active',
    profileImage:
        j['profile_image']?.toString() ?? '/uploads/profile/default.png',
    submitted: (j['submitted'] as num?)?.toInt() ?? 0,
    approved: (j['approved'] as num?)?.toInt() ?? 0,
    pending: (j['pending'] as num?)?.toInt() ?? 0,
    rejected: (j['rejected'] as num?)?.toInt() ?? 0,
  );
}

class AdminMentor {
  final int id;
  final String name;
  final String department;
  final String employeeId;
  final String status;
  final String profileImage;
  final int studentsAssigned;
  final int reviewed;
  final int approved;
  final int rejected;

  const AdminMentor({
    required this.id,
    required this.name,
    required this.department,
    required this.employeeId,
    required this.status,
    required this.profileImage,
    required this.studentsAssigned,
    required this.reviewed,
    required this.approved,
    required this.rejected,
  });

  factory AdminMentor.fromJson(Map<String, dynamic> j) => AdminMentor(
    id: (j['id'] as num?)?.toInt() ?? 0,
    name: j['name']?.toString() ?? '',
    department: j['department']?.toString() ?? '',
    employeeId: j['employee_id']?.toString() ?? '',
    status: j['status']?.toString() ?? 'active',
    profileImage:
        j['profile_image']?.toString() ?? '/uploads/profile/default.png',
    studentsAssigned: (j['students_assigned'] as num?)?.toInt() ?? 0,
    reviewed: (j['reviewed'] as num?)?.toInt() ?? 0,
    approved: (j['approved'] as num?)?.toInt() ?? 0,
    rejected: (j['rejected'] as num?)?.toInt() ?? 0,
  );
}

class AdminCertificate {
  final int id;
  final String studentName;
  final String rollNumber;
  final String department;
  final String eventName;
  final String organizingInstitute;
  final String eventDate;
  final String participationType;
  final String certificateType;
  final String certificateFile;
  final String status;
  final int points;
  final String mentorRemark;

  const AdminCertificate({
    required this.id,
    required this.studentName,
    required this.rollNumber,
    required this.department,
    required this.eventName,
    required this.organizingInstitute,
    required this.eventDate,
    required this.participationType,
    required this.certificateType,
    required this.certificateFile,
    required this.status,
    required this.points,
    required this.mentorRemark,
  });

  factory AdminCertificate.fromJson(Map<String, dynamic> j) => AdminCertificate(
    id: (j['id'] as num?)?.toInt() ?? 0,
    studentName: j['student_name']?.toString() ?? '',
    rollNumber: j['roll_number']?.toString() ?? '',
    department: j['department']?.toString() ?? '',
    eventName: j['event_name']?.toString() ?? '',
    organizingInstitute: j['organizing_institute']?.toString() ?? '',
    eventDate: j['event_date']?.toString() ?? '',
    participationType: j['participation_type']?.toString() ?? '',
    certificateType: j['certificate_type']?.toString() ?? '',
    certificateFile: j['certificate_file']?.toString() ?? '',
    status: j['status']?.toString() ?? 'pending',
    points: (j['points'] as num?)?.toInt() ?? 0,
    mentorRemark: j['mentor_remark']?.toString() ?? '',
  );
}

class AdminStudentDetail {
  final int id;
  final String name;
  final String email;
  final String rollNumber;
  final String department;
  final String status;
  final String profileImage;
  final String mentorName;
  final int mentorId;
  final int submitted;
  final int approved;
  final int pending;
  final int rejected;
  final int totalPoints;

  const AdminStudentDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNumber,
    required this.department,
    required this.status,
    required this.profileImage,
    required this.mentorName,
    required this.mentorId,
    required this.submitted,
    required this.approved,
    required this.pending,
    required this.rejected,
    required this.totalPoints,
  });

  factory AdminStudentDetail.fromJson(Map<String, dynamic> j) =>
      AdminStudentDetail(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        rollNumber: j['roll_number']?.toString() ?? '',
        department: j['department']?.toString() ?? '',
        status: j['status']?.toString() ?? 'active',
        profileImage:
            j['profile_image']?.toString() ?? '/uploads/profile/default.png',
        mentorName: j['mentor_name']?.toString() ?? 'Not Assigned',
        mentorId: (j['mentor_id'] as num?)?.toInt() ?? 0,
        submitted: (j['submitted'] as num?)?.toInt() ?? 0,
        approved: (j['approved'] as num?)?.toInt() ?? 0,
        pending: (j['pending'] as num?)?.toInt() ?? 0,
        rejected: (j['rejected'] as num?)?.toInt() ?? 0,
        totalPoints: (j['total_points'] as num?)?.toInt() ?? 0,
      );
}

class AdminMonthlyUpload {
  final String month;
  final int uploads;

  const AdminMonthlyUpload({required this.month, required this.uploads});

  factory AdminMonthlyUpload.fromJson(Map<String, dynamic> j) =>
      AdminMonthlyUpload(
        month: j['month']?.toString() ?? '',
        uploads: (j['uploads'] as num?)?.toInt() ?? 0,
      );
}

class AdminAnalytics {
  final int totalCertificates;
  final int totalApproved;
  final int approvalRate;
  final List<AdminMonthlyUpload> monthlyUploads;

  const AdminAnalytics({
    required this.totalCertificates,
    required this.totalApproved,
    required this.approvalRate,
    required this.monthlyUploads,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> j) => AdminAnalytics(
    totalCertificates: (j['total_certificates'] as num?)?.toInt() ?? 0,
    totalApproved: (j['total_approved'] as num?)?.toInt() ?? 0,
    approvalRate: (j['approval_rate'] as num?)?.toInt() ?? 0,
    monthlyUploads: ((j['monthly_uploads'] as List?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => AdminMonthlyUpload.fromJson(e))
        .toList(),
  );
}
