import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Minimum splash duration for branding
    final splashDelay = Future.delayed(const Duration(seconds: 2));

    // Try to verify token with backend
    final isValid = await authProvider.verifyTokenWithBackend();

    await splashDelay;

    if (!mounted) return;

    if (isValid) {
      final role = authProvider.role;
      if (role == 'student') {
        Navigator.pushReplacementNamed(context, '/student-dashboard');
      } else if (role == 'mentor') {
        Navigator.pushReplacementNamed(context, '/mentor-dashboard');
      } else {
        // Unknown role — go to login for safety
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // No valid token — always show login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF6F8FE,
      ), // Using the app's background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Mock logo circle with icon since we don't have the assets image directly available
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0D1B2A), // Dark color from the design logo
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons
                      .change_history, // Triangle logo from image approximately
                  color: Color(0xFF4A90E2),
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'CertiTrack',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5145FF),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Academic Certificate Credit\nSystem',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF6B7280),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                child: LinearProgressIndicator(
                  backgroundColor: Color(0xFFE2E1FB),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5145FF)),
                  minHeight: 6,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Text(
                'VPPCOE Student Participation Portal',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
