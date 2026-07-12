import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import 'package:intl/intl.dart';

class TrendChartWidget extends StatelessWidget {
  final List<TransactionModel> transactions;

  const TrendChartWidget({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final now = DateTime.now();
    final expenses = transactions.where((tx) => 
        tx.type == 'expense' && 
        tx.date.year == now.year && 
        tx.date.month == now.month).toList();

    if (expenses.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No spending data to display trend.'),
        ),
      );
    }

    // 1. Group expenses by date (day of month)
    final Map<int, double> dailySums = {};
    for (var tx in expenses) {
      final day = tx.date.day;
      dailySums[day] = (dailySums[day] ?? 0) + tx.amount;
    }

    // 2. Generate spots
    final List<FlSpot> spots = [];
    final int daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    
    for (int i = 1; i <= daysInMonth; i++) {
      // If we are looking ahead in the current month, don't plot zero spots for future days
      if (DateTime.now().month == DateTime.now().month && i > DateTime.now().day) {
        break;
      }
      final double total = dailySums[i] ?? 0;
      spots.add(FlSpot(i.toDouble(), total));
    }

    if (spots.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Not enough data.')),
      );
    }

    // Find min and max for bounds
    double maxAmount = 100.0;
    for (var spot in spots) {
      if (spot.y > maxAmount) {
        maxAmount = spot.y;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 1,
              maxX: spots.length.toDouble(),
              minY: 0,
              maxY: maxAmount * 1.1,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Days of the Month (${DateFormat('MMMM').format(DateTime.now())})',
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
