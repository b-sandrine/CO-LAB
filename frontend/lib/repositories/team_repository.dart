import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_service.dart';
import '../shared/models/team_model.dart';
import '../shared/models/application_model.dart';

class TeamRepository {
  final _ctrl = StreamController<void>.broadcast();
  void _notify() { if (!_ctrl.isClosed) _ctrl.add(null); }

  Future<List<TeamModel>> _fetchAllOpen() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('projects',
        where: 'isOpen = 1', orderBy: 'createdAt DESC');
    final teams = <TeamModel>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final members = await _fetchMembers(id);
      teams.add(TeamModel.fromMap(row, id).copyWith(members: members));
    }
    return teams;
  }

  Future<List<TeamMember>> _fetchMembers(String projectId) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('project_members',
        where: 'projectId = ?', whereArgs: [projectId]);
    return rows.map((r) => TeamMember.fromMap(r, r['userId'] as String)).toList();
  }

  Stream<List<TeamModel>> watchAll() =>
      Rx.merge([Stream.value(null), _ctrl.stream]).asyncMap((_) => _fetchAllOpen());

  Future<TeamModel?> getById(String id) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final members = await _fetchMembers(id);
    return TeamModel.fromMap(rows.first, id).copyWith(members: members);
  }

  Future<String> create(TeamModel team) async {
    final db = await DatabaseService.instance.database;
    final id = const Uuid().v4();
    await db.insert('projects', {'id': id, ...team.toMap()});

    // Auto-join owner as Team Lead
    if (team.ownerId != null) {
      final userRows = await db.query('users',
          where: 'id = ?', whereArgs: [team.ownerId]);
      final ownerName = userRows.isNotEmpty
          ? (userRows.first['fullName'] as String? ?? '')
          : '';
      final initial = ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?';
      await db.insert('project_members', {
        'id': '${id}_${team.ownerId}',
        'projectId': id,
        'userId': team.ownerId,
        'name': ownerName,
        'initial': initial,
        'role': 'Team Lead',
        'degreeProgram': '',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    _notify();
    return id;
  }

  // ── Applications ──────────────────────────────────────────────────────────

  Future<void> apply(ApplicationModel application) async {
    final db = await DatabaseService.instance.database;
    final id = '${application.projectId}_${application.applicantId}';
    await db.insert(
      'project_applications',
      {'id': id, ...application.toMap()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notify();
  }

  Stream<List<ApplicationModel>> watchApplications(String projectId) =>
      Rx.merge([Stream.value(null), _ctrl.stream]).asyncMap((_) async {
        final db = await DatabaseService.instance.database;
        final rows = await db.query('project_applications',
            where: 'projectId = ?', whereArgs: [projectId]);
        return rows.map((r) => ApplicationModel.fromMap(r, r['id'] as String)).toList();
      });

  Future<bool> hasApplied({required String projectId, required String userId}) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('project_applications',
        where: 'projectId = ? AND applicantId = ?', whereArgs: [projectId, userId]);
    return rows.isNotEmpty;
  }

  Future<void> approveApplication(ApplicationModel app) async {
    final db = await DatabaseService.instance.database;

    // Update application status
    await db.update(
      'project_applications',
      {'status': ApplicationStatus.approved.name},
      where: 'id = ?',
      whereArgs: [app.id],
    );

    // Fetch user details for member record
    final userRows = await db.query('users',
        where: 'id = ?', whereArgs: [app.applicantId]);
    final name = userRows.isNotEmpty
        ? (userRows.first['fullName'] as String? ?? app.applicantName)
        : app.applicantName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final degree = userRows.isNotEmpty
        ? (userRows.first['degreeProgram'] as String? ?? '')
        : '';

    // Add to project_members
    await db.insert('project_members', {
      'id': '${app.projectId}_${app.applicantId}',
      'projectId': app.projectId,
      'userId': app.applicantId,
      'name': name,
      'initial': initial,
      'role': app.selectedRole,
      'degreeProgram': degree,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Update user's joinedTeamIds
    if (userRows.isNotEmpty) {
      final existing = DatabaseService.decodeStringList(userRows.first['joinedTeamIds']);
      if (!existing.contains(app.projectId)) {
        existing.add(app.projectId);
        await db.update(
          'users',
          {'joinedTeamIds': DatabaseService.encodeList(existing)},
          where: 'id = ?',
          whereArgs: [app.applicantId],
        );
      }
    }

    // Bump memberCount
    await db.rawUpdate(
      'UPDATE projects SET memberCount = memberCount + 1 WHERE id = ?',
      [app.projectId],
    );

    _notify();
  }

  Future<void> rejectApplication(String applicationId) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'project_applications',
      {'status': ApplicationStatus.rejected.name},
      where: 'id = ?',
      whereArgs: [applicationId],
    );
    _notify();
  }
}
