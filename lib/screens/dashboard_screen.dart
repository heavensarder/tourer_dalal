import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourer_dalal/src/config/constants.dart';
import 'package:tourer_dalal/src/config/theme.dart';
import 'package:tourer_dalal/src/models/transaction_model.dart';
import 'package:tourer_dalal/src/providers/app_state.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:intl/intl.dart';
import 'package:tourer_dalal/src/widgets/app_drawer.dart';
import 'package:glassmorphism/glassmorphism.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final GlobalKey _addMemberKey = GlobalKey();
  final GlobalKey _addExpenseKey = GlobalKey();
  final GlobalKey _batchAddKey = GlobalKey();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _refresh().then((_) {
      _animationController.forward();
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.isFirstRun) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ShowCaseWidget.of(
            context,
          ).startShowCase([_addMemberKey, _addExpenseKey, _batchAddKey]);
          appState.setFirstRun(false);
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<AppState>(context, listen: false).loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final size = MediaQuery.of(context).size;

    double totalCollected = 0.0;
    double totalSpent = 0.0;

    for (var transaction in appState.transactions) {
      if (transaction.type == 'deposit') {
        totalCollected += transaction.amount;
      } else if (transaction.type == 'expense') {
        totalSpent += transaction.amount;
      }
    }

    final bool showLowBalanceWarning =
        appState.lowBalanceThreshold != null &&
        appState.currentBalance <= appState.lowBalanceThreshold!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset('assets/images/my_logo.png', height: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Tourer Dalal',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _isLoading ? null : _refresh,
            ),
          ),
        ],
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E21),
              const Color(0xFF1D1E33),
              Colors.deepPurple.shade900.withOpacity(0.3),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.purpleAccent,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                color: Colors.purpleAccent,
                backgroundColor: const Color(0xFF1D1E33),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + kToolbarHeight + 10,
                      20,
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showLowBalanceWarning) ...[
                          _buildLowBalanceWarning(appState, context),
                          const SizedBox(height: 20),
                        ],
                        _buildModernBalanceCard(
                          appState.currentBalance,
                          appState.currencySymbol,
                          size,
                        ),
                        const SizedBox(height: 24),
                        _buildModernSummaryCards(
                          totalCollected,
                          totalSpent,
                          appState.currencySymbol,
                        ),
                        const SizedBox(height: 10),
                        _buildModernQuickActions(context),
                        const SizedBox(height: 10),
                        _buildRecentActivityHeader(context),
                        const SizedBox(height: 16),
                        appState.transactions.isEmpty
                            ? _buildEmptyState()
                            : _buildRecentTransactions(appState, context),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLowBalanceWarning(AppState appState, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade600.withOpacity(0.2),
            Colors.red.shade800.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.shade400.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade400.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.red.shade300,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Low Balance Alert',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Balance is below ${appState.currencySymbol}${appState.lowBalanceThreshold!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBalanceCard(
    double currentBalance,
    String currencySymbol,
    Size size,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade600,
            Colors.deepPurple.shade700,
            Colors.indigo.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade700.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Balance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currencySymbol,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentBalance.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentBalance >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: currentBalance >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currentBalance >= 0 ? 'Healthy' : 'Needs Attention',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSummaryCards(
    double totalCollected,
    double totalSpent,
    String currencySymbol,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Collected',
            totalCollected,
            currencySymbol,
            Icons.arrow_downward_rounded,
            Colors.green.shade400,
            [
              Colors.green.shade600.withOpacity(0.2),
              Colors.green.shade700.withOpacity(0.3),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Total Spent',
            totalSpent,
            currencySymbol,
            Icons.arrow_upward_rounded,
            Colors.red.shade400,
            [
              Colors.red.shade600.withOpacity(0.2),
              Colors.red.shade700.withOpacity(0.3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    String currencySymbol,
    IconData icon,
    Color accentColor,
    List<Color> gradientColors,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              Icon(
                Icons.more_horiz_rounded,
                color: Colors.white.withOpacity(0.4),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencySymbol,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  amount.toStringAsFixed(2),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            Row(
              children: [
                Showcase(
                  key: _addMemberKey,
                  description: 'Add new members to your group here.',
                  child: _buildModernActionButton(
                    context,
                    'Add Member',
                    Icons.person_add_rounded,
                    [Colors.blue.shade400, Colors.blue.shade600],
                    () => Navigator.pushNamed(context, Routes.addMember),
                  ),
                ),
                SizedBox(width: 16),
                _buildModernActionButton(
                  context,
                  'View Members',
                  Icons.groups_rounded,
                  [Colors.teal.shade400, Colors.teal.shade600],
                  () => Navigator.pushNamed(context, Routes.members),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Showcase(
                  key: _addExpenseKey,
                  description: 'Record any group expenses here.',
                  child: _buildModernActionButton(
                    context,
                    'Add Expense',
                    Icons.money_off_rounded,
                    [Colors.orange.shade400, Colors.orange.shade600],
                    () => Navigator.pushNamed(context, Routes.addExpense),
                  ),
                ),
                SizedBox(width: 16),
                Showcase(
                  key: _batchAddKey,
                  description: 'Add contributions to all members at once.',
                  child: _buildModernActionButton(
                    context,
                    'Batch Add',
                    Icons.group_add_rounded,
                    [Colors.purple.shade400, Colors.purple.shade600],
                    () => Navigator.pushNamed(context, Routes.batchAdd),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildModernActionButton(
                  context,
                  'Transactions',
                  Icons.receipt_long_rounded,
                  [Colors.pink.shade400, Colors.pink.shade600],
                  () => Navigator.pushNamed(context, Routes.transactions),
                ),
                SizedBox(width: 16),
                _buildModernActionButton(
                  context,
                  'PDF Report',
                  Icons.picture_as_pdf_rounded,
                  [Colors.indigo.shade400, Colors.indigo.shade600],
                  () => Navigator.pushNamed(context, Routes.pdfReport),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernActionButton(
    BuildContext context,
    String text,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, Routes.transactions),
          child: Text(
            'View All',
            style: TextStyle(
              color: Colors.purpleAccent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            color: Colors.white.withOpacity(0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding members or expenses',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(AppState appState, BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appState.transactions.length > 5
          ? 5
          : appState.transactions.length,
      itemBuilder: (context, index) {
        final transaction = appState.transactions[index];
        String memberName = 'N/A';
        if (transaction.memberId != null) {
          try {
            final member = appState.members.firstWhere(
              (m) => m.id == transaction.memberId,
            );
            memberName = member.name;
          } catch (e) {
            // Member not found
          }
        }

        final bool isDeposit = transaction.type == 'deposit';
        final Color accentColor = isDeposit
            ? Colors.green.shade400
            : Colors.red.shade400;
        final IconData iconData = isDeposit
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1E33).withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: accentColor, size: 22),
            ),
            title: Text(
              transaction.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  memberName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat(
                    'MMM d, HH:mm',
                  ).format(DateTime.parse(transaction.dateTime)),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Text(
              '${isDeposit ? '+' : '-'}${appState.currencySymbol}${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: accentColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
