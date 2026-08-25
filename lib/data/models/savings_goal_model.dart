import 'dart:convert';

SavingGoal savingGoalFromJson(String str) =>
    SavingGoal.fromJson(json.decode(str));

String savingGoalToJson(SavingGoal data) => json.encode(data.toJson());

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

class SavingGoal {
  final bool success;
  final String message;
  final Data data;

  SavingGoal({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SavingGoal.fromJson(Map<String, dynamic> json) => SavingGoal(
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
  final double progressPercentage;
  final DateTime targetDate;
  final String status;
  final String icon;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Data({
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

  factory Data.fromJson(Map<String, dynamic> json) {
    final target = _parseInt(json["target_amount"]);
    final current = _parseInt(json["current_amount"]);
    final calcRemaining = target - current;
    final remaining = _parseInt(json["remaining_amount"], calcRemaining < 0 ? 0 : calcRemaining);
    final calcPct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final double progressPct = calcPct;

    return Data(
      id: json["id"]?.toString() ?? '',
      name: json["name"]?.toString() ?? '',
      description: json["description"]?.toString() ?? '',
      accountId: json["account_id"]?.toString() ?? '',
      accountName: json["account_name"]?.toString() ?? 'Kas Utama',
      currencyId: json["currency_id"]?.toString() ?? 'IDR',
      currencyCode: json["currency_code"]?.toString() ?? 'IDR',
      currencySymbol: json["currency_symbol"]?.toString() ?? 'Rp',
      targetAmount: target,
      currentAmount: current,
      remainingAmount: remaining < 0 ? 0 : remaining,
      monthlyTarget: _parseInt(json["monthly_target"]),
      progressPercentage: progressPct.clamp(0.0, 1.0),
      targetDate: _parseDate(json["target_date"]),
      status: json["status"]?.toString() ?? 'active',
      icon: json["icon"]?.toString() ?? '🎯',
      color: json["color"]?.toString() ?? '#00FFA3',
      createdAt: _parseDate(json["created_at"]),
      updatedAt: _parseDate(json["updated_at"]),
    );
  }

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
