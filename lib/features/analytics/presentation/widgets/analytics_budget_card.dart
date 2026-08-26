import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/data/models/budget_model.dart';
import 'analytics_chart_card.dart';

class AnalyticsBudgetCard extends StatefulWidget {
  final List<BudgetModel> budgetsList;
  final int totalBudgeted;
  final int totalBudgetSpent;

  const AnalyticsBudgetCard({
    super.key,
    required this.budgetsList,
    required this.totalBudgeted,
    required this.totalBudgetSpent,
  });

  @override
  State<AnalyticsBudgetCard> createState() => _AnalyticsBudgetCardState();
}

class _AnalyticsBudgetCardState extends State<AnalyticsBudgetCard> {
  bool _isBudgetExpanded = false;

  @override
  Widget build(BuildContext context) {
    final double pct = widget.totalBudgeted > 0
        ? (widget.totalBudgetSpent / widget.totalBudgeted).clamp(0.0, 1.0)
        : 0.0;
    final int pctInt = (pct * 100).toInt();

    final maxVal = widget.budgetsList.fold<double>(
      1.0,
      (m, b) {
        final bMax = b.totalAmount > b.totalSpent ? b.totalAmount : b.totalSpent;
        return bMax > m ? bMax.toDouble() : m;
      },
    );
    final maxY = maxVal * 1.25;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isBudgetExpanded = !_isBudgetExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('📊 ', style: TextStyle(fontSize: 16)),
                    Text(
                      'Analitik Anggaran (Budget)',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      _isBudgetExpanded ? 'Tutup' : 'Grafik Detail',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isBudgetExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (widget.budgetsList.isEmpty)
            const Text(
              'Belum ada alokasi anggaran aktif.',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Terpakai: ${formatRupiah(widget.totalBudgetSpent)}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Batas: ${formatRupiah(widget.totalBudgeted)}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: AppColors.bgInput,
                    color: pct > 0.9 ? AppColors.error : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.budgetsList.length} anggaran aktif',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '$pctInt% Digunakan',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: pct > 0.9 ? AppColors.error : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                if (_isBudgetExpanded) ...[
                  const SizedBox(height: 18),
                  const Divider(color: AppColors.cardBorder),
                  const SizedBox(height: 12),
                  const Text(
                    'Perbandingan Anggaran vs Pengeluaran',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 170,
                    child: BarChart(
                      BarChartData(
                        maxY: maxY,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt();
                                if (idx < 0 || idx >= widget.budgetsList.length) return const SizedBox();
                                final name = widget.budgetsList[idx].name;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    name.length > 8 ? '${name.substring(0, 6)}..' : name,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 10,
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
                              final item = widget.budgetsList[groupIdx];
                              final label = rodIdx == 0 ? 'Batas Anggaran' : 'Terpakai';
                              final actualVal = rodIdx == 0 ? item.totalAmount : item.totalSpent;
                              return BarTooltipItem(
                                '${item.name}\n$label: ${formatRupiah(actualVal)}',
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
                        barGroups: List.generate(widget.budgetsList.length, (i) {
                          final b = widget.budgetsList[i];
                          // Ensure visible min height for 0 values
                          final targetY = b.totalAmount.toDouble();
                          final spentY = b.totalSpent > 0 ? b.totalSpent.toDouble() : maxY * 0.02;

                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: targetY,
                                color: AppColors.info,
                                width: 12,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                              ),
                              BarChartRodData(
                                toY: spentY,
                                color: b.totalSpent > b.totalAmount ? AppColors.error : AppColors.warning,
                                width: 12,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                              ),
                            ],
                            barsSpace: 6,
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LegendDot(color: AppColors.info, label: 'Alokasi Batas'),
                      SizedBox(width: 16),
                      LegendDot(color: AppColors.warning, label: 'Realisasi Terpakai'),
                    ],
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
