import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/my_certificate.dart';
import '../../providers/dashboard_provider.dart';
import '../../config/api_config.dart';

class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({super.key});

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  int _currentIndex = 1;

  final List<String> _tabs = ['All', 'Approved', 'Pending', 'Rejected'];
  String _currentFilter = 'All';

  List<MyCertificate> _certificates = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchData();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _currentFilter = _tabs[_tabController.index];
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final certs = await _apiService.fetchMyCertificates(
        status: _currentFilter == 'All' ? null : _currentFilter.toLowerCase(),
      );
      setState(() {
        _certificates = certs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData iconData;
    String labelText;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        iconData = Icons.check_circle_outline;
        labelText = 'Approved';
        break;
      case 'rejected':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        iconData = Icons.cancel_outlined;
        labelText = 'Rejected';
        break;
      case 'pending':
      default:
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFEA580C);
        iconData = Icons.remove_circle_outline;
        labelText = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            labelText,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(MyCertificate cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    cert.eventName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                _buildStatusBadge(cert.status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Left Side
                Container(
                  width: 70,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    image: cert.certificateFile != null
                        ? DecorationImage(
                            image: NetworkImage(
                              "${ApiConfig.origin}/${cert.certificateFile!.replaceAll(r'\', '/')}",
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: cert.certificateFile == null
                      ? const Center(
                          child: Icon(
                            Icons.description,
                            color: Colors.blueGrey,
                            size: 30,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Certificate Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Institute:', cert.organizingInstitute),
                      _buildDetailRow('Date:', cert.eventDate),
                      _buildDetailRow('Type:', cert.certificateType),

                      const SizedBox(height: 12),

                      if (cert.status.toLowerCase() == 'approved')
                        Text(
                          'Points Earned: ${cert.points} Credits',
                          style: const TextStyle(
                            color: Color(0xFF5145FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),

                      if (cert.status.toLowerCase() == 'rejected' &&
                          cert.mentorRemark != null)
                        Text(
                          'Remark: ${cert.mentorRemark}',
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Certificates',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF5145FF),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF5145FF),
              indicatorWeight: 3,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5145FF)),
            )
          : _errorMsg != null
          ? Center(child: Text('Error: \$_errorMsg'))
          : _certificates.isEmpty
          ? const Center(
              child: Text(
                'No certificates uploaded yet.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _certificates.length,
              itemBuilder: (context, index) {
                return _buildCertificateCard(_certificates[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            "/upload-certificate",
          );
          if (result == true) {
            await _fetchData();
            if (!mounted) return;
            await Provider.of<DashboardProvider>(
              context,
              listen: false,
            ).loadDashboardData();
          }
        },
        backgroundColor: const Color(0xFF5145FF),
        elevation: 4,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Dashboard', 0, _currentIndex == 0),
              _buildNavItem(
                Icons.military_tech_outlined,
                'Certificates',
                1,
                _currentIndex == 1,
              ),
              const SizedBox(width: 48),
              _buildNavItem(
                Icons.calendar_today_outlined,
                'Events',
                2,
                _currentIndex == 2,
              ),
              _buildNavItem(
                Icons.person_outline,
                'Profile',
                3,
                _currentIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isActive) {
    final color = isActive ? const Color(0xFF5145FF) : Colors.grey.shade500;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, '/my-certificates');
        } else if (index == 3) {
          Navigator.pushReplacementNamed(context, '/profile');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
