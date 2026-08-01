import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/constants/api_url.dart';
import 'package:money_manajemen/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String login,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> login({
    required String login,
    required String password,
  }) async {
    final uri = Uri.parse(ApiUrl.login);

    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Key': ApiUrl.appKey,
      },
      body: jsonEncode({
        'login': login,
        'password': password,
      }),
    );

    final Map<String, dynamic> responseJson = jsonDecode(response.body);

    if (response.statusCode == 200 && responseJson['success'] == true) {
      return UserModel.fromJson(responseJson);
    } else {
      final errorMessage = responseJson['message'] ?? 'Login gagal (${response.statusCode})';
      throw Exception(errorMessage);
    }
  }
}
