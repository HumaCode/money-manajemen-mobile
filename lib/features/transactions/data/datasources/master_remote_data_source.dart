import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/constants/api_url.dart';
import 'package:money_manajemen/core/database/database_helper.dart';
import 'package:money_manajemen/features/auth/data/datasources/auth_local_data_source.dart';
import '../models/category_model.dart';
import '../models/account_model.dart';

abstract class MasterRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<List<AccountModel>> getAccounts();
  Future<List<CategoryModel>> getCachedCategories();
  Future<List<AccountModel>> getCachedAccounts();
  Future<bool> createTransaction(Map<String, dynamic> payload);
  Future<bool> updateTransaction(String id, Map<String, dynamic> payload);
}

class MasterRemoteDataSourceImpl implements MasterRemoteDataSource {
  final http.Client client;
  final AuthLocalDataSource localDataSource;

  MasterRemoteDataSourceImpl({
    required this.client,
    required this.localDataSource,
  });

  @override
  Future<List<CategoryModel>> getCachedCategories() async {
    return await DatabaseHelper.instance.getCategories();
  }

  @override
  Future<List<AccountModel>> getCachedAccounts() async {
    return await DatabaseHelper.instance.getAccounts();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final token = await localDataSource.getToken();
    final uri = Uri.parse(ApiUrl.categories);

    try {
      final response = await client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${token ?? ''}',
              'X-App-Key': ApiUrl.appKey,
              'x-api-key': ApiUrl.appKey,
            },
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseJson = jsonDecode(response.body);

      if (response.statusCode == 200 && responseJson['data'] != null) {
        dynamic rawList = responseJson['data'];
        if (rawList is Map && rawList['data'] is List) {
          rawList = rawList['data'];
        }
        if (rawList is List) {
          final categories = rawList
              .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
              .toList();
          if (categories.isNotEmpty) {
            await DatabaseHelper.instance.insertOrUpdateCategories(categories);
          }
          return categories;
        }
      }
      return getCachedCategories();
    } catch (_) {
      return getCachedCategories();
    }
  }

  @override
  Future<List<AccountModel>> getAccounts() async {
    final token = await localDataSource.getToken();
    final uri = Uri.parse(ApiUrl.accounts);

    try {
      final response = await client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${token ?? ''}',
              'X-App-Key': ApiUrl.appKey,
              'x-api-key': ApiUrl.appKey,
            },
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseJson = jsonDecode(response.body);

      if (response.statusCode == 200 && responseJson['data'] != null) {
        dynamic rawList = responseJson['data'];
        if (rawList is Map && rawList['data'] is List) {
          rawList = rawList['data'];
        }
        if (rawList is List) {
          final accounts = rawList
              .map((item) => AccountModel.fromJson(item as Map<String, dynamic>))
              .toList();
          if (accounts.isNotEmpty) {
            await DatabaseHelper.instance.insertOrUpdateAccounts(accounts);
          }
          return accounts;
        }
      }
      return getCachedAccounts();
    } catch (_) {
      return getCachedAccounts();
    }
  }

  @override
  Future<bool> createTransaction(Map<String, dynamic> payload) async {
    final token = await localDataSource.getToken();
    final uri = Uri.parse(ApiUrl.transactions);

    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${token ?? ''}',
              'X-App-Key': ApiUrl.appKey,
              'x-api-key': ApiUrl.appKey,
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && responseJson['success'] == true) {
        return true;
      } else {
        String msg = responseJson['message'] ?? 'Gagal membuat transaksi';
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
        throw Exception('Gagal terhubung ke server');
      }
      rethrow;
    }
  }

  @override
  Future<bool> updateTransaction(String id, Map<String, dynamic> payload) async {
    final token = await localDataSource.getToken();
    final uri = Uri.parse('${ApiUrl.transactions}/$id');

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
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && responseJson['success'] == true) {
        return true;
      } else {
        String msg = responseJson['message'] ?? 'Gagal memperbarui transaksi';
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
        throw Exception('Gagal terhubung ke server');
      }
      rethrow;
    }
  }
}
