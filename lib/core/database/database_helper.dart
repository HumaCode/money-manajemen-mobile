import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/data/models/category_model.dart';
import 'package:money_manajemen/data/models/account_model.dart';
import 'package:money_manajemen/data/models/transaction_model.dart';
import 'package:money_manajemen/features/dashboard/presentation/widgets/notification_sheet.dart';
import 'package:money_manajemen/data/models/savings_goal_model.dart' as saving_model;

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

    // Activities Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT NOT NULL,
        icon_type TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Saving Goals Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS saving_goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        account_id TEXT,
        account_name TEXT,
        currency_id TEXT,
        currency_code TEXT,
        currency_symbol TEXT,
        target_amount INTEGER NOT NULL,
        current_amount INTEGER NOT NULL,
        remaining_amount INTEGER NOT NULL,
        monthly_target INTEGER NOT NULL,
        progress_percentage REAL NOT NULL,
        target_date TEXT,
        status TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        created_at TEXT,
        updated_at TEXT
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
    await db.delete('activities');
  }

  // ---- Activities / Notifications Operations ----
  Future<void> addActivity({
    required String title,
    required String message,
    String iconType = 'info',
    String colorHex = '#00FFA3',
  }) async {
    final db = await instance.database;
    await db.insert(
      'activities',
      {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
        'icon_type': iconType,
        'color_hex': colorHex,
        'is_read': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NotificationItem>> getActivities() async {
    final db = await instance.database;
    final result = await db.query('activities', orderBy: 'created_at DESC');
    if (result.isEmpty) {
      await addActivity(
        title: 'Sinkronisasi Rekening',
        message: 'Berhasil melakukan sinkronisasi data rekening & saldo dengan server.',
        iconType: 'account',
        colorHex: '#00FFA3',
      );
      await addActivity(
        title: 'Selamat Datang',
        message: 'Aplikasi Money Management siap digunakan untuk mencatat keuangan Anda.',
        iconType: 'info',
        colorHex: '#60a5fa',
      );
      final seeded = await db.query('activities', orderBy: 'created_at DESC');
      return _mapActivityRows(seeded);
    }
    return _mapActivityRows(result);
  }

  List<NotificationItem> _mapActivityRows(List<Map<String, dynamic>> rows) {
    return rows.map((json) {
      IconData iconData = Icons.notifications_rounded;
      final type = json['icon_type']?.toString() ?? 'info';
      if (type == 'scan') {
        iconData = Icons.document_scanner_rounded;
      } else if (type == 'transaction') {
        iconData = Icons.receipt_long_rounded;
      } else if (type == 'account') {
        iconData = Icons.account_balance_wallet_rounded;
      } else if (type == 'security') {
        iconData = Icons.fingerprint_rounded;
      } else if (type == 'analytics') {
        iconData = Icons.pie_chart_outline_rounded;
      }

      Color iconColor = AppColors.accent;
      final hex = json['color_hex']?.toString() ?? '#00FFA3';
      try {
        final cleanHex = hex.replaceAll('#', '');
        iconColor = Color(int.parse('FF$cleanHex', radix: 16));
      } catch (_) {}

      DateTime parsedTime = DateTime.now();
      if (json['created_at'] != null) {
        try {
          parsedTime = DateTime.parse(json['created_at'].toString());
        } catch (_) {}
      }

      return NotificationItem(
        id: json['id'].toString(),
        title: json['title'].toString(),
        message: json['message'].toString(),
        time: parsedTime,
        icon: iconData,
        iconColor: iconColor,
        isRead: (json['is_read'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  Future<void> markAllActivitiesAsRead() async {
    final db = await instance.database;
    await db.update('activities', {'is_read': 1});
  }

  Future<void> markActivityAsRead(String id) async {
    final db = await instance.database;
    await db.update('activities', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ---- Saving Goals Local SQLite Sync ----
  Future<void> replaceSavingGoals(List<saving_model.Data> goals) async {
    final db = await instance.database;
    final batch = db.batch();
    batch.delete('saving_goals');
    for (final goal in goals) {
      batch.insert(
        'saving_goals',
        goal.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<saving_model.Data>> getSavingGoals() async {
    final db = await instance.database;
    final result = await db.query('saving_goals', orderBy: 'created_at DESC');
    return result.map((json) => saving_model.Data.fromJson(json)).toList();
  }
}
