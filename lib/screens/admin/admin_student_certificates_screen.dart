import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import 'admin_certificate_detail_screen.dart';

class AdminStudentCertificatesScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const AdminStudentCertificatesScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<AdminStudentCertificatesScreen> createState() =>
      _AdminStudentCertificatesScreenState();
}

class _AdminStudentCertificatesScreenState
    extends State<AdminStudentCertificatesScreen>
    with SingleTickerProviderStateMixin {
  final AdminApiService _api = AdminApiService();
  static const Color _primary = Color(0xFF5145FF);
  static const Color _bg = Color(0xFFF6F8FE);

  late TabController _tabController;
  final List<String?> _filters = [null, 'approved', 'pending', 'rejected'];
  final List<String> _tabLabels = ['All', 'Approved', 'Pending', 'Rejected'];

  bool _loading = true;
  String? _error;
  List<AdminCertificate> _allCerts = [];
  List<AdminCertificate> _filteredCerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _applyFilter();
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final certs = await _api.fetchStudentCertificates(widget.studentId);
      if (!mounted) return;
      setState(() {
        _allCerts = certs;
        _applyFilter();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final filter = _filters[_tabController.index];
    setState(() {
      _filteredCerts = filter == null
          ? _allCerts
          : _allCerts.where((c) => c.status == filter).toList();
    });
  }

  Color _statusBg(String status) {
    if (status == 'approved') return const Color(0xFFDCFCE7);
    if (status == 'rejected') return const Color(0xFFFEE2E2);
    return const Color(0xFFFEF3C7);
  }

  Color _statusTxt(String status) {
    if (status == 'approved') return const Color(0xFF16A34A);
    if (status == 'rejected') return const Color(0xFFDC2626);
    return const Color(0xFFD97706);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.studentName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            const Text(
              'Certificates',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primary,
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: _primary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              color: _primary,
              onRefresh: _load,
              child: _filteredCerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            size: 56,
                            color: Color(0xFFE2E8F0),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No ${_tabLabels[_tabController.index].toLowerCase()} certificates',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _filteredCerts.length,
                      itemBuilder: (_, i) => _certCard(_filteredCerts[i]),
                    ),
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

  Widget _certCard(AdminCertificate c) {
    final status = c.status.toLowerCase();
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminCertificateDetailScreen(certificate: c),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.eventName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg(status),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      color: _statusTxt(status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              c.organizingInstitute,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (c.certificateType.isNotEmpty) ...[
                  const Icon(
                    Icons.workspace_premium_outlined,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    c.certificateType,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  c.eventDate.isEmpty ? '—' : c.eventDate,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const Spacer(),
                if (status == 'approved' && c.points > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rate_rounded,
                        size: 13,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${c.points} pts',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
            if (status == 'rejected' && c.mentorRemark.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 13,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        c.mentorRemark,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
