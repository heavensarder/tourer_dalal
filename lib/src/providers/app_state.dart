import 'package:flutter/material.dart';
import 'package:tourer_dalal/src/db/db_helper.dart';
import 'package:tourer_dalal/src/models/member.dart';
import 'package:tourer_dalal/src/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart'; // New import
import 'package:tourer_dalal/src/config/constants.dart'; // New import

class AppState extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  List<Member> _members = [];
  List<TransactionModel> _transactions = [];
  double _currentBalance = 0.0;

  // New settings fields
  String _currencySymbol = '৳'; // Default to Bangladeshi Taka symbol
  double? _lowBalanceThreshold;
  bool _allowDeletingTransactions = false;
  bool _isFirstRun = true; // Default to true

  List<Member> get members => _members;
  List<TransactionModel> get transactions => _transactions;
  double get currentBalance => _currentBalance;

  // Getters for new settings
  String get currencySymbol => _currencySymbol;
  double? get lowBalanceThreshold => _lowBalanceThreshold;
  bool get allowDeletingTransactions => _allowDeletingTransactions;
  bool get isFirstRun => _isFirstRun;

  Future<void> loadAll() async {
    try {
      // Load settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _currencySymbol = prefs.getString(AppSettingsKeys.currencySymbol) ?? '৳';
      _lowBalanceThreshold = prefs.getDouble(AppSettingsKeys.lowBalanceThreshold);
      _allowDeletingTransactions = prefs.getBool(AppSettingsKeys.allowDeletingTransactions) ?? false;
      _isFirstRun = prefs.getBool(AppSettingsKeys.isFirstRun) ?? true; // Load isFirstRun

      await reloadMembers();
      await reloadTransactions();
      _currentBalance = await _dbHelper.getCurrentBalance();
      notifyListeners();
    } catch (e) {
      // In a real app, you'd want to log this error
      debugPrint('Failed to load data: $e');
      throw Exception('Failed to load data: $e');
    }
  }

  Function? _lastUndoAction;

  // Method to trigger undo
  Future<void> undoLastAction() async {
    if (_lastUndoAction != null) {
      await _lastUndoAction!();
      _lastUndoAction = null; // Clear after undoing
      notifyListeners();
    }
  }

  Future<void> addMember(String name, {double initialAmount = 0.0, double initialContributionPerRound = 0.0}) async {
    try {
      final memberData = {
        'name': name,
        'initialContributionPerRound': initialContributionPerRound,
      };
      final newMemberId = await _dbHelper.insertMember(memberData, initialAmount: initialAmount);
      
      _lastUndoAction = () async {
        await deleteMember(newMemberId, isUndo: true);
      };
      
      await loadAll(); // Reload all data to reflect changes
    } catch (e) {
      debugPrint('Failed to add member: $e');
      throw Exception('Failed to add member: $e');
    }
  }

  Future<void> topUpMember(int memberId, double amount, {String note = ''}) async {
    try {
      final newTransId = await _dbHelper.addMemberContribution(memberId, amount, note: note);
      
      _lastUndoAction = () async {
        await deleteTransaction(newTransId, isUndo: true);
      };
      
      await loadAll();
    } catch (e) {
      debugPrint('Failed to top up member: $e');
      throw Exception('Failed to top up member: $e');
    }
  }

  Future<void> batchAdd(double amountPerMember, {String note = ''}) async {
    try {
      final newTransIds = await _dbHelper.addBatchContribution(amountPerMember, note: note);
      
      _lastUndoAction = () async {
        for (var id in newTransIds) {
          try {
             await _dbHelper.deleteTransaction(id);
          } catch(e) {
            // ignore if already deleted
          }
        }
        await loadAll();
      };
      
      await loadAll();
    } catch (e) {
      debugPrint('Failed to perform batch add: $e');
      throw Exception('Failed to perform batch add: $e');
    }
  }

  Future<void> addExpense(String title, double amount, {String note = ''}) async {
    try {
      final newTransId = await _dbHelper.insertExpense(title, amount, note: note);
      
      _lastUndoAction = () async {
         await deleteTransaction(newTransId, isUndo: true);
      };
      await loadAll();
    } catch (e) {
      debugPrint('Failed to add expense: $e');
      throw Exception('Failed to add expense: $e');
    }
  }

  Future<void> deleteTransaction(int transactionId, {bool isUndo = false}) async {
    try {
      final deletedData = await _dbHelper.deleteTransaction(transactionId);
      
      if (!isUndo) {
        _lastUndoAction = () async {
           await _dbHelper.restoreTransaction(deletedData);
           await loadAll();
        };
      }
      
      await loadAll();
    } catch (e) {
      debugPrint('Failed to delete transaction: $e');
      throw Exception('Failed to delete transaction: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      await _dbHelper.clearAllData();
      _lastUndoAction = null; 
      await loadAll();
    } catch (e) {
      debugPrint('Failed to clear all data: $e');
      throw Exception('Failed to clear all data: $e');
    }
  }

  Future<void> deleteMember(int id, {bool isUndo = false}) async {
    try {
      final deletedMemberData = await _dbHelper.deleteMember(id);
      
      if (!isUndo) {
        _lastUndoAction = () async {
           await _dbHelper.insertMember(deletedMemberData, id: id);
           await loadAll();
        };
      }
      await loadAll();
    } catch (e) {
      debugPrint('Failed to delete member: $e');
      throw Exception('Failed to delete member: $e');
    }
  }

  Future<void> reloadMembers() async {
    try {
      final memberMaps = await _dbHelper.getMembersRaw();
      _members = memberMaps.map((map) => Member.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reload members: $e');
      throw Exception('Failed to reload members: $e');
    }
  }

  Future<void> reloadTransactions() async {
    try {
      final transactionMaps = await _dbHelper.getTransactionsRaw();
      _transactions = transactionMaps.map((map) => TransactionModel.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reload transactions: $e');
      throw Exception('Failed to reload transactions: $e');
    }
  }

  // New methods to update settings
  Future<void> setCurrencySymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppSettingsKeys.currencySymbol, symbol);
    _currencySymbol = symbol;
    notifyListeners();
  }

  Future<void> setLowBalanceThreshold(double? threshold) async {
    final prefs = await SharedPreferences.getInstance();
    if (threshold == null) {
      await prefs.remove(AppSettingsKeys.lowBalanceThreshold);
    } else {
      await prefs.setDouble(AppSettingsKeys.lowBalanceThreshold, threshold);
    }
    _lowBalanceThreshold = threshold;
    notifyListeners();
  }

  Future<void> setAllowDeletingTransactions(bool allow) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppSettingsKeys.allowDeletingTransactions, allow);
    _allowDeletingTransactions = allow;
    notifyListeners();
  }

  Future<void> setFirstRun(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppSettingsKeys.isFirstRun, value);
    _isFirstRun = value;
    notifyListeners();
  }
}
