import 'package:flutter/material.dart';
import '../../models/mentor_models.dart';
import '../../services/mentor_api_service.dart';
import 'review_certificate_screen.dart';

class StudentCertificatesScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const StudentCertificatesScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentCertificatesScreen> createState() =>
      _StudentCertificatesScreenState();
}

class _StudentCertificatesScreenState extends State<StudentCertificatesScreen> {
  final MentorApiService _api = MentorApiService();

  bool _loading = true;
  String? _error;
  List<MentorStudentCertificate> _certs = [];

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
      final certs = await _api.fetchStudentCertificates(widget.studentId);
      if (!mounted) return;
      setState(() => _certs = certs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusBg(String status) {
    final s = status.toLowerCase();
    if (s == 'approved') return const Color(0xFFDCFCE7);
    if (s == 'rejected') return const Color(0xFFFEE2E2);
    return const Color(0xFFFEF3C7);
  }

  Color _statusText(String status) {
    final s = status.toLowerCase();
    if (s == 'approved') return const Color(0xFF16A34A);
    if (s == 'rejected') return const Color(0xFFDC2626);
    return const Color(0xFFD97706);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FE),
      appBar: AppBar(title: Text(widget.studentName)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF5145FF)),
              )
            : (_error != null)
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              )
            : (_certs.isEmpty)
            ? const Center(
                child: Text(
                  'No certificates uploaded yet.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _certs.length,
                itemBuilder: (context, i) {
                  final c = _certs[i];
                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReviewCertificateScreen(certificateId: c.id),
                        ),
                      );
                      if (result == true) {
                        _load();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.eventName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusBg(c.status),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  c.status.toUpperCase(),
                                  style: TextStyle(
                                    color: _statusText(c.status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.organizingInstitute,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.eventDate,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (c.status.toLowerCase() == 'approved') ...[
                            const SizedBox(height: 10),
                            Text(
                              'Points: ${c.points}',
                              style: const TextStyle(
                                color: Color(0xFF5145FF),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                          if (c.status.toLowerCase() == 'rejected' &&
                              (c.mentorRemark ?? '').isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Remark: ${c.mentorRemark}',
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
