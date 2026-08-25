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
    int parsedBalance = 0;
    dynamic rawBalance = json['balance'] ??
        json['currentBalance'] ??
        json['current_balance'] ??
        json['initialBalance'] ??
        json['initial_balance'] ??
        json['startingBalance'] ??
        json['starting_balance'] ??
        json['totalBalance'] ??
        json['total_balance'] ??
        json['saldo'] ??
        json['amount'];

    if (rawBalance is Map) {
      rawBalance = rawBalance['amount'] ?? rawBalance['value'] ?? rawBalance['raw'];
    }

    if (rawBalance is num) {
      parsedBalance = rawBalance.toInt();
    } else if (rawBalance != null) {
      String str = rawBalance.toString().replaceAll('Rp', '').replaceAll('rp', '').trim();
      if (str.contains(',') && str.contains('.')) {
        if (str.indexOf(',') < str.indexOf('.')) {
          str = str.replaceAll(',', '');
        } else {
          str = str.replaceAll('.', '').replaceAll(',', '.');
        }
      } else if (str.contains(',')) {
        str = str.replaceAll(',', '.');
      }

      final d = double.tryParse(str);
      if (d != null) {
        parsedBalance = d.toInt();
      } else {
        final digitsOnly = str.replaceAll(RegExp(r'[^\d]'), '');
        parsedBalance = int.tryParse(digitsOnly) ?? 0;
      }
    }

    final nameStr = json['name']?.toString() ?? json['account_name']?.toString() ?? '';

    final accNo = json['account_number']?.toString() ??
        json['accountNumber']?.toString() ??
        json['maskedAccountNumber']?.toString() ??
        json['masked_account_number']?.toString() ??
        '';

    return AccountModel(
      id: json['id']?.toString() ?? '',
      name: nameStr,
      accountNumber: accNo,
      balance: parsedBalance,
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
