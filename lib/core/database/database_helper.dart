import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/features/transactions/data/models/category_model.dart';
import 'package:money_manajemen/features/transactions/data/models/account_model.dart';
import 'package:money_manajemen/features/transactions/data/models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('moneyflow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT,
        color TEXT
      )
    ''');

    // Accounts Table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        account_number TEXT,
        balance INTEGER NOT NULL,
        currency TEXT NOT NULL
      )
    ''');

    // Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        account_id TEXT,
        to_account_id TEXT,
        amount INTEGER NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  // ---- Categories Operations ----
  Future<void> insertOrUpdateCategories(List<CategoryModel> categories) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final cat in categories) {
      batch.insert(
        'categories',
        cat.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => CategoryModel.fromJson(json)).toList();
  }

  // ---- Accounts Operations ----
  Future<void> insertOrUpdateAccounts(List<AccountModel> accounts) async {
    final db = await instance.database;
    await db.delete('accounts');
    final batch = db.batch();
    for (final acc in accounts) {
      batch.insert(
        'accounts',
        acc.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AccountModel>> getAccounts() async {
    final db = await instance.database;
    final result = await db.query('accounts');
    return result.map((json) => AccountModel.fromJson(json)).toList();
  }

  Future<void> syncTransactions(List<TransactionModel> transactions) async {
    final db = await instance.database;
    await db.delete('transactions', where: 'is_synced = 1');
    final batch = db.batch();
    for (final tx in transactions) {
      batch.insert(
        'transactions',
        {
          'id': tx.id,
          'title': tx.title,
          'category': tx.category,
          'account_id': tx.accountId,
          'to_account_id': tx.toAccountId,
          'amount': tx.amount,
          'type': tx.type.name,
          'date': tx.date.toIso8601String(),
          'is_synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertOrUpdateTransactions(List<TransactionModel> transactions) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final tx in transactions) {
      batch.insert(
        'transactions',
        {
          'id': tx.id,
          'title': tx.title,
          'category': tx.category,
          'account_id': tx.accountId,
          'to_account_id': tx.toAccountId,
          'amount': tx.amount,
          'type': tx.type.name,
          'date': tx.date.toIso8601String(),
          'is_synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveLocalTransaction(TransactionModel tx, {bool isSynced = false}) async {
    final db = await instance.database;
    await db.insert(
      'transactions',
      {
        'id': tx.id,
        'title': tx.title,
        'category': tx.category,
        'account_id': tx.accountId,
        'to_account_id': tx.toAccountId,
        'amount': tx.amount,
        'type': tx.type.name,
        'date': tx.date.toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((json) {
      TransactionType type = TransactionType.expense;
      final typeStr = json['type']?.toString();
      if (typeStr == 'income') type = TransactionType.income;
      if (typeStr == 'transfer') type = TransactionType.transfer;

      DateTime parsedDate = DateTime.now();
      if (json['date'] != null) {
        try {
          parsedDate = DateTime.parse(json['date'].toString());
        } catch (_) {}
      }

      return TransactionModel(
        id: json['id'].toString(),
        title: json['title'].toString(),
        category: json['category'].toString(),
        date: parsedDate,
        amount: json['amount'] as int,
        type: type,
        icon: type == TransactionType.income
            ? Icons.work_rounded
            : (type == TransactionType.transfer ? Icons.swap_horiz_rounded : Icons.restaurant_rounded),
        color: type == TransactionType.income
            ? AppColors.success
            : (type == TransactionType.transfer ? AppColors.info : AppColors.warning),
        accountId: json['account_id']?.toString(),
        toAccountId: json['to_account_id']?.toString(),
      );
    }).toList();
  }

  Future<void> deleteTransaction(String id) async {
    final db = await instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('categories');
    await db.delete('accounts');
    await db.delete('transactions');
  }
}
