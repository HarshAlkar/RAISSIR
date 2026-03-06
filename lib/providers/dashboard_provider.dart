import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';
import '../exceptions/auth_exception.dart';

class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  StudentProfile? _profile;
  DashboardStats? _stats;
  List<Certificate>? _recentCertificates;

  bool _isLoading = false;
  String _error = "";
  bool _isUnauthorized = false;

  StudentProfile? get profile => _profile;
  DashboardStats? get stats => _stats;
  List<Certificate>? get recentCertificates => _recentCertificates;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isUnauthorized => _isUnauthorized;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = "";
    _isUnauthorized = false;
    notifyListeners();

    try {
      final profileResult = await _apiService.fetchProfile();
      final statsResult = await _apiService.fetchDashboardStats();
      final certsResult = await _apiService.fetchRecentCertificates();

      _profile = profileResult;
      _stats = statsResult;
      _recentCertificates = certsResult;
    } on UnauthorizedException catch (e) {
      _isUnauthorized = true;
      _error = e.message;
      _profile = null;
      _stats = null;
      _recentCertificates = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _profile = null;
      _stats = null;
      _recentCertificates = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
