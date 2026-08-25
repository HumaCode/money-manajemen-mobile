class WalletSummaryModel {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double incomeChangePercentage;
  final double expenseChangePercentage;

  WalletSummaryModel({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    this.incomeChangePercentage = 0.0,
    this.expenseChangePercentage = 0.0,
  });

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    return WalletSummaryModel(
      totalBalance: (data['total_balance'] ?? data['balance'] ?? 0).toDouble(),
      totalIncome: (data['total_income'] ?? data['income'] ?? 0).toDouble(),
      totalExpense: (data['total_expense'] ?? data['expense'] ?? 0).toDouble(),
      incomeChangePercentage: (data['income_change_percentage'] ?? data['income_change'] ?? 0.0).toDouble(),
      expenseChangePercentage: (data['expense_change_percentage'] ?? data['expense_change'] ?? 0.0).toDouble(),
    );
  }
}

class TopExpenseItemModel {
  final String categoryName;
  final String emoji;
  final double amount;
  final double percentage; // e.g. 0.35 or 35.0

  TopExpenseItemModel({
    required this.categoryName,
    required this.emoji,
    required this.amount,
    required this.percentage,
  });

  factory TopExpenseItemModel.fromJson(Map<String, dynamic> json) {
    return TopExpenseItemModel(
      categoryName: json['category_name'] ?? json['name'] ?? json['category'] ?? 'Lainnya',
      emoji: json['emoji'] ?? json['icon'] ?? '💰',
      amount: (json['amount'] ?? json['total'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class MonthlyComparisonModel {
  final String label;
  final double income;
  final double expense;

  MonthlyComparisonModel({
    required this.label,
    required this.income,
    required this.expense,
  });

  factory MonthlyComparisonModel.fromJson(Map<String, dynamic> json) {
    return MonthlyComparisonModel(
      label: json['label'] ?? json['month'] ?? '',
      income: (json['income'] ?? 0).toDouble(),
      expense: (json['expense'] ?? 0).toDouble(),
    );
  }
}
