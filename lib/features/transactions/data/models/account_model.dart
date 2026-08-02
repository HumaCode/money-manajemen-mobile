class AccountModel {
  final String id;
  final String name;
  final String accountNumber;
  final int balance;
  final String currency;

  AccountModel({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.balance,
    required this.currency,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['account_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      balance: json['balance'] is num ? (json['balance'] as num).toInt() : 0,
      currency: json['currency']?.toString() ?? 'IDR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'account_number': accountNumber,
      'balance': balance,
      'currency': currency,
    };
  }
}
