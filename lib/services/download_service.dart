import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../pages/model.dart';

class DownloadService {
  static String _getFileNameSuffix(String periodLabel) {
    return periodLabel.replaceAll(' ', '_').replaceAll(',', '').toLowerCase();
  }

  static Future<File?> _saveFileBytes(Uint8List bytes, String fileName) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        await OpenFile.open(filePath);
        return file;
      }
    } catch (e) {
      print('Error saving file: $e');
    }
    return null;
  }

  static Future<String?> downloadAsPDF({
    required List<ExpenseItem> expenses,
    required List<ExpenseItem> allExpenses, // All expenses for opening balance calculation
    required String periodLabel,
    required double totalAmount,
    required String userName,
  }) async {
    try {
      final pdfBytes = await _generatePDFContent(
        expenses,
        allExpenses,
        periodLabel,
        totalAmount,
        userName,
      );
      final fileName = 'expense_report_${_getFileNameSuffix(periodLabel)}.pdf';
      final file = await _saveFileBytes(pdfBytes, fileName);

      if (file != null) {
        return null;
      }
      return 'Failed to create PDF file';
    } catch (e) {
      return 'Error creating PDF: $e';
    }
  }

  // Calculate opening balance based on expenses before the selected period
  static double _calculateOpeningBalance(
      List<ExpenseItem> allExpenses,
      List<ExpenseItem> selectedExpenses,
      ) {
    if (selectedExpenses.isEmpty) return 0.0;

    // Get the earliest date from selected expenses
    final earliestSelectedDate = selectedExpenses
        .map((e) => e.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    // Calculate balance from all expenses before the selected period
    double openingBalance = 0.0;

    for (var expense in allExpenses) {
      if (expense.date.isBefore(earliestSelectedDate)) {
        if (expense.isIncome) {
          openingBalance += expense.displayAmount;
        } else {
          openingBalance -= expense.displayAmount;
        }
      }
    }

    return openingBalance;
  }

  static Future<Uint8List> _generatePDFContent(
      List<ExpenseItem> expenses,
      List<ExpenseItem> allExpenses,
      String periodLabel,
      double totalAmount,
      String userName,
      ) async {
    final pdf = pw.Document();
    final sortedExpenses = List<ExpenseItem>.from(expenses)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate proper opening balance
    double openingBalance = _calculateOpeningBalance(allExpenses, expenses);
    double incomeTotal = 0.0;
    double expenseTotal = 0.0;
    double runningBalance = openingBalance;

    // Calculate totals for selected period only
    for (var e in sortedExpenses) {
      if (e.isIncome) {
        incomeTotal += e.displayAmount;
      } else {
        expenseTotal += e.displayAmount;
      }
    }

    double closingBalance = openingBalance + incomeTotal - expenseTotal;

    final headerColor = PdfColor.fromHex('6C63FF');
    final evenRowColor = PdfColors.grey200;
    final oddRowColor = PdfColors.white;

    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated on $formattedDate',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${context.pageNumber} / ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          pw.Text(
            "$userName's $periodLabel Expense Report",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),

          pw.Table(
            border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: headerColor),
                children: [
                  _simpleCell('Date', isHeader: true),
                  _simpleCell('Title', isHeader: true),
                  _simpleCell('Category', isHeader: true),
                  _simpleCell('Amount', isHeader: true, alignRight: true),
                  _simpleCell('Remaining', isHeader: true, alignRight: true),
                ],
              ),
              ...sortedExpenses.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final isIncome = e.isIncome;
                final color = isIncome ? PdfColors.green : PdfColors.red;

                runningBalance += isIncome ? e.displayAmount : -e.displayAmount;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: i % 2 == 0 ? evenRowColor : oddRowColor,
                  ),
                  children: [
                    _simpleCell(DateFormat('dd/MM/yyyy').format(e.date)),
                    _simpleCell(e.title),
                    _simpleCell(e.category.label),
                    _simpleCell(
                      e.displayAmount.toStringAsFixed(2),
                      color: color,
                      alignRight: true,
                    ),
                    _simpleCell(
                      runningBalance.toStringAsFixed(2),
                      alignRight: true,
                    ),
                  ],
                );
              }).toList(),

              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: (sortedExpenses.length - 1) % 2 == 0
                      ? oddRowColor
                      : evenRowColor,
                ),
                children: List.generate(
                  5,
                      (index) => pw.Container(
                    height: 24,
                    child: pw.Text(''),
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          pw.Container(
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(12),
              color: PdfColor.fromHex('F3F4F6'),
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary',
                    style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Opening Balance:', style: pw.TextStyle(fontSize: 14)),
                    pw.Text('${openingBalance.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: openingBalance >= 0 ? PdfColors.green : PdfColors.red,
                          fontWeight: pw.FontWeight.bold,
                        )),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Income:',
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.green)),
                    pw.Text('${incomeTotal.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.green)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Expense:',
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.red)),
                    pw.Text('${expenseTotal.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.red)),
                  ],
                ),
                pw.Divider(height: 24, thickness: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Closing Balance:',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${closingBalance.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: closingBalance >= 0 ? PdfColors.green : PdfColors.red,
                        )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _simpleCell(
      String text, {
        bool isHeader = false,
        PdfColor? color,
        bool alignRight = false,
      }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.white : PdfColors.black),
        ),
      ),
    );
  }
}