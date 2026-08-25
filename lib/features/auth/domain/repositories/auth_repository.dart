import 'package:money_manajemen/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login({
    required String login,
    required String password,
  });

  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> logout();
}
