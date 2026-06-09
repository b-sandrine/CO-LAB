import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_service.dart';
import '../shared/models/opportunity_model.dart';

class OpportunityRepository {
  final _ctrl = StreamController<void>.broadcast();
  void _notify() { if (!_ctrl.isClosed) _ctrl.add(null); }

  Future<List<OpportunityModel>> _fetchAll() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('opportunities', orderBy: 'createdAt DESC');
    return rows.map((r) => OpportunityModel.fromMap(r, r['id'] as String)).toList();
  }

  Future<List<String>> _fetchRegisteredIds(String userId) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('registrations',
        columns: ['eventId'], where: 'userId = ?', whereArgs: [userId]);
    return rows.map((r) => r['eventId'] as String).toList();
  }

  Stream<List<OpportunityModel>> watchAll() =>
      Rx.merge([Stream.value(null), _ctrl.stream]).asyncMap((_) => _fetchAll());

  Stream<List<OpportunityModel>> watchByType(String type) =>
      Rx.merge([Stream.value(null), _ctrl.stream]).asyncMap((_) async {
        final db = await DatabaseService.instance.database;
        final rows = await db.query('opportunities',
            where: 'type = ?', whereArgs: [type], orderBy: 'createdAt DESC');
        return rows.map((r) => OpportunityModel.fromMap(r, r['id'] as String)).toList();
      });

  Stream<List<String>> watchUserRegisteredIds(String userId) =>
      Rx.merge([Stream.value(null), _ctrl.stream])
          .asyncMap((_) => _fetchRegisteredIds(userId));

  Future<void> create(OpportunityModel opp) async {
    final db = await DatabaseService.instance.database;
    final id = opp.id.isEmpty ? const Uuid().v4() : opp.id;
    await db.insert('opportunities', {'id': id, ...opp.toMap()});
    _notify();
  }

  Future<void> delete(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('opportunities', where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  Future<void> rsvp({required String opportunityId, required String userId}) async {
    final db = await DatabaseService.instance.database;
    final existing = await db.query('registrations',
        where: 'eventId = ? AND userId = ?', whereArgs: [opportunityId, userId]);
    if (existing.isNotEmpty) return;

    await db.insert('registrations', {
      'id': '${opportunityId}_$userId',
      'eventId': opportunityId,
      'userId': userId,
      'status': 'confirmed',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    await db.rawUpdate(
      'UPDATE opportunities SET participantCount = participantCount + 1 WHERE id = ?',
      [opportunityId],
    );
    _notify();
  }

  Future<void> cancelRsvp({required String opportunityId, required String userId}) async {
    final db = await DatabaseService.instance.database;
    final count = await db.delete('registrations',
        where: 'eventId = ? AND userId = ?', whereArgs: [opportunityId, userId]);

    if (count > 0) {
      await db.rawUpdate(
        'UPDATE opportunities SET participantCount = MAX(0, participantCount - 1) WHERE id = ?',
        [opportunityId],
      );
      _notify();
    }
  }

  Future<bool> hasRegistered({required String opportunityId, required String userId}) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('registrations',
        where: 'eventId = ? AND userId = ?', whereArgs: [opportunityId, userId]);
    return rows.isNotEmpty;
  }
}
