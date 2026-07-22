import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyUsers     = 'users';
  static const _keyLoggedIn  = 'logged_in_user';

  static final AuthService instance = AuthService._();
  AuthService._();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<Map<String, dynamic>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUsers);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> _saveUsers(Map<String, dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsers, jsonEncode(users));
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = await _getUsers();
    final normalizedEmail = email.trim().toLowerCase();

    if (users.containsKey(normalizedEmail)) {
      return AuthResult.error('این ایمیل قبلاً ثبت شده');
    }

    users[normalizedEmail] = {
      'name': name.trim(),
      'email': normalizedEmail,
      'password': _hashPassword(password),
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _saveUsers(users);
    await _setLoggedIn(normalizedEmail);
    return AuthResult.success(users[normalizedEmail]);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final users = await _getUsers();
    final normalizedEmail = email.trim().toLowerCase();

    final user = users[normalizedEmail];
    if (user == null) {
      return AuthResult.error('ایمیل یا رمز عبور اشتباه است');
    }

    if (user['password'] != _hashPassword(password)) {
      return AuthResult.error('ایمیل یا رمز عبور اشتباه است');
    }

    await _setLoggedIn(normalizedEmail);
    return AuthResult.success(user);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyLoggedIn);
    if (email == null) return null;

    final users = await _getUsers();
    return users[email] as Map<String, dynamic>?;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLoggedIn) != null;
  }

  Future<void> _setLoggedIn(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLoggedIn, email);
  }
}

class AuthResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? user;

  AuthResult._({required this.success, this.error, this.user});

  factory AuthResult.success(Map<String, dynamic> user) =>
      AuthResult._(success: true, user: user);

  factory AuthResult.error(String message) =>
      AuthResult._(success: false, error: message);
}