class ApiConfig {
  /// Production Backend URL (Always use HTTPS for real devices)
  static const String _productionUrl = 'https://raissir.onrender.com';

  /// Build-time override (optional)
  /// Use: flutter run --dart-define=API_BASE_URL=https://your-api.com
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// The final resolved origin URL.
  /// This ensures that the production Render URL is used on real devices.
  static String get origin {
    // 1. Explicit build-time override wins if provided
    if (_baseUrlOverride.trim().isNotEmpty) {
      return _baseUrlOverride.trim().replaceAll(RegExp(r'/$'), '');
    }

    // 2. Default to Production URL
    // All requests must use the Render backend to work on real phones.
    return _productionUrl;
  }

  // API Endpoints
  static String get authBase => '$origin/api/auth';
  static String get studentBase => '$origin/api/student';
  static String get mentorBase => '$origin/api/mentor';
  static String get mentorsList => '$origin/api/mentors';
  static String get uploadsBase => '$origin/uploads';
}
