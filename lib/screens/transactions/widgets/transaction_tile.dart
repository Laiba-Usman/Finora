import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../models/category_model.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/extensions.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final VoidCallback onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    required this.onTap,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'payments':
        return Icons.payments;
      case 'laptop':
        return Icons.laptop;
      case 'trending_up':
        return Icons.trending_up;
      case 'add_card':
        return Icons.add_card;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.type == 'expense';
    
    // Category Details
    final catName = category?.name ?? 'Uncategorized';
    final catColorHex = category?.color ?? '#64748B';
    final catIconName = category?.icon ?? 'category';
    
    final catColor = catColorHex.toColor();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: catColor.withOpacity(0.15),
          child: Icon(
            _getIconData(catIconName),
            color: catColor,
          ),
        ),
        title: Text(
          transaction.note?.isNotEmpty == true ? transaction.note! : catName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.note?.isNotEmpty == true) ...[
              Text(
                catName,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              DateFormatter.formatShortDate(transaction.date),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isExpense ? "-" : "+"}${transaction.amount.formatCurrency(context)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isExpense 
                    ? const Color(0xFFEF4444) // Red 500
                    : const Color(0xFF10B981), // Emerald 500
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
