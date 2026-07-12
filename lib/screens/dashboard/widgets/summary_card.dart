import 'package:flutter/material.dart';
import '../../../utils/currency_formatter.dart';

class SummaryCard extends StatelessWidget {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final String currencySymbol;

  const SummaryCard({
    super.key,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 0 : 4,
      shadowColor: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [theme.colorScheme.surface, theme.colorScheme.surface.withOpacity(0.8)]
                : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.85)],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(totalBalance, currencySymbol: currencySymbol),
              style: TextStyle(
                color: isDark ? theme.colorScheme.primary : Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Color(0xFF34D399), // Emerald 400
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(totalIncome, currencySymbol: currencySymbol),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward,
                          color: Color(0xFFF87171), // Red 400
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expenses',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(totalExpense, currencySymbol: currencySymbol),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
