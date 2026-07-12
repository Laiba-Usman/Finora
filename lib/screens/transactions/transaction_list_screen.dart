import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'widgets/transaction_tile.dart';
import 'widgets/filter_bottom_sheet.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false).loadTransactions();
    });
  }

  void _onSearchChanged() {
    Provider.of<TransactionProvider>(context, listen: false)
        .setSearchQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txProvider = Provider.of<TransactionProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          // Transaction List
          Expanded(
            child: txProvider.isLoading
                ? const LoadingIndicator(message: 'Filtering transactions...')
                : txProvider.filteredTransactions.isEmpty
                    ? const EmptyState(
                        title: 'No results found',
                        description: 'Try adjusting your filters or search query.',
                        icon: Icons.search_off_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: txProvider.filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = txProvider.filteredTransactions[index];
                          final category = catProvider.getCategoryById(tx.categoryId);
                          
                          // Wrap in Dismissible for swiping to delete
                          return Dismissible(
                            key: Key(tx.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              color: theme.colorScheme.error,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) async {
                              final userId = authProvider.user?.uid;
                              await txProvider.deleteTransaction(tx.id, userId: userId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Transaction deleted')),
                                );
                              }
                            },
                            child: TransactionTile(
                              transaction: tx,
                              category: category,
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.editTransaction,
                                  arguments: tx,
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.addTransaction);
        },
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
