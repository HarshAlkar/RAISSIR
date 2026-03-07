import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import '../../config/api_config.dart';
import 'admin_student_certificates_screen.dart';

class AdminStudentDetailsScreen extends StatefulWidget {
  final int studentId;

  const AdminStudentDetailsScreen({super.key, required this.studentId});

  @override
  State<AdminStudentDetailsScreen> createState() =>
      _AdminStudentDetailsScreenState();
}

class _AdminStudentDetailsScreenState extends State<AdminStudentDetailsScreen> {
  final AdminApiService _api = AdminApiService();
  static const Color _primary = Color(0xFF5145FF);
  static const Color _bg = Color(0xFFF6F8FE);

  bool _loading = true;
  String? _error;
  AdminStudentDetail? _student;

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
      final s = await _api.fetchStudentDetail(widget.studentId);
      if (!mounted) return;
      setState(() => _student = s);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          _student?.name ?? 'Student Details',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          if (_student != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _student!.status == 'active'
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _student!.status == 'active' ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: _student!.status == 'active'
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              color: _primary,
              onRefresh: _load,
              child: _buildBody(),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildBody() {
    final s = _student!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // ── Profile Card ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  s.profileImage.startsWith('http')
                      ? s.profileImage
                      : '${ApiConfig.origin}${s.profileImage}',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person, color: _primary, size: 40),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Info Cards ──────────────────────────────────────────────────────
        _infoRow([
          _infoItem(
            Icons.badge_outlined,
            'Roll Number',
            s.rollNumber.isEmpty ? '—' : s.rollNumber,
          ),
          _infoItem(
            Icons.business_outlined,
            'Department',
            s.department.isEmpty ? '—' : s.department,
          ),
        ]),
        const SizedBox(height: 12),
        _infoRow([
          _infoItem(
            Icons.person_outline,
            'Assigned Mentor',
            s.mentorName,
            highlight: s.mentorId > 0,
          ),
          _infoItem(
            Icons.star_rate_rounded,
            'Total Points',
            '${s.totalPoints} pts',
            highlight: s.totalPoints > 0,
            highlightColor: const Color(0xFFF59E0B),
          ),
        ]),
        const SizedBox(height: 24),

        // ── Certificate Stats ────────────────────────────────────────────────
        const Text(
          'Certificate Statistics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statBox(
              'SUBMITTED',
              s.submitted,
              const Color(0xFFEEF2FF),
              _primary,
            ),
            const SizedBox(width: 10),
            _statBox(
              'APPROVED',
              s.approved,
              const Color(0xFFDCFCE7),
              const Color(0xFF16A34A),
            ),
            const SizedBox(width: 10),
            _statBox(
              'PENDING',
              s.pending,
              const Color(0xFFFFF7ED),
              const Color(0xFFD97706),
            ),
            const SizedBox(width: 10),
            _statBox(
              'REJECTED',
              s.rejected,
              const Color(0xFFFEE2E2),
              const Color(0xFFDC2626),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Action Button ───────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminStudentCertificatesScreen(
                    studentId: widget.studentId,
                    studentName: s.name,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.military_tech_outlined, size: 20),
            label: const Text(
              'View Certificates',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _infoRow(List<Widget> children) {
    return Row(children: children.map((w) => Expanded(child: w)).toList());
  }

  Widget _infoItem(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
    Color highlightColor = _primary,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight ? highlightColor : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlight ? highlightColor : const Color(0xFF0F172A),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, int val, Color bg, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              val.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
