class ClanMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final String? emoji;
  final String? imageUrl;

  const ClanMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isMe = false,
    this.emoji,
    this.imageUrl,
  });

  factory ClanMessage.fromMap(Map<String, dynamic> map, String id, String currentUserId) {
    return ClanMessage(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      content: map['content'] as String? ?? map['message'] as String? ?? '',
      timestamp: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      isMe: (map['senderId'] as String?) == currentUserId,
      emoji: map['emoji'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'emoji': emoji,
    'imageUrl': imageUrl,
    'createdAt': timestamp.millisecondsSinceEpoch,
  };
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
  final String? description;
  final String? ownerId;
  final String? category;
  final String? imageUrl;

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
    this.description,
    this.ownerId,
    this.category,
    this.imageUrl,
  });

  factory ClanModel.fromMap(Map<String, dynamic> map, String id) {
    final name = map['name'] as String? ?? '';
    final words = name.trim().split(' ');
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();

    return ClanModel(
      id: id,
      name: name,
      initials: initials,
      color: (map['color'] as int?) ?? 0xFFCC2027,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTime: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
      memberCount: (map['memberCount'] as int?) ?? 0,
      description: map['description'] as String?,
      ownerId: map['ownerId'] as String?,
      category: map['category'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'name': name,
      'description': description,
      'category': category,
      'ownerId': ownerId,
      'memberCount': memberCount,
      'lastMessage': lastMessage,
      'color': color,
      'imageUrl': imageUrl,
      'updatedAt': now,
      'createdAt': now,
    };
  }

  ClanModel copyWith({
    List<ClanMessage>? messages,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    int? memberCount,
  }) {
    return ClanModel(
      id: id,
      name: name,
      initials: initials,
      color: color,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      memberCount: memberCount ?? this.memberCount,
      messages: messages ?? this.messages,
      description: description,
      ownerId: ownerId,
      category: category,
      imageUrl: imageUrl,
    );
  }
}
