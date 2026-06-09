import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_service.dart';
import '../shared/models/clan_model.dart';

class ClanRepository {
  final _ctrl = StreamController<void>.broadcast();
  final _msgCtrls = <String, StreamController<void>>{};

  void _notify() { if (!_ctrl.isClosed) _ctrl.add(null); }
  void _notifyMessages(String clanId) {
    _msgCtrls[clanId]?.add(null);
    _notify(); // also update clan list (lastMessage changes)
  }

  StreamController<void> _msgCtrl(String clanId) =>
      _msgCtrls.putIfAbsent(clanId, () => StreamController<void>.broadcast());

  // ── Clans ─────────────────────────────────────────────────────────────────

  Stream<List<ClanModel>> watchUserClans(String userId) =>
      Rx.merge([Stream.value(null), _ctrl.stream]).asyncMap((_) async {
        final db = await DatabaseService.instance.database;
        final memberRows = await db.query('clan_members',
            columns: ['clanId'], where: 'userId = ?', whereArgs: [userId]);
        if (memberRows.isEmpty) return <ClanModel>[];
        final ids = memberRows.map((r) => r['clanId'] as String).toList();
        final placeholders = List.filled(ids.length, '?').join(',');
        final clanRows = await db.query(
          'clans',
          where: 'id IN ($placeholders)',
          whereArgs: ids,
          orderBy: 'updatedAt DESC',
        );
        return clanRows.map((r) => ClanModel.fromMap(r, r['id'] as String)).toList();
      });

  Stream<List<ClanModel>> watchAllClans() =>
      Rx.merge([Stream.value(null), _ctrl.stream]).asyncMap((_) async {
        final db = await DatabaseService.instance.database;
        final rows = await db.query('clans', orderBy: 'updatedAt DESC');
        return rows.map((r) => ClanModel.fromMap(r, r['id'] as String)).toList();
      });

  Future<ClanModel?> getClan(String clanId) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('clans', where: 'id = ?', whereArgs: [clanId]);
    if (rows.isEmpty) return null;
    return ClanModel.fromMap(rows.first, clanId);
  }

  Future<String> createClan({
    required String name,
    required String description,
    required String category,
    required String ownerId,
  }) async {
    final db = await DatabaseService.instance.database;
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('clans', {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'ownerId': ownerId,
      'memberCount': 1,
      'lastMessage': 'Clan created',
      'color': 0xFFCC2027,
      'updatedAt': now,
      'createdAt': now,
    });

    await db.insert('clan_members', {
      'id': '${id}_$ownerId',
      'clanId': id,
      'userId': ownerId,
      'joinedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    _notify();
    return id;
  }

  Future<void> joinClan({required String clanId, required String userId}) async {
    final db = await DatabaseService.instance.database;
    final existing = await db.query('clan_members',
        where: 'clanId = ? AND userId = ?', whereArgs: [clanId, userId]);
    if (existing.isNotEmpty) return;

    await db.insert('clan_members', {
      'id': '${clanId}_$userId',
      'clanId': clanId,
      'userId': userId,
      'joinedAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.rawUpdate(
      'UPDATE clans SET memberCount = memberCount + 1 WHERE id = ?',
      [clanId],
    );
    _notify();
  }

  Future<void> leaveClan({required String clanId, required String userId}) async {
    final db = await DatabaseService.instance.database;
    final count = await db.delete('clan_members',
        where: 'clanId = ? AND userId = ?', whereArgs: [clanId, userId]);

    if (count > 0) {
      await db.rawUpdate(
        'UPDATE clans SET memberCount = MAX(0, memberCount - 1) WHERE id = ?',
        [clanId],
      );
      _notify();
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Stream<List<ClanMessage>> watchMessages(String clanId, String currentUserId) =>
      Rx.merge([Stream.value(null), _msgCtrl(clanId).stream]).asyncMap((_) async {
        final db = await DatabaseService.instance.database;
        final rows = await db.query('clan_messages',
            where: 'clanId = ?', whereArgs: [clanId], orderBy: 'createdAt ASC');
        return rows
            .map((r) => ClanMessage.fromMap(r, r['id'] as String, currentUserId))
            .toList();
      });

  Future<void> sendMessage({
    required String clanId,
    required String senderId,
    required String senderName,
    required String content,
    String? imageUrl,
  }) async {
    final db = await DatabaseService.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = const Uuid().v4();

    await db.insert('clan_messages', {
      'id': id,
      'clanId': clanId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'imageUrl': imageUrl,
      'emoji': null,
      'createdAt': now,
    });

    await db.update(
      'clans',
      {
        'lastMessage': imageUrl != null ? '📷 Photo' : content,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [clanId],
    );

    _notifyMessages(clanId);
  }
}
