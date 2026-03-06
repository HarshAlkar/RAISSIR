import 'package:flutter/foundation.dart';

class ApiConfig {
  // ─── Production URL (Render) ───────────────────────────────────────────────
  // Change this when you get a new Render URL.
  static const String _productionUrl = 'https://raissir.onrender.com';

  // ─── Local development ─────────────────────────────────────────────────────
  // Your machine's local IP — used when API_BASE_URL is not set and we are
  // running in debug mode on a real Android device.
  // Run: ipconfig  →  look for your Wi-Fi IPv4 address
  static const String _localIp = '192.168.29.109';
  static const String _localPort = '5000';

  // ─── Build-time overrides (optional) ──────────────────────────────────────
  // Override at build time:
  //   flutter run  --dart-define=API_BASE_URL=http://192.168.1.5:5000
  //   flutter build apk --dart-define=API_BASE_URL=https://raissir.onrender.com
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  // ─── Resolve base URL ─────────────────────────────────────────────────────
  static String get origin {
    // 1. Explicit build-time override wins
    if (_baseUrlOverride.trim().isNotEmpty) {
      return _baseUrlOverride.trim().replaceAll(RegExp(r'/$'), '');
    }

    // 2. In release/profile mode → always use production Render URL
    if (!kDebugMode) return _productionUrl;

    // 3. Debug mode on Android real device or emulator → use local IP
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$_localIp:$_localPort';
    }

    // 4. Web / Desktop debug → localhost
    return 'http://localhost:$_localPort';
  }

  // ─── Named base URLs ──────────────────────────────────────────────────────
  static String get authBase => '$origin/api/auth';
  static String get studentBase => '$origin/api/student';
  static String get mentorBase => '$origin/api/mentor';
  static String get mentorsList => '$origin/api/mentors';

  /// Base URL for loading uploaded certificate images
  static String get uploadsBase => '$origin/uploads';
}
