import 'dart:convert';

SavingContribution savingContributionFromJson(String str) =>
    SavingContribution.fromJson(json.decode(str));

String savingContributionToJson(SavingContribution data) =>
    json.encode(data.toJson());

int _parseInt(dynamic val, [int defaultValue = 0]) {
  if (val == null) return defaultValue;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) {
    final parsedDouble = double.tryParse(val);
    if (parsedDouble != null) return parsedDouble.toInt();
    final parsedInt = int.tryParse(val);
    if (parsedInt != null) return parsedInt;
  }
  return defaultValue;
}

DateTime _parseDate(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is DateTime) return val;
  try {
    return DateTime.parse(val.toString());
  } catch (_) {
    return DateTime.now();
  }
}

class SavingContribution {
  final bool success;
  final String message;
  final Data data;

  SavingContribution({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SavingContribution.fromJson(Map<String, dynamic> json) =>
      SavingContribution(
        success: json["success"] ?? true,
        message: json["message"]?.toString() ?? '',
        data: Data.fromJson(json["data"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
      };
}

class Data {
  final Goal goal;
  final Contribution contribution;

  Data({required this.goal, required this.contribution});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        goal: Goal.fromJson(json["goal"] ?? {}),
        contribution: Contribution.fromJson(json["contribution"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "goal": goal.toJson(),
        "contribution": contribution.toJson(),
      };
}

class Contribution {
  final String savingsGoalId;
  final String amount;
  final DateTime contributedAt;
  final String notes;
  final String id;
  final SavingsGoal savingsGoal;

  Contribution({
    required this.savingsGoalId,
    required this.amount,
    required this.contributedAt,
    required this.notes,
    required this.id,
    required this.savingsGoal,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) => Contribution(
        savingsGoalId: json["savings_goal_id"]?.toString() ?? '',
        amount: json["amount"]?.toString() ?? '0',
        contributedAt: _parseDate(json["contributed_at"]),
        notes: json["notes"]?.toString() ?? '',
        id: json["id"]?.toString() ?? '',
        savingsGoal: json["savings_goal"] != null
            ? SavingsGoal.fromJson(json["savings_goal"])
            : SavingsGoal(
                id: json["savings_goal_id"]?.toString() ?? '',
                userId: '',
                accountId: '',
                currencyId: 'IDR',
                name: '',
                description: '',
                targetAmount: '0',
                currentAmount: '0',
                monthlyTarget: '0',
                targetDate: DateTime.now(),
                status: 'active',
                icon: 'savings',
                color: '#00FFA3',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
      );

  Map<String, dynamic> toJson() => {
        "savings_goal_id": savingsGoalId,
        "amount": amount,
        "contributed_at": contributedAt.toIso8601String(),
        "notes": notes,
        "id": id,
        "savings_goal": savingsGoal.toJson(),
      };
}

class SavingsGoal {
  final String id;
  final String userId;
  final String accountId;
  final String currencyId;
  final String name;
  final String description;
  final String targetAmount;
  final String currentAmount;
  final String monthlyTarget;
  final DateTime targetDate;
  final String status;
  final String icon;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.currencyId,
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.monthlyTarget,
    required this.targetDate,
    required this.status,
    required this.icon,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json["id"]?.toString() ?? '',
        userId: json["user_id"]?.toString() ?? '',
        accountId: json["account_id"]?.toString() ?? '',
        currencyId: json["currency_id"]?.toString() ?? 'IDR',
        name: json["name"]?.toString() ?? '',
        description: json["description"]?.toString() ?? '',
        targetAmount: json["target_amount"]?.toString() ?? '0',
        currentAmount: json["current_amount"]?.toString() ?? '0',
        monthlyTarget: json["monthly_target"]?.toString() ?? '0',
        targetDate: _parseDate(json["target_date"]),
        status: json["status"]?.toString() ?? 'active',
        icon: json["icon"]?.toString() ?? '🎯',
        color: json["color"]?.toString() ?? '#00FFA3',
        createdAt: _parseDate(json["created_at"]),
        updatedAt: _parseDate(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "account_id": accountId,
        "currency_id": currencyId,
        "name": name,
        "description": description,
        "target_amount": targetAmount,
        "current_amount": currentAmount,
        "monthly_target": monthlyTarget,
        "target_date": targetDate.toIso8601String(),
        "status": status,
        "icon": icon,
        "color": color,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
      };
}

class Goal {
  final String id;
  final String name;
  final String description;
  final String accountId;
  final String accountName;
  final String currencyId;
  final String currencyCode;
  final String currencySymbol;
  final int targetAmount;
  final int currentAmount;
  final int remainingAmount;
  final int monthlyTarget;
  final int progressPercentage;
  final DateTime targetDate;
  final String status;
  final String icon;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    required this.id,
    required this.name,
    required this.description,
    required this.accountId,
    required this.accountName,
    required this.currencyId,
    required this.currencyCode,
    required this.currencySymbol,
    required this.targetAmount,
    required this.currentAmount,
    required this.remainingAmount,
    required this.monthlyTarget,
    required this.progressPercentage,
    required this.targetDate,
    required this.status,
    required this.icon,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json["id"]?.toString() ?? '',
        name: json["name"]?.toString() ?? '',
        description: json["description"]?.toString() ?? '',
        accountId: json["account_id"]?.toString() ?? '',
        accountName: json["account_name"]?.toString() ?? '',
        currencyId: json["currency_id"]?.toString() ?? 'IDR',
        currencyCode: json["currency_code"]?.toString() ?? 'IDR',
        currencySymbol: json["currency_symbol"]?.toString() ?? 'Rp',
        targetAmount: _parseInt(json["target_amount"]),
        currentAmount: _parseInt(json["current_amount"]),
        remainingAmount: _parseInt(json["remaining_amount"]),
        monthlyTarget: _parseInt(json["monthly_target"]),
        progressPercentage: _parseInt(json["progress_percentage"]),
        targetDate: _parseDate(json["target_date"]),
        status: json["status"]?.toString() ?? 'active',
        icon: json["icon"]?.toString() ?? '🎯',
        color: json["color"]?.toString() ?? '#00FFA3',
        createdAt: _parseDate(json["created_at"]),
        updatedAt: _parseDate(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "account_id": accountId,
        "account_name": accountName,
        "currency_id": currencyId,
        "currency_code": currencyCode,
        "currency_symbol": currencySymbol,
        "target_amount": targetAmount,
        "current_amount": currentAmount,
        "remaining_amount": remainingAmount,
        "monthly_target": monthlyTarget,
        "progress_percentage": progressPercentage,
        "target_date":
            "${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}",
        "status": status,
        "icon": icon,
        "color": color,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
      };
}
