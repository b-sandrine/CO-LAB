enum ApplicationStatus { pending, approved, rejected }

class ApplicationModel {
  final String id;
  final String projectId;
  final String applicantId;
  final String applicantName;
  final String selectedRole;
  final String message;
  final ApplicationStatus status;
  final DateTime createdAt;

  const ApplicationModel({
    required this.id,
    required this.projectId,
    required this.applicantId,
    required this.applicantName,
    required this.selectedRole,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    return ApplicationModel(
      id: id,
      projectId: map['projectId'] as String? ?? '',
      applicantId: map['applicantId'] as String? ?? '',
      applicantName: map['applicantName'] as String? ?? '',
      selectedRole: map['selectedRole'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String?),
        orElse: () => ApplicationStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'projectId': projectId,
    'applicantId': applicantId,
    'applicantName': applicantName,
    'selectedRole': selectedRole,
    'message': message,
    'status': status.name,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  ApplicationModel copyWith({ApplicationStatus? status}) => ApplicationModel(
    id: id,
    projectId: projectId,
    applicantId: applicantId,
    applicantName: applicantName,
    selectedRole: selectedRole,
    message: message,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}
