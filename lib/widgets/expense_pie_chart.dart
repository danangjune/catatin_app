import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpensePieChart extends StatelessWidget {
  final List<ExpenseData> expenses;

  const ExpensePieChart({Key? key, required this.expenses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: PieChart(
        PieChartData(
          sections:
              expenses.map((data) {
                return PieChartSectionData(
                  color: data.color,
                  value: data.percentage,
                  title: '${data.percentage.toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}

class ExpenseData {
  final String category;
  final double amount;
  final double percentage;
  final Color color;

  ExpenseData({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}
