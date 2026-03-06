import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/dashboard_data.dart';
import '../models/my_certificate.dart';
import '../exceptions/auth_exception.dart';
import '../utils/auth_helper.dart';

class ApiService {
  // Use a getter so the URL is always fresh (not stale from construction time)
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
    debugPrint('📡 fetchProfile → $url');
    try {
      final response = await http
          .get(Uri.parse(url), headers: await getHeaders())
          .timeout(const Duration(seconds: 10));

      debugPrint('fetchProfile status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return StudentProfile.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      } else {
        final msg =
            _extractError(response.body) ??
            'Profile load failed (${response.statusCode})';
        throw Exception(msg);
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      debugPrint('fetchProfile error: $e');
      throw Exception('Cannot connect to server. Check your network.');
    }
  }

  // ── Dashboard stats ───────────────────────────────────────────────────────

  Future<DashboardStats> fetchDashboardStats() async {
    final url = '$baseUrl/dashboard';
    debugPrint('📡 fetchDashboardStats → $url');
    try {
      final response = await http
          .get(Uri.parse(url), headers: await getHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return DashboardStats.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      } else {
        throw Exception(
          'Dashboard load failed (${response.statusCode}): ${response.body}',
        );
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      debugPrint('fetchDashboardStats error: $e');
      throw Exception('Cannot connect to server. Check your network.');
    }
  }

  // ── Recent certificates ───────────────────────────────────────────────────

  Future<List<Certificate>> fetchRecentCertificates() async {
    final url = '$baseUrl/recent-certificates';
    debugPrint('📡 fetchRecentCertificates → $url');
    try {
      final response = await http
          .get(Uri.parse(url), headers: await getHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Iterable l = json.decode(response.body);
        return List<Certificate>.from(l.map((m) => Certificate.fromJson(m)));
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      } else {
        // Non-critical — return empty list instead of crashing
        return [];
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      debugPrint('fetchRecentCertificates error: $e');
      return []; // non-critical, don't block profile from loading
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

    final response = await request.send();
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

    if (body.isEmpty) return {};
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
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
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Iterable l = data['certificates'];
        return List<MyCertificate>.from(
          l.map((m) => MyCertificate.fromJson(m)),
        );
      } else if (response.statusCode == 401) {
        AuthHelper.handleUnauthorized();
        throw UnauthorizedException();
      } else {
        throw Exception('Failed to load certificates');
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      throw Exception('Cannot connect to server. Check your network.');
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
