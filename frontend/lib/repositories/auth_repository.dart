import 'package:shared_preferences/shared_preferences.dart';
import '../shared/models/user_model.dart';
import '../services/auth_service.dart';
import '../core/database/database_service.dart';

class AuthRepository {
  static const _keyHasOnboarded = 'has_onboarded';

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHasOnboarded);
  }

  Future<UserModel?> loadCurrentUser() => AuthService.loadCurrentUser();

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasOnboarded) ?? false;
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
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasOnboarded, true);
  }
}
