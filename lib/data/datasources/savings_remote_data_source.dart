import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/constants/api_url.dart';
import 'package:money_manajemen/core/database/database_helper.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/models/savings_goal_model.dart';
import 'package:money_manajemen/data/models/savings_contribution_model.dart' hide Data;

abstract class SavingsRemoteDataSource {
  Future<List<Data>> getSavingGoals();
  Future<List<Data>> getLocalSavingGoals();
  Future<Map<String, dynamic>> getSavingGoalDetail(String id);
  Future<Data?> createSavingGoal({
    required String name,
    required int targetAmount,
    int currentAmount = 0,
    int monthlyTarget = 0,
    DateTime? targetDate,
    String? description,
    String? accountId,
    String? currencyId,
    String icon = '🎯',
    String color = '#00FFA3',
  });
  Future<Data?> updateSavingGoal(
    String id, {
    required String name,
    required int targetAmount,
    int? currentAmount,
    int? monthlyTarget,
    DateTime? targetDate,
    String? description,
    String? status,
  });
  Future<Contribution?> addSavingContribution(
    String id, {
    required int amount,
    required DateTime contributedAt,
    String? notes,
    String? accountId,
  });
  Future<Contribution?> updateSavingContribution(
    String goalId,
    String contributionId, {
    required int amount,
    required DateTime contributedAt,
    String? notes,
  });
  Future<bool> deleteSavingContribution(String goalId, String contributionId);
  Future<bool> deleteSavingGoal(String id);
}

class SavingsRemoteDataSourceImpl implements SavingsRemoteDataSource {
  final http.Client client;
  final AuthLocalDataSource localDataSource;

  SavingsRemoteDataSourceImpl({
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
  Future<List<Data>> getLocalSavingGoals() {
    return DatabaseHelper.instance.getSavingGoals();
  }

  @override
  Future<List<Data>> getSavingGoals() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiUrl.savingGoals);

      final response = await client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        dynamic rawData = body['data'];
        List dynamicList = [];
        if (rawData is List) {
          dynamicList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          dynamicList = rawData['data'];
        }

        final goals = dynamicList.map((j) => Data.fromJson(j)).toList();
        await DatabaseHelper.instance.replaceSavingGoals(goals);

        return goals;
      }
    } catch (e) {}
    return await getLocalSavingGoals();
  }

  @override
  Future<Map<String, dynamic>> getSavingGoalDetail(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await client
          .get(Uri.parse(ApiUrl.savingGoalDetail(id)), headers: headers)
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return body['data'] ?? {};
      }
    } catch (_) {}
    return {};
  }

  @override
  Future<Data?> createSavingGoal({
    required String name,
    required int targetAmount,
    int currentAmount = 0,
    int monthlyTarget = 0,
    DateTime? targetDate,
    String? description,
    String? accountId,
    String? currencyId,
    String icon = '🎯',
    String color = '#00FFA3',
  }) async {
    try {
      final headers = await _getHeaders();
      final tDate = targetDate ?? DateTime.now().add(const Duration(days: 365));
      final dateStr =
          "${tDate.year.toString().padLeft(4, '0')}-${tDate.month.toString().padLeft(2, '0')}-${tDate.day.toString().padLeft(2, '0')}";

      final Map<String, dynamic> payload = {
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'monthly_target': monthlyTarget,
        'target_date': dateStr,
        'icon': icon,
        'color': color,
        'description': description ?? '',
      };

      if (accountId != null && accountId.isNotEmpty) {
        payload['account_id'] = accountId;
      }
      if (currencyId != null && currencyId.isNotEmpty) {
        payload['currency_id'] = currencyId;
      }

      final url = Uri.parse(ApiUrl.savingGoals);

      final response = await client
          .post(url, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        dynamic dataObj = body['data'];
        if (dataObj is Map) {
          if (dataObj.containsKey('saving_goal')) {
            dataObj = dataObj['saving_goal'];
          } else if (dataObj.containsKey('goal')) {
            dataObj = dataObj['goal'];
          }
          return Data.fromJson(Map<String, dynamic>.from(dataObj));
        }
      }

      String errMsg =
          body['message']?.toString() ??
          body['error']?.toString() ??
          'Server error ${response.statusCode}';
      if (body['data'] is Map) {
        final errorsMap = body['data'] as Map;
        final errorDetails = errorsMap.values
            .map((v) => v is List ? v.join(', ') : v.toString())
            .join('\n');
        if (errorDetails.isNotEmpty) {
          errMsg = '$errMsg:\n$errorDetails';
        }
      }
      throw Exception(errMsg);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Data?> updateSavingGoal(
    String id, {
    required String name,
    required int targetAmount,
    int? currentAmount,
    int? monthlyTarget,
    DateTime? targetDate,
    String? description,
    String? status,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> payload = {
        'name': name,
        'target_amount': targetAmount,
      };

      if (currentAmount != null) payload['current_amount'] = currentAmount;
      if (monthlyTarget != null) payload['monthly_target'] = monthlyTarget;
      if (description != null) payload['description'] = description;
      if (status != null) payload['status'] = status;
      if (targetDate != null) {
        payload['target_date'] =
            "${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      }

      final response = await client
          .put(
            Uri.parse(ApiUrl.savingGoalDetail(id)),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        return Data.fromJson(body['data']);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<Contribution?> addSavingContribution(
    String id, {
    required int amount,
    required DateTime contributedAt,
    String? notes,
    String? accountId,
  }) async {
    try {
      final headers = await _getHeaders();
      final dtStr =
          "${contributedAt.year.toString().padLeft(4, '0')}-${contributedAt.month.toString().padLeft(2, '0')}-${contributedAt.day.toString().padLeft(2, '0')} ${contributedAt.hour.toString().padLeft(2, '0')}:${contributedAt.minute.toString().padLeft(2, '0')}:${contributedAt.second.toString().padLeft(2, '0')}";

      final Map<String, dynamic> payload = {
        'amount': amount,
        'contributed_at': dtStr,
        'notes': notes ?? '',
      };
      if (accountId != null && accountId.isNotEmpty) {
        payload['account_id'] = accountId;
      }

      final response = await client
          .post(
            Uri.parse(ApiUrl.savingGoalAddSaving(id)),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        final dataObj = body['data'];
        if (dataObj != null && dataObj['contribution'] != null) {
          return Contribution.fromJson(dataObj['contribution']);
        } else if (dataObj != null && dataObj is Map<String, dynamic>) {
          return Contribution.fromJson(dataObj);
        }
      }

      final errMsg =
          body['message'] ??
          body['error'] ??
          'Server error ${response.statusCode}';
      throw Exception(errMsg.toString());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Contribution?> updateSavingContribution(
    String goalId,
    String contributionId, {
    required int amount,
    required DateTime contributedAt,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final dtStr =
          "${contributedAt.year.toString().padLeft(4, '0')}-${contributedAt.month.toString().padLeft(2, '0')}-${contributedAt.day.toString().padLeft(2, '0')} ${contributedAt.hour.toString().padLeft(2, '0')}:${contributedAt.minute.toString().padLeft(2, '0')}:${contributedAt.second.toString().padLeft(2, '0')}";

      final Map<String, dynamic> payload = {
        'amount': amount,
        'contributed_at': dtStr,
        'notes': notes ?? '',
      };

      final response = await client
          .put(
            Uri.parse(
              ApiUrl.savingGoalContributionDetail(goalId, contributionId),
            ),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        final dataObj = body['data'];
        if (dataObj != null && dataObj['contribution'] != null) {
          return Contribution.fromJson(dataObj['contribution']);
        } else if (dataObj != null && dataObj is Map<String, dynamic>) {
          return Contribution.fromJson(dataObj);
        }
      }

      final errMsg =
          body['message'] ??
          body['error'] ??
          'Server error ${response.statusCode}';
      throw Exception(errMsg.toString());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> deleteSavingContribution(
    String goalId,
    String contributionId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await client
          .delete(
            Uri.parse(
              ApiUrl.savingGoalContributionDetail(goalId, contributionId),
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return response.statusCode == 200 &&
          (body['success'] == true || body.isEmpty);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteSavingGoal(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await client
          .delete(Uri.parse(ApiUrl.savingGoalDetail(id)), headers: headers)
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return response.statusCode == 200 && body['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
