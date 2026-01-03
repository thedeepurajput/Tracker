import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/DatabaseHelper.dart';
import '../services/download.dart';
import './add_expense.dart';
import './expense_detail.dart';
import './model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title, required this.userName});
  final String title;
  final String userName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ExpenseItem> _allTransactions = [];
  List<ExpenseItem> _currentMonthTransactions = [];
  bool _isLoading = true;
  String _userName = '';
  String? _profileImagePath;
  static const String _defaultUserId = 'user_1';

  DateTime _selectedMonth = DateTime.now();
  double _openingBalance = 0.0;
  double _closingBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _loadTransactions();
  }

  void _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final dbUserName = await ExpenseDatabase.instance.getUserName(_defaultUserId);
    final imagePath = prefs.getString('user_profile_image');

    setState(() {
      _userName = (dbUserName != null && dbUserName.isNotEmpty)
          ? dbUserName
          : (widget.userName.isNotEmpty ? widget.userName : 'User');
      _profileImagePath = imagePath;
    });
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await ExpenseDatabase.instance.getAllTransactions();
      setState(() {
        _allTransactions = transactions;
        _calculateBankStatementLogic();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateBankStatementLogic() {
    _currentMonthTransactions = _allTransactions.where((t) {
      return t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month;
    }).toList();

    final firstDayOfSelectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);

    _openingBalance = _allTransactions
        .where((t) => t.date.isBefore(firstDayOfSelectedMonth))
        .fold(0.0, (sum, t) => sum + t.amount);

    _closingBalance = _openingBalance + _totalIncome - _totalExpense;
  }

  void _changeMonth(int monthsToAdd) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + monthsToAdd);
      _calculateBankStatementLogic();
    });
  }

  double get _totalIncome => _currentMonthTransactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.displayAmount);

  double get _totalExpense => _currentMonthTransactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.displayAmount);

  void _showAddTransactionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransaction(
        selectedDate: DateTime.now(),
        onAdd: (_) => _loadTransactions(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildModernAppBar(theme),
      body: Column(
        children: [
          _buildMonthSelector(theme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTransactions,
              color: theme.colorScheme.primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildFuturisticBankCard(),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Transactions",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${_currentMonthTransactions.length}",
                              style: TextStyle(
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  _buildTransactionList(theme),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
      // --- UPDATE: Button shifted to Default Corner (Right) with Slightly Rounded Corners ---
      floatingActionButton: Container(
        height: 55,
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // Halka Rounded (Instead of 30)
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              const Color(0xFF4B6EFA)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showAddTransactionDialog,
            borderRadius: BorderRadius.circular(16), // Matching radius
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 26,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  "Add Transaction",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Changed to endFloat (Bottom Right) which is the standard default
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildModernAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      systemOverlayStyle: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleSpacing: 24,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: _profileImagePath != null
                  ? FileImage(File(_profileImagePath!))
                  : null,
              child: _profileImagePath == null
                  ? Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello,',
                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
              Text(
                _userName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                  ]
              ),
              child: Icon(Icons.download_rounded, color: theme.iconTheme.color, size: 20),
            ),
            onPressed: () => showModalBottomSheet(
                context: context,
                builder: (ctx) => DownloadDialog(
                  expenses: _currentMonthTransactions,
                  allExpenses: _allTransactions,
                  periodLabel: DateFormat('MMMM yyyy').format(_selectedMonth),
                  totalAmount: _totalExpense,
                  userName: _userName,
                )
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(theme, Icons.chevron_left, () => _changeMonth(-1)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth).toUpperCase(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          _buildNavButton(theme, Icons.chevron_right, () => _changeMonth(1)),
        ],
      ),
    );
  }

  Widget _buildNavButton(ThemeData theme, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: theme.cardTheme.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
        ),
        child: Icon(icon, size: 20, color: theme.iconTheme.color),
      ),
    );
  }

  Widget _buildFuturisticBankCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF203A43).withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                  )
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OPENING BALANCE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${_openingBalance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.nfc, color: Colors.white, size: 20),
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE BALANCE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${_closingBalance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildGlassPill(
                      label: 'CREDIT',
                      amount: '+₹${_totalIncome.toStringAsFixed(0)}',
                      color: const Color(0xFF4ADE80),
                    ),
                    const SizedBox(width: 12),
                    _buildGlassPill(
                      label: 'DEBIT',
                      amount: '-₹${_totalExpense.toStringAsFixed(0)}',
                      color: const Color(0xFFF87171),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPill({required String label, required String amount, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(ThemeData theme) {
    if (_isLoading) {
      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
    }

    if (_currentMonthTransactions.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20)]
                ),
                child: Icon(Icons.receipt_long_rounded, size: 40, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Text(
                "No transactions found",
                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final transaction = _currentMonthTransactions[index];
          return _buildTechTransactionTile(transaction, theme);
        },
        childCount: _currentMonthTransactions.length,
      ),
    );
  }

  Widget _buildTechTransactionTile(ExpenseItem transaction, ThemeData theme) {
    bool isCredit = transaction.isIncome;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ExpenseDetailsBottomSheet(
                expense: transaction,
                onUpdate: (_) => _loadTransactions(),
                onDelete: () => _loadTransactions(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: isCredit
                        ? const Color(0xFFE8F5E9).withOpacity(isDark ? 0.2 : 1)
                        : const Color(0xFFFFF0F1).withOpacity(isDark ? 0.2 : 1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      isCredit ? Icons.arrow_downward_rounded : transaction.category.icon,
                      color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM, hh:mm a').format(transaction.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isCredit ? '+' : '-'} ₹${transaction.displayAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isCredit
                            ? const Color(0xFF10B981)
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}