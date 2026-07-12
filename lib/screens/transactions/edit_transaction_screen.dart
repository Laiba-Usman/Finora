import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/validators.dart';
import '../../utils/date_formatter.dart';

class EditTransactionScreen extends StatefulWidget {
  const EditTransactionScreen({super.key});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  TransactionModel? _originalTransaction;
  String _transactionType = 'expense';
  String? _selectedCategoryId;
  String _paymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  String? _receiptImagePath;
  bool _isLoading = false;
  bool _initialized = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final tx = ModalRoute.of(context)!.settings.arguments as TransactionModel;
      _originalTransaction = tx;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';
      _transactionType = tx.type;
      _selectedCategoryId = tx.categoryId;
      _paymentMethod = tx.paymentMethod;
      _selectedDate = tx.date;
      _receiptImagePath = tx.receiptPath;
      _initialized = true;
    }
  }

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

      // On Windows the XFile.path may be a URI — copy bytes to a real temp file.
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

  Future<void> _updateTransaction() async {
    if (_formKey.currentState!.validate() && _originalTransaction != null) {
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

        final updatedTx = _originalTransaction!.copyWith(
          amount: double.parse(_amountController.text.trim()),
          type: _transactionType,
          categoryId: _selectedCategoryId!,
          note: _noteController.text.trim(),
          paymentMethod: _paymentMethod,
          date: _selectedDate,
          receiptPath: _receiptImagePath,
        );

        final userId = authProvider.user?.uid;
        await txProvider.updateTransaction(updatedTx, userId: userId);

        if (_transactionType == 'expense') {
          final cat = catProvider.getCategoryById(_selectedCategoryId!);
          final monthStr = DateFormatter.toYearMonthString(_selectedDate);

          await budgetProvider.checkBudgetThresholds(
            txProvider.transactions,
            monthStr,
            cat?.name,
            categoryId: _selectedCategoryId,
          );
          
          await budgetProvider.checkBudgetThresholds(
            txProvider.transactions,
            monthStr,
            'Overall',
            categoryId: null,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction updated successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating transaction: $e')),
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

    final filteredCategories = _transactionType == 'expense'
        ? catProvider.expenseCategories
        : catProvider.incomeCategories;

    if (_selectedCategoryId != null &&
        !filteredCategories.any((cat) => cat.id == _selectedCategoryId)) {
      _selectedCategoryId = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              CustomTextField(
                controller: _amountController,
                labelText: 'Amount',
                hintText: '0.00',
                prefixIcon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.validateAmount,
              ),
              const SizedBox(height: 20),
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
              CustomTextField(
                controller: _noteController,
                labelText: 'Note',
                hintText: 'Enter notes or tags',
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: 20),
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
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
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
              CustomButton(
                text: 'Update Transaction',
                isLoading: _isLoading,
                onPressed: _updateTransaction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
