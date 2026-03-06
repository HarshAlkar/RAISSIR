import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/dashboard_data.dart';
import '../models/my_certificate.dart';
import '../exceptions/auth_exception.dart';
import '../utils/auth_helper.dart';

class ApiService {
  final String baseUrl = ApiConfig.studentBase;

  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<StudentProfile> fetchProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await getHeaders(),
    );
    if (response.statusCode == 200) {
      return StudentProfile.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      AuthHelper.handleUnauthorized();
      throw UnauthorizedException();
    } else {
      throw Exception(
        'Failed with status ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<DashboardStats> fetchDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: await getHeaders(),
    );
    if (response.statusCode == 200) {
      return DashboardStats.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      AuthHelper.handleUnauthorized();
      throw UnauthorizedException();
    } else {
      throw Exception(
        'Failed to load dashboard stats: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<Certificate>> fetchRecentCertificates() async {
    final response = await http.get(
      Uri.parse('$baseUrl/recent-certificates'),
      headers: await getHeaders(),
    );
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Certificate>.from(
        l.map((model) => Certificate.fromJson(model)),
      );
    } else if (response.statusCode == 401) {
      AuthHelper.handleUnauthorized();
      throw UnauthorizedException();
    } else {
      throw Exception(
        'Failed to load recent certificates: ${response.statusCode} - ${response.body}',
      );
    }
  }

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

    var request = http.MultipartRequest(
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

    var multipartFile = await http.MultipartFile.fromPath(
      'certificate_file',
      filePath,
    );
    request.files.add(multipartFile);

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 401) {
      AuthHelper.handleUnauthorized();
      throw UnauthorizedException();
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      // Try to extract real error message from server
      String errMsg = 'Upload failed (${response.statusCode})';
      try {
        final decoded = json.decode(body);
        if (decoded is Map) {
          errMsg =
              decoded['error']?.toString() ??
              decoded['msg']?.toString() ??
              errMsg;
        }
      } catch (_) {}
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

  Future<List<MyCertificate>> fetchMyCertificates({String? status}) async {
    String url = '$baseUrl/certificates';
    final normalizedStatus = status?.trim().toLowerCase();
    if (normalizedStatus != null && normalizedStatus.isNotEmpty) {
      url += '?status=$normalizedStatus';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: await getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      Iterable l = data['certificates'];
      return List<MyCertificate>.from(l.map((m) => MyCertificate.fromJson(m)));
    } else if (response.statusCode == 401) {
      AuthHelper.handleUnauthorized();
      throw UnauthorizedException();
    } else {
      throw Exception('Failed to load certificates');
    }
  }
}
