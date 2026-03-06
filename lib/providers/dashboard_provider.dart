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
  String _error = '';
  bool _isUnauthorized = false;

  StudentProfile? get profile => _profile;
  DashboardStats? get stats => _stats;
  List<Certificate>? get recentCertificates => _recentCertificates;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isUnauthorized => _isUnauthorized;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = '';
    _isUnauthorized = false;
    notifyListeners();

    try {
      // Load profile and stats in parallel for speed
      final results = await Future.wait([
        _apiService.fetchProfile(),
        _apiService.fetchDashboardStats(),
      ]);

      _profile = results[0] as StudentProfile;
      _stats = results[1] as DashboardStats;

      // Recent certificates is non-critical — load separately, don't fail dashboard
      try {
        _recentCertificates = await _apiService.fetchRecentCertificates();
      } catch (_) {
        _recentCertificates = [];
      }
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
      debugPrint('DashboardProvider error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _profile = null;
    _stats = null;
    _recentCertificates = null;
    _error = '';
    _isUnauthorized = false;
    _isLoading = false;
    notifyListeners();
  }
}
