import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_service.dart';
import '../shared/models/notification_model.dart';

class NotificationRepository {
  final _ctrl = StreamController<void>.broadcast();
  void _notify() { if (!_ctrl.isClosed) _ctrl.add(null); }

  Stream<List<NotificationModel>> watchUserNotifications(String userId) =>
      Rx.merge([Stream.value(null), _ctrl.stream]).asyncMap((_) async {
        final db = await DatabaseService.instance.database;
        final rows = await db.query('notifications',
            where: 'userId = ?',
            whereArgs: [userId],
            orderBy: 'createdAt DESC');
        return rows.map((r) => NotificationModel.fromMap(r, r['id'] as String)).toList();
      });

  Future<int> unreadCount(String userId) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('notifications',
        where: 'userId = ? AND isRead = 0', whereArgs: [userId]);
    return rows.length;
  }

  Future<void> markAsRead(String notificationId) async {
    final db = await DatabaseService.instance.database;
    await db.update('notifications', {'isRead': 1},
        where: 'id = ?', whereArgs: [notificationId]);
    _notify();
  }

  Future<void> markAllRead(String userId) async {
    final db = await DatabaseService.instance.database;
    await db.update('notifications', {'isRead': 1},
        where: 'userId = ?', whereArgs: [userId]);
    _notify();
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? referenceId,
  }) async {
    final db = await DatabaseService.instance.database;
    final id = const Uuid().v4();
    await db.insert('notifications', {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': 0,
      'referenceId': referenceId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    _notify();
  }
}
