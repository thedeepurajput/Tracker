import 'package:flutter/material.dart';
import '../pages/model.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart'; // Import the new theme file

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
        backgroundColor: isError ? Colors.red : AppTheme.primary,
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
    if (error != null) _showSnackBar(error, true);
    else _showSnackBar('Month PDF opened successfully!');
  }

  Future<void> _downloadCustomPeriodReport() async {
    if (_isDownloading) return;

    // Use the extracted theme for cleaner code
    final DateTimeRange? selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: AppTheme.downloadDialogTheme, // Using clean theme
          child: child!,
        );
      },
    );

    if (selectedRange == null) return;

    setState(() => _isDownloading = true);
    Navigator.pop(context);

    final filteredExpenses = widget.allExpenses.where((expense) {
      final expenseDateOnly = DateTime(expense.date.year, expense.date.month, expense.date.day);
      final startDateOnly = DateTime(selectedRange.start.year, selectedRange.start.month, selectedRange.start.day);
      final endDateOnly = DateTime(selectedRange.end.year, selectedRange.end.month, selectedRange.end.day);
      return expenseDateOnly.compareTo(startDateOnly) >= 0 && expenseDateOnly.compareTo(endDateOnly) <= 0;
    }).toList();

    if (filteredExpenses.isEmpty) {
      setState(() => _isDownloading = false);
      _showSnackBar('No expenses found in selected range!', true);
      return;
    }

    final totalAmount = filteredExpenses.fold<double>(0.0, (sum, expense) => sum + (expense.isExpense ? -expense.amount : expense.amount));
    final periodLabel = '${selectedRange.start.day}/${selectedRange.start.month}/${selectedRange.start.year} - ${selectedRange.end.day}/${selectedRange.end.month}/${selectedRange.end.year}';

    final error = await DownloadService.downloadAsPDF(
      expenses: filteredExpenses,
      allExpenses: widget.allExpenses,
      periodLabel: periodLabel,
      totalAmount: totalAmount,
      userName: widget.userName,
    );

    setState(() => _isDownloading = false);
    if (error != null) _showSnackBar(error, true);
    else _showSnackBar('Custom Period PDF opened successfully!');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color(0xFF4B6EFA)],
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Download Report', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            _buildDownloadOption('Month Report', 'For ${widget.periodLabel}', Icons.calendar_month_rounded, const Color(0xFFFFA726), _downloadMonthReport),
            const SizedBox(height: 16),
            _buildDownloadOption('Custom Period', 'Select date range', Icons.date_range_rounded, const Color(0xFFFFA726), _downloadCustomPeriodReport),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: _isDownloading ? null : onTap,
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: _isDownloading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      ),
    );
  }
}