import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/category_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedType;
  String? _selectedCategoryId;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    _selectedType = txProvider.filterType;
    _selectedCategoryId = txProvider.filterCategoryId;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txProvider = Provider.of<TransactionProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Transactions',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 20),
          // Type Selector
          Text('Type', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('All')),
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = null);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Income')),
                  selected: _selectedType == 'income',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = 'income');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Expense')),
                  selected: _selectedType == 'expense',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = 'expense');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Category Selector
          Text('Category', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            hint: const Text('All Categories'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Categories'),
              ),
              ...catProvider.categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat.id,
                  child: Text(cat.name),
                );
              }),
            ],
            onChanged: (val) {
              setState(() {
                _selectedCategoryId = val;
              });
            },
          ),
          const SizedBox(height: 20),
          // Date Range Selector
          Text('Date Range', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range),
            label: Text(
              _selectedDateRange == null
                  ? 'Select Date Range'
                  : '${_selectedDateRange!.start.toString().split(' ')[0]} to ${_selectedDateRange!.end.toString().split(' ')[0]}',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),
          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    txProvider.clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    txProvider.setFilterType(_selectedType);
                    txProvider.setFilterCategory(_selectedCategoryId);
                    if (_selectedDateRange != null) {
                      txProvider.setDateRange(
                        _selectedDateRange!.start,
                        _selectedDateRange!.end,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
