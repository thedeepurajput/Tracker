import 'package:flutter/material.dart';
import '../pages/model.dart';
import '../services/download_service.dart';

class DownloadDialog extends StatefulWidget {
  final List<ExpenseItem> expenses;
  final List<ExpenseItem> allExpenses;
  final String periodLabel;
  final double totalAmount;
  final String userName;

  const DownloadDialog({
    Key? key,
    required this.expenses,
    required this.allExpenses,
    required this.periodLabel,
    required this.totalAmount,
    required this.userName,
  }) : super(key: key);

  @override
  State<DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<DownloadDialog> {
  bool _isDownloading = false;

  void _showSnackBar(String message, [bool isError = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _downloadMonthReport() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);
    Navigator.pop(context);

    final error = await DownloadService.downloadAsPDF(
      expenses: widget.expenses,
      allExpenses: widget.allExpenses,
      periodLabel: widget.periodLabel,
      totalAmount: widget.totalAmount,
      userName: widget.userName,
    );

    setState(() => _isDownloading = false);

    if (error != null) {
      _showSnackBar(error, true);
    } else {
      _showSnackBar('Month PDF opened successfully!');
    }
  }

  Future<void> _downloadCustomPeriodReport() async {
    if (_isDownloading) return;

    // Enhanced date range picker with better theme matching
    final DateTimeRange? selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      saveText: 'Download PDF',
      helpText: 'SELECT DATE RANGE FOR REPORT',
      cancelText: 'Cancel',
      confirmText: 'Generate',
      fieldStartHintText: 'Start Date',
      fieldEndHintText: 'End Date',
      fieldStartLabelText: 'From',
      fieldEndLabelText: 'To',
      errorFormatText: 'Enter valid date',
      errorInvalidText: 'Enter date in valid range',
      errorInvalidRangeText: 'Invalid range',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // Main color scheme matching your app theme
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF), // Your main purple
              onPrimary: Colors.white,
              primaryContainer: Color(0xFFE8E6FF), // Light purple
              onPrimaryContainer: Color(0xFF4B6EFA),
              secondary: Color(0xFFFFA726), // Your orange accent
              onSecondary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2D3748), // Dark text
              outline: Color(0xFFE2E8F0), // Light border
              surfaceVariant: Color(0xFFF8FAFC),
              onSurfaceVariant: Color(0xFF64748B),
            ),

            // Dialog styling
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              elevation: 24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),

            // AppBar in date picker
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            // Text button styling
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.hovered)) {
                    return const Color(0xFF6C63FF).withOpacity(0.1);
                  }
                  if (states.contains(MaterialState.pressed)) {
                    return const Color(0xFF6C63FF).withOpacity(0.2);
                  }
                  return null;
                }),
              ),
            ),

            // Input decoration for date fields
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
              helperStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
              errorStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),

            // Calendar theme
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: const Color(0xFF6C63FF),
              headerForegroundColor: Colors.white,
              weekdayStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              dayStyle: const TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              yearStyle: const TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              rangeSelectionBackgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
              rangePickerBackgroundColor: Colors.white,
              rangePickerHeaderBackgroundColor: const Color(0xFF6C63FF),
              rangePickerHeaderForegroundColor: Colors.white,
              rangeSelectionOverlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFF6C63FF).withOpacity(0.3);
                }
                return const Color(0xFF6C63FF).withOpacity(0.1);
              }),
              dayOverlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFF6C63FF);
                }
                if (states.contains(MaterialState.hovered)) {
                  return const Color(0xFF6C63FF).withOpacity(0.1);
                }
                if (states.contains(MaterialState.pressed)) {
                  return const Color(0xFF6C63FF).withOpacity(0.2);
                }
                return null;
              }),
              todayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFF6C63FF);
                }
                return const Color(0xFFFFA726).withOpacity(0.2);
              }),
              todayForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return const Color(0xFFFFA726);
              }),
            ),

            // Divider theme for calendar
            dividerTheme: const DividerThemeData(
              color: Color(0xFFE2E8F0),
              thickness: 1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedRange == null) return;

    setState(() => _isDownloading = true);
    Navigator.pop(context);

    // Filter expenses for the selected date range
    final filteredExpenses = widget.allExpenses.where((expense) {
      final expenseDate = expense.date;
      final expenseDateOnly = DateTime(expenseDate.year, expenseDate.month, expenseDate.day);
      final startDateOnly = DateTime(selectedRange.start.year, selectedRange.start.month, selectedRange.start.day);
      final endDateOnly = DateTime(selectedRange.end.year, selectedRange.end.month, selectedRange.end.day);

      return expenseDateOnly.compareTo(startDateOnly) >= 0 &&
          expenseDateOnly.compareTo(endDateOnly) <= 0;
    }).toList();

    // Debug information
    print('Selected range: ${selectedRange.start} to ${selectedRange.end}');
    print('Total expenses available: ${widget.allExpenses.length}');
    print('Filtered expenses found: ${filteredExpenses.length}');

    if (widget.allExpenses.isNotEmpty) {
      print('Sample expense dates:');
      for (int i = 0; i < (widget.allExpenses.length > 5 ? 5 : widget.allExpenses.length); i++) {
        print('  ${widget.allExpenses[i].date} - ${widget.allExpenses[i].title}');
      }
    }

    if (filteredExpenses.isEmpty) {
      setState(() => _isDownloading = false);
      _showSnackBar('No expenses found in selected date range!', true);
      return;
    }

    // Calculate total amount for filtered expenses
    final totalAmount = filteredExpenses.fold<double>(
      0.0,
          (sum, expense) => sum + (expense.isExpense ? -expense.amount : expense.amount),
    );

    // Format period label for custom range
    final periodLabel =
        '${selectedRange.start.day}/${selectedRange.start.month}/${selectedRange.start.year} - '
        '${selectedRange.end.day}/${selectedRange.end.month}/${selectedRange.end.year}';

    final error = await DownloadService.downloadAsPDF(
      expenses: filteredExpenses,
      allExpenses: widget.allExpenses,
      periodLabel: periodLabel,
      totalAmount: totalAmount,
      userName: widget.userName,
    );

    setState(() => _isDownloading = false);

    if (error != null) {
      _showSnackBar(error, true);
    } else {
      _showSnackBar('Custom Period PDF opened successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4B6EFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Download PDF for ${widget.userName}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PDF will be opened directly without saving',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 24),
            _buildDownloadOption(
              title: 'Month Report',
              subtitle: 'Download for ${widget.periodLabel}',
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFFFFA726),
              onTap: _downloadMonthReport,
            ),
            const SizedBox(height: 16),
            _buildDownloadOption(
              title: 'Custom Period Report',
              subtitle: 'Select a date range',
              icon: Icons.date_range_rounded,
              color: const Color(0xFFFFA726),
              onTap: _downloadCustomPeriodReport,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isDownloading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isDownloading ? Colors.grey[400] : const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isDownloading) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.download_rounded,
                    color: color,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}