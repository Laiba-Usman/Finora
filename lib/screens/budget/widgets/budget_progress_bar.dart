import 'package:flutter/material.dart';
import '../../../utils/currency_formatter.dart';

class BudgetProgressBar extends StatelessWidget {
  final String categoryName;
  final double spent;
  final double limit;
  final String currencySymbol;

  const BudgetProgressBar({
    super.key,
    required this.categoryName,
    required this.spent,
    required this.limit,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = limit > 0 ? (spent / limit) : 0.0;
    
    // Choose progress color based on threshold
    Color progressColor = theme.colorScheme.primary;
    if (percentage >= 1.0) {
      progressColor = const Color(0xFFEF4444); // Red 500
    } else if (percentage >= 0.8) {
      progressColor = const Color(0xFFF59E0B); // Amber 500
    } else {
      progressColor = const Color(0xFF10B981); // Emerald 500
    }

    final double cappedPercentage = percentage > 1.0 ? 1.0 : percentage;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: progressColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: cappedPercentage,
              minHeight: 12,
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${spent.formatCurrency(context)}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              Text(
                'Limit: ${limit.formatCurrency(context)}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          if (spent > limit) ...[
            const SizedBox(height: 4),
            Text(
              'Exceeded by ${(spent - limit).formatCurrency(context)}!',
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
