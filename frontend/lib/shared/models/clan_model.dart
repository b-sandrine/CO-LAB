class ClanMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final String? emoji;

  const ClanMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isMe = false,
    this.emoji,
  });
}

class ClanModel {
  final String id;
  final String name;
  final String initials;
  final int color;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final int memberCount;
  final List<ClanMessage> messages;

  const ClanModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.memberCount = 0,
    this.messages = const [],
  });
}
