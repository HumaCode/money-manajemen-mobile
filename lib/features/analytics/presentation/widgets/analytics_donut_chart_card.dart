import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_empty_state.dart';
import 'package:money_manajemen/data/models/category_spend_model.dart';
import 'analytics_chart_card.dart';

class AnalyticsDonutChartCard extends StatefulWidget {
  final List<CategorySpendModel> categorySpends;

  const AnalyticsDonutChartCard({
    super.key,
    required this.categorySpends,
  });

  @override
  State<AnalyticsDonutChartCard> createState() => _AnalyticsDonutChartCardState();
}

class _AnalyticsDonutChartCardState extends State<AnalyticsDonutChartCard> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.categorySpends.fold<int>(0, (sum, c) => sum + c.amount);
    final colors = [
      AppColors.accent,
      AppColors.info,
      AppColors.purple,
      AppColors.warning,
    ];

    Widget content;
    if (widget.categorySpends.isEmpty || total == 0) {
      content = const AppEmptyState(
        compact: true,
        icon: Icons.pie_chart_outline_rounded,
        title: 'Belum Ada Data Pengeluaran',
        message: 'Grafik distribusi pengeluaran akan muncul secara otomatis di sini.',
      );
    } else {
      content = Row(
        children: [
          Expanded(
            flex: 5,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 42,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: List.generate(widget.categorySpends.length, (i) {
                  final c = widget.categorySpends[i];
                  final isTouched = i == _touchedPieIndex;
                  final radius = isTouched ? 46.0 : 40.0;
                  return PieChartSectionData(
                    value: c.amount.toDouble(),
                    color: colors[i % colors.length],
                    radius: radius,
                    showTitle: false,
                  );
                }),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.categorySpends.length, (i) {
                final c = widget.categorySpends[i];
                final pct = (c.amount / total * 100).toStringAsFixed(0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[i % colors.length],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${c.name} $pct%',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      );
    }

    return AnalyticsChartCard(
      title: 'Distribusi Pengeluaran',
      subtitle: 'Per kategori',
      child: SizedBox(
        height: 200,
        child: content,
      ),
    );
  }
}
