import 'package:flutter/foundation.dart';

class ApiConfig {
  // ─── Production URL (Render) ─────────────────────────────────────────────
  static const String _productionUrl = 'https://raissir.onrender.com';

  // ─── Local development IP (same Wi-Fi network) ───────────────────────────
  // Only used when running on a desktop or emulator, NOT real phone.
  static const String _localIp = '192.168.29.109';
  static const String _localPort = '5000';

  // ─── Build-time override ──────────────────────────────────────────────────
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.5:5000
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  // ─── URL resolution ───────────────────────────────────────────────────────
  static String get origin {
    // 1. Explicit build-time override always wins
    if (_baseUrlOverride.trim().isNotEmpty) {
      return _baseUrlOverride.trim().replaceAll(RegExp(r'/$'), '');
    }

    // 2. Web → local or production based on mode
    if (kIsWeb) {
      return kDebugMode ? 'http://localhost:$_localPort' : _productionUrl;
    }

    // 3. Android / iOS real device → always use Render (production)
    //    Real phones may not be on the same Wi-Fi as the dev machine.
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return _productionUrl;
    }

    // 4. Desktop (Windows/Mac/Linux) or emulator → local backend
    return 'http://$_localIp:$_localPort';
  }

  static String get authBase => '$origin/api/auth';
  static String get studentBase => '$origin/api/student';
  static String get mentorBase => '$origin/api/mentor';
  static String get mentorsList => '$origin/api/mentors';
  static String get uploadsBase => '$origin/uploads';
}
