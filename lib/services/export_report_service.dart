
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:my_manager/models/transaction.dart';
import 'package:my_manager/services/transaction_service.dart';

class ExportReportService {
  final TransactionService _transactionService = TransactionService();

  List<Transaction> _getTransactions() {
    final transactions = _transactionService.getTransactions();
    transactions.sort((a, b) => a.date.compareTo(b.date));
    return transactions;
  }

  double _getTotal(List<Transaction> transactions, String type) {
    return transactions
        .where((transaction) =>
    transaction.type.toLowerCase() == type.toLowerCase())
        .fold<double>(0.0, (sum, transaction) => sum + transaction.amount);
  }

  String _dateText(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toString();
  }

  String _fileName(String extension) {
    return 'my_manager_report_'
        '${DateTime.now().millisecondsSinceEpoch}.$extension';
  }

  String _csvEscape(dynamic value) {
    final text = value?.toString() ?? '';
    final escaped = text.replaceAll('"', '""');

    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r')) {
      return '"$escaped"';
    }

    return escaped;
  }

  String _rowsToCsv(List<List<dynamic>> rows) {
    return rows
        .map((row) => row.map(_csvEscape).join(','))
        .join('\r\n');
  }

  // Create CSV file in the app's documents directory.
  Future<File> exportCsv() async {
    final transactions = _getTransactions();

    final income = _getTotal(transactions, 'Income');
    final expense = _getTotal(transactions, 'Expense');
    final balance = income - expense;

    final rows = <List<dynamic>>[
      ['My Manager - Financial Report'],
      ['Total Income', _formatAmount(income)],
      ['Total Expense', _formatAmount(expense)],
      ['Balance', _formatAmount(balance)],
      [],
      ['Date', 'Type', 'Category', 'Description', 'Amount'],
      ...transactions.map(
        (transaction) => [
          _dateText(transaction.date),
          transaction.type,
          transaction.category,
          transaction.description,
          _formatAmount(transaction.amount),
        ],
      ),
    ];

    final csvText = _rowsToCsv(rows);
    final directory = await getApplicationDocumentsDirectory();

    final file = File('${directory.path}/${_fileName('csv')}');

    // UTF-8 BOM helps spreadsheet applications recognize UTF-8.
    await file.writeAsBytes([
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode(csvText),
    ]);

    return file;
  }

  // Create PDF report in the app's documents directory.
  Future<File> exportPdf() async {
    final transactions = _getTransactions();

    final income = _getTotal(transactions, 'Income');
    final expense = _getTotal(transactions, 'Expense');
    final balance = income - expense;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'My Manager',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Financial Report',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Generated: ${_dateText(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Divider(),
          pw.SizedBox(height: 12),
          pw.Text(
            'Total Income: ${_formatAmount(income)}',
            style: const pw.TextStyle(fontSize: 13),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Total Expense: ${_formatAmount(expense)}',
            style: const pw.TextStyle(fontSize: 13),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Balance: ${_formatAmount(balance)}',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Transaction History',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          if (transactions.isEmpty)
            pw.Text('No transactions available.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Date',
                'Type',
                'Category',
                'Description',
                'Amount',
              ],
              data: transactions
                  .map(
                    (transaction) => [
                      _dateText(transaction.date),
                      transaction.type,
                      transaction.category,
                      transaction.description,
                      _formatAmount(transaction.amount),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE0E0E0),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(5),
              border: pw.TableBorder.all(
                color: PdfColor.fromInt(0xFFBDBDBD),
                width: 0.5,
              ),
            ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${_fileName('pdf')}');

    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static const MethodChannel _downloadsChannel =
      MethodChannel('com.moslah.my_manager/downloads');

  // Save bytes directly to the phone's public Downloads directory.
  Future<String> _saveToDownloads({
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) async {
    if (Platform.isAndroid) {
      try {
        final String? result = await _downloadsChannel.invokeMethod<String>(
          'saveToDownloads',
          {
            'fileName': fileName,
            'bytes': Uint8List.fromList(bytes),
            'mimeType': mimeType,
          },
        );
        if (result != null && result.isNotEmpty) {
          return result;
        }
      } catch (e) {
        debugPrint('MethodChannel saveToDownloads error: $e');
      }
    }

    // Fallback for non-Android or if MethodChannel fails
    Directory? targetDir;
    try {
      targetDir = await getDownloadsDirectory();
    } catch (_) {}
    targetDir ??= await getApplicationDocumentsDirectory();

    final targetFile = File('${targetDir.path}/$fileName');
    await targetFile.writeAsBytes(bytes);
    return targetFile.path;
  }

  // Download CSV directly to phone's Downloads directory.
  Future<void> downloadCsv(BuildContext context) async {
    try {
      final file = await exportCsv();
      final bytes = await file.readAsBytes();
      final fileName = file.uri.pathSegments.last;

      await _saveToDownloads(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'text/csv',
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV ফাইল Downloads ফোল্ডারে সেভ হয়েছে ($fileName)'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV ডাউনলোড ব্যর্থ হয়েছে: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Download PDF directly to phone's Downloads directory.
  Future<void> downloadPdf(BuildContext context) async {
    try {
      final file = await exportPdf();
      final bytes = await file.readAsBytes();
      final fileName = _fileName('pdf');

      await _saveToDownloads(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/pdf',
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF ফাইল Downloads ফোল্ডারে সেভ হয়েছে ($fileName)'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF ডাউনলোড ব্যর্থ হয়েছে: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Share CSV with another app.
  Future<void> shareCsv(BuildContext context) async {
    try {
      final file = await exportCsv();

      if (!context.mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'My Manager CSV Report',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV শেয়ার ব্যর্থ হয়েছে: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Share PDF with another app.
  Future<void> sharePdf(BuildContext context) async {
    try {
      final file = await exportPdf();

      if (!context.mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'My Manager PDF Report',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF শেয়ার ব্যর্থ হয়েছে: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}


