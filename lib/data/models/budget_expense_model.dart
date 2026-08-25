import 'dart:convert';

BudgetExpenseModel budgetExpenseModelFromJson(String str) =>
    BudgetExpenseModel.fromJson(json.decode(str));

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

DateTime? _parseDate(dynamic val) {
  if (val == null) return null;
  if (val is DateTime) return val;
  try {
    return DateTime.parse(val.toString());
  } catch (_) {
    return null;
  }
}

class BudgetExpenseModel {
  final String id;
  final String budgetId;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final int spentAmount;
  final String spentAmountFormatted;
  final DateTime? spentDate;
  final String notes;

  BudgetExpenseModel({
    required this.id,
    required this.budgetId,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.spentAmount,
    required this.spentAmountFormatted,
    this.spentDate,
    required this.notes,
  });

  factory BudgetExpenseModel.fromJson(Map<String, dynamic> json) {
    return BudgetExpenseModel(
      id: json["id"]?.toString() ?? '',
      budgetId: json["budget_id"]?.toString() ?? '',
      categoryId: json["category_id"]?.toString() ?? '',
      categoryName: json["category_name"]?.toString() ?? 'Uncategorized',
      categoryIcon: json["category_icon"]?.toString() ?? '🍔',
      spentAmount: _parseInt(json["spent_amount"]),
      spentAmountFormatted: json["spent_amount_formatted"]?.toString() ?? '',
      spentDate: _parseDate(json["spent_date"]),
      notes: json["notes"]?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "budget_id": budgetId,
        "category_id": categoryId,
        "category_name": categoryName,
        "category_icon": categoryIcon,
        "spent_amount": spentAmount,
        "spent_amount_formatted": spentAmountFormatted,
        "spent_date": spentDate?.toIso8601String(),
        "notes": notes,
      };
}
