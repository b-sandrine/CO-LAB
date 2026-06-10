import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/notification_repository.dart';
import '../../../shared/models/notification_model.dart';
import '../../auth/providers/auth_provider.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepository());

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).watchUserNotifications(userId);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).whenData((list) {
    return list.where((n) => !n.isRead).length;
  }).valueOrNull ?? 0;
});

class NotificationActionsNotifier extends StateNotifier<AsyncValue<void>> {
  NotificationActionsNotifier(this._repo, this._ref) : super(const AsyncData(null));
  final NotificationRepository _repo;
  final Ref _ref;

  Future<void> markRead(String id) async {
    await _repo.markAsRead(id);
  }

  Future<void> markAllRead() async {
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    await _repo.markAllRead(userId);
  }
}

final notificationActionsProvider =
    StateNotifierProvider<NotificationActionsNotifier, AsyncValue<void>>(
  (ref) => NotificationActionsNotifier(
    ref.read(notificationRepositoryProvider),
    ref,
  ),
);
