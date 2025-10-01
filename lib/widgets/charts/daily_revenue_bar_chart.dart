import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DailyRevenueBarChart extends StatelessWidget {
  final Map<DateTime, double> dailyRevenue;
  const DailyRevenueBarChart({super.key, required this.dailyRevenue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barGroups = dailyRevenue.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key.millisecondsSinceEpoch,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: theme.primaryColor,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return AspectRatio(
      aspectRatio: 2.5, // Proporção mais larga
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(DateFormat('dd/MM').format(date)),
                  );
                },
                reservedSize: 30,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final date = DateTime.fromMillisecondsSinceEpoch(group.x.toInt());
                return BarTooltipItem(
                  '${DateFormat('dd/MM/yyyy').format(date)}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'R\$ ${rod.toY.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: rod.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}