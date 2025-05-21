import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendBarChart extends StatelessWidget {
  final List<FinancialData> data;

  const TrendBarChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              data
                  .map((e) => e.income > e.expense ? e.income : e.expense)
                  .reduce((a, b) => a > b ? a : b) *
              1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Text(
                      data[value.toInt()].month,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups:
              data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.income,
                      color: Color(0xFF20BF55),
                      width: 12,
                    ),
                    BarChartRodData(
                      toY: entry.value.expense,
                      color: Colors.redAccent,
                      width: 12,
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}

class FinancialData {
  final String month;
  final double income;
  final double expense;

  FinancialData({
    required this.month,
    required this.income,
    required this.expense,
  });
}
