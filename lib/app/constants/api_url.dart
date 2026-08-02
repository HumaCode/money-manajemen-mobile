class ApiUrl {
  static const String baseUrl = 'https://cuan.humacode.my.id/api/v1';
  static const String appKey = 'humacode2026';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';
  static const String logout = '$baseUrl/auth/logout';

  // Dashboard Summary
  static const String walletSummary = '$baseUrl/wallet-summary';
  static const String topExpenses = '$baseUrl/top-expenses';
  static const String recentTransactions = '$baseUrl/recent-transactions';

  // Transactions
  static const String transactions = '$baseUrl/transactions';
  static const String scanReceipt = '$baseUrl/transactions/scan-receipt';

  // Master Data
  static const String categories = '$baseUrl/categories';
  static const String accounts = '$baseUrl/accounts';

  // Saving Goals
  static const String savingGoals = '$baseUrl/saving-goals';
}
