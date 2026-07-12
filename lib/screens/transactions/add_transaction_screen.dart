import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/validators.dart';
import '../../utils/date_formatter.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _transactionType = 'expense'; // 'income' or 'expense'
  String? _selectedCategoryId;
  String _paymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  String? _receiptImagePath;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image == null) return;

      // On Windows the XFile.path may be a URI (file:///) not a plain path.
      // Copy bytes to a temp file so we always get a real filesystem path.
      final bytes = await image.readAsBytes();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(bytes);

      setState(() {
        _receiptImagePath = tempFile.path;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking receipt image: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final txProvider = Provider.of<TransactionProvider>(context, listen: false);
        final catProvider = Provider.of<CategoryProvider>(context, listen: false);
        final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

        final newTx = TransactionModel(
          id: const Uuid().v4(),
          amount: double.parse(_amountController.text.trim()),
          type: _transactionType,
          categoryId: _selectedCategoryId!,
          note: _noteController.text.trim(),
          paymentMethod: _paymentMethod,
          date: _selectedDate,
          receiptPath: _receiptImagePath,
          isSynced: false,
          createdAt: DateTime.now(),
        );

        final userId = authProvider.user?.uid;
        
        // Save to provider (inserts in SQLite & attempts Firestore sync)
        await txProvider.addTransaction(newTx, userId: userId);

        // Check category and overall budget alerts if it is an expense
        if (_transactionType == 'expense') {
          final cat = catProvider.getCategoryById(_selectedCategoryId!);
          final monthStr = DateFormatter.toYearMonthString(_selectedDate);
          
          // Check specific category threshold
          await budgetProvider.checkBudgetThresholds(
            txProvider.transactions,
            monthStr,
            cat?.name,
            categoryId: _selectedCategoryId,
          );

          // Check overall threshold
          await budgetProvider.checkBudgetThresholds(
            txProvider.transactions,
            monthStr,
            'Overall',
            categoryId: null,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction added successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving transaction: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catProvider = Provider.of<CategoryProvider>(context);

    // Get categories filtered by current transaction type
    final filteredCategories = _transactionType == 'expense'
        ? catProvider.expenseCategories
        : catProvider.incomeCategories;

    // Adjust selected category if it does not belong to currently selected type
    if (_selectedCategoryId != null &&
        !filteredCategories.any((cat) => cat.id == _selectedCategoryId)) {
      _selectedCategoryId = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transaction Type Selector
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Expense')),
                      selected: _transactionType == 'expense',
                      onSelected: (selected) {
                        if (selected) setState(() => _transactionType = 'expense');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Income')),
                      selected: _transactionType == 'income',
                      onSelected: (selected) {
                        if (selected) setState(() => _transactionType = 'income');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Amount Field
              CustomTextField(
                controller: _amountController,
                labelText: 'Amount',
                hintText: '0.00',
                prefixIcon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.validateAmount,
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                hint: const Text('Select Category'),
                items: filteredCategories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Note Field
              CustomTextField(
                controller: _noteController,
                labelText: 'Note',
                hintText: 'Enter notes or tags',
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 20),

              // Payment Method
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.payment_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'online', child: Text('Online / Bank Transfer')),
                ],
                onChanged: (val) {
                  setState(() {
                    _paymentMethod = val ?? 'cash';
                  });
                },
              ),
              const SizedBox(height: 20),

              // Date Picker Button
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text('Date: ${DateFormatter.formatDate(_selectedDate)}'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Receipt Attachment
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), style: BorderStyle.values[1]), // Dashed style is simulated
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _receiptImagePath != null
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_receiptImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _receiptImagePath = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              'Attach Receipt (Optional)',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
              CustomButton(
                text: 'Save Transaction',
                isLoading: _isLoading,
                onPressed: _saveTransaction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
