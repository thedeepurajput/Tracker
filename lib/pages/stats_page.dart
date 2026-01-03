import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Make sure fl_chart is in pubspec.yaml
import 'package:intl/intl.dart';
import '../services/DatabaseHelper.dart';
import '../pages/model.dart';
import '../theme/app_theme.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  DateTime _selectedMonth = DateTime.now();
  List<ExpenseItem> _transactions = [];
  bool _isLoading = true;
  int _touchedIndex = -1; // For chart interaction

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final all = await ExpenseDatabase.instance.getAllTransactions();

    // Filter for selected month
    final filtered = all.where((t) {
      return t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month &&
          t.isExpense; // Only show Expenses in Chart
    }).toList();

    setState(() {
      _transactions = filtered;
      _isLoading = false;
    });
  }

  void _changeMonth(int months) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + months);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalExpense = _transactions.fold(0.0, (sum, t) => sum + t.displayAmount);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Analytics"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Month Selector
          _buildMonthSelector(theme),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_transactions.isEmpty)
            Expanded(child: _buildEmptyState(theme))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Total Expense Text
                    Text(
                      "Total Expense",
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${totalExpense.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 40),

                    // Pie Chart
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _generateChartSections(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Category Breakdown List
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Breakdown", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ..._buildCategoryList(totalExpense, theme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(-1)
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(1)
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No expenses this month", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateChartSections() {
    // Group Data
    Map<String, double> dataMap = {};
    for (var item in _transactions) {
      dataMap[item.category.label] = (dataMap[item.category.label] ?? 0) + item.displayAmount;
    }

    final List<MapEntry<String, double>> sortedList = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return List.generate(sortedList.length, (i) {
      final isTouched = i == _touchedIndex;
      final entry = sortedList[i];
      final fontSize = isTouched ? 18.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;

      final category = ExpenseCategory.values.firstWhere(
              (e) => e.label == entry.key,
          orElse: () => ExpenseCategory.other
      );

      return PieChartSectionData(
        color: category.color,
        value: entry.value,
        title: '${(entry.value / _transactions.fold(0.0, (sum, t) => sum + t.displayAmount) * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  List<Widget> _buildCategoryList(double total, ThemeData theme) {
    // Group Data again for list
    Map<String, double> dataMap = {};
    for (var item in _transactions) {
      dataMap[item.category.label] = (dataMap[item.category.label] ?? 0) + item.displayAmount;
    }

    final sortedList = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedList.map((entry) {
      final category = ExpenseCategory.values.firstWhere(
              (e) => e.label == entry.key,
          orElse: () => ExpenseCategory.other
      );
      final percentage = (entry.value / total * 100);

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      color: category.color,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("₹${entry.value.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${percentage.toStringAsFixed(1)}%", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            )
          ],
        ),
      );
    }).toList();
  }
}