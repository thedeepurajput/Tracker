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
    required String periodLabel,
    required double totalAmount,
    required String userName,
  }) async {
    try {
      final pdfBytes = await _generatePDFContent(expenses, periodLabel, totalAmount, userName);
      final fileName = 'expense_report_${_getFileNameSuffix(periodLabel)}.pdf';
      final file = await _saveFileBytes(pdfBytes, fileName);

      if (file != null) {
        return null; // Success
      }
      return 'Failed to create PDF file';
    } catch (e) {
      return 'Error creating PDF: $e';
    }
  }

  static Future<Uint8List> _generatePDFContent(
      List<ExpenseItem> expenses,
      String periodLabel,
      double totalAmount,
      String userName,
      ) async {
    final pdf = pw.Document();
    final sortedExpenses = List<ExpenseItem>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Define colors
    final headerColor = PdfColor.fromHex('6C63FF');
    final rowColor1 = PdfColor.fromHex('E6F0FA'); // Light blue
    final rowColor2 = PdfColor.fromHex('F3E8FF'); // Light purple
    final footerColor = PdfColor.fromHex('FFA726'); // Orange footer

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'Page ${context.pageNumber}/${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  height: 20,
                  color: footerColor,
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${DateFormat('dd MMMM, yyyy').format(DateTime.now())} ${DateFormat('HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey600,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 30),
            pw.Text(
              'DETAILED TRANSACTIONS',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FixedColumnWidth(80),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: headerColor,
                  ),
                  children: [
                    _buildTableCell('DATE', isHeader: true),
                    _buildTableCell('TITLE', isHeader: true),
                    _buildTableCell('CATEGORY', isHeader: true),
                    _buildTableCell('AMOUNT', isHeader: true),
                  ],
                ),
                ...sortedExpenses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final expense = entry.value;
                  final isEven = index % 2 == 0;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? rowColor1 : rowColor2,
                    ),
                    children: [
                      _buildTableCell(DateFormat('dd/MM/yy').format(expense.date)),
                      _buildTableCell(expense.title),
                      _buildTableCell(expense.category.name.toUpperCase()),
                      _buildTableCell(
                        '${expense.amount.toStringAsFixed(2)}',
                        alignment: pw.Alignment.centerRight,
                        isAmount: true,
                        isIncome: expense.isIncome,
                      ),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue100,
                  ),
                  children: [
                    _buildTableCell(''),
                    _buildTableCell(''),
                    _buildTableCell('TOTAL', isHeader: true, alignment: pw.Alignment.centerRight),
                    _buildTableCell(
                      '${totalAmount.toStringAsFixed(2)}',
                      isHeader: true,
                      alignment: pw.Alignment.centerRight,
                      isAmount: true,
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(
      String text, {
        bool isHeader = false,
        pw.Alignment alignment = pw.Alignment.centerLeft,
        bool isAmount = false,
        bool isIncome = false,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment: alignment,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: isHeader ? 10 : 9,
            fontWeight: pw.FontWeight.bold,
            color: isAmount
                ? (isIncome ? PdfColors.green600 : PdfColors.red600)
                : isHeader
                ? PdfColors.white
                : PdfColors.grey700,
          ),
          textAlign: isAmount ? pw.TextAlign.right : pw.TextAlign.left,
        ),
      ),
    );
  }
}