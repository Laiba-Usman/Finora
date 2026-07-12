import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/currency_converter_provider.dart';
import '../../widgets/custom_button.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<CurrencyConverterProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Currency Converter'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Converter Card
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Amount Input Field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount to Convert',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amt = double.tryParse(val.trim());
                          if (amt == null) {
                            return 'Please enter a valid number';
                          }
                          if (amt <= 0) {
                            return 'Amount must be greater than zero';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // From Currency Dropdown
                      DropdownButtonFormField<String>(
                        value: provider.fromCurrency,
                        decoration: const InputDecoration(
                          labelText: 'From Currency',
                          prefixIcon: Icon(Icons.keyboard_arrow_right),
                        ),
                        items: provider.currencies
                            .map((code) => DropdownMenuItem(
                                  value: code,
                                  child: Text(code),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) provider.setFromCurrency(val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Swap/Reverse Icon Button
                      Center(
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                          child: IconButton(
                            onPressed: provider.swapCurrencies,
                            icon: Icon(
                              Icons.swap_vert,
                              color: theme.colorScheme.secondary == Colors.yellow || theme.colorScheme.secondary.value == 0xFFFFC436
                                  ? theme.brightness == Brightness.dark ? Colors.yellow : const Color(0xFF200E26)
                                  : theme.colorScheme.secondary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // To Currency Dropdown
                      DropdownButtonFormField<String>(
                        value: provider.toCurrency,
                        decoration: const InputDecoration(
                          labelText: 'To Currency',
                          prefixIcon: Icon(Icons.keyboard_arrow_left),
                        ),
                        items: provider.currencies
                            .map((code) => DropdownMenuItem(
                                  value: code,
                                  child: Text(code),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) provider.setToCurrency(val);
                        },
                      ),
                      const SizedBox(height: 28),

                      // Convert Button
                      CustomButton(
                        text: 'Convert',
                        isLoading: provider.isLoading,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final amt = double.tryParse(_amountController.text.trim());
                            if (amt != null) {
                              provider.convertCurrency(
                                inputAmount: amt,
                                from: provider.fromCurrency,
                                to: provider.toCurrency,
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Error Message Section
                if (provider.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 24.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: theme.colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Results Card Section
                if (provider.convertedAmount != null && provider.exchangeRate != null)
                  Container(
                    margin: const EdgeInsets.only(top: 24.0),
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Conversion Result',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${NumberFormat('#,##0.00').format(provider.amount)} ${provider.fromCurrency}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Icon(Icons.arrow_downward, size: 20, color: Colors.grey),
                        ),
                        Text(
                          '${NumberFormat('#,##0.00').format(provider.convertedAmount)} ${provider.toCurrency}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Divider(height: 32),
                        Text(
                          'Exchange Rate: 1 ${provider.fromCurrency} = ${provider.exchangeRate} ${provider.toCurrency}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (provider.isCachedData) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Showing last cached rate — connect to internet for latest rates',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
