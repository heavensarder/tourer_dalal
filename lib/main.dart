import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourer_dalal/src/db/db_helper.dart';
import 'package:tourer_dalal/providers/theme_provider.dart';
import 'package:tourer_dalal/screens/dashboard_screen.dart';
import 'package:tourer_dalal/src/config/constants.dart';
import 'package:tourer_dalal/src/config/theme.dart';
import 'package:tourer_dalal/src/providers/app_state.dart';
import 'package:tourer_dalal/src/screens/placeholder_screen.dart';
import 'package:tourer_dalal/src/screens/members_screen.dart';
import 'package:tourer_dalal/src/screens/add_member_screen.dart';
import 'package:tourer_dalal/src/screens/member_detail_screen.dart';
import 'package:tourer_dalal/src/screens/batch_add_screen.dart';
import 'package:tourer_dalal/src/screens/add_expense_screen.dart';
import 'package:tourer_dalal/src/screens/transaction_history_screen.dart';
import 'package:tourer_dalal/src/screens/pdf_report_screen.dart';
import 'package:tourer_dalal/src/screens/settings_screen.dart';
import 'package:showcaseview/showcaseview.dart'; // New import
import 'package:tourer_dalal/src/screens/splash_screen.dart'; // New import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize DB Helper
  await DBHelper().initDB();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ShowCaseWidget(
            builder: (context) => MaterialApp(
              title: 'Tourer Dalal',
              theme: ThemeData(
                primarySwatch: Colors.purple,
                brightness: Brightness.dark, // Set to dark for glassmorphism
              ),
              darkTheme: ThemeData(
                primarySwatch: Colors.purple,
                brightness: Brightness.dark,
              ),
              themeMode: themeProvider.themeMode,
              initialRoute: Routes.splash,
              routes: {
                Routes.splash: (context) => const SplashScreen(),
                Routes.dashboard: (context) => const DashboardScreen(),
                Routes.members: (context) => const MembersScreen(),
                Routes.addMember: (context) => const AddMemberScreen(),
                Routes.memberDetail: (context) {
                  final memberId =
                      ModalRoute.of(context)!.settings.arguments as int;
                  return MemberDetailScreen(memberId: memberId);
                },
                Routes.batchAdd: (context) => const BatchAddScreen(),
                Routes.addExpense: (context) => const AddExpenseScreen(),
                Routes.transactions: (context) =>
                    const TransactionHistoryScreen(),
                Routes.pdfReport: (context) => const PdfReportScreen(),
                Routes.settings: (context) => const SettingsScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}