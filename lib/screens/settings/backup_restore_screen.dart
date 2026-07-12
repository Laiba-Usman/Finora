import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_button.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _backupData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    if (authProvider.isGuest || authProvider.user == null) {
      _showGuestWarning();
      return;
    }

    setState(() => _isBackingUp = true);

    try {
      final userId = authProvider.user!.uid;
      // Triggers provider to push all unsynced or all transactions
      await txProvider.syncUnsyncedTransactions(userId);
      // Backup all monthly budgets
      await budgetProvider.syncAllBudgets(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup complete! All data synced to cloud.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _restoreData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    if (authProvider.isGuest || authProvider.user == null) {
      _showGuestWarning();
      return;
    }

    setState(() => _isRestoring = true);

    try {
      final userId = authProvider.user!.uid;
      // Fetch cloud records
      final cloudTxs = await _firestoreService.fetchTransactions(userId);
      
      // Restore budgets from cloud
      final currentMonth = DateFormatter.toYearMonthString(DateTime.now());
      await budgetProvider.restoreBudgets(userId, currentMonth);

      if (cloudTxs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backup records found on cloud.')),
          );
        }
      } else {
        // Insert into local DB
        for (var tx in cloudTxs) {
          await txProvider.addTransaction(tx);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restored ${cloudTxs.length} transactions from cloud.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  void _showGuestWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text(
          'Cloud sync is not available in Guest mode. Please sign in or create an account to back up your data.',
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
    final authProvider = Provider.of<AuthProvider>(context);
    final isGuest = authProvider.isGuest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cloud_queue, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Secure Cloud Synchronization',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Keep your data safe. Back up your transactions to Firestore database and restore them anytime on any device.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            if (isGuest) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.amber),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You are currently logged in as a Guest. Cloud synchronization features are disabled.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            CustomButton(
              text: 'Backup to Cloud',
              isLoading: _isBackingUp,
              onPressed: isGuest ? _showGuestWarning : _backupData,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: isGuest ? _showGuestWarning : (_isRestoring ? null : _restoreData),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isRestoring
                  ? const CircularProgressIndicator()
                  : const Text('Restore from Cloud'),
            ),
          ],
        ),
      ),
    );
  }
}
