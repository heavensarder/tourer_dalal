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
  String currencySymbol,
) async {
  final pdf = pw.Document();

  // Load app logo
  final logoImage = await imageFromAssetBundle('assets/images/my_logo.png');

  // Helper to format currency - hardcoded to BDT
  String formatCurrency(double amount) => 'BDT ${amount.toStringAsFixed(2)}';

  // Reverse transactions to show oldest first (first input on top)
  final reversedTransactions = transactions.reversed.toList();

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

  // Calculate total paid by all members
  double totalMembersPaid = members.fold(0.0, (sum, member) => sum + member.totalPaid);

  // Define grayscale colors
  final black = PdfColors.black;
  final darkGray = PdfColors.grey800;
  final mediumGray = PdfColors.grey600;
  final lightGray = PdfColors.grey300;
  final veryLightGray = PdfColors.grey100;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: black, width: 2),
            ),
          ),
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: black, width: 2),
                    ),
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Image(logoImage),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Tourer Dalal',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: black,
                        ),
                      ),
                      pw.Text(
                        'Financial Report',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: darkGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Generated',
                    style: pw.TextStyle(fontSize: 10, color: mediumGray),
                  ),
                  pw.Text(
                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: black,
                    ),
                  ),
                  pw.Text(
                    DateFormat('HH:mm').format(DateTime.now()),
                    style: pw.TextStyle(fontSize: 10, color: mediumGray),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      footer: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: lightGray, width: 1),
            ),
          ),
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Tourer Dalal © ${DateTime.now().year}',
                style: pw.TextStyle(fontSize: 9, color: mediumGray),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: mediumGray),
              ),
            ],
          ),
        );
      },
      build: (pw.Context context) {
        return [
          // Summary Section
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Financial Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: black,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    // Current Balance Card
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: darkGray,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Current Balance',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              formatCurrency(currentBalance),
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    // Total Deposits Card
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: veryLightGray,
                          borderRadius: pw.BorderRadius.circular(12),
                          border: pw.Border.all(color: mediumGray, width: 1.5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Total Deposits',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: darkGray,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              formatCurrency(totalDeposits),
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    // Total Expenses Card
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: veryLightGray,
                          borderRadius: pw.BorderRadius.circular(12),
                          border: pw.Border.all(color: mediumGray, width: 1.5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Total Expenses',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: darkGray,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              formatCurrency(totalExpenses),
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Members Section
          if (members.isNotEmpty) ...[
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                'Members Overview',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: black,
                ),
              ),
            ),
            pw.Table(
              border: pw.TableBorder.all(color: mediumGray, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(50),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: darkGray),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '#',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Member Name',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Total Paid',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 11,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                // Data rows
                ...members.asMap().entries.map((entry) {
                  final index = entry.key;
                  final member = entry.value;
                  final isEven = index % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? veryLightGray : PdfColors.white,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${index + 1}',
                          style: pw.TextStyle(fontSize: 10, color: black),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          member.name,
                          style: pw.TextStyle(fontSize: 10, color: black),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          formatCurrency(member.totalPaid),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: black,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
                // Total row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: mediumGray),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'TOTAL',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        formatCurrency(totalMembersPaid),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 11,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
          ],

          // Transactions Section
          if (transactions.isNotEmpty) ...[
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                'Transaction History',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: black,
                ),
              ),
            ),
            pw.Table(
              border: pw.TableBorder.all(color: mediumGray, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FixedColumnWidth(70),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FixedColumnWidth(80),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: darkGray),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Date & Time',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Type',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Title',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Member',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Amount',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                // Data rows
                ...reversedTransactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final transaction = entry.value;
                  final isEven = index % 2 == 0;
                  final isDeposit = transaction.type == 'deposit';
                  
                  Member? member;
                  if (transaction.memberId != null) {
                    try {
                      member = members.firstWhere((m) => m.id == transaction.memberId);
                    } catch (e) {
                      member = null;
                    }
                  }

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? veryLightGray : PdfColors.white,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              DateFormat('dd MMM yyyy').format(DateTime.parse(transaction.dateTime)),
                              style: pw.TextStyle(fontSize: 9, color: black),
                            ),
                            pw.Text(
                              DateFormat('HH:mm').format(DateTime.parse(transaction.dateTime)),
                              style: pw.TextStyle(fontSize: 8, color: mediumGray),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: darkGray, width: 1),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            isDeposit ? 'Deposit' : 'Expense',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: black,
                            ),
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          transaction.title,
                          style: pw.TextStyle(fontSize: 9, color: black),
                          maxLines: 2,
                          overflow: pw.TextOverflow.clip,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          member?.name ?? 'N/A',
                          style: pw.TextStyle(fontSize: 9, color: black),
                          maxLines: 2,
                          overflow: pw.TextOverflow.clip,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${isDeposit ? '+' : '-'}${formatCurrency(transaction.amount)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: black,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
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
              appState.currencySymbol,
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