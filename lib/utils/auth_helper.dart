import '../main.dart';
import '../services/auth_service.dart';

class AuthHelper {
  static void handleUnauthorized() async {
    final authService = AuthService();
    await authService.logout();

    // Use the global navigator key to redirect to login
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}
