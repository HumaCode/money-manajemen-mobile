class ApiUrl {
  static const String baseUrl = 'http://192.168.1.6:8001/api/v1';
  static const String appKey = 'humacode2026';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String loginVerify2fa = '$baseUrl/auth/login/verify-2fa';
  static const String loginResend2fa = '$baseUrl/auth/login/resend-2fa';
  static const String me = '$baseUrl/auth/me';
  static const String updateProfile = '$baseUrl/auth/profile';
  static const String updatePassword = '$baseUrl/auth/password';
  static const String logout = '$baseUrl/auth/logout';

  // 2FA Security
  static const String twoFactorStatus = '$baseUrl/auth/2fa/status';
  static const String twoFactorSendOtp = '$baseUrl/auth/2fa/send-otp';
  static const String twoFactorVerifyOtp = '$baseUrl/auth/2fa/verify-otp';
  static const String twoFactorDisable = '$baseUrl/auth/2fa/disable';

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
  static const String currencies = '$baseUrl/currencies';

  // Saving Goals
  static const String savingGoals = '$baseUrl/saving-goals';
  static String savingGoalDetail(dynamic id) => '$baseUrl/saving-goals/$id';
  static String savingGoalAddSaving(dynamic id) =>
      '$baseUrl/saving-goals/$id/add-saving';
}
