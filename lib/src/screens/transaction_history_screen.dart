import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourer_dalal/src/config/theme.dart';
import 'package:tourer_dalal/src/models/member.dart';
import 'package:tourer_dalal/src/models/transaction_model.dart';
import 'package:tourer_dalal/src/providers/app_state.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // New import

enum TransactionFilter { all, deposits, expenses }

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  TransactionFilter _currentFilter = TransactionFilter.all;

  List<TransactionModel> _getFilteredTransactions(AppState appState) {
    switch (_currentFilter) {
      case TransactionFilter.deposits:
        return appState.transactions.where((t) => t.type == 'deposit').toList();
      case TransactionFilter.expenses:
        return appState.transactions.where((t) => t.type == 'expense').toList();
      case TransactionFilter.all:
      default:
        return appState.transactions;
    }
  }

  Future<void> _showTransactionDetailDialog(BuildContext context, TransactionModel transaction, AppState appState) async {
    Member? member;
    if (transaction.memberId != null) {
      try {
        member = appState.members.firstWhere((m) => m.id == transaction.memberId);
      } catch (e) {
        member = null; // Member not found
      }
    }

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(transaction.title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Type: ${transaction.type == 'deposit' ? 'Deposit' : 'Expense'}'),
                if (member != null) Text('Member: ${member.name}'),
                Text('Amount: ${appState.currencySymbol}${transaction.amount.toStringAsFixed(2)}'),
                Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(transaction.dateTime))}'),
                if (transaction.note != null && transaction.note!.isNotEmpty) Text('Note: ${transaction.note}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            if (appState.allowDeletingTransactions) // Conditional delete button
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
                onPressed: () async {
                  final bool? confirmDelete = await showDialog<bool>(
                    context: dialogContext,
                    builder: (BuildContext confirmContext) {
                      return AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(confirmContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(confirmContext).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmDelete == true) {
                    try {
                      await appState.deleteTransaction(transaction.id);
                      if (mounted) {
                        Navigator.of(dialogContext).pop(); // Close detail dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction deleted successfully!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete transaction: $e')),
                        );
                      }
                    }
                  }
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final List<TransactionModel> filteredTransactions = _getFilteredTransactions(appState);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(kSpacingXS),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _currentFilter == TransactionFilter.all,
                      onSelected: (selected) {
                        if (selected) setState(() => _currentFilter = TransactionFilter.all);
                      },
                    ),
                    FilterChip(
                      label: const Text('Deposits'),
                      selected: _currentFilter == TransactionFilter.deposits,
                      onSelected: (selected) {
                        if (selected) setState(() => _currentFilter = TransactionFilter.deposits);
                      },
                    ),
                    FilterChip(
                      label: const Text('Expenses'),
                      selected: _currentFilter == TransactionFilter.expenses,
                      onSelected: (selected) {
                        if (selected) setState(() => _currentFilter = TransactionFilter.expenses);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredTransactions.isEmpty
                    ? const Center(child: Text('No transactions found.'))
                    : ListView.builder(
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          Member? member;
                          if (transaction.memberId != null) {
                            try {
                              member = appState.members.firstWhere((m) => m.id == transaction.memberId);
                            } catch (e) {
                              member = null; // Member not found
                            }
                          }

                          final bool isDeposit = transaction.type == 'deposit';
                          final Color amountColor = isDeposit ? Colors.green : Colors.red;
                          final IconData icon = isDeposit ? Icons.arrow_circle_up : Icons.arrow_circle_down;

                          return Slidable(
                            key: ValueKey(transaction.id),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              children: [
                                if (appState.allowDeletingTransactions)
                                  SlidableAction(
                                    onPressed: (context) => _showTransactionDetailDialog(context, transaction, appState), // Re-use dialog for delete confirmation
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,
                                    label: 'Delete',
                                  ),
                              ],
                            ),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: kSpacingXXS, horizontal: kSpacingXS),
                              child: ListTile(
                                leading: Icon(icon, color: amountColor),
                                title: Text(transaction.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (member != null) Text('Member: ${member.name}'),
                                    Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(transaction.dateTime))),
                                  ],
                                ),
                                trailing: Text(
                                  '${isDeposit ? '+' : '-'}${appState.currencySymbol}${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
                                ),
                                onTap: () => _showTransactionDetailDialog(context, transaction, appState),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
