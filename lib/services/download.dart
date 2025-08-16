import 'package:flutter/material.dart';
import '../pages/model.dart';
import '../services/download_service.dart';

class DownloadDialog extends StatefulWidget {
  final List<ExpenseItem> expenses;
  final String periodLabel;
  final double totalAmount;
  final String userName;

  const DownloadDialog({
    Key? key,
    required this.expenses,
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
      periodLabel: widget.periodLabel,
      totalAmount: widget.totalAmount,
      userName: widget.userName,
    );

    setState(() => _isDownloading = false);

    if (error != null) {
      _showSnackBar(error, true);
    } else {
      _showSnackBar('Month PDF downloaded and opened successfully!');
    }
  }

  Future<void> _downloadCustomPeriodReport() async {
    if (_isDownloading) return;

    // Show date range picker
    final DateTimeRange? selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Prevent future dates
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedRange == null) return; // User cancelled

    setState(() => _isDownloading = true);
    Navigator.pop(context);

    // Filter expenses for the selected date range
    final filteredExpenses = widget.expenses.where((expense) {
      final expenseDate = expense.date;
      return expenseDate.isAfter(selectedRange.start.subtract(const Duration(days: 1))) &&
          expenseDate.isBefore(selectedRange.end.add(const Duration(days: 1)));
    }).toList();

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
      periodLabel: periodLabel,
      totalAmount: totalAmount,
      userName: widget.userName,
    );

    setState(() => _isDownloading = false);

    if (error != null) {
      _showSnackBar(error, true);
    } else {
      _showSnackBar('Custom Period PDF downloaded and opened successfully!');
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
                color: const Color(0xFFFFA726), // Orange divider
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PDF will be saved and opened automatically',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 24),
            _buildDownloadOption(
              title: 'Month Report',
              subtitle: 'Download for ${widget.periodLabel}',
              color: const Color(0xFFFFA726),
              onTap: _downloadMonthReport,
            ),
            const SizedBox(height: 16),
            _buildDownloadOption(
              title: 'Custom Period Report',
              subtitle: 'Select a date range',
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color, // Orange border
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}