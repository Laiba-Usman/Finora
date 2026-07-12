import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class ExportService {
  // Export Transactions to CSV and trigger Share Sheet
  Future<void> exportToCsv(List<TransactionModel> transactions) async {
    final List<List<dynamic>> rows = [];
    
    // CSV Header
    rows.add([
      'Transaction ID',
      'Amount',
      'Type',
      'Category ID',
      'Date',
      'Payment Method',
      'Note',
      'Created At'
    ]);

    // CSV Rows
    for (var tx in transactions) {
      rows.add([
        tx.id,
        tx.amount,
        tx.type,
        tx.categoryId,
        DateFormat('yyyy-MM-dd HH:mm').format(tx.date),
        tx.paymentMethod,
        tx.note ?? '',
        DateFormat('yyyy-MM-dd HH:mm').format(tx.createdAt),
      ]);
    }

    final String csvContent = const ListToCsvConverter().convert(rows);
    
    final Directory directory = await getTemporaryDirectory();
    final String currentDateStr = DateFormat('yyyy_MM_dd').format(DateTime.now());
    final String path = '${directory.path}/finora_statement_$currentDateStr.csv';
    final File file = File(path);
    await file.writeAsString(csvContent);

    // Share the file via share_plus
    await Share.shareXFiles([XFile(path)], text: 'Exported Transactions CSV Statement - Finora');
  }

  // Export Transactions to PDF and trigger Share Sheet
  Future<void> exportToPdf(List<TransactionModel> transactions, {String currencySymbol = '\$'}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Finora Financial Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Report generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Type', 'Amount', 'Payment Method', 'Note'],
              data: transactions.map((tx) {
                return [
                  DateFormat('yyyy-MM-dd').format(tx.date),
                  tx.type.toUpperCase(),
                  '$currencySymbol${tx.amount.toStringAsFixed(2)}',
                  tx.paymentMethod,
                  tx.note ?? '',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    final Directory directory = await getTemporaryDirectory();
    final String currentDateStr = DateFormat('yyyy_MM_dd').format(DateTime.now());
    final String path = '${directory.path}/finora_statement_$currentDateStr.pdf';
    final File file = File(path);
    await file.writeAsBytes(await pdf.save());

    // Share the file via share_plus
    await Share.shareXFiles([XFile(path)], text: 'Exported Transactions PDF Statement - Finora');
  }
}
