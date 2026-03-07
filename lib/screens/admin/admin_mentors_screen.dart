import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import '../../config/api_config.dart';
import 'admin_mentor_students_screen.dart';

class AdminMentorsScreen extends StatefulWidget {
  const AdminMentorsScreen({super.key});

  @override
  State<AdminMentorsScreen> createState() => _AdminMentorsScreenState();
}

class _AdminMentorsScreenState extends State<AdminMentorsScreen> {
  final AdminApiService _api = AdminApiService();
  static const Color _primary = Color(0xFF5145FF);
  static const Color _bg = Color(0xFFF6F8FE);

  bool _loading = true;
  String? _error;
  List<AdminMentor> _mentors = [];
  String _search = '';
  String _filter = 'All'; // All, Active, Pending (Inactive)
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
      final m = await _api.fetchMentors(
        search: _search,
        filter: _filter == 'All'
            ? null
            : (_filter == 'Active' ? 'active' : 'pending'),
      );
      if (!mounted) return;
      setState(() => _mentors = m);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus(AdminMentor m) async {
    final newStatus = m.status == 'active' ? 'inactive' : 'active';
    try {
      await _api.updateMentorStatus(m.id, newStatus);
      _load();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _showRegisterMentorDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final empIdCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool regLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Register New Mentor',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'Full Name', Icons.person_outline),
                _dialogField(emailCtrl, 'Email Address', Icons.email_outlined),
                _dialogField(deptCtrl, 'Department', Icons.business_outlined),
                _dialogField(empIdCtrl, 'Employee ID', Icons.badge_outlined),
                _dialogField(
                  passCtrl,
                  'Password',
                  Icons.lock_outline,
                  isPass: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: regLoading
                  ? null
                  : () async {
                      setDialogState(() => regLoading = true);
                      try {
                        await _api.registerMentor(
                          name: nameCtrl.text,
                          email: emailCtrl.text,
                          department: deptCtrl.text,
                          employeeId: empIdCtrl.text,
                          password: passCtrl.text,
                        );
                        Navigator.pop(ctx);
                        _load();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mentor registered!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      } finally {
                        setDialogState(() => regLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              child: regLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isPass = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        obscureText: isPass,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Mentors',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.school_outlined, color: _primary),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.filter_list_rounded,
              color: Color(0xFF64748B),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
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
                      hintText: 'Search mentors by name, department, or ID...',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          'All Mentors (${_mentors.length})',
                          'Active',
                          'Pending',
                        ].map((f) {
                          bool isSel =
                              _filter == (f.contains('All') ? 'All' : f);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                f,
                                style: TextStyle(
                                  color: isSel
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              selected: isSel,
                              onSelected: (bool s) {
                                if (s) {
                                  setState(
                                    () =>
                                        _filter = f.contains('All') ? 'All' : f,
                                  );
                                  _load();
                                }
                              },
                              selectedColor: _primary,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSel
                                      ? _primary
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
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
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _mentors.length + 1,
                      itemBuilder: (_, i) {
                        if (i == _mentors.length) return _buildRegisterCard();
                        return _mentorCard(_mentors[i]);
                      },
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
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _mentorCard(AdminMentor m) {
    bool isActive = m.status == 'active';

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
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  m.profileImage.startsWith('http')
                      ? m.profileImage
                      : '${ApiConfig.origin}${m.profileImage}',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
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
                    Text(
                      m.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${m.department} Department • ${m.employeeId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Active Status' : 'Inactive',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statItem(
                'STUDENTS ASSIGNED',
                m.studentsAssigned,
                const Color(0xFFF8FAFC),
                const Color(0xFF0F172A),
              ),
              const SizedBox(width: 12),
              _statItem(
                'REVIEWED',
                m.reviewed,
                const Color(0xFFF8FAFC),
                const Color(0xFF0F172A),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statItem(
                'APPROVED',
                m.approved,
                const Color(0xFFF8FAFC),
                const Color(0xFF16A34A),
              ),
              const SizedBox(width: 12),
              _statItem(
                'REJECTED',
                m.rejected,
                const Color(0xFFF8FAFC),
                const Color(0xFFDC2626),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminMentorStudentsScreen(
                          mentorId: m.id,
                          mentorName: m.name,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View Students',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Reassign',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFFEBEB)
                      : const Color(0xFFE6F9EF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFFFCCCC)
                        : const Color(0xFFCCF2DD),
                  ),
                ),
                child: IconButton(
                  onPressed: () => _toggleStatus(m),
                  icon: Icon(
                    isActive
                        ? Icons.block_flipped
                        : Icons.check_circle_outlined,
                    size: 18,
                    color: isActive ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, int val, Color bg, Color valCol) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            val.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: valCol,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterCard() {
    return GestureDetector(
      onTap: _showRegisterMentorDialog,
      child: Container(
        margin: const EdgeInsets.only(bottom: 30, top: 10),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: _primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Register New Mentor',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add staff to manage student certificates',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
