import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/constants/api_url.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/models/budget_model.dart';
import 'package:money_manajemen/data/models/budget_expense_model.dart';

abstract class BudgetRemoteDataSource {
  Future<List<BudgetModel>> getBudgets({String status = 'all', String period = 'all'});
  Future<BudgetModel?> getBudgetDetail(String id);
  Future<BudgetModel?> createBudget({
    required String name,
    required String currencyId,
    required int totalAmount,
    String period = 'monthly',
    DateTime? startDate,
    DateTime? endDate,
    bool rolloverUnused = false,
    String? notes,
  });
  Future<BudgetModel?> updateBudget(
    String id, {
    required String name,
    required String currencyId,
    required int totalAmount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? rolloverUnused,
    String? notes,
  });
  Future<bool> deleteBudget(String id);
  Future<bool> addBudgetExpense(
    String budgetId, {
    required String categoryId,
    required int spentAmount,
    DateTime? spentDate,
    String? notes,
  });
  Future<List<BudgetExpenseModel>> getBudgetExpenses(String budgetId);
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final http.Client client;
  final AuthLocalDataSource localDataSource;

  BudgetRemoteDataSourceImpl({
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
  Future<List<BudgetModel>> getBudgets({String status = 'all', String period = 'all'}) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiUrl.budgets}?status=$status&period=$period');
      final response = await client.get(url, headers: headers).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        dynamic rawData = body['data'];
        List dynamicList = rawData is List ? rawData : [];
        return dynamicList.map((item) => BudgetModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting budgets: $e');
      return [];
    }
  }

  @override
  Future<BudgetModel?> getBudgetDetail(String id) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiUrl.budgetDetail(id));
      final response = await client.get(url, headers: headers).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true && body['data'] != null) {
        return BudgetModel.fromJson(body['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting budget detail: $e');
      return null;
    }
  }

  @override
  Future<BudgetModel?> createBudget({
    required String name,
    required String currencyId,
    required int totalAmount,
    String period = 'monthly',
    DateTime? startDate,
    DateTime? endDate,
    bool rolloverUnused = false,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiUrl.budgets);

      final Map<String, dynamic> payload = {
        'name': name,
        'currency_id': currencyId,
        'total_amount': totalAmount,
        'period': period,
        'rollover_unused': rolloverUnused,
        if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await client
          .post(url, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && body['success'] == true) {
        return BudgetModel.fromJson(body['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating budget: $e');
      return null;
    }
  }

  @override
  Future<BudgetModel?> updateBudget(
    String id, {
    required String name,
    required String currencyId,
    required int totalAmount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? rolloverUnused,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiUrl.budgetDetail(id));

      final Map<String, dynamic> payload = {
        'name': name,
        'currency_id': currencyId,
        'total_amount': totalAmount,
        if (period != null) 'period': period,
        if (isActive != null) 'is_active': isActive,
        if (rolloverUnused != null) 'rollover_unused': rolloverUnused,
        if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
        if (notes != null) 'notes': notes,
      };

      final response = await client
          .put(url, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return BudgetModel.fromJson(body['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating budget: $e');
      return null;
    }
  }

  @override
  Future<bool> deleteBudget(String id) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiUrl.budgetDetail(id));
      final response = await client.delete(url, headers: headers).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return response.statusCode == 200 && body['success'] == true;
    } catch (e) {
      debugPrint('Error deleting budget: $e');
      return false;
    }
  }

  @override
  Future<bool> addBudgetExpense(
    String budgetId, {
    required String categoryId,
    required int spentAmount,
    DateTime? spentDate,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiUrl.budgetAddExpense(budgetId));

      final Map<String, dynamic> payload = {
        'category_id': categoryId,
        'spent_amount': spentAmount,
        'spent_date': (spentDate ?? DateTime.now()).toIso8601String().split('T')[0],
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await client
          .post(url, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return (response.statusCode == 200 || response.statusCode == 201) && body['success'] == true;
    } catch (e) {
      debugPrint('Error adding budget expense: $e');
      return false;
    }
  }

  @override
  Future<List<BudgetExpenseModel>> getBudgetExpenses(String budgetId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiUrl.budgetExpenses(budgetId));
      final response = await client.get(url, headers: headers).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        dynamic rawData = body['data'];
        List dynamicList = rawData is List ? rawData : [];
        return dynamicList.map((item) => BudgetExpenseModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting budget expenses: $e');
      return [];
    }
  }
}
