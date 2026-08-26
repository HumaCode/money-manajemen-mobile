import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/constants/api_url.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/models/transaction_model.dart';
import 'package:money_manajemen/data/models/analytics_model.dart';

abstract class AnalyticsRemoteDataSource {
  Future<WalletSummaryModel> getWalletSummary({String? period});
  Future<List<TopExpenseItemModel>> getTopExpenses({String? period});
  Future<List<DataTransaksi>> getRecentTransactions();
  Future<Map<String, dynamic>> getBudgetAnalytics();
  Future<Map<String, dynamic>> getSavingAnalytics();
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final http.Client client;
  final AuthLocalDataSource localDataSource;

  AnalyticsRemoteDataSourceImpl({
    required this.client,
    required this.localDataSource,
  });

  Future<Map<String, String>> _getHeaders() async {
    final token = await localDataSource.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
      'X-App-Key': ApiUrl.appKey,
      'x-api-key': ApiUrl.appKey,
    };
  }

  @override
  Future<WalletSummaryModel> getWalletSummary({String? period}) async {
    final headers = await _getHeaders();
    final queryParams = period != null ? '?period=$period' : '';
    final uri = Uri.parse('${ApiUrl.walletSummary}$queryParams');

    final response = await client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
    final responseJson = jsonDecode(response.body);

    if (response.statusCode == 200 && (responseJson['success'] == true || responseJson['status'] == 'success')) {
      return WalletSummaryModel.fromJson(responseJson);
    } else {
      throw Exception(responseJson['message'] ?? 'Gagal mengambil ringkasan dompet');
    }
  }

  @override
  Future<List<TopExpenseItemModel>> getTopExpenses({String? period}) async {
    final headers = await _getHeaders();
    final queryParams = period != null ? '?period=$period' : '';
    final uri = Uri.parse('${ApiUrl.topExpenses}$queryParams');

    final response = await client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
    final responseJson = jsonDecode(response.body);

    if (response.statusCode == 200 && (responseJson['success'] == true || responseJson['status'] == 'success')) {
      final List rawData = responseJson['data'] ?? [];
      return rawData.map((e) => TopExpenseItemModel.fromJson(e)).toList();
    } else {
      throw Exception(responseJson['message'] ?? 'Gagal mengambil data top expenses');
    }
  }

  @override
  Future<List<DataTransaksi>> getRecentTransactions() async {
    final headers = await _getHeaders();
    final uri = Uri.parse(ApiUrl.recentTransactions);

    final response = await client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
    final responseJson = jsonDecode(response.body);

    if (response.statusCode == 200 && (responseJson['success'] == true || responseJson['status'] == 'success')) {
      final List rawData = responseJson['data'] ?? [];
      return rawData.map((e) => DataTransaksi.fromJson(e)).toList();
    } else {
      throw Exception(responseJson['message'] ?? 'Gagal mengambil transaksi terbaru');
    }
  }

  @override
  Future<Map<String, dynamic>> getBudgetAnalytics() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiUrl.budgetAnalytics);
      final response = await client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      final responseJson = jsonDecode(response.body);
      if (response.statusCode == 200 && (responseJson['success'] == true || responseJson['status'] == 'success')) {
        return responseJson['data'] ?? {};
      }
    } catch (_) {}
    return {};
  }

  @override
  Future<Map<String, dynamic>> getSavingAnalytics() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiUrl.savingAnalytics);
      final response = await client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      final responseJson = jsonDecode(response.body);
      if (response.statusCode == 200 && (responseJson['success'] == true || responseJson['status'] == 'success')) {
        return responseJson['data'] ?? {};
      }
    } catch (_) {}
    return {};
  }
}
