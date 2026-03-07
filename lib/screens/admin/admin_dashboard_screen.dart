import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/admin_api_service.dart';
import 'admin_main_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminApiService _api = AdminApiService();
  bool _loading = true;
  String? _error;
  AdminDashboardData? _data;
  List<AdminActivityItem> _activity = [];

  static const Color _primary = Color(0xFF5145FF);
  static const Color _bg = Color(0xFFF6F8FE);
  static const Color _cardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _api.fetchDashboard();
      final a = await _api.fetchRecentActivity();
      if (!mounted) return;
      setState(() {
        _data = d;
        _activity = a;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _error != null
            ? _buildError()
            : _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            'CERTITRACK UNIVERSITY SYSTEM',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none_outlined,
            color: Color(0xFF64748B),
          ),
        ),
        GestureDetector(
          onTap: () => _showLogoutDialog(),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: _primary, shape: BoxShape.circle),
            child: const Center(
              child: Text(
                'AD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final d = _data;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsGrid(d),
        const SizedBox(height: 24),
        _sectionHeader('Recent Activity'),
        const SizedBox(height: 12),
        _buildActivityList(),
        const SizedBox(height: 24),
        _sectionHeader('Quick Actions'),
        const SizedBox(height: 12),
        _buildQuickActions(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        if (title == 'Recent Activity')
          TextButton(
            onPressed: () => AdminMainScreen.navKey.currentState?.setIndex(3),
            child: const Text(
              'View All',
              style: TextStyle(color: _primary, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsGrid(AdminDashboardData? d) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _statCard(
          'Total Students',
          d?.totalStudents.toString() ?? '0',
          Icons.school_outlined,
          const Color(0xFFEFF6FF),
          const Color(0xFF3B82F6),
        ),
        _statCard(
          'Total Mentors',
          d?.totalMentors.toString() ?? '0',
          Icons.people_outline,
          const Color(0xFFF5F3FF),
          const Color(0xFF8B5CF6),
        ),
        _statCard(
          'Certificates',
          d?.totalCertificates.toString() ?? '0',
          Icons.description_outlined,
          const Color(0xFFECFDF5),
          const Color(0xFF10B981),
        ),
        _statCard(
          'Pending',
          d?.pendingVerifications.toString() ?? '0',
          Icons.hourglass_empty_rounded,
          const Color(0xFFFFF7ED),
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String val,
    IconData icon,
    Color bg,
    Color iconCol,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconCol, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                val,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    if (_activity.isEmpty && !_loading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            'No recent activity',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _activity.length > 5 ? 5 : _activity.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
        itemBuilder: (_, i) {
          final item = _activity[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFF1F5F9),
              child: Icon(
                item.status == 'approved'
                    ? Icons.check_circle_outline
                    : Icons.history,
                size: 20,
                color: item.status == 'approved' ? Colors.green : Colors.blue,
              ),
            ),
            title: Text(
              item.studentName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            subtitle: Text(
              item.eventName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              item.createdAt.split('T')[0],
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _quickAction(
          icon: Icons.school_outlined,
          label: 'Manage Students',
          onTap: () => AdminMainScreen.navKey.currentState?.setIndex(1),
        ),
        const SizedBox(height: 10),
        _quickAction(
          icon: Icons.people_outline,
          label: 'Manage Mentors',
          onTap: () => AdminMainScreen.navKey.currentState?.setIndex(2),
        ),
        const SizedBox(height: 10),
        _quickAction(
          icon: Icons.description_outlined,
          label: 'System Reports',
          onTap: () => AdminMainScreen.navKey.currentState?.setIndex(3),
        ),
        const SizedBox(height: 10),
        _quickAction(
          icon: Icons.settings_outlined,
          label: 'System Settings',
          onTap: () => AdminMainScreen.navKey.currentState?.setIndex(4),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
