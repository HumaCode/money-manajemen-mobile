import 'package:money_manajemen/features/auth/data/models/user_model.dart';
import 'package:money_manajemen/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserModel> execute({
    required String login,
    required String password,
  }) async {
    return await repository.login(login: login, password: password);
  }
}
