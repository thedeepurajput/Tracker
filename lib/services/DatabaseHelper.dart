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
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      // Ensure directory exists
      final directory = Directory(dirname(path));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      return await openDatabase(
        path,
        version: 5, // Increased version for adding customCategoryId column
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onOpen: (db) async {
          // Enable foreign keys
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      print('Database initialization error: $e');
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    // Create transactions table without description
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        transactionType TEXT NOT NULL DEFAULT 'expense',
        incomeCategory TEXT,
        customCategoryId TEXT
      )
    ''');

    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from old 'expenses' table to new 'transactions' table
      try {
        final tables = await db.query(
          'sqlite_master',
          where: 'type = ? AND name = ?',
          whereArgs: ['table', 'expenses'],
        );

        if (tables.isNotEmpty) {
          // Create new transactions table without description
          await db.execute('''
            CREATE TABLE transactions (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              category TEXT NOT NULL,
              date TEXT NOT NULL,
              paymentMethod TEXT NOT NULL,
              isRecurring INTEGER NOT NULL DEFAULT 0,
              transactionType TEXT NOT NULL DEFAULT 'expense',
              incomeCategory TEXT
            )
          ''');

          // Migrate data from expenses to transactions
          final oldExpenses = await db.query('expenses');
          for (final expense in oldExpenses) {
            await db.insert('transactions', {
              'id': expense['id'],
              'title': expense['title'],
              'amount': expense['amount'],
              'category': expense['category'],
              'date': expense['date'],
              'paymentMethod': expense['paymentMethod'],
              'isRecurring': expense['isRecurring'],
              'transactionType': 'expense',
              'incomeCategory': null,
            });
          }

          // Drop old table
          await db.execute('DROP TABLE expenses');
        } else {
          // Fresh installation, just create the new table
          await _createDB(db, newVersion);
        }
      } catch (e) {
        print('Database upgrade error for version 2: $e');
        await _createDB(db, newVersion);
      }
    }

    if (oldVersion < 3) {
      // Add users table for version 3
      try {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL
          )
        ''');
      } catch (e) {
        print('Database upgrade error for version 3: $e');
        await _createDB(db, newVersion);
      }
    }

    if (oldVersion < 4) {
      // Migration to remove description column for version 4
      try {
        // Create a new table without description
        await db.execute('''
          CREATE TABLE transactions_new (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            paymentMethod TEXT NOT NULL,
            isRecurring INTEGER NOT NULL DEFAULT 0,
            transactionType TEXT NOT NULL DEFAULT 'expense',
            incomeCategory TEXT
          )
        ''');

        // Migrate data to new table
        await db.execute('''
          INSERT INTO transactions_new (
            id, title, amount, category, date, paymentMethod, isRecurring, transactionType, incomeCategory
          )
          SELECT id, title, amount, category, date, paymentMethod, isRecurring, transactionType, incomeCategory
          FROM transactions
        ''');

        // Drop old table and rename new one
        await db.execute('DROP TABLE transactions');
        await db.execute('ALTER TABLE transactions_new RENAME TO transactions');
      } catch (e) {
        print('Database upgrade error for version 4: $e');
        await _createDB(db, newVersion);
      }
    }

    if (oldVersion < 5) {
      // Add customCategoryId column for version 5
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN customCategoryId TEXT');
      } catch (e) {
        print('Database upgrade error for version 5: $e');
        await _createDB(db, newVersion);
      }
    }
  }

  // Method to set or update user name
  Future<void> setUserName(String userId, String name) async {
    try {
      final db = await instance.database;

      // Validate name
      if (name.trim().isEmpty) {
        throw Exception('User name cannot be empty');
      }

      // Check if user exists
      final existingUser = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (existingUser.isNotEmpty) {
        // Update existing user
        await db.update(
          'users',
          {'name': name},
          where: 'id = ?',
          whereArgs: [userId],
        );
      } else {
        // Insert new user
        await db.insert(
          'users',
          {
            'id': userId,
            'name': name,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      print('Set user name error: $e');
      rethrow;
    }
  }

  // Method to get user name
  Future<String?> getUserName(String userId) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (result.isNotEmpty) {
        return result.first['name'] as String?;
      }
      return null;
    } catch (e) {
      print('Get user name error: $e');
      return null;
    }
  }

  Future<void> insertTransaction(ExpenseItem transaction) async {
    try {
      final db = await instance.database;

      // Determine transaction type and category
      final isIncome = transaction.amount < 0;
      final transactionType = isIncome ? 'income' : 'expense';

      await db.insert(
        'transactions',
        {
          'id': transaction.id,
          'title': transaction.title,
          'amount': transaction.amount,
          'category': transaction.category.toString().split('.').last,
          'date': transaction.date.toIso8601String(),
          'paymentMethod': transaction.paymentMethod.toString().split('.').last,
          'isRecurring': transaction.isRecurring ? 1 : 0,
          'transactionType': transactionType,
          'incomeCategory': isIncome ? _getIncomeCategoryFromTitle(transaction.title) : null,
          'customCategoryId': transaction.customCategoryId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Insert transaction error: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<void> insertExpense(ExpenseItem expense) async {
    await insertTransaction(expense);
  }

  Future<List<ExpenseItem>> getAllTransactions() async {
    try {
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
          description: '',
          customCategoryId: json['customCategoryId'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Get all transactions error: $e');
      return [];
    }
  }

  // Legacy method for backward compatibility
  Future<List<ExpenseItem>> getAllExpenses() async {
    return await getAllTransactions();
  }

  Future<List<ExpenseItem>> getExpensesOnly() async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'transactions',
        where: 'amount > 0',
        orderBy: 'date DESC',
      );

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
          description: '',
          customCategoryId: json['customCategoryId'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Get expenses only error: $e');
      return [];
    }
  }

  Future<List<ExpenseItem>> getIncomeOnly() async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'transactions',
        where: 'amount < 0',
        orderBy: 'date DESC',
      );

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
          description: '',
          customCategoryId: json['customCategoryId'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Get income only error: $e');
      return [];
    }
  }

  Future<Map<String, double>> getFinancialSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await instance.database;
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (startDate != null) {
        whereClause += ' AND date >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClause += ' AND date <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.query(
        'transactions',
        where: whereClause,
        whereArgs: whereArgs,
      );

      double totalIncome = 0.0;
      double totalExpenses = 0.0;

      for (final transaction in result) {
        final amount = (transaction['amount'] is num ? transaction['amount'] as num : 0.0).toDouble();
        if (amount < 0) {
          totalIncome += amount.abs();
        } else {
          totalExpenses += amount;
        }
      }

      return {
        'income': totalIncome,
        'expenses': totalExpenses,
        'balance': totalIncome - totalExpenses,
      };
    } catch (e) {
      print('Get financial summary error: $e');
      return {'income': 0.0, 'expenses': 0.0, 'balance': 0.0};
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final db = await instance.database;
      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Delete transaction error: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<void> deleteExpense(String id) async {
    await deleteTransaction(id);
  }

  Future<void> updateTransaction(ExpenseItem transaction) async {
    try {
      final db = await instance.database;

      final isIncome = transaction.amount < 0;
      final transactionType = isIncome ? 'income' : 'expense';

      await db.update(
        'transactions',
        {
          'title': transaction.title,
          'amount': transaction.amount,
          'category': transaction.category.name,
          'date': transaction.date.toIso8601String(),
          'paymentMethod': transaction.paymentMethod.name,
          'isRecurring': transaction.isRecurring ? 1 : 0,
          'transactionType': transactionType,
          'incomeCategory': isIncome ? _getIncomeCategoryFromTitle(transaction.title) : null,
        },
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    } catch (e) {
      print('Update transaction error: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<void> updateExpense(ExpenseItem expense) async {
    await updateTransaction(expense);
  }

  // Helper method to determine income category from title
  String? _getIncomeCategoryFromTitle(String title) {
    final titleLower = title.toLowerCase();

    if (titleLower.contains('salary') || titleLower.contains('wage')) {
      return 'salary';
    } else if (titleLower.contains('business') || titleLower.contains('profit')) {
      return 'business';
    } else if (titleLower.contains('freelance') || titleLower.contains('contract')) {
      return 'freelance';
    } else if (titleLower.contains('investment') || titleLower.contains('dividend') || titleLower.contains('interest')) {
      return 'investment';
    } else if (titleLower.contains('bonus') || titleLower.contains('incentive')) {
      return 'bonus';
    } else if (titleLower.contains('gift') || titleLower.contains('present')) {
      return 'gift';
    }

    return 'other';
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Utility method to get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await instance.database;

      final totalTransactions = await db.rawQuery('SELECT COUNT(*) as count FROM transactions');
      final totalExpenses = await db.rawQuery('SELECT COUNT(*) as count FROM transactions WHERE amount > 0');
      final totalIncome = await db.rawQuery('SELECT COUNT(*) as count FROM transactions WHERE amount < 0');
      final totalUsers = await db.rawQuery('SELECT COUNT(*) as count FROM users');

      return {
        'total': totalTransactions.first['count'] as int,
        'expenses': totalExpenses.first['count'] as int,
        'income': totalIncome.first['count'] as int,
        'users': totalUsers.first['count'] as int,
      };
    } catch (e) {
      print('Get database stats error: $e');
      return {'total': 0, 'expenses': 0, 'income': 0, 'users': 0};
    }
  }
}