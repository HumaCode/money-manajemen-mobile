import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'analytics_chart_card.dart';

class AnalyticsDailySpendingCard extends StatelessWidget {
  final List<double> dailySpending;

  const AnalyticsDailySpendingCard({
    super.key,
    required this.dailySpending,
  });

  @override
  Widget build(BuildContext context) {
    double maxVal = 0.0;
    for (var val in dailySpending) {
      if (val > maxVal) maxVal = val;
    }
    final maxY = maxVal > 0 ? (maxVal * 1.35) : 100.0;

    final now = DateTime.now();
    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    Widget content;
    if (dailySpending.isEmpty || maxVal == 0) {
      content = const Center(
        child: Text(
          'Belum ada pengeluaran harian (7 hari terakhir)',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      );
    } else {
      content = LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? (maxY / 3) : 30,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.cardBorder.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dailySpending.length) {
                    return const SizedBox.shrink();
                  }
                  final date = now.subtract(Duration(days: 6 - index));
                  final dayStr = dayNames[date.weekday % 7];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      dayStr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: index == 6 ? FontWeight.bold : FontWeight.w500,
                        color: index == 6 ? AppColors.accent : AppColors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF161E31),
              getTooltipItems: (spots) => spots.map((s) {
                final amountInRupiah = (s.y * 1000).toInt();
                return LineTooltipItem(
                  formatRupiah(amountInRupiah),
                  const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                dailySpending.length,
                (i) => FlSpot(i.toDouble(), dailySpending[i]),
              ),
              isCurved: true,
              preventCurveOverShooting: true,
              isStrokeCapRound: true,
              color: AppColors.accent,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => spot.y > 0,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.accent,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF0A0F1D),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.35),
                    AppColors.accent.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnalyticsChartCard(
      title: 'Pengeluaran Harian',
      subtitle: '7 Hari Terakhir',
      child: SizedBox(
        height: 180,
        child: content,
      ),
    );
  }
}
