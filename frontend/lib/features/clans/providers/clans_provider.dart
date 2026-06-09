import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/clan_model.dart';
import '../../../shared/models/mock_data.dart';

class ClansNotifier extends StateNotifier<List<ClanModel>> {
  ClansNotifier() : super(MockData.clans);

  void sendMessage(String clanId, String content) {
    state = state.map((clan) {
      if (clan.id != clanId) return clan;
      final newMsg = ClanMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'user_001',
        senderName: 'Me',
        content: content,
        timestamp: DateTime.now(),
        isMe: true,
      );
      return ClanModel(
        id: clan.id,
        name: clan.name,
        initials: clan.initials,
        color: clan.color,
        lastMessage: content,
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        memberCount: clan.memberCount,
        messages: [...clan.messages, newMsg],
      );
    }).toList();
  }
}

final clansProvider = StateNotifierProvider<ClansNotifier, List<ClanModel>>((ref) => ClansNotifier());

final selectedClanProvider = Provider.family<ClanModel?, String>((ref, id) {
  return ref.watch(clansProvider).firstWhere((c) => c.id == id, orElse: () => MockData.clans.first);
});
