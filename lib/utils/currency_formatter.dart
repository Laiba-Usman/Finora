import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';

class CurrencyFormatter {
  static String format(double amount, {String currencySymbol = '\$'}) {
    final format = NumberFormat.currency(
      symbol: '$currencySymbol ',
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  static String formatCompact(double amount, {String currencySymbol = '\$'}) {
    if (currencySymbol != '\$') {
      return '$currencySymbol ${NumberFormat.compact().format(amount)}';
    }
    final format = NumberFormat.compactSimpleCurrency(name: 'USD');
    return format.format(amount);
  }
}

extension CurrencyFormatterExtension on num {
  String formatCurrency(BuildContext context, {bool listen = true}) {
    final currencySymbol = Provider.of<ThemeProvider>(context, listen: listen).currencySymbol;
    return CurrencyFormatter.format(toDouble(), currencySymbol: currencySymbol);
  }

  String formatCurrencyInt(BuildContext context, {bool listen = true}) {
    final currencySymbol = Provider.of<ThemeProvider>(context, listen: listen).currencySymbol;
    final format = NumberFormat.currency(
      symbol: '$currencySymbol ',
      decimalDigits: 0,
    );
    return format.format(toDouble());
  }

  String formatCurrencyCompact(BuildContext context, {bool listen = true}) {
    final currencySymbol = Provider.of<ThemeProvider>(context, listen: listen).currencySymbol;
    return CurrencyFormatter.formatCompact(toDouble(), currencySymbol: currencySymbol);
  }
}
