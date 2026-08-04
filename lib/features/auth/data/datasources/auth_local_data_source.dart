import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_manajemen/features/auth/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  Future<void> saveUser(UserDetail user);
  Future<UserDetail?> getUser();
  Future<void> saveBiometricToken(String token);
  Future<String?> getBiometricToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _tokenKey = 'AUTH_TOKEN';
  static const String _userKey = 'AUTH_USER';
  static const String _biometricTokenKey = 'BIOMETRIC_SAVED_TOKEN';

  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_biometricTokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<void> saveBiometricToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_biometricTokenKey, token);
  }

  @override
  Future<String?> getBiometricToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricTokenKey);
  }

  @override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  @override
  Future<void> saveUser(UserDetail user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<UserDetail?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_userKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return UserDetail.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      } catch (_) {}
    }
    return null;
  }
}
