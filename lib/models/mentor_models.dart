class MentorProfile {
  final int id;
  final String name;
  final String email;
  final String department;
  final String employeeId;
  final String role;

  MentorProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.employeeId,
    required this.role,
  });

  factory MentorProfile.fromJson(Map<String, dynamic> json) {
    return MentorProfile(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      department: (json['department'] ?? '').toString(),
      employeeId: (json['employee_id'] ?? '').toString(),
      role: (json['role'] ?? 'mentor').toString(),
    );
  }
}

class MentorDashboardData {
  final String mentorName;
  final String department;
  final int students;
  final int pending;
  final int approved;
  final int rejected;

  MentorDashboardData({
    required this.mentorName,
    required this.department,
    required this.students,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory MentorDashboardData.fromJson(Map<String, dynamic> json) {
    return MentorDashboardData(
      mentorName: (json['mentor_name'] ?? json['mentorName'] ?? '').toString(),
      department: (json['department'] ?? '').toString(),
      students: _parseInt(json['students']),
      pending: _parseInt(json['pending']),
      approved: _parseInt(json['approved']),
      rejected: _parseInt(json['rejected']),
    );
  }
}

class MentorActivityItem {
  final String studentName;
  final String eventName;
  final String date;
  final String status;

  MentorActivityItem({
    required this.studentName,
    required this.eventName,
    required this.date,
    required this.status,
  });

  factory MentorActivityItem.fromJson(Map<String, dynamic> json) {
    return MentorActivityItem(
      studentName: (json['student_name'] ?? json['studentName'] ?? '')
          .toString(),
      eventName: (json['event_name'] ?? json['eventName'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class MentorVerificationStats {
  final int reviewed;
  final int approved;
  final int rejected;
  final int pending;
  final int progress; // percentage 0-100

  MentorVerificationStats({
    required this.reviewed,
    required this.approved,
    required this.rejected,
    required this.pending,
    required this.progress,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory MentorVerificationStats.fromJson(Map<String, dynamic> json) {
    return MentorVerificationStats(
      reviewed: _parseInt(json['reviewed']),
      approved: _parseInt(json['approved']),
      rejected: _parseInt(json['rejected']),
      pending: _parseInt(json['pending']),
      progress: _parseInt(json['progress']),
    );
  }
}

class MentorWeeklySummary {
  final String week;
  final int count;

  MentorWeeklySummary({required this.week, required this.count});

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory MentorWeeklySummary.fromJson(Map<String, dynamic> json) {
    return MentorWeeklySummary(
      week: (json['week'] ?? '').toString(),
      count: _parseInt(json['count']),
    );
  }
}

class MentorRecentDecision {
  final String studentName;
  final String eventName;
  final String status;
  final String? remark;

  MentorRecentDecision({
    required this.studentName,
    required this.eventName,
    required this.status,
    this.remark,
  });

  factory MentorRecentDecision.fromJson(Map<String, dynamic> json) {
    return MentorRecentDecision(
      studentName: (json['student_name'] ?? '').toString(),
      eventName: (json['event_name'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      remark: json['mentor_remark']?.toString(),
    );
  }
}

class MentorStudent {
  final int id;
  final String name;
  final String rollNumber;
  final String department;
  final int submitted;
  final int approved;
  final int pending;

  MentorStudent({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.department,
    required this.submitted,
    required this.approved,
    required this.pending,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory MentorStudent.fromJson(Map<String, dynamic> json) {
    return MentorStudent(
      id: _parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      rollNumber: (json['roll_number'] ?? '').toString(),
      department: (json['department'] ?? '').toString(),
      submitted: _parseInt(json['submitted']),
      approved: _parseInt(json['approved']),
      pending: _parseInt(json['pending']),
    );
  }
}

class MentorStudentCertificate {
  final int id;
  final String eventName;
  final String organizingInstitute;
  final String eventDate;
  final String certificateType;
  final String? certificateFile;
  final String status;
  final int points;
  final String? mentorRemark;

  MentorStudentCertificate({
    required this.id,
    required this.eventName,
    required this.organizingInstitute,
    required this.eventDate,
    required this.certificateType,
    this.certificateFile,
    required this.status,
    required this.points,
    this.mentorRemark,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory MentorStudentCertificate.fromJson(Map<String, dynamic> json) {
    return MentorStudentCertificate(
      id: _parseInt(json['id']),
      eventName: (json['event_name'] ?? '').toString(),
      organizingInstitute: (json['organizing_institute'] ?? '').toString(),
      eventDate: (json['event_date'] ?? '').toString(),
      certificateType: (json['certificate_type'] ?? '').toString(),
      certificateFile: json['certificate_file']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      points: _parseInt(json['points']),
      mentorRemark: json['mentor_remark']?.toString(),
    );
  }
}

class MentorReviewCertificate {
  final int id;
  final int studentId;
  final String studentName;
  final String rollNumber;
  final String eventName;
  final String issuer;
  final String date;
  final String category;
  final String type;
  final String? image;
  final String status;
  final int points;
  final String? mentorRemark;

  MentorReviewCertificate({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.eventName,
    required this.issuer,
    required this.date,
    required this.category,
    required this.type,
    this.image,
    required this.status,
    required this.points,
    this.mentorRemark,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory MentorReviewCertificate.fromJson(Map<String, dynamic> json) {
    return MentorReviewCertificate(
      id: _parseInt(json['id']),
      studentId: _parseInt(json['student_id']),
      studentName: (json['student_name'] ?? '').toString(),
      rollNumber: (json['roll_number'] ?? '').toString(),
      eventName: (json['event_name'] ?? '').toString(),
      issuer: (json['issuer'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      image: json['image']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      points: _parseInt(json['points']),
      mentorRemark: json['mentor_remark']?.toString(),
    );
  }
}
