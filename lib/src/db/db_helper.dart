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

  Future<int> insertMember(Map<String, dynamic> memberData, {double initialAmount = 0.0, int? id}) async {
    final db = await database;
    return await db.transaction((txn) async {
      final memberId = await txn.insert('members', {
        if (id != null) 'id': id,
        ...memberData,
        'totalPaid': initialAmount,
        'createdAt': memberData['createdAt'] ?? DateTime.now().toIso8601String(),
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

  Future<int> addMemberContribution(int memberId, double amount, {String title = 'Top-up', String note = '', int? transactionId}) async {
    final db = await database;
    return await db.transaction((txn) async {
      final member = (await txn.query('members', where: 'id = ?', whereArgs: [memberId])).first;
      final currentTotalPaid = member['totalPaid'] as double;
      
      await txn.update(
        'members',
        {'totalPaid': currentTotalPaid + amount},
        where: 'id = ?',
        whereArgs: [memberId],
      );

      return await txn.insert('transactions', {
        if (transactionId != null) 'id': transactionId,
        'type': 'deposit',
        'memberId': memberId,
        'title': title,
        'amount': amount,
        'note': note,
        'dateTime': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<List<int>> addBatchContribution(double amountPerMember, {String title = 'Batch add', String note = ''}) async {
    final db = await database;
    return await db.transaction((txn) async {
      final members = await txn.query('members');
      List<int> transactionIds = [];
      for (var member in members) {
        final memberId = member['id'] as int;
        final currentTotalPaid = member['totalPaid'] as double;
        await txn.update(
          'members',
          {'totalPaid': currentTotalPaid + amountPerMember},
          where: 'id = ?',
          whereArgs: [memberId],
        );

        final id = await txn.insert('transactions', {
          'type': 'deposit',
          'memberId': memberId,
          'title': title,
          'amount': amountPerMember,
          'note': note,
          'dateTime': DateTime.now().toIso8601String(),
        });
        transactionIds.add(id);
      }
      return transactionIds;
    });
  }

  Future<int> insertExpense(String title, double amount, {String note = '', int? id}) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.insert('transactions', {
        if (id != null) 'id': id,
        'type': 'expense',
        'title': title,
        'amount': amount,
        'note': note,
        'dateTime': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> restoreTransaction(Map<String, dynamic> transactionData) async {
     final db = await database;
     await db.transaction((txn) async {
        final type = transactionData['type'];
        final amount = transactionData['amount'];
        final memberId = transactionData['memberId'];

        if (type == 'deposit' && memberId != null) {
          final member = (await txn.query('members', where: 'id = ?', whereArgs: [memberId])).firstOrNull;
          if (member != null) {
             final currentTotalPaid = member['totalPaid'] as double;
             await txn.update(
              'members',
              {'totalPaid': currentTotalPaid + amount},
              where: 'id = ?',
              whereArgs: [memberId],
            );
          }
        }
        
        await txn.insert('transactions', transactionData);
     });
  }

  Future<Map<String, dynamic>> deleteTransaction(int transactionId) async {
    final db = await database;
    return await db.transaction((txn) async {
      final transaction = (await txn.query('transactions', where: 'id = ?', whereArgs: [transactionId])).first;

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
      
      return transaction;
    });
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('members');
      await txn.delete('transactions');
    });
  }

  Future<Map<String, dynamic>> deleteMember(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      final member = (await txn.query('members', where: 'id = ?', whereArgs: [id])).first;
       await txn.delete(
        'members',
        where: 'id = ?',
        whereArgs: [id],
      );
      return member;
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