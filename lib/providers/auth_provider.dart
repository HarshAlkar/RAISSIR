import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _error = '';
  String? _token;
  String? _role;

  bool get isLoading => _isLoading;
  String get error => _error;
  String? get token => _token;
  String? get role => _role;

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Returns the role string directly on success so caller doesn't need to
  /// read [role] asynchronously after this call returns.
  Future<String?> login(String email, String password) async {
    _setLoading(true);
    _error = '';
    notifyListeners();

    try {
      final response = await _authService.login(email, password);

      final token = response['token']?.toString();
      // Normalize role to lowercase to avoid 'Mentor' vs 'mentor' mismatch
      final role = (response['user']?['role'] ?? '')
          .toString()
          .toLowerCase()
          .trim();

      if (token == null || token.isEmpty) {
        _error = 'Login failed: no token received';
        _setLoading(false);
        return null;
      }

      _token = token;
      _role = role;

      await _authService.saveToken(token);
      await _authService.saveRole(role);

      _setLoading(false);
      return role; // ← return role directly to avoid race condition
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return null;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _error = '';
    notifyListeners();

    try {
      await _authService.register(userData);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // ── Token check (startup) ─────────────────────────────────────────────────

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
    if (_token == null || _token!.isEmpty) return false;

    final valid = await _authService.verifyToken();
    if (!valid) {
      _token = null;
      _role = null;
      notifyListeners();
    }
    return valid;
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _role = null;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
