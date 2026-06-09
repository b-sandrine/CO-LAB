enum RegistrationStatus { pending, confirmed, cancelled }

class RegistrationModel {
  final String id;
  final String eventId;
  final String userId;
  final RegistrationStatus status;
  final DateTime createdAt;

  const RegistrationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.createdAt,
  });

  factory RegistrationModel.fromMap(Map<String, dynamic> map, String id) {
    return RegistrationModel(
      id: id,
      eventId: map['eventId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      status: RegistrationStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String?),
        orElse: () => RegistrationStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'eventId': eventId,
    'userId': userId,
    'status': status.name,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}
