import '../shared/models/user_model.dart';
import '../services/auth_service.dart';
import '../core/database/database_service.dart';

class AuthRepository {
  Future<String?> getCurrentUserId() => AuthService.getCurrentUserId();

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) => AuthService.register(name: name, email: email, password: password);

  Future<UserModel> signIn({required String email, required String password}) =>
      AuthService.signIn(email: email, password: password);

  Future<void> signOut() async {
    await AuthService.signOut();
    // onboardingCompleted lives in the DB — do NOT clear it here
  }

  Future<UserModel?> loadCurrentUser() => AuthService.loadCurrentUser();

  Future<bool> hasCompletedOnboarding() async {
    final userId = await AuthService.getCurrentUserId();
    if (userId == null) return false;
    final db = await DatabaseService.instance.database;
    final rows = await db.query('users',
        columns: ['onboardingCompleted'],
        where: 'id = ?',
        whereArgs: [userId]);
    if (rows.isEmpty) return false;
    return (rows.first['onboardingCompleted'] as int? ?? 0) == 1;
  }

  Future<void> completeOnboarding({
    required String userId,
    required String degreeProgram,
    required List<String> skills,
    required List<String> interests,
  }) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'users',
      {
        'degreeProgram': degreeProgram,
        'skills': DatabaseService.encodeList(skills),
        'interests': DatabaseService.encodeList(interests),
        'onboardingCompleted': 1,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    // Auto-join new users to the default clans so "My Clans" is pre-populated
    final now = DateTime.now().millisecondsSinceEpoch;
    const defaultClanIds = ['clan_tech', 'clan_design', 'clan_biz', 'clan_data'];
    for (final clanId in defaultClanIds) {
      final existing = await db.query('clan_members',
          where: 'clanId = ? AND userId = ?', whereArgs: [clanId, userId]);
      if (existing.isEmpty) {
        await db.insert('clan_members', {
          'id': '${clanId}_$userId',
          'clanId': clanId,
          'userId': userId,
          'joinedAt': now,
        });
        await db.rawUpdate(
            'UPDATE clans SET memberCount = memberCount + 1 WHERE id = ?',
            [clanId]);
      }
    }
  }
}
