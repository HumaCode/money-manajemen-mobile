import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/datasources/auth_remote_data_source.dart';
import 'package:money_manajemen/data/models/user_model.dart';
import 'package:money_manajemen/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<UserModel> login({
    required String login,
    required String password,
  }) async {
    final result = await remoteDataSource.login(login: login, password: password);
    if (result.data?.token != null && result.data!.token.isNotEmpty) {
      await localDataSource.saveToken(result.data!.token);
    }
    return result;
  }

  @override
  Future<void> saveToken(String token) async {
    await localDataSource.saveToken(token);
  }

  @override
  Future<String?> getToken() async {
    return await localDataSource.getToken();
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearToken();
  }
}
