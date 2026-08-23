import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/constants/api_url.dart';
import 'package:money_manajemen/core/database/database_helper.dart';
import 'package:money_manajemen/features/auth/data/datasources/auth_local_data_source.dart';
import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<DataTransaksi>> getTransactions({int maxRetries = 3});
  Future<List<TransactionModel>> getLocalTransactions();
  Future<bool> deleteTransaction(String id);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final http.Client client;
  final AuthLocalDataSource localDataSource;

  TransactionRemoteDataSourceImpl({
    required this.client,
    required this.localDataSource,
  });

  @override
  Future<List<TransactionModel>> getLocalTransactions() async {
    return await DatabaseHelper.instance.getTransactions();
  }

  @override
  Future<List<DataTransaksi>> getTransactions({int maxRetries = 3}) async {
    final token = await localDataSource.getToken();
    final uri = Uri.parse(ApiUrl.transactions);

    int attempt = 0;
    while (attempt < maxRetries) {
      attempt++;
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
            .timeout(const Duration(seconds: 10));

        final Map<String, dynamic> responseJson = jsonDecode(response.body);

        if (response.statusCode == 200 && responseJson['success'] == true) {
          final transactionResponse = TransactionResponseModel.fromJson(responseJson);
          
          // Sync server transactions to SQLite database
          final mappedTx = transactionResponse.data
              .map((d) => TransactionModel.fromDataTransaksi(d))
              .toList();
          await DatabaseHelper.instance.syncTransactions(mappedTx);
          
          return transactionResponse.data;
        } else {
          final errorMessage = responseJson['message'] ?? 'Gagal mengambil data transaksi (${response.statusCode})';
          throw Exception(errorMessage);
        }
      } catch (e) {
        if (attempt >= maxRetries) {
          final localTx = await DatabaseHelper.instance.getTransactions();
          if (localTx.isNotEmpty) {
            // Return empty remote list if local fallback is present
            return [];
          }
          if (e is FormatException) {
            throw Exception('Respon server tidak valid');
          }
          if (e is TimeoutException) {
            throw Exception('Koneksi ke server timeout');
          }
          if (e is SocketException || e is http.ClientException) {
            throw Exception('Gagal terhubung ke server. Periksa jaringan Anda.');
          }
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
    return [];
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    final token = await localDataSource.getToken();
    final uri = Uri.parse('${ApiUrl.transactions}/$id');

    try {
      final response = await client
          .delete(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${token ?? ''}',
              'X-App-Key': ApiUrl.appKey,
              'x-api-key': ApiUrl.appKey,
            },
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
