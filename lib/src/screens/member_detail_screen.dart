import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourer_dalal/src/config/theme.dart';
import 'package:tourer_dalal/src/models/member.dart';
import 'package:tourer_dalal/src/models/transaction_model.dart';
import 'package:tourer_dalal/src/providers/app_state.dart';
import 'package:tourer_dalal/src/widgets/top_up_dialog.dart';
import 'package:intl/intl.dart'; // Import for DateFormat

class MemberDetailScreen extends StatelessWidget {
  final int memberId;

  const MemberDetailScreen({super.key, required this.memberId});

  void _showTopUpDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TopUpDialog(memberId: member.id, memberName: member.name);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Details'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          Member? member;
          try {
            member = appState.members.firstWhere((m) => m.id == memberId);
          } catch (e) {
            member = null; // Member not found
          }

          if (member == null) {
            return const Center(child: Text('Member not found.'));
          }

          final List<TransactionModel> memberTransactions = appState.transactions
              .where((t) => t.memberId == memberId)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(kSpacingS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(kSpacingS),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name, style: Theme.of(context).textTheme.headlineMedium),
                        SizedBox(height: kSpacingXS),
                        Text('Total Paid: \৳${member.totalPaid.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(height: kSpacingXS),
                        Text('Initial Contribution Per Round: \\৳$${member.initialContributionPerRound.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                        Text('Joined: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(member.createdAt))}', style: Theme.of(context).textTheme.bodySmall),
                        SizedBox(height: kSpacingS),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: member != null ? () => _showTopUpDialog(context, member!) : null,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Top Up'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: kSpacingM),
                Text('Transactions', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: kSpacingXS),
                if (memberTransactions.isEmpty)
                  const Text('No transactions for this member yet.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: memberTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = memberTransactions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: kSpacingXXS),
                        child: ListTile(
                          leading: Icon(
                            transaction.type == 'deposit' ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                            color: transaction.type == 'deposit' ? Colors.green : Colors.red,
                          ),
                          title: Text(transaction.title),
                          subtitle: Text(
                            '${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(transaction.dateTime))}'
                            '${transaction.note != null && transaction.note!.isNotEmpty ? '\n${transaction.note}' : ''}',
                          ),
                          trailing: Text(
                            '${transaction.type == 'deposit' ? '+' : '-'}\৳${transaction.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: transaction.type == 'deposit' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}