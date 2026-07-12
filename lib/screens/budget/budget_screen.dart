import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/date_formatter.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_textfield.dart';
import 'widgets/budget_progress_bar.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime _currentMonthDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final monthStr = DateFormatter.toYearMonthString(_currentMonthDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BudgetProvider>(context, listen: false).loadBudgets(monthStr);
      Provider.of<TransactionProvider>(context, listen: false).loadTransactions();
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonthDate = DateTime(
        _currentMonthDate.year,
        _currentMonthDate.month + offset,
      );
    });
    _loadData();
  }

  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => AddBudgetDialog(
        currentMonth: DateFormatter.toYearMonthString(_currentMonthDate),
        onSave: () => _loadData(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);

    final monthStr = DateFormatter.toYearMonthString(_currentMonthDate);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Budgets'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Month Selector Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.08),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      DateFormatter.formatMonth(_currentMonthDate),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Budgets List
          Expanded(
            child: budgetProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : budgetProvider.budgets.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.monetization_on_outlined,
                                    size: 64,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Manage Spending Limits',
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Set limits for categories or overall budgets to receive real-time notifications.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 28),
                                ElevatedButton.icon(
                                  onPressed: _showAddBudgetDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Set Monthly Budget'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        itemCount: budgetProvider.budgets.length,
                        itemBuilder: (context, index) {
                          final budget = budgetProvider.budgets[index];
                          final spent = budgetProvider.getSpentAmount(budget, txProvider.transactions);
                          
                          String categoryName = 'Overall Budget';
                          if (budget.categoryId != null) {
                            final cat = catProvider.getCategoryById(budget.categoryId!);
                            categoryName = cat?.name ?? 'Unknown Category';
                          }

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              side: BorderSide(
                                color: theme.colorScheme.outline.withOpacity(0.08),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  BudgetProgressBar(
                                    categoryName: categoryName,
                                    spent: spent,
                                    limit: budget.amount,
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AddBudgetDialog(
                                              currentMonth: monthStr,
                                              budgetToEdit: budget,
                                              onSave: () => _loadData(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        label: const Text('Edit'),
                                      ),
                                      const SizedBox(width: 12),
                                      TextButton.icon(
                                        onPressed: () async {
                                          await budgetProvider.deleteBudget(budget.id, monthStr);
                                          _loadData();
                                        },
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: budgetProvider.budgets.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _showAddBudgetDialog,
              tooltip: 'Set Budget',
              child: const Icon(Icons.add),
            ),
    );
  }
}

class AddBudgetDialog extends StatefulWidget {
  final String currentMonth;
  final BudgetModel? budgetToEdit;
  final VoidCallback onSave;

  const AddBudgetDialog({
    required this.currentMonth,
    this.budgetToEdit,
    required this.onSave,
  });

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.budgetToEdit != null) {
      _amountController.text = widget.budgetToEdit!.amount.toString();
      _selectedCategoryId = widget.budgetToEdit!.categoryId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = Provider.of<CategoryProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isEditing = widget.budgetToEdit != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Budget Limit' : 'Set Budget Limit'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category Selection (disabled when editing)
              if (isEditing)
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Target Category',
                    border: InputBorder.none,
                  ),
                  child: Text(
                    _selectedCategoryId == null
                        ? 'Overall Budget (All Categories)'
                        : (catProvider.getCategoryById(_selectedCategoryId!)?.name ?? 'Unknown Category'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Target Category',
                  ),
                  hint: const Text('Overall Budget (All Categories)'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Overall Budget (All)'),
                    ),
                    ...catProvider.expenseCategories.map((cat) {
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
              // Limit Amount
              CustomTextField(
                controller: _amountController,
                labelText: 'Limit Amount',
                hintText: 'e.g. 500.00',
                prefixIcon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.validateAmount,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final budget = isEditing
                  ? widget.budgetToEdit!.copyWith(
                      amount: double.parse(_amountController.text.trim()),
                    )
                  : BudgetModel(
                      id: const Uuid().v4(),
                      categoryId: _selectedCategoryId,
                      amount: double.parse(_amountController.text.trim()),
                      month: widget.currentMonth,
                    );
              
              final userId = authProvider.user?.uid;
              await budgetProvider.setBudget(budget, userId: userId);
              widget.onSave();
              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
