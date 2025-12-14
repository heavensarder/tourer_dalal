import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:tourer_dalal/src/config/theme.dart';
import 'package:tourer_dalal/src/models/member.dart';
import 'package:tourer_dalal/src/models/transaction_model.dart';
import 'package:tourer_dalal/src/providers/app_state.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show Uint8List;

// Helper function to generate the PDF document
Future<Uint8List> createReportPdf(
  PdfPageFormat format,
  List<Member> members,
  List<TransactionModel> transactions,
  double currentBalance,
) async {
  final pdf = pw.Document();

  // Helper to format currency
  String formatCurrency(double amount) => 'BDT ${amount.toStringAsFixed(2)}';

  // Calculate total deposits and expenses from transactions
  double totalDeposits = 0.0;
  double totalExpenses = 0.0;
  for (var transaction in transactions) {
    if (transaction.type == 'deposit') {
      totalDeposits += transaction.amount;
    } else if (transaction.type == 'expense') {
      totalExpenses += transaction.amount;
    }
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: format,
      build: (pw.Context context) {
        return [
          pw.Center(
            child: pw.Text(
              'Tourer Dalal Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Report Timestamp: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
          pw.SizedBox(height: 20),

          // Summary
          pw.Header(level: 1, child: pw.Text('Summary')),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Deposits:'),
              pw.Text(formatCurrency(totalDeposits)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Expenses:'),
              pw.Text(formatCurrency(totalExpenses)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Current Balance:'),
              pw.Text(formatCurrency(currentBalance)),
            ],
          ),
          pw.SizedBox(height: 20),

          // Members
          pw.Header(level: 1, child: pw.Text('Members')),
          pw.Divider(),
          pw.Table.fromTextArray(
            headers: ['Name', 'Total Paid'],
            data: members.map((member) => [
              member.name,
              formatCurrency(member.totalPaid),
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(5),
          ),
          pw.SizedBox(height: 20),

          // Transactions
          pw.Header(level: 1, child: pw.Text('Transactions')),
          pw.Divider(),
          pw.Table.fromTextArray(
            headers: ['Date', 'Type', 'Title', 'Member', 'Amount'],
            data: transactions.map((transaction) {
              Member? member;
              if (transaction.memberId != null) {
                try {
                  member = members.firstWhere((m) => m.id == transaction.memberId);
                } catch (e) {
                  member = null; // Member not found
                }
              }
              return [
                DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(transaction.dateTime)),
                transaction.type,
                transaction.title,
                member?.name ?? 'N/A',
                '${transaction.type == 'deposit' ? '+' : '-'}${formatCurrency(transaction.amount)}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(5),
          ),
        ];
      },
    ),
  );

  return pdf.save();
}

class PdfReportScreen extends StatelessWidget {
  const PdfReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Report'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          // Ensure data is loaded before generating report
          if (appState.members.isEmpty && appState.transactions.isEmpty && appState.currentBalance == 0.0) {
            return const Center(child: Text('No data available to generate report.'));
          }

          return PdfPreview(
            build: (format) => createReportPdf(
              format,
              appState.members,
              appState.transactions,
              appState.currentBalance,
            ),
            allowPrinting: true,
            allowSharing: true,
            canChangePageFormat: false,
            canChangeOrientation: false,
            maxPageWidth: 700,
          );
        },
      ),
    );
  }
}