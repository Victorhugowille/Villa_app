import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PaymentMethodPieChart extends StatelessWidget {
  final Map<String, double> revenueByPaymentMethod;
  const PaymentMethodPieChart({super.key, required this.revenueByPaymentMethod});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Color> colors = [
      theme.primaryColor,
      theme.colorScheme.secondary,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.brown,
    ];

    int colorIndex = 0;
    final sections = revenueByPaymentMethod.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      final totalRevenue = revenueByPaymentMethod.values.fold(0.0, (a, b) => a + b);
      final percentage = totalRevenue > 0 ? (entry.value / totalRevenue * 100) : 0.0;
      
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.key}\n${percentage.toStringAsFixed(0)}%',
        radius: 80, // Raio menor
        titleStyle: const TextStyle(
          fontSize: 11, // Fonte menor
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    }).toList();

    return AspectRatio(
      aspectRatio: 2.2, // Proporção mais larga
      child: PieChart(
        PieChartData(
          sections: sections.isNotEmpty ? sections : [
             PieChartSectionData(
              color: Colors.grey[300],
              value: 1,
              title: 'Sem dados',
              radius: 80,
              titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            )
          ],
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 30, // Centro menor
        ),
      ),
    );
  }
}