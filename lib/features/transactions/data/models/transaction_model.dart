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
