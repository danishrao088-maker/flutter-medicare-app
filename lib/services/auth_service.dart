import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/profile.dart';
import '../models/user.dart';

/// Result of an authentication attempt. `user` is non-null on success;
/// `error` is non-null on failure.
class AuthResult {
  final User? user;
  final String? error;
  const AuthResult.success(this.user) : error = null;
  const AuthResult.failure(this.error) : user = null;

  bool get isSuccess => user != null;
}

/// Handles registration, login, logout, and "remember me" persistence.
///
/// Passwords never touch disk in plain text. Each user has a unique
/// 128-bit salt; the stored value is `sha256(salt + password)` encoded
/// as base64. Salt is regenerated whenever the password changes.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kCurrentUserId = 'current_user_id';

  final _db = DatabaseHelper.instance;
  final _rng = Random.secure();

  // ===== Hashing =====
  String _generateSalt([int length = 16]) {
    final bytes = List<int>.generate(length, (_) => _rng.nextInt(256));
    return base64Encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(salt + password);
    return base64Encode(sha256.convert(bytes).bytes);
  }

  // ===== Public API =====
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existing = await _db.getUserByEmail(normalizedEmail);
    if (existing != null) {
      return const AuthResult.failure(
        'An account with this email already exists.',
      );
    }

    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);

    final newUser = User(
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: hash,
      salt: salt,
    );

    try {
      final id = await _db.insertUser(newUser);
      final created = newUser.copyWith(id: id);

      // Create a default "Self" profile for the new user so they can start
      // adding medicines immediately.
      await _db.insertProfile(
        Profile(
          name: created.name,
          relation: 'Self',
          age: 25,
          avatar: created.avatar,
          userId: id,
        ),
      );

      await _setCurrentUserId(id);
      return AuthResult.success(created);
    } catch (e) {
      return AuthResult.failure('Could not create account: $e');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final user = await _db.getUserByEmail(email.trim().toLowerCase());
    if (user == null) {
      return const AuthResult.failure('No account found with that email.');
    }
    final hash = _hashPassword(password, user.salt);
    if (hash != user.passwordHash) {
      return const AuthResult.failure('Incorrect password.');
    }
    if (rememberMe) {
      await _setCurrentUserId(user.id!);
    } else {
      await _clearCurrentUserId();
    }
    return AuthResult.success(user);
  }

  Future<void> logout() async => _clearCurrentUserId();

  Future<User?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kCurrentUserId);
    if (id == null) return null;
    return _db.getUserById(id);
  }

  Future<void> _setCurrentUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCurrentUserId, id);
  }

  Future<void> _clearCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentUserId);
  }
}
