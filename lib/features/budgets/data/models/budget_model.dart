import 'dart:convert';

BudgetModel budgetModelFromJson(String str) => BudgetModel.fromJson(json.decode(str));

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

double _parseDouble(dynamic val, [double defaultValue = 0.0]) {
  if (val == null) return defaultValue;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is String) {
    final parsed = double.tryParse(val);
    if (parsed != null) return parsed;
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

class BudgetModel {
  final String id;
  final String name;
  final String currencyId;
  final String currencyCode;
  final String currencySymbol;
  final int totalAmount;
  final String totalAmountFormatted;
  final int totalSpent;
  final String spentAmountFormatted;
  final int remainingAmount;
  final String remainingAmountFormatted;
  final double progressPercentage;
  final String period;
  final DateTime? startDate;
  final DateTime? endDate;
  final String dateRangeFormatted;
  final bool isActive;
  final bool rolloverUnused;
  final String status;
  final String notes;

  BudgetModel({
    required this.id,
    required this.name,
    required this.currencyId,
    required this.currencyCode,
    required this.currencySymbol,
    required this.totalAmount,
    required this.totalAmountFormatted,
    required this.totalSpent,
    required this.spentAmountFormatted,
    required this.remainingAmount,
    required this.remainingAmountFormatted,
    required this.progressPercentage,
    required this.period,
    this.startDate,
    this.endDate,
    required this.dateRangeFormatted,
    required this.isActive,
    required this.rolloverUnused,
    required this.status,
    required this.notes,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    final total = _parseInt(json["total_amount"]);
    final spent = _parseInt(json["total_spent"]);
    final remaining = _parseInt(json["remaining_amount"], total - spent);
    final rawPct = _parseDouble(json["progress_percentage"]);

    return BudgetModel(
      id: json["id"]?.toString() ?? '',
      name: json["name"]?.toString() ?? '',
      currencyId: json["currency_id"]?.toString() ?? '',
      currencyCode: json["currency_code"]?.toString() ?? 'IDR',
      currencySymbol: json["currency_symbol"]?.toString() ?? 'Rp',
      totalAmount: total,
      totalAmountFormatted: json["total_amount_formatted"]?.toString() ?? '',
      totalSpent: spent,
      spentAmountFormatted: json["spent_amount_formatted"]?.toString() ?? '',
      remainingAmount: remaining < 0 ? 0 : remaining,
      remainingAmountFormatted: json["remaining_amount_formatted"]?.toString() ?? '',
      progressPercentage: rawPct,
      period: json["period"]?.toString() ?? 'monthly',
      startDate: _parseDate(json["start_date"]),
      endDate: _parseDate(json["end_date"]),
      dateRangeFormatted: json["date_range_formatted"]?.toString() ?? '-',
      isActive: json["is_active"] == true || json["is_active"] == 1,
      rolloverUnused: json["rollover_unused"] == true || json["rollover_unused"] == 1,
      status: json["status"]?.toString() ?? 'on_track',
      notes: json["notes"]?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "currency_id": currencyId,
        "currency_code": currencyCode,
        "currency_symbol": currencySymbol,
        "total_amount": totalAmount,
        "total_amount_formatted": totalAmountFormatted,
        "total_spent": totalSpent,
        "spent_amount_formatted": spentAmountFormatted,
        "remaining_amount": remainingAmount,
        "remaining_amount_formatted": remainingAmountFormatted,
        "progress_percentage": progressPercentage,
        "period": period,
        "start_date": startDate?.toIso8601String(),
        "end_date": endDate?.toIso8601String(),
        "date_range_formatted": dateRangeFormatted,
        "is_active": isActive,
        "rollover_unused": rolloverUnused,
        "status": status,
        "notes": notes,
      };
}
