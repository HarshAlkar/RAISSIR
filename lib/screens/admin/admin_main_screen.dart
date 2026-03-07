import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_students_screen.dart';
import 'admin_mentors_screen.dart';
import 'admin_certificates_screen.dart';
import 'admin_settings_screen.dart';

class AdminMainScreen extends StatefulWidget {
  static final GlobalKey<AdminMainScreenState> navKey =
      GlobalKey<AdminMainScreenState>();
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => AdminMainScreenState();
}

class AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _pages = [
    const AdminDashboardScreen(),
    const AdminStudentsScreen(),
    const AdminMentorsScreen(),
    const AdminCertificatesScreen(),
    const AdminSettingsScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5145FF);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        selectedItemColor: primary,
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Mentors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Certificates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
