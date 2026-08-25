import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';

enum TransactionType { income, expense, transfer }

class TransactionModel {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final int amount;
  final TransactionType type;
  final IconData icon;
  final Color color;
  final String? accountId;
  final String? toAccountId;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    required this.type,
    required this.icon,
    required this.color,
    this.accountId,
    this.toAccountId,
  });

  bool get isIncome => type == TransactionType.income;

  factory TransactionModel.fromDataTransaksi(DataTransaksi data) {
    TransactionType type;
    if (data.type == 'income') {
      type = TransactionType.income;
    } else if (data.type == 'expense') {
      type = TransactionType.expense;
    } else {
      type = TransactionType.transfer;
    }

    IconData iconData = Icons.account_balance_wallet_rounded;
    final iconLower = data.icon.toLowerCase();
    if (iconLower.contains('work') || iconLower.contains('gaji') || iconLower.contains('briefcase')) {
      iconData = Icons.work_rounded;
    } else if (iconLower.contains('food') || iconLower.contains('utensils') || iconLower.contains('makan') || iconLower.contains('restaurant')) {
      iconData = Icons.restaurant_rounded;
    } else if (iconLower.contains('gas') || iconLower.contains('car') || iconLower.contains('bensin') || iconLower.contains('transport')) {
      iconData = Icons.local_gas_station_rounded;
    } else if (iconLower.contains('shop') || iconLower.contains('bag') || iconLower.contains('belanja')) {
      iconData = Icons.shopping_bag_rounded;
    } else if (iconLower.contains('transfer') || iconLower.contains('swap')) {
      iconData = Icons.swap_horiz_rounded;
    } else if (iconLower.contains('gift') || iconLower.contains('bonus')) {
      iconData = Icons.card_giftcard_rounded;
    }

    Color color = AppColors.primary;
    if (data.color.isNotEmpty && data.color.startsWith('#')) {
      try {
        final hex = data.color.replaceAll('#', '');
        color = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    } else if (type == TransactionType.income) {
      color = AppColors.success;
    } else if (type == TransactionType.expense) {
      color = AppColors.warning;
    } else {
      color = AppColors.info;
    }

    final parsedTitle = data.title.isNotEmpty 
        ? data.title 
        : (data.description.isNotEmpty ? data.description : (data.categoryName.isNotEmpty ? data.categoryName : 'Transaksi'));

    final parsedCategory = data.categoryName.isNotEmpty 
        ? data.categoryName 
        : (data.typeLabel.isNotEmpty ? data.typeLabel : 'Umum');

    final parsedAmount = type == TransactionType.expense ? -data.amount.abs() : data.amount.abs();

    return TransactionModel(
      id: data.id,
      title: parsedTitle,
      category: parsedCategory,
      date: data.transactionDate,
      amount: parsedAmount,
      type: type,
      icon: iconData,
      color: color,
      accountId: data.accountId,
      toAccountId: data.toAccountId?.toString(),
    );
  }
}

class TransactionResponseModel {
  final bool success;
  final String message;
  final List<DataTransaksi> data;
  final Pagination? pagination;
  final Links? links;

  TransactionResponseModel({
    required this.success,
    required this.message,
    required this.data,
    this.pagination,
    this.links,
  });

  factory TransactionResponseModel.fromJson(Map<String, dynamic> json) {
    return TransactionResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? List<DataTransaksi>.from(
              (json['data'] as List).map((x) => DataTransaksi.fromJson(x as Map<String, dynamic>)))
          : [],
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
      links: json['links'] != null ? Links.fromJson(json['links']) : null,
    );
  }
}

class DataTransaksi {
  final String id;
  final String userId;
  final String accountId;
  final dynamic toAccountId;
  final String categoryId;
  final String currencyId;
  final String type;
  final String typeLabel;
  final String description;
  final String title;
  final String categoryName;
  final int amount;
  final String amountFormatted;
  final String signedAmount;
  final DateTime transactionDate;
  final String transactionDateFormatted;
  final String dateGroup;
  final String formattedDate;
  final String color;
  final String icon;

  DataTransaksi({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.toAccountId,
    required this.categoryId,
    required this.currencyId,
    required this.type,
    required this.typeLabel,
    required this.description,
    required this.title,
    required this.categoryName,
    required this.amount,
    required this.amountFormatted,
    required this.signedAmount,
    required this.transactionDate,
    required this.transactionDateFormatted,
    required this.dateGroup,
    required this.formattedDate,
    required this.color,
    required this.icon,
  });

  factory DataTransaksi.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    if (json['transaction_date'] != null) {
      try {
        parsedDate = DateTime.parse(json['transaction_date']);
      } catch (_) {}
    }

    int parsedAmount = 0;
    if (json['amount'] != null) {
      if (json['amount'] is num) {
        parsedAmount = (json['amount'] as num).toInt();
      } else {
        parsedAmount = int.tryParse(json['amount'].toString()) ?? 0;
      }
    }

    return DataTransaksi(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      accountId: json['account_id']?.toString() ?? '',
      toAccountId: json['to_account_id'],
      categoryId: json['category_id']?.toString() ?? '',
      currencyId: json['currency_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'expense',
      typeLabel: json['type_label']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      amount: parsedAmount,
      amountFormatted: json['amount_formatted']?.toString() ?? '',
      signedAmount: json['signed_amount']?.toString() ?? '',
      transactionDate: parsedDate,
      transactionDateFormatted: json['transaction_date_formatted']?.toString() ?? '',
      dateGroup: json['date_group']?.toString() ?? '',
      formattedDate: json['formatted_date']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
    );
  }
}

class Links {
  final String first;
  final String last;
  final dynamic prev;
  final dynamic next;

  Links({
    required this.first,
    required this.last,
    required this.prev,
    required this.next,
  });

  factory Links.fromJson(Map<String, dynamic> json) {
    return Links(
      first: json['first']?.toString() ?? '',
      last: json['last']?.toString() ?? '',
      prev: json['prev'],
      next: json['next'],
    );
  }
}

class Pagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.hasMore,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] is int ? json['current_page'] : int.tryParse(json['current_page']?.toString() ?? '1') ?? 1,
      lastPage: json['last_page'] is int ? json['last_page'] : int.tryParse(json['last_page']?.toString() ?? '1') ?? 1,
      perPage: json['per_page'] is int ? json['per_page'] : int.tryParse(json['per_page']?.toString() ?? '15') ?? 15,
      total: json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      hasMore: json['has_more'] ?? false,
    );
  }
}
