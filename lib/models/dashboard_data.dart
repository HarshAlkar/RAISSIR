class StudentProfile {
  final String name;
  final String studentId;
  final String avatar;
  final String email;
  final String department;

  StudentProfile({
    required this.name,
    required this.studentId,
    required this.avatar,
    required this.email,
    required this.department,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      name: json['name'] ?? '',
      studentId:
          json['roll_number']?.toString() ??
          json['studentId']?.toString() ??
          '',
      avatar: json['avatar'] ?? 'https://i.pravatar.cc/150?img=11',
      email: json['email'] ?? '',
      department: json['department'] ?? '',
    );
  }
}

class DashboardStats {
  final int totalUploaded;
  final int approved;
  final int pending;
  final int credits;

  DashboardStats({
    required this.totalUploaded,
    required this.approved,
    required this.pending,
    required this.credits,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUploaded:
          _parseInt(json['totalUploaded'] ?? json['total_uploaded'] ?? json['total']),
      approved: _parseInt(json['approved'] ?? json['approved_count']),
      pending: _parseInt(json['pending'] ?? json['pending_count']),
      credits: _parseInt(json['credits'] ?? json['total_credits']),
    );
  }
}

class Certificate {
  final String eventName;
  final String organizingInstitute;
  final String eventDate;
  final String participationType;
  final String status;

  Certificate({
    required this.eventName,
    required this.organizingInstitute,
    required this.eventDate,
    required this.participationType,
    required this.status,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      eventName: json['eventName'] ?? '',
      organizingInstitute: json['organizingInstitute'] ?? '',
      eventDate: json['eventDate'] ?? '',
      participationType: json['participationType'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
