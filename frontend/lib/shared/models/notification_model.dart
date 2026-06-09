enum NotificationType { eventReminder, clanAnnouncement, teamInvitation, newMessage, newOpportunity }

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String? referenceId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.referenceId,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == (map['type'] as String?),
        orElse: () => NotificationType.newMessage,
      ),
      isRead: (map['isRead'] as int? ?? 0) == 1,
      referenceId: map['referenceId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'body': body,
    'type': type.name,
    'isRead': isRead ? 1 : 0,
    'referenceId': referenceId,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}
