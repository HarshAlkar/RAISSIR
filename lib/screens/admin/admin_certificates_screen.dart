import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';

class AdminCertificatesScreen extends StatefulWidget {
  const AdminCertificatesScreen({super.key});

  @override
  State<AdminCertificatesScreen> createState() =>
      _AdminCertificatesScreenState();
}

class _AdminCertificatesScreenState extends State<AdminCertificatesScreen>
    with SingleTickerProviderStateMixin {
  final AdminApiService _api = AdminApiService();
  static const Color _primary = Color(0xFF5145FF);
  static const Color _bg = Color(0xFFF6F8FE);

  late TabController _tabController;
  final List<String?> _filters = [null, 'approved', 'pending', 'rejected'];
  final List<String> _tabLabels = ['All', 'Approved', 'Pending', 'Rejected'];

  bool _loading = true;
  String? _error;
  List<AdminCertificate> _certs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final status = _filters[_tabController.index];
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await _api.fetchCertificates(status: status);
      if (!mounted) return;
      setState(() => _certs = c);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        title: const Text(
          'Certificate Monitoring',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
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
              child: _certs.isEmpty
                  ? const Center(
                      child: Text(
                        'No certificates found.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _certs.length,
                      itemBuilder: (_, i) => _certCard(_certs[i]),
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
    return Container(
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
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  c.studentName +
                      (c.rollNumber.isNotEmpty ? '  (${c.rollNumber})' : ''),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Text(
                c.eventDate.isEmpty ? '—' : c.eventDate,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          if (status == 'approved' && c.points > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.star_rate_rounded,
                  size: 14,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  '${c.points} points awarded',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          if (status == 'rejected' && c.mentorRemark.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Remark: ${c.mentorRemark}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (c.department.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              c.department,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
