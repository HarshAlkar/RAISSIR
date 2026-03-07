import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/dashboard_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/student/upload_certificate_screen.dart';
import 'screens/student/my_certificates_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/profile_screen.dart';
import 'screens/student/dashboard_screen.dart';
import 'screens/auth/mentor_registration_screen.dart';
import 'screens/mentor/mentor_dashboard_screen.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/mentor/mentor_students_screen.dart';
import 'screens/mentor/mentor_verify_screen.dart';
import 'screens/mentor/mentor_settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CertiTrack',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF5145FF),
        scaffoldBackgroundColor: const Color(0xFFF6F8FE),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/student-dashboard': (context) => const DashboardScreen(),
        '/upload-certificate': (context) => const UploadCertificateScreen(),
        '/my-certificates': (context) => const MyCertificatesScreen(),
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const StudentProfileScreen(),
        '/mentor-signup': (context) => const MentorRegistrationScreen(),
        '/mentor/dashboard': (context) => const MentorDashboardScreen(),
        '/mentor-dashboard': (context) => const MentorDashboardScreen(),
        '/admin-dashboard': (context) => const AdminMainScreen(),
        '/mentor/students': (context) => const MentorStudentsScreen(),
        '/mentor/verify': (context) => const MentorVerifyScreen(),
        '/mentor/settings': (context) => const MentorSettingsScreen(),
        '/mentor-settings': (context) => const MentorSettingsScreen(),
      },
    );
  }
}
