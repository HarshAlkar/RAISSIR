import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _error = "";
  String? _token;
  String? _role;

  bool get isLoading => _isLoading;
  String get error => _error;
  String? get token => _token;
  String? get role => _role;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(email, password);
      _token = response['token'];
      _role = response['user']['role'];

      await _authService.saveToken(_token!);
      if (_role != null) {
        await _authService.saveRole(_role!);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.register(userData);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  Future<void> checkToken() async {
    _token = await _authService.getToken();
    _role = await _authService.getRole();
    notifyListeners();
  }

  /// Verifies the stored token against the backend.
  /// Returns true if valid, false if invalid/expired (and clears local state).
  Future<bool> verifyTokenWithBackend() async {
    _token = await _authService.getToken();
    _role = await _authService.getRole();
    if (_token == null) return false;

    final valid = await _authService.verifyToken();
    if (!valid) {
      // Clear stale local state
      _token = null;
      _role = null;
      notifyListeners();
    }
    return valid;
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _role = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = "";
    notifyListeners();
  }
}
