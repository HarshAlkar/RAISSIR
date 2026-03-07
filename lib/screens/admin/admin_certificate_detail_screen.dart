import 'package:flutter/material.dart';
import '../../services/admin_api_service.dart';
import '../../config/api_config.dart';

class AdminCertificateDetailScreen extends StatefulWidget {
  final AdminCertificate certificate;

  const AdminCertificateDetailScreen({super.key, required this.certificate});

  @override
  State<AdminCertificateDetailScreen> createState() =>
      _AdminCertificateDetailScreenState();
}

class _AdminCertificateDetailScreenState
    extends State<AdminCertificateDetailScreen> {
  static const Color _primary = Color(0xFF5145FF);
  bool _imageError = false;

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

  IconData _statusIcon(String status) {
    if (status == 'approved') return Icons.check_circle_outline_rounded;
    if (status == 'rejected') return Icons.cancel_outlined;
    return Icons.hourglass_empty_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.certificate;
    final status = c.status.toLowerCase();
    final hasImage = c.certificateFile.isNotEmpty;
    final imageUrl = hasImage
        ? '${ApiConfig.uploadsBase}/certificates/${c.certificateFile}'
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FE),
      appBar: AppBar(
        title: const Text(
          'Certificate Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusBg(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(status),
                      size: 13,
                      color: _statusTxt(status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        color: _statusTxt(status),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Event Info Card ─────────────────────────────────────────────
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Event Information'),
                const SizedBox(height: 14),
                _detailRow(Icons.event_outlined, 'Event Name', c.eventName),
                _divider(),
                _detailRow(
                  Icons.business_outlined,
                  'Organizing Institute',
                  c.organizingInstitute,
                ),
                _divider(),
                _detailRow(
                  Icons.calendar_today_outlined,
                  'Event Date',
                  c.eventDate.isEmpty ? '—' : c.eventDate,
                ),
                _divider(),
                _detailRow(
                  Icons.workspace_premium_outlined,
                  'Certificate Type',
                  c.certificateType.isEmpty ? '—' : c.certificateType,
                ),
                _divider(),
                _detailRow(
                  Icons.people_outline,
                  'Participation Type',
                  c.participationType.isEmpty ? '—' : c.participationType,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Student Info Card ───────────────────────────────────────────
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Student Information'),
                const SizedBox(height: 14),
                _detailRow(Icons.person_outline, 'Student Name', c.studentName),
                if (c.rollNumber.isNotEmpty) ...[
                  _divider(),
                  _detailRow(Icons.badge_outlined, 'Roll Number', c.rollNumber),
                ],
                if (c.department.isNotEmpty) ...[
                  _divider(),
                  _detailRow(
                    Icons.business_outlined,
                    'Department',
                    c.department,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Review Info Card ────────────────────────────────────────────
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Review Information'),
                const SizedBox(height: 14),
                // Status badge row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _statusBg(status),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _statusIcon(status),
                        size: 18,
                        color: _statusTxt(status),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Approval Status',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _statusTxt(status),
                          ),
                        ),
                      ],
                    ),
                    if (status == 'approved' && c.points > 0) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rate_rounded,
                              size: 15,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${c.points} pts',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (status == 'rejected' && c.mentorRemark.isNotEmpty) ...[
                  _divider(),
                  _detailRow(
                    Icons.comment_outlined,
                    'Mentor Remark',
                    c.mentorRemark,
                    valueColor: const Color(0xFFDC2626),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Certificate Image ───────────────────────────────────────────
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Certificate Image'),
                const SizedBox(height: 14),
                if (!hasImage || _imageError)
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: Color(0xFFCBD5E1),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No image available',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) {
                              return child;
                            }
                            return Container(
                              height: 200,
                              color: const Color(0xFFF8FAFC),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: _primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _imageError = true);
                            });
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                if (hasImage && !_imageError && imageUrl != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Tap image to view full size',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 20, color: Color(0xFFF1F5F9));
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
