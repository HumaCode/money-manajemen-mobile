class AccountModel {
  final bool success;
  final String message;
  final List<DataAkun> data;

  AccountModel({
    required this.success,
    required this.message,
    required this.data,
  });
}

class DataAkun {
  final String id;
  final String userId;
  final String accountTypeId;
  final String currencyId;
  final String name;
  final String institutionName;
  final String accountNumber;
  final String icon;
  final String color;
  final String balance;
  final String currentBalance;
  final String creditLimit;
  final bool isActive;
  final bool isDefault;
  final dynamic notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;
  final String maskedAccountNumber;
  final String balanceFormatted;

  DataAkun({
    required this.id,
    required this.userId,
    required this.accountTypeId,
    required this.currencyId,
    required this.name,
    required this.institutionName,
    required this.accountNumber,
    required this.icon,
    required this.color,
    required this.balance,
    required this.currentBalance,
    required this.creditLimit,
    required this.isActive,
    required this.isDefault,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.maskedAccountNumber,
    required this.balanceFormatted,
  });
}
