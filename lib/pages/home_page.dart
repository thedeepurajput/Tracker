import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/DatabaseHelper.dart';
import '../services/download.dart';
import './add_expense.dart';
import './expense_detail.dart';
import './model.dart';

enum DateFilterType { day, month, year }

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title, required this.userName});

  final String title;
  final String userName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<ExpenseItem> _transactions = [];
  String _searchQuery = '';
  ExpenseCategory? _filterCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSearching = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _userName = '';
  static const String _defaultUserId = 'user_1';
  bool _showOpeningBalance = false;

  DateFilterType _dateFilterType = DateFilterType.month;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  Offset _fabPosition = const Offset(0, 0);
  Offset _defaultFabPosition = const Offset(0, 0);
  Size _screenSize = Size.zero;
  bool _isDragging = false;
  final double _fabWidth = 200;
  final double _fabHeight = 56;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeUser();
    _loadTransactionsFromDatabase();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFabPosition();
    });
  }

  void _initializeFabPosition() {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    setState(() {
      _screenSize = size;
      _defaultFabPosition = Offset(
        size.width - _fabWidth - 16 - padding.right,
        size.height - _fabHeight - 16 - padding.bottom,
      );
      _fabPosition = _defaultFabPosition;
      print(
          'FAB initialized: $_fabPosition, screen size: $_screenSize, safe area padding: $padding');
    });
  }

  void _initializeUser() async {
    try {
      final dbUserName =
          await ExpenseDatabase.instance.getUserName(_defaultUserId);
      if (dbUserName != null && dbUserName.isNotEmpty) {
        setState(() {
          _userName = dbUserName;
        });
      } else {
        final initialName =
            widget.userName.isNotEmpty ? widget.userName : 'User';
        await ExpenseDatabase.instance.setUserName(_defaultUserId, initialName);
        setState(() {
          _userName = initialName;
        });
      }
    } catch (e) {
      print('Error initializing user: $e');
      setState(() {
        _userName = widget.userName.isNotEmpty ? widget.userName : 'User';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadTransactionsFromDatabase() async {
    setState(() => _isLoading = true);
    final transactions = await ExpenseDatabase.instance.getAllExpenses();
    print('Loaded transactions: ${transactions.length}');
    for (var t in transactions) {
      print(
          'Transaction: ${t.title}, Date: ${t.date}, IsExpense: ${t.isExpense}');
    }
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
    _animationController.forward();
  }

  List<ExpenseItem> get _filteredTransactions {
    return _transactions.where((transaction) {
      final matchesSearch = transaction.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          transaction.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesFilter =
          _filterCategory == null || transaction.category == _filterCategory;
      final matchesDate = _matchesDateFilter(transaction.date);
      return matchesSearch && matchesFilter && matchesDate;
    }).toList();
  }

  List<ExpenseItem> get _filteredExpenses {
    return _filteredTransactions
        .where((transaction) => transaction.isExpense)
        .toList();
  }

  List<ExpenseItem> get _filteredIncome {
    return _filteredTransactions
        .where((transaction) => transaction.isIncome)
        .toList();
  }

  List<ExpenseItem> get _allExpenses {
    return _transactions.where((transaction) {
      final matchesCategory =
          _filterCategory == null || transaction.category == _filterCategory;

      return transaction.isExpense &&
          matchesCategory &&
          (_searchQuery.isEmpty ||
              transaction.title
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              transaction.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  List<ExpenseItem> get _allIncome {
    return _transactions
        .where((transaction) =>
            transaction.isIncome &&
            (_searchQuery.isEmpty ||
                transaction.title
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                transaction.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase())))
        .toList();
  }

  double get _totalAllExpenses {
    return _allExpenses.fold(
        0.0, (sum, expense) => sum + expense.displayAmount);
  }

  double get _totalAllIncome {
    return _allIncome.fold(0.0, (sum, income) => sum + income.displayAmount);
  }

  double get _netBalanceAll {
    return _totalAllIncome - _totalAllExpenses;
  }

  double get _totalExpenses {
    return _filteredExpenses.fold(
        0.0, (sum, expense) => sum + expense.displayAmount);
  }

  double get _totalIncome {
    return _filteredIncome.fold(
        0.0, (sum, income) => sum + income.displayAmount);
  }

  double get _netBalance {
    return _totalIncome - _totalExpenses;
  }

  double get _openingBalance {
    final currentPeriodStart = _getPeriodStartDate();
    final transactionsBeforePeriod = _transactions
        .where((transaction) => transaction.date.isBefore(currentPeriodStart))
        .toList();

    final incomeBeforePeriod = transactionsBeforePeriod
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.displayAmount);

    final expensesBeforePeriod = transactionsBeforePeriod
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.displayAmount);

    return incomeBeforePeriod - expensesBeforePeriod;
  }

  DateTime _getPeriodStartDate() {
    switch (_dateFilterType) {
      case DateFilterType.day:
        return DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day);
      case DateFilterType.month:
        return DateTime(_selectedYear, _selectedMonth, 1);
      case DateFilterType.year:
        return DateTime(_selectedYear, 1, 1);
    }
  }

  bool _matchesDateFilter(DateTime transactionDate) {
    switch (_dateFilterType) {
      case DateFilterType.day:
        return _isSameDay(transactionDate, _selectedDate);
      case DateFilterType.month:
        return transactionDate.year == _selectedYear &&
            transactionDate.month == _selectedMonth;
      case DateFilterType.year:
        return transactionDate.year == _selectedYear;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String get _periodLabel {
    switch (_dateFilterType) {
      case DateFilterType.day:
        return DateFormat('MMM dd, yyyy').format(_selectedDate);
      case DateFilterType.month:
        return DateFormat('MMMM yyyy')
            .format(DateTime(_selectedYear, _selectedMonth));
      case DateFilterType.year:
        return _selectedYear.toString();
    }
  }

  Map<String, List<ExpenseItem>> _groupTransactionsByDay() {
    final Map<String, List<ExpenseItem>> grouped = {};
    final now = DateTime.now();
    for (var transaction in _filteredTransactions) {
      String key;
      final transactionDate = transaction.date;
      if (_isSameDay(transactionDate, now)) {
        key = 'Today';
      } else if (_isSameDay(
          transactionDate, now.subtract(const Duration(days: 1)))) {
        key = 'Yesterday';
      } else {
        key = DateFormat('MMM dd, yyyy').format(transactionDate);
      }
      grouped.putIfAbsent(key, () => []).add(transaction);
    }
    grouped.forEach((key, transactions) {
      transactions.sort((a, b) => b.date.compareTo(a.date));
    });
    final sortedGrouped = Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) {
          if (a.key == 'Today') return -1;
          if (b.key == 'Today') return 1;
          if (a.key == 'Yesterday') return -1;
          if (b.key == 'Yesterday') return 1;
          final aDate = a.key == 'Today'
              ? now
              : a.key == 'Yesterday'
                  ? now.subtract(const Duration(days: 1))
                  : DateFormat('MMM dd, yyyy').parse(a.key);
          final bDate = b.key == 'Today'
              ? now
              : b.key == 'Yesterday'
                  ? now.subtract(const Duration(days: 1))
                  : DateFormat('MMM dd, yyyy').parse(b.key);
          return bDate.compareTo(aDate);
        }),
    );
    return sortedGrouped;
  }

  void _showDownloadDialog() {
    print('Filtered transactions: ${_filteredTransactions.length}');
    if (_filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('No transactions to download for the selected period'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DownloadDialog(
        expenses: _filteredTransactions,
        allExpenses: _transactions,
        periodLabel: _periodLabel,
        totalAmount: _netBalance,
        userName: _userName,
      ),
    );
  }

  void _showDateFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setDialogState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Time Period',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _buildFilterTypeChipWithState(
                              DateFilterType.day, 'Day', setDialogState)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildFilterTypeChipWithState(
                              DateFilterType.month, 'Month', setDialogState)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildFilterTypeChipWithState(
                              DateFilterType.year, 'Year', setDialogState)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_dateFilterType == DateFilterType.day) ...[
                    _buildDatePickerSectionWithState(setDialogState),
                  ] else if (_dateFilterType == DateFilterType.month) ...[
                    _buildMonthYearPickerSectionWithState(setDialogState),
                  ] else ...[
                    _buildYearPickerSectionWithState(setDialogState),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filter',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTypeChipWithState(
      DateFilterType type, String label, StateSetter setDialogState) {
    final isSelected = _dateFilterType == type;
    return GestureDetector(
      onTap: () {
        setDialogState(() {
          _dateFilterType = type;
          if (type == DateFilterType.month) {
            _selectedMonth = DateTime.now().month;
            _selectedYear = DateTime.now().year;
          } else if (type == DateFilterType.year) {
            _selectedYear = DateTime.now().year;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF6C63FF), width: 2)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerSectionWithState(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setDialogState(() => _selectedDate = picked);
              }
            },
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF6C63FF)),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthYearPickerSectionWithState(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Month & Year',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  diameterRatio: 1.5,
                  onSelectedItemChanged: (int index) {
                    HapticFeedback.lightImpact();
                    setDialogState(() => _selectedMonth = index + 1);
                  },
                  children: List<Widget>.generate(12, (index) {
                    return Center(
                      child: Text(
                        DateFormat('MMMM').format(DateTime(2023, index + 1)),
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }),
                  scrollController: FixedExtentScrollController(
                      initialItem: _selectedMonth - 1),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  diameterRatio: 1.5,
                  onSelectedItemChanged: (int index) {
                    HapticFeedback.lightImpact();
                    setDialogState(
                        () => _selectedYear = DateTime.now().year - index);
                  },
                  children: List<Widget>.generate(10, (index) {
                    final year = DateTime.now().year - index;
                    return Center(
                      child: Text(
                        year.toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }),
                  scrollController: FixedExtentScrollController(
                    initialItem: DateTime.now().year - _selectedYear,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearPickerSectionWithState(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Year',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CupertinoPicker(
            itemExtent: 32.0,
            onSelectedItemChanged: (int index) {
              setDialogState(() => _selectedYear = DateTime.now().year - index);
            },
            selectionOverlay: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
            ),
            children: List<Widget>.generate(15, (index) {
              final year = DateTime.now().year - index;
              return Center(
                child: Text(
                  year.toString(),
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }),
            scrollController: FixedExtentScrollController(
              initialItem: DateTime.now().year - _selectedYear,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddTransactionDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AddTransaction(
          selectedDate: _selectedDate,
          onAdd: (transaction) => _loadTransactionsFromDatabase(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  void _showEditUsernameDialog() {
    TextEditingController controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Edit Username',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter new username',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF718096)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await ExpenseDatabase.instance
                      .setUserName(_defaultUserId, newName);
                  setState(() {
                    _userName = newName;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Username updated to "$newName"'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update username: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Username cannot be empty'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(ExpenseItem transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: ExpenseDetailsBottomSheet(
          expense: transaction,
          onUpdate: (updatedTransaction) => _loadTransactionsFromDatabase(),
          onDelete: () {
            _loadTransactionsFromDatabase();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _updateFabPosition(DragUpdateDetails details) {
    setState(() {
      _fabPosition = Offset(
        (_fabPosition.dx + details.delta.dx).clamp(
            0.0,
            _screenSize.width -
                _fabWidth -
                MediaQuery.of(context).padding.right),
        (_fabPosition.dy + details.delta.dy).clamp(
            0.0,
            _screenSize.height -
                _fabHeight -
                MediaQuery.of(context).padding.bottom),
      );
      print('FAB moved to: $_fabPosition');
    });
  }

  Widget _buildFAB() {
    if (_screenSize == Size.zero) return const SizedBox.shrink();

    return Positioned(
      left: _fabPosition.dx,
      top: _fabPosition.dy,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() => _isDragging = true);
          HapticFeedback.lightImpact();
        },
        onPanUpdate: _updateFabPosition,
        onPanEnd: (details) {
          setState(() => _isDragging = false);
          HapticFeedback.lightImpact();
        },
        onTap: () {
          if (!_isDragging) {
            HapticFeedback.lightImpact();
            _showAddTransactionDialog();
          }
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          setState(() {
            _fabPosition = _defaultFabPosition;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('FAB position reset to default'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        child: Container(
          width: _fabWidth,
          height: _fabHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_isDragging ? 20 : 16),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF8B5FBF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF)
                    .withOpacity(_isDragging ? 0.4 : 0.3),
                blurRadius: _isDragging ? 16 : 12,
                offset: Offset(0, _isDragging ? 8 : 6),
                spreadRadius: _isDragging ? 2 : 0,
              ),
            ],
            border: _isDragging
                ? Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  )
                : null,
          ),
          child: AnimatedContainer(
            duration: Duration(milliseconds: _isDragging ? 0 : 200),
            padding: EdgeInsets.symmetric(
              horizontal: _isDragging ? 20 : 16,
              vertical: _isDragging ? 16 : 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isDragging ? Icons.drag_indicator : Icons.add,
                  color: Colors.white,
                  size: _isDragging ? 20 : 24,
                ),
                if (!_isDragging) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Add Transaction',
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
      ExpenseItem transaction, int index, int groupLength, ThemeData theme) {
    final isIncome = transaction.isIncome;
    final displayAmount = transaction.displayAmount;

    // Use default category
    final categoryLabel = transaction.category.label;
    final categoryIcon = transaction.category.icon;
    final categoryColor = transaction.category.color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTransactionDetails(transaction),
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFF6C63FF).withOpacity(0.1),
          highlightColor: const Color(0xFF6C63FF).withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isIncome ? const Color(0xFF00B894) : categoryColor,
                        isIncome
                            ? const Color(0xFF00B894).withOpacity(0.8)
                            : categoryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isIncome ? Icons.trending_up : categoryIcon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            isIncome ? 'Income' : categoryLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: const Color(0xFF718096),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${isIncome ? '+' : '-'}₹${displayAmount.abs().toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isIncome
                        ? const Color(0xFF00B894)
                        : const Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupedTransactions = _groupTransactionsByDay();

    if (_screenSize == Size.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeFabPosition();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 60,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF6C63FF),
                elevation: 0,
                title: _isSearching
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search transactions...',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.white70),
                          ),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                      )
                    : GestureDetector(
                        onTap: _showEditUsernameDialog,
                        child: Text(
                          'Hello, ${_userName.isEmpty ? 'User' : _userName}! 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                actions: [
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search,
                        color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) _searchQuery = '';
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined,
                        color: Colors.white),
                    onPressed: _showDownloadDialog,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    onSelected: (value) {
                      setState(() {
                        if (value == 'all') {
                          _filterCategory = null;
                        } else {
                          _filterCategory = ExpenseCategory.values.firstWhere(
                            (cat) => cat.toString() == value,
                            orElse: () => ExpenseCategory.other,
                          );
                        }
                      });
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'all',
                          child: Row(
                            children: [
                              Icon(Icons.clear_all,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              const Text('All Categories'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        // Show all categories
                        ...ExpenseCategory.values.map(
                          (category) => PopupMenuItem<String>(
                            value: category.toString(),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: category.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    category.icon,
                                    size: 16,
                                    color: category.color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(category.label.toUpperCase()),
                              ],
                            ),
                          ),
                        ),
                      ];
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildDateFilterSelector(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: _buildBalanceCard(),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(DateTime.now()),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade200,
                      ),
                    ],
                  ),
                ),
              ),
              _isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF6C63FF)),
                          ),
                        ),
                      ),
                    )
                  : groupedTransactions.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final dayKey =
                                  groupedTransactions.keys.elementAt(index);
                              final transactions = groupedTransactions[dayKey]!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 8),
                                    child: Text(
                                      dayKey,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2D3748),
                                      ),
                                    ),
                                  ),
                                  ...transactions.asMap().entries.map((entry) {
                                    final transaction = entry.value;
                                    return FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: _buildTransactionCard(
                                          transaction,
                                          entry.key,
                                          transactions.length,
                                          theme),
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                            childCount: groupedTransactions.length,
                          ),
                        ),
            ],
          ),
          _buildFAB(),
        ],
      ),
    );
  }

  Widget _buildDateFilterSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showDateFilterDialog,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _dateFilterType == DateFilterType.day
                          ? Icons.calendar_today_outlined
                          : _dateFilterType == DateFilterType.month
                              ? Icons.calendar_view_month_outlined
                              : Icons.calendar_month_outlined,
                      color: const Color(0xFF6C63FF),
                      size: 20,
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF6C63FF),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _periodLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _dateFilterType.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isPositive =
        _showOpeningBalance ? _openingBalance >= 0 : _netBalanceAll >= 0;
    final displayAmount =
        _showOpeningBalance ? _openingBalance : _netBalanceAll;
    final cardTitle = _showOpeningBalance ? 'Opening Balance' : 'Net Balance';
    final cardSubtitle = _showOpeningBalance
        ? 'Before ${_periodLabel}'
        : (isPositive ? 'Surplus' : 'Deficit');

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          setState(() => _showOpeningBalance = false);
        } else if (details.primaryVelocity! < 0) {
          setState(() => _showOpeningBalance = true);
        }
      },
      onTap: () {
        setState(() => _showOpeningBalance = !_showOpeningBalance);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPositive
                ? [const Color(0xFF00B894), const Color(0xFF00D2A0)]
                : [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isPositive
                      ? const Color(0xFF00B894)
                      : const Color(0xFFFF6B6B))
                  .withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          _showOpeningBalance ? Colors.white30 : Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          _showOpeningBalance ? Colors.white : Colors.white30,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                cardTitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${displayAmount.abs().toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                cardSubtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
