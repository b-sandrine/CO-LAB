import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import '../core/database/database_service.dart';
import '../shared/models/user_model.dart';

class ProfileRepository {
  final _ctrl = StreamController<void>.broadcast();
  void _notify() { if (!_ctrl.isClosed) _ctrl.add(null); }

  Stream<UserModel?> watchUser(String userId) =>
      Rx.merge([Stream.value(null), _ctrl.stream]).asyncMap((_) => getUser(userId));

  Future<UserModel?> getUser(String userId) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first, userId);
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? bio,
    String? degreeProgram,
    List<String>? skills,
    List<String>? interests,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['fullName'] = name;
    if (bio != null) data['bio'] = bio;
    if (degreeProgram != null) data['degreeProgram'] = degreeProgram;
    if (skills != null) data['skills'] = DatabaseService.encodeList(skills);
    if (interests != null) data['interests'] = DatabaseService.encodeList(interests);
    if (data.isEmpty) return;

    final db = await DatabaseService.instance.database;
    await db.update('users', data, where: 'id = ?', whereArgs: [userId]);
    _notify();
  }

  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(dir.path, 'profile_photos', '$userId.jpg');
    await Directory(p.dirname(dest)).create(recursive: true);
    await imageFile.copy(dest);

    final db = await DatabaseService.instance.database;
    await db.update('users', {'photoUrl': dest},
        where: 'id = ?', whereArgs: [userId]);
    _notify();
    return dest;
  }

  Future<void> incrementLeadershipPoints(String userId, int points) async {
    final db = await DatabaseService.instance.database;
    await db.rawUpdate(
      'UPDATE users SET leadershipPoints = leadershipPoints + ? WHERE id = ?',
      [points, userId],
    );
    _notify();
  }

  Future<List<Map<String, dynamic>>> getUserRsvps(String userId) async {
    final db = await DatabaseService.instance.database;
    final regRows = await db.query('registrations',
        where: 'userId = ?', whereArgs: [userId]);

    final rsvps = <Map<String, dynamic>>[];
    for (final reg in regRows) {
      final eventId = reg['eventId'] as String;
      final oppRows = await db.query('opportunities',
          where: 'id = ?', whereArgs: [eventId]);
      if (oppRows.isNotEmpty) {
        rsvps.add({
          'id': eventId,
          'title': oppRows.first['title'],
          'date': oppRows.first['eventDate'], // int milliseconds
          'status': reg['status'],
        });
      }
    }
    return rsvps;
  }
}
