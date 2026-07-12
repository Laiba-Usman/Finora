import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../models/category_model.dart';
import '../../../utils/extensions.dart';

import '../../../utils/currency_formatter.dart';

class PieChartWidget extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  const PieChartWidget({
    super.key,
    required this.transactions,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final expenseTransactions = transactions.where((tx) => 
        tx.type == 'expense' && 
        tx.date.year == now.year && 
        tx.date.month == now.month).toList();

    if (expenseTransactions.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No expenses logged for this month.'),
        ),
      );
    }

    // 1. Group expenses by category
    final Map<String, double> categorySums = {};
    double totalExpenseAmount = 0;
    for (var tx in expenseTransactions) {
      categorySums[tx.categoryId] = (categorySums[tx.categoryId] ?? 0) + tx.amount;
      totalExpenseAmount += tx.amount;
    }

    // 2. Generate PieChart sections
    final List<PieChartSectionData> sections = [];
    categorySums.forEach((categoryId, amount) {
      final category = _getCategory(categoryId);
      final double percentage = totalExpenseAmount > 0 ? (amount / totalExpenseAmount) * 100 : 0;
      
      sections.add(
        PieChartSectionData(
          color: category.color.toColor(),
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: categorySums.keys.map((catId) {
            final cat = _getCategory(catId);
            final double amt = categorySums[catId]!;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: cat.color.toColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${cat.name} (${amt.formatCurrencyInt(context)})',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        )
      ],
    );
  }

  CategoryModel _getCategory(String id) {
    try {
      return categories.firstWhere((cat) => cat.id == id);
    } catch (_) {
      return CategoryModel(
        id: id,
        name: 'Unknown',
        icon: 'help',
        color: '#64748B',
        type: 'expense',
      );
    }
  }
}
