import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/data/models/savings_goal_model.dart' as saving_model;
import 'analytics_chart_card.dart';

class AnalyticsSavingsCard extends StatefulWidget {
  final List<saving_model.Data> savingsList;
  final int totalSavingsCurrent;
  final int totalSavingsTarget;

  const AnalyticsSavingsCard({
    super.key,
    required this.savingsList,
    required this.totalSavingsCurrent,
    required this.totalSavingsTarget,
  });

  @override
  State<AnalyticsSavingsCard> createState() => _AnalyticsSavingsCardState();
}

class _AnalyticsSavingsCardState extends State<AnalyticsSavingsCard> {
  bool _isSavingsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final double pct = widget.totalSavingsTarget > 0
        ? (widget.totalSavingsCurrent / widget.totalSavingsTarget).clamp(0.0, 1.0)
        : 0.0;
    final int pctInt = (pct * 100).toInt();

    final colorsList = [
      AppColors.accent,
      AppColors.info,
      AppColors.purple,
      AppColors.warning,
      AppColors.success,
    ];

    final maxVal = widget.savingsList.fold<double>(
      1.0,
      (m, s) {
        final sMax = s.targetAmount > s.currentAmount ? s.targetAmount : s.currentAmount;
        return sMax > m ? sMax.toDouble() : m;
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
                _isSavingsExpanded = !_isSavingsExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🎯 ', style: TextStyle(fontSize: 16)),
                    Text(
                      'Analitik Tabungan (Savings)',
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
                      _isSavingsExpanded ? 'Tutup' : 'Grafik Detail',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isSavingsExpanded
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
          if (widget.savingsList.isEmpty)
            const Text(
              'Belum ada impian tabungan aktif.',
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
                      'Terkumpul: ${formatRupiah(widget.totalSavingsCurrent)}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Target: ${formatRupiah(widget.totalSavingsTarget)}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
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
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.savingsList.length} impian aktif',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '$pctInt% Tercapai',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                if (_isSavingsExpanded) ...[
                  const SizedBox(height: 18),
                  const Divider(color: AppColors.cardBorder),
                  const SizedBox(height: 12),
                  const Text(
                    'Progres Per Impian Tabungan',
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
                                if (idx < 0 || idx >= widget.savingsList.length) return const SizedBox();
                                final name = widget.savingsList[idx].name;
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
                              final s = widget.savingsList[groupIdx];
                              final label = rodIdx == 0 ? 'Terkumpul' : 'Target';
                              final actualVal = rodIdx == 0 ? s.currentAmount : s.targetAmount;
                              return BarTooltipItem(
                                '${s.name}\n$label: ${formatRupiah(actualVal)}',
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
                        barGroups: List.generate(widget.savingsList.length, (i) {
                          final s = widget.savingsList[i];
                          final currentY = s.currentAmount > 0 ? s.currentAmount.toDouble() : maxY * 0.02;
                          final targetY = s.targetAmount.toDouble();

                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: currentY,
                                color: colorsList[i % colorsList.length],
                                width: 12,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                              ),
                              BarChartRodData(
                                toY: targetY,
                                color: AppColors.cardBorder,
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
                      LegendDot(color: AppColors.accent, label: 'Terkumpul'),
                      SizedBox(width: 16),
                      LegendDot(color: AppColors.cardBorder, label: 'Target Total'),
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
