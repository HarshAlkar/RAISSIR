import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import '../../config/api_config.dart';
import 'admin_certificates_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final AdminApiService _api = AdminApiService();
  static const Color _primary = Color(0xFF5145FF);
  static const Color _bg = Color(0xFFF6F8FE);

  bool _loading = true;
  String? _error;
  List<AdminStudent> _students = [];
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _api.fetchStudents(search: _search);
      if (!mounted) return;
      setState(() => _students = s);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus(AdminStudent s) async {
    final newStatus = s.status == 'active' ? 'disabled' : 'active';
    try {
      await _api.updateStudentStatus(s.id, newStatus);
      _load();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _showAssignMentorDialog(AdminStudent s) async {
    List<AdminMentor> mentors = [];
    bool loadingMentors = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (loadingMentors) {
            _api.fetchMentors().then((m) {
              setDialogState(() {
                mentors = m;
                loadingMentors = false;
              });
            });
          }

          return AlertDialog(
            title: const Text(
              'Assign Mentor',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            content: loadingMentors
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: mentors.length,
                      itemBuilder: (_, i) {
                        final m = mentors[i];
                        return ListTile(
                          title: Text(m.name),
                          subtitle: Text(m.department),
                          onTap: () async {
                            Navigator.pop(ctx);
                            try {
                              await _api.assignMentor(s.id, m.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mentor assigned successfully'),
                                ),
                              );
                              _load();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Students',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.people_outline_rounded, color: _primary),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF64748B),
            ),
            onPressed: () {},
          ),
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(
              'https://raissir.onrender.com/uploads/profile/default.png',
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (v) {
                  setState(() => _search = v);
                  _load();
                },
                decoration: const InputDecoration(
                  hintText: 'Search student by name or roll no b',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : _error != null
                ? _buildError()
                : RefreshIndicator(
                    color: _primary,
                    onRefresh: _load,
                    child: _students.isEmpty
                        ? const Center(child: Text('No students found.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _students.length,
                            itemBuilder: (_, i) => _studentCard(_students[i]),
                          ),
                  ),
          ),
        ],
      ),
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

  Widget _studentCard(AdminStudent s) {
    bool isActive = s.status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  s.profileImage.startsWith('http')
                      ? s.profileImage
                      : '${ApiConfig.origin}${s.profileImage}',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 70,
                    height: 70,
                    color: const Color(0xFFEEF2FF),
                    child: const Icon(Icons.person, color: _primary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: isActive
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Roll: ${s.rollNumber} | Dept: ${s.department}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats Row
          Row(
            children: [
              _statItem(
                'SUBMITTED',
                s.submitted,
                const Color(0xFFF8FAFC),
                const Color(0xFF5145FF),
              ),
              const SizedBox(width: 12),
              _statItem(
                'APPROVED',
                s.approved,
                const Color(0xFFF5F3FF),
                const Color(0xFF7C3AED),
              ),
              const SizedBox(width: 12),
              _statItem(
                'PENDING',
                s.pending,
                const Color(0xFFFFF7ED),
                const Color(0xFFD97706),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Buttons Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to certificates screen but filtered for this student if possible, or just view all for now
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminCertificatesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.military_tech_outlined, size: 18),
                  label: const Text(
                    'View Certificates',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAssignMentorDialog(s),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                  label: const Text(
                    'Assign Mentor',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Disable/Enable toggle
          GestureDetector(
            onTap: () => _toggleStatus(s),
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.block_flipped : Icons.check_circle_outline,
                    size: 16,
                    color: isActive
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'Disable' : 'Enable',
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, int val, Color bg, Color textCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: textCol,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              val.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textCol,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
