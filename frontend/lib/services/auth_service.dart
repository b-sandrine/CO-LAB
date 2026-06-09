import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_service.dart';
import '../shared/models/user_model.dart';

class AuthService {
  AuthService._();

  static const _sessionKey = 'current_user_id';

  static String _hash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await DatabaseService.instance.database;
    final existing = await db.query('users',
        where: 'email = ?', whereArgs: [email.toLowerCase().trim()]);
    if (existing.isNotEmpty) {
      throw Exception('An account with this email already exists.');
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final user = UserModel(
      id: id,
      name: name.trim(),
      email: email.toLowerCase().trim(),
      degreeProgram: '',
      createdAt: now,
    );

    await db.insert('users', {
      'id': id,
      'passwordHash': _hash(password),
      ...user.toMap(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, id);
    return user;
  }

  static Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('users',
        where: 'email = ?', whereArgs: [email.toLowerCase().trim()]);
    if (rows.isEmpty) {
      throw Exception('No account found for this email.');
    }
    final row = rows.first;
    if (row['passwordHash'] != _hash(password)) {
      throw Exception('Incorrect password.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, row['id'] as String);
    return UserModel.fromMap(row, row['id'] as String);
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  static Future<UserModel?> loadCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;
    final db = await DatabaseService.instance.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first, userId);
  }
}
