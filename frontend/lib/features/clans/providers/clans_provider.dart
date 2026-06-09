import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/clan_repository.dart';
import '../../../shared/models/clan_model.dart';
import '../../auth/providers/auth_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final clanRepositoryProvider =
    Provider<ClanRepository>((ref) => ClanRepository());

// ── User's clans (live stream) ────────────────────────────────────────────────

final userClansProvider = StreamProvider<List<ClanModel>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return const Stream.empty();
  return ref.watch(clanRepositoryProvider).watchUserClans(userId);
});

// ── Messages for a specific clan (live stream) ────────────────────────────────

final clanMessagesProvider =
    StreamProvider.family<List<ClanMessage>, String>((ref, clanId) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return ref.watch(clanRepositoryProvider).watchMessages(clanId, userId);
});

// ── Single clan (from user's list or direct DB fetch) ─────────────────────────

final selectedClanProvider =
    Provider.family<ClanModel?, String>((ref, clanId) {
  return ref.watch(userClansProvider).whenData((clans) {
    try {
      return clans.firstWhere((c) => c.id == clanId);
    } catch (_) {
      return null;
    }
  }).valueOrNull;
});

// ── Chat actions ──────────────────────────────────────────────────────────────

class ClanChatNotifier extends StateNotifier<AsyncValue<void>> {
  ClanChatNotifier(this._repo) : super(const AsyncData(null));
  final ClanRepository _repo;

  Future<void> send({
    required String clanId,
    required String senderId,
    required String senderName,
    required String content,
    String? imageUrl,
  }) async {
    try {
      await _repo.sendMessage(
        clanId: clanId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        imageUrl: imageUrl,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> joinClan({required String clanId, required String userId}) async {
    state = const AsyncLoading();
    try {
      await _repo.joinClan(clanId: clanId, userId: userId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> leaveClan({required String clanId, required String userId}) async {
    state = const AsyncLoading();
    try {
      await _repo.leaveClan(clanId: clanId, userId: userId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final clanActionsProvider =
    StateNotifierProvider<ClanChatNotifier, AsyncValue<void>>(
  (ref) => ClanChatNotifier(ref.read(clanRepositoryProvider)),
);
