import 'package:flutter/material.dart';

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

  const TransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    required this.type,
    required this.icon,
    required this.color,
  });

  bool get isIncome => type == TransactionType.income;
}

class TransactionResponseModel {
  final bool success;
  final String message;
  final List<DataTransaksi> data;
  final Pagination pagination;
  final Links links;

  TransactionResponseModel({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
    required this.links,
  });
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
}
