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

  /// Calls the backend login API.
  /// Returns the **role string** ("student", "mentor", "admin") on success.
  /// Returns **null** on failure, and sets [error].
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _authService.login(email, password);

      // Extract and normalize values immediately from the response map
      final String? rawToken = response['token']?.toString();
      final String rawRole = (response['user']?['role'] ?? '')
          .toString()
          .toLowerCase()
          .trim();
      final String userName = (response['user']?['name'] ?? '').toString();

      if (rawToken == null || rawToken.isEmpty) {
        _error = 'Server did not return a token. Please try again.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      if (rawRole.isEmpty) {
        _error = 'Server did not return a role. Please try again.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Commit to in-memory state BEFORE persistence
      _token = rawToken;
      _role = rawRole;

      // Persist to SharedPreferences
      await _authService.saveToken(rawToken);
      await _authService.saveRole(rawRole);

      _isLoading = false;
      notifyListeners();

      debugPrint('✅ Login success — name: $userName, role: $_role');
      return rawRole; // return directly so caller doesn't read stale state
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Login error: $_error');
      return null;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _authService.register(userData);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Startup token check ───────────────────────────────────────────────────

  /// Reads stored token + role from device storage (no network).
  Future<void> checkToken() async {
    _token = await _authService.getToken();
    _role = await _authService.getRole();
    notifyListeners();
  }

  /// Verifies the stored token with the backend.
  /// On success:  updates [role] from the *backend response* (not just local storage).
  /// On failure:  clears all local auth state.
  Future<bool> verifyTokenWithBackend() async {
    _token = await _authService.getToken();
    _role = await _authService.getRole();

    if (_token == null || _token!.isEmpty) {
      debugPrint('🔑 No stored token — going to login');
      return false;
    }

    final result = await _authService.verifyTokenAndGetRole();

    if (result == null) {
      // Token invalid / expired / network error cleared it
      _token = null;
      _role = null;
      notifyListeners();
      debugPrint('🔑 Token invalid — clearing state');
      return false;
    }

    // Trust the role from backend (overrides any stale SharedPreferences value)
    _role = result;
    await _authService.saveRole(result);
    notifyListeners();
    debugPrint('🔑 Token valid — role: $_role');
    return true;
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _role = null;
    _error = '';
    notifyListeners();
    debugPrint('👋 Logged out');
  }
}
