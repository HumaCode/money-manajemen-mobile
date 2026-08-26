import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'analytics_chart_card.dart';

class AnalyticsBarChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;

  const AnalyticsBarChartCard({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
    double maxVal = 1.0;
    for (var d in monthlyData) {
      final inc = (d['income'] as num).toDouble();
      final exp = (d['expense'] as num).toDouble();
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    final maxY = maxVal * 1.2;

    return AnalyticsChartCard(
      title: 'Pemasukan vs Pengeluaran',
      subtitle: '6 bulan terakhir',
      legend: const [
        LegendDot(color: AppColors.success, label: 'Pemasukan'),
        LegendDot(color: AppColors.error, label: 'Pengeluaran'),
      ],
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= monthlyData.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        monthlyData[index]['label'],
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.bgCardHover,
                getTooltipItem: (group, groupIdx, rod, rodIdx) {
                  final label = rodIdx == 0 ? 'Income' : 'Expense';
                  return BarTooltipItem(
                    '$label\nRp ${rod.toY.toStringAsFixed(1)}Jt',
                    const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  );
                },
              ),
            ),
            barGroups: List.generate(monthlyData.length, (i) {
              final d = monthlyData[i];
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: d['income'],
                    color: AppColors.success,
                    width: 8,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  BarChartRodData(
                    toY: d['expense'],
                    color: AppColors.error,
                    width: 8,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
                barsSpace: 4,
              );
            }),
          ),
        ),
      ),
    );
  }
}
