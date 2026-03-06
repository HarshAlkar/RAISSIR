import 'package:flutter/foundation.dart';

class ApiConfig {
  // ─── Build-time overrides ─────────────────────────────────────────────────
  // Run with:
  //   flutter run --dart-define=API_HOST=192.168.1.10
  //   flutter run --dart-define=API_BASE_URL=https://your-app.onrender.com
  // ─────────────────────────────────────────────────────────────────────────

  /// Full base URL override (e.g. Render production URL).
  /// If set, it takes precedence over everything else.
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Host override (e.g. your LAN IP for real phone testing).
  static const String _hostOverride = String.fromEnvironment('API_HOST');

  static const String _portOverride = String.fromEnvironment(
    'API_PORT',
    defaultValue: '5000',
  );

  // ─── Your machine's local IP (auto-detected for real device testing) ─────
  // Change this to your computer's Wi-Fi IP when testing on a real phone.
  // Find it with: ipconfig (Windows) or ifconfig (Mac/Linux)
  static const String _lanIp = '192.168.29.109';
  // ─────────────────────────────────────────────────────────────────────────

  static String get _host {
    // 1. Explicit override wins
    if (_hostOverride.trim().isNotEmpty) return _hostOverride.trim();

    // 2. Web / Desktop → localhost
    if (kIsWeb) return 'localhost';

    // 3. Android emulator → special loopback alias
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Use LAN IP so both emulator and real device work.
      // Emulator can also reach LAN IP as long as host is on same network.
      return _lanIp;
    }

    // 4. iOS simulator / macOS
    return 'localhost';
  }

  static String get _port =>
      _portOverride.trim().isEmpty ? '5000' : _portOverride.trim();

  /// The base URL for all API calls.
  /// Reads API_BASE_URL build variable first (for Render production),
  /// then falls back to local host:port.
  static String get origin {
    if (_baseUrlOverride.trim().isNotEmpty) {
      // Remove trailing slash if present
      return _baseUrlOverride.trim().replaceAll(RegExp(r'/$'), '');
    }
    return 'http://$_host:$_port';
  }

  static String get authBase => '$origin/api/auth';
  static String get studentBase => '$origin/api/student';
  static String get mentorBase => '$origin/api/mentor';
  static String get mentorsList => '$origin/api/mentors';

  /// Base URL for loading uploaded files (certificates, etc.)
  static String get uploadsBase => '$origin/uploads';
}
