class MyCertificate {
  final int id;
  final String eventName;
  final String organizingInstitute;
  final String eventDate;
  final String certificateType;
  final String? certificateFile;
  final String status;
  final int points;
  final String? mentorRemark;

  MyCertificate({
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

  factory MyCertificate.fromJson(Map<String, dynamic> json) {
    return MyCertificate(
      id: _parseInt(json['id']),
      eventName: json['event_name'] ?? '',
      organizingInstitute: json['organizing_institute'] ?? '',
      eventDate: json['event_date'] ?? '',
      certificateType: json['certificate_type'] ?? '',
      certificateFile: json['certificate_file'],
      status: json['status'] ?? 'pending',
      points: _parseInt(json['points']),
      mentorRemark: json['mentor_remark'],
    );
  }
}
