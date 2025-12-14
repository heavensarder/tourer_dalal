import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initDB();
    return _database!;
  }

  Future<void> initDB() async {
    String path = join(await getDatabasesPath(), 'tourer_dalal.db');
    _database = await openDatabase(
      path,
      version: 2, // Increment version
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            initialContributionPerRound REAL DEFAULT 0.0,
            totalPaid REAL DEFAULT 0.0,
            createdAt TEXT NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            refId INTEGER,
            memberId INTEGER,
            title TEXT,
            amount REAL NOT NULL,
            note TEXT,
            dateTime TEXT NOT NULL
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop existing tables if they exist
        await db.execute('DROP TABLE IF EXISTS members');
        await db.execute('DROP TABLE IF EXISTS transactions');
        // Recreate tables
        await db.execute('''
          CREATE TABLE members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            initialContributionPerRound REAL DEFAULT 0.0,
            totalPaid REAL DEFAULT 0.0,
            createdAt TEXT NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            refId INTEGER,
            memberId INTEGER,
            title TEXT,
            amount REAL NOT NULL,
            note TEXT,
            dateTime TEXT NOT NULL
          );
        ''');
      },
    );
  }

  Future<int> insertMember(Map<String, dynamic> memberData, {double initialAmount = 0.0}) async {
    final db = await database;
    return await db.transaction((txn) async {
      final memberId = await txn.insert('members', {
        ...memberData,
        'totalPaid': initialAmount,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (initialAmount > 0) {
        await txn.insert('transactions', {
          'type': 'deposit',
          'memberId': memberId,
          'title': 'Initial Contribution',
          'amount': initialAmount,
          'note': 'Initial contribution for ${memberData['name']}',
          'dateTime': DateTime.now().toIso8601String(),
        });
      }
      return memberId;
    });
  }

  Future<void> addMemberContribution(int memberId, double amount, {String title = 'Top-up', String note = ''}) async {
    final db = await database;
    await db.transaction((txn) async {
      final member = (await txn.query('members', where: 'id = ?', whereArgs: [memberId])).first;
      final currentTotalPaid = member['totalPaid'] as double;
      
      await txn.update(
        'members',
        {'totalPaid': currentTotalPaid + amount},
        where: 'id = ?',
        whereArgs: [memberId],
      );

      await txn.insert('transactions', {
        'type': 'deposit',
        'memberId': memberId,
        'title': title,
        'amount': amount,
        'note': note,
        'dateTime': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> addBatchContribution(double amountPerMember, {String title = 'Batch add', String note = ''}) async {
    final db = await database;
    await db.transaction((txn) async {
      final members = await txn.query('members');
      for (var member in members) {
        final memberId = member['id'] as int;
        final currentTotalPaid = member['totalPaid'] as double;
        await txn.update(
          'members',
          {'totalPaid': currentTotalPaid + amountPerMember},
          where: 'id = ?',
          whereArgs: [memberId],
        );

        await txn.insert('transactions', {
          'type': 'deposit',
          'memberId': memberId,
          'title': title,
          'amount': amountPerMember,
          'note': note,
          'dateTime': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<int> insertExpense(String title, double amount, {String note = ''}) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.insert('transactions', {
        'type': 'expense',
        'title': title,
        'amount': amount,
        'note': note,
        'dateTime': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> deleteTransaction(int transactionId) async {
    final db = await database;
    await db.transaction((txn) async {
      final transaction = (await txn.query('transactions', where: 'id = ?', whereArgs: [transactionId])).first;
      if (transaction == null) {
        throw Exception('Transaction not found');
      }

      final String type = transaction['type'] as String;
      final double amount = transaction['amount'] as double;
      final int? memberId = transaction['memberId'] as int?;

      if (type == 'deposit' && memberId != null) {
        final member = (await txn.query('members', where: 'id = ?', whereArgs: [memberId])).first;
        if (member != null) {
          final currentTotalPaid = member['totalPaid'] as double;
          await txn.update(
            'members',
            {'totalPaid': currentTotalPaid - amount},
            where: 'id = ?',
            whereArgs: [memberId],
          );
        }
      }

      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('members');
      await txn.delete('transactions');
    });
  }

  Future<void> deleteMember(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'members',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<Map<String, dynamic>>> getMembersRaw() async {
    final db = await database;
    return await db.query('members');
  }

  Future<List<Map<String, dynamic>>> getTransactionsRaw({String? typeFilter}) async {
    final db = await database;
    if (typeFilter != null) {
      return await db.query('transactions', where: 'type = ?', whereArgs: [typeFilter], orderBy: 'dateTime DESC');
    } else {
      return await db.query('transactions', orderBy: 'dateTime DESC');
    }
  }

  Future<double> getCurrentBalance() async {
    final db = await database;
    final deposits = await db.rawQuery("SELECT SUM(amount) as total FROM transactions WHERE type = 'deposit'");
    final expenses = await db.rawQuery("SELECT SUM(amount) as total FROM transactions WHERE type = 'expense'");

    final totalDeposits = (deposits.first['total'] as num?)?.toDouble() ?? 0.0;
    final totalExpenses = (expenses.first['total'] as num?)?.toDouble() ?? 0.0;

    return totalDeposits - totalExpenses;
  }

  Future<Map<String, dynamic>?> getMemberById(int id) async {
    final db = await database;
    final results = await db.query('members', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }
}