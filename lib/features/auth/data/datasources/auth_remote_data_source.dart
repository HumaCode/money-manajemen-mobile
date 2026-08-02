import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/constants/api_url.dart';
import 'package:money_manajemen/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String login,
    required String password,
  });
  Future<UserDetail> getProfile();
  Future<UserDetail> updateProfile({
    required String name,
    required String username,
    required String email,
    String? phone,
    String? gender,
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

    try {
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Key': ApiUrl.appKey,
          'x-api-key': ApiUrl.appKey,
        },
        body: jsonEncode({
          'login': login,
          'password': password,
          'device_name': 'android_phone',
        }),
      ).timeout(const Duration(seconds: 30));

      final Map<String, dynamic> responseJson = jsonDecode(response.body);

      if (response.statusCode == 200 && responseJson['success'] == true) {
        final userModel = UserModel.fromJson(responseJson);
        if (userModel.data?.user != null) {
          await AuthLocalDataSourceImpl().saveUser(userModel.data!.user);
        }
        return userModel;
      } else {
        final errorMessage = responseJson['message'] ?? 'Login gagal (${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Respon server tidak valid');
      }
      if (e is TimeoutException) {
        throw Exception('Koneksi ke server timeout. Periksa koneksi internet Anda.');
      }
      if (e is SocketException || e is http.ClientException) {
        throw Exception('Gagal terhubung ke server. Periksa koneksi jaringan Anda.');
      }
      rethrow;
    }
  }

  @override
  Future<UserDetail> getProfile() async {
    final token = await AuthLocalDataSourceImpl().getToken();
    final uri = Uri.parse(ApiUrl.me);

    try {
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
          'X-App-Key': ApiUrl.appKey,
          'x-api-key': ApiUrl.appKey,
        },
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseJson = jsonDecode(response.body);

      if (response.statusCode == 200 && responseJson['data'] != null) {
        final user = UserDetail.fromJson(responseJson['data'] as Map<String, dynamic>);
        await AuthLocalDataSourceImpl().saveUser(user);
        return user;
      } else {
        final errorMessage = responseJson['message'] ?? 'Gagal mengambil profil';
        throw Exception(errorMessage);
      }
    } catch (e) {
      final localUser = await AuthLocalDataSourceImpl().getUser();
      if (localUser != null) {
        return localUser;
      }
      rethrow;
    }
  }

  @override
  Future<UserDetail> updateProfile({
    required String name,
    required String username,
    required String email,
    String? phone,
    String? gender,
  }) async {
    final token = await AuthLocalDataSourceImpl().getToken();
    final uri = Uri.parse(ApiUrl.updateProfile);

    final currentUser = await AuthLocalDataSourceImpl().getUser();
    final fallbackUser = UserDetail(
      id: currentUser?.id ?? '1',
      name: name,
      username: username,
      email: email,
      phone: phone,
      gender: gender ?? currentUser?.gender,
      avatar: currentUser?.avatar,
      preference: currentUser?.preference,
    );

    try {
      final response = await client
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${token ?? ''}',
              'X-App-Key': ApiUrl.appKey,
              'x-api-key': ApiUrl.appKey,
            },
            body: jsonEncode({
              'name': name,
              'username': username,
              'email': email,
              'phone': phone,
              'gender': gender,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> responseJson = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && responseJson['data'] != null) {
        final user = UserDetail.fromJson(responseJson['data'] as Map<String, dynamic>);
        await AuthLocalDataSourceImpl().saveUser(user);
        return user;
      } else {
        String msg = responseJson['message'] ?? 'Gagal memperbarui profil (${response.statusCode})';
        if (responseJson['errors'] is Map && (responseJson['errors'] as Map).isNotEmpty) {
          final errorsMap = responseJson['errors'] as Map<String, dynamic>;
          final firstErrorList = errorsMap.values.first;
          if (firstErrorList is List && firstErrorList.isNotEmpty) {
            msg = firstErrorList.first.toString();
          }
        }
        throw Exception(msg);
      }
    } catch (e) {
      if (e is SocketException || e is http.ClientException || e is TimeoutException) {
        await AuthLocalDataSourceImpl().saveUser(fallbackUser);
        return fallbackUser;
      }
      rethrow;
    }
  }
}
