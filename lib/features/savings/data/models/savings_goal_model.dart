import 'dart:convert';

SavingGoal savingGoalFromJson(String str) =>
    SavingGoal.fromJson(json.decode(str));

String savingGoalToJson(SavingGoal data) => json.encode(data.toJson());

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
    success: json["success"],
    message: json["message"],
    data: Data.fromJson(json["data"]),
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

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json["id"],
    name: json["name"],
    description: json["description"],
    accountId: json["account_id"],
    accountName: json["account_name"],
    currencyId: json["currency_id"],
    currencyCode: json["currency_code"],
    currencySymbol: json["currency_symbol"],
    targetAmount: json["target_amount"],
    currentAmount: json["current_amount"],
    remainingAmount: json["remaining_amount"],
    monthlyTarget: json["monthly_target"],
    progressPercentage: json["progress_percentage"]?.toDouble(),
    targetDate: DateTime.parse(json["target_date"]),
    status: json["status"],
    icon: json["icon"],
    color: json["color"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
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
