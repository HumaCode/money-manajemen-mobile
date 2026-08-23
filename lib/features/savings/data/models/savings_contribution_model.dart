import 'dart:convert';

SavingContribution savingContributionFromJson(String str) =>
    SavingContribution.fromJson(json.decode(str));

String savingContributionToJson(SavingContribution data) =>
    json.encode(data.toJson());

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
  final Goal goal;
  final Contribution contribution;

  Data({required this.goal, required this.contribution});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    goal: Goal.fromJson(json["goal"]),
    contribution: Contribution.fromJson(json["contribution"]),
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
    savingsGoalId: json["savings_goal_id"],
    amount: json["amount"],
    contributedAt: DateTime.parse(json["contributed_at"]),
    notes: json["notes"],
    id: json["id"],
    savingsGoal: SavingsGoal.fromJson(json["savings_goal"]),
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
    id: json["id"],
    userId: json["user_id"],
    accountId: json["account_id"],
    currencyId: json["currency_id"],
    name: json["name"],
    description: json["description"],
    targetAmount: json["target_amount"],
    currentAmount: json["current_amount"],
    monthlyTarget: json["monthly_target"],
    targetDate: DateTime.parse(json["target_date"]),
    status: json["status"],
    icon: json["icon"],
    color: json["color"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
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
    progressPercentage: json["progress_percentage"],
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
