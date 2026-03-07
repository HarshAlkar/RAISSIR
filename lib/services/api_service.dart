import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/dashboard_data.dart';
import '../models/my_certificate.dart';
import '../exceptions/auth_exception.dart';
import '../utils/auth_helper.dart';

class ApiService {
  String get baseUrl => ApiConfig.studentBase;

  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<StudentProfile> fetchProfile() async {
    final url = '$baseUrl/profile';
    try {
      final response = await http
          .get(Uri.parse(url), headers: await getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return StudentProfile.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      } else {
        final msg = _extractError(response.body) ?? 'Profile load failed';
        throw Exception(msg);
      }
    } on SocketException {
      throw Exception(
        'Network error: Unable to load profile. Check your internet.',
      );
    } on TimeoutException {
      throw Exception('Connection timed out while loading profile.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  // ── Dashboard stats ───────────────────────────────────────────────────────

  Future<DashboardStats> fetchDashboardStats() async {
    final url = '$baseUrl/dashboard';
    try {
      final response = await http
          .get(Uri.parse(url), headers: await getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return DashboardStats.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      } else {
        throw Exception('Dashboard load failed (${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Network error: Cannot reach server for stats.');
    } on TimeoutException {
      throw Exception('Dashboard sync timed out.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  // ── Recent certificates ───────────────────────────────────────────────────

  Future<List<Certificate>> fetchRecentCertificates() async {
    final url = '$baseUrl/recent-certificates';
    try {
      final response = await http
          .get(Uri.parse(url), headers: await getHeaders())
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final List<dynamic> l = json.decode(response.body);
        return l.map((m) => Certificate.fromJson(m)).toList();
      }
      return [];
    } catch (_) {
      return []; // Non-critical failures return empty list
    }
  }

  // ── Upload certificate ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadCertificate({
    required String participationType,
    required String eventName,
    required String organizingInstitute,
    required String eventDate,
    required String certificateType,
    required String rollNumber,
    required String description,
    required String filePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-certificate'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['participation_type'] = participationType;
      request.fields['event_name'] = eventName;
      request.fields['organizing_institute'] = organizingInstitute;
      request.fields['event_date'] = eventDate;
      request.fields['certificate_type'] = certificateType;
      request.fields['roll_number'] = rollNumber;
      request.fields['description'] = description;

      request.files.add(
        await http.MultipartFile.fromPath('certificate_file', filePath),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final body = await response.stream.bytesToString();

      if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errMsg =
            _extractError(body) ?? 'Upload failed (${response.statusCode})';
        throw Exception(errMsg);
      }

      return body.isNotEmpty ? json.decode(body) : {};
    } on SocketException {
      throw Exception(
        'Network error: Could not upload file. Check your connectivity.',
      );
    } on TimeoutException {
      throw Exception(
        'Upload timed out. The file might be too large or the server is slow.',
      );
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  // ── My certificates ───────────────────────────────────────────────────────

  Future<List<MyCertificate>> fetchMyCertificates({String? status}) async {
    String url = '$baseUrl/certificates';
    final normalizedStatus = status?.trim().toLowerCase();
    if (normalizedStatus != null && normalizedStatus.isNotEmpty) {
      url += '?status=$normalizedStatus';
    }
    try {
      final response = await http
          .get(Uri.parse(url), headers: await getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> l = data['certificates'] ?? [];
        return l.map((m) => MyCertificate.fromJson(m)).toList();
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      } else {
        throw Exception('Failed to load certificates');
      }
    } on SocketException {
      throw Exception('Network error: Unable to fetch certificates.');
    } on TimeoutException {
      throw Exception('Request timed out while fetching your certificates.');
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      rethrow;
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String? _extractError(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map) {
        return decoded['error']?.toString() ?? decoded['msg']?.toString();
      }
    } catch (_) {}
    return null;
  }
}
