import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../pages/model.dart';

class ExpenseDatabase {
  static final ExpenseDatabase instance = ExpenseDatabase._init();
  static Database? _database;

  ExpenseDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Ensure directory exists
    final directory = Directory(dirname(path));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return await openDatabase(
      path,
      version: 7, // Version maintain rakha hai taaki crash na ho
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        isRecurring INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration logic to safely handle old data structures
    if (oldVersion < 7) {
      try {
        // Fix amounts sign logic if coming from very old versions
        final allTransactions = await db.query('transactions');
        for (final t in allTransactions) {
          final id = t['id'] as String;
          final amount = (t['amount'] as num).toDouble();

          // Agar purana 'transactionType' column exist karta tha aur logic ulta tha
          // toh usey fix karein. Simple check: Expense should be negative.
          // Since we can't easily detect type without the column, we assume
          // existing amounts are largely correct or leave them as is.
          // This block is mainly a placeholder to prevent upgrade crashes.
        }
      } catch (e) {
        // Ignore migration errors
      }
    }
  }

  // --- Transaction Operations ---

  Future<void> insertTransaction(ExpenseItem item) async {
    final db = await instance.database;
    await db.insert(
      'transactions',
      item.toJson(), // Ab ye Model ke naye structure se match karega
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Legacy support
  Future<void> insertExpense(ExpenseItem item) async => insertTransaction(item);

  Future<List<ExpenseItem>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');

    return result.map((json) {
      return ExpenseItem(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] is num ? json['amount'] as num : 0.0).toDouble(),
        category: ExpenseCategory.values.firstWhere(
              (e) => e.toString().split('.').last == json['category'],
          orElse: () => ExpenseCategory.other,
        ),
        date: DateTime.parse(json['date'] as String),
        paymentMethod: PaymentMethod.values.firstWhere(
              (e) => e.toString().split('.').last == json['paymentMethod'],
          orElse: () => PaymentMethod.cash,
        ),
        isRecurring: (json['isRecurring'] as int?) == 1,
      );
    }).toList();
  }

  Future<void> updateExpense(ExpenseItem item) async {
    final db = await instance.database;
    await db.update(
      'transactions',
      item.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- User Operations ---

  Future<void> setUserName(String userId, String name) async {
    final db = await instance.database;
    await db.insert(
      'users',
      {'id': userId, 'name': name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getUserName(String userId) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (result.isNotEmpty) return result.first['name'] as String?;
    return null;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}