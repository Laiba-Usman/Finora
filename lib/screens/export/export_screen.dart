import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ExportService _exportService = ExportService();
  bool _isExportingCsv = false;
  bool _isExportingPdf = false;

  Future<void> _exportCsv() async {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    if (txProvider.transactions.isEmpty) {
      _showEmptyWarning();
      return;
    }

    setState(() => _isExportingCsv = true);
    try {
      await _exportService.exportToCsv(txProvider.transactions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingCsv = false);
      }
    }
  }

  Future<void> _exportPdf() async {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    if (txProvider.transactions.isEmpty) {
      _showEmptyWarning();
      return;
    }

    setState(() => _isExportingPdf = true);
    try {
      await _exportService.exportToPdf(
        txProvider.transactions,
        currencySymbol: themeProvider.currencySymbol,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  void _showEmptyWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Data'),
        content: const Text(
          'There are no transactions in your history to export. Log some transactions first!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.picture_as_pdf, size: 80, color: Colors.redAccent),
            const SizedBox(height: 24),
            const Text(
              'Export Financial Statements',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Generate offline statements of your transaction records. Share or open them in third party apps.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // CSV Export Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.table_rows, color: Colors.green, size: 36),
                title: const Text('Export to CSV'),
                subtitle: const Text('Best for spreadsheet tools like Excel/Sheets'),
                trailing: _isExportingCsv 
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.download),
                onTap: _isExportingCsv ? null : _exportCsv,
              ),
            ),
            const SizedBox(height: 16),
            // PDF Export Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
                title: const Text('Export to PDF'),
                subtitle: const Text('Best for printing or formal sharing'),
                trailing: _isExportingPdf
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.download),
                onTap: _isExportingPdf ? null : _exportPdf,
              ),
            ),
            const Spacer(),
            Text(
              'Total available records: ${txProvider.transactions.length}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
