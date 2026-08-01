import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_bottom_nav.dart';
import '../widgets/category_progress_row.dart';
import '../models/category_spend_model.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:money_manajemen/features/transactions/presentation/pages/transactions_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  int _navIndex = 2;
  String _activePeriod = 'Bulan Ini';
  int _touchedPieIndex = -1;

  final List<String> _periods = const ['Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

  final List<CategorySpendModel> _categorySpends = const [
    CategorySpendModel(
      name: 'Makanan',
      emoji: '🍔',
      amount: 3200000,
      percentage: 0.85,
    ),
    CategorySpendModel(
      name: 'Transportasi',
      emoji: '🚗',
      amount: 2100000,
      percentage: 0.65,
    ),
    CategorySpendModel(
      name: 'Belanja',
      emoji: '🛍️',
      amount: 1800000,
      percentage: 0.50,
    ),
    CategorySpendModel(
      name: 'Tagihan',
      emoji: '💡',
      amount: 1400000,
      percentage: 0.35,
    ),
  ];

  final List<Map<String, dynamic>> _monthlyData = const [
    {'label': 'Ags', 'income': 12.0, 'expense': 7.5},
    {'label': 'Sep', 'income': 13.5, 'expense': 8.2},
    {'label': 'Okt', 'income': 14.2, 'expense': 7.8},
    {'label': 'Nov', 'income': 13.8, 'expense': 8.5},
    {'label': 'Des', 'income': 14.5, 'expense': 7.9},
    {'label': 'Jan', 'income': 15.0, 'expense': 8.5},
  ];

  final List<double> _dailySpending = const [250, 180, 320, 290, 410, 350, 280];

  Animation<double> _fadeFor(double start, double end) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(start, end, curve: Curves.easeOut),
  );

  Animation<Offset> _slideFor(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entrance,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == _navIndex) return;
          if (i == 0) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            }
          } else if (i == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const TransactionsScreen()),
            );
          } else if (i == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Halaman Profil — coming next'),
                backgroundColor: AppColors.bgCardHover,
              ),
            );
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildPeriodChips(),
            const SizedBox(height: 20),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildBarChartCard(),
            const SizedBox(height: 20),
            _buildDonutChartCard(),
            const SizedBox(height: 20),
            _buildDailySpendingCard(),
            const SizedBox(height: 20),
            _buildCategoryListCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeFor(0.0, 0.35),
      child: SlideTransition(
        position: _slideFor(0.0, 0.35),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analitik',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text('Pantau performa keuanganmu', style: AppTextStyles.tagline),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChips() {
    return FadeTransition(
      opacity: _fadeFor(0.05, 0.4),
      child: Row(
        children: _periods.map((p) {
          final isActive = p == _activePeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activePeriod = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : AppColors.bgInput,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isActive ? AppColors.accent : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppColors.bgDeep
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return FadeTransition(
      opacity: _fadeFor(0.1, 0.45),
      child: SlideTransition(
        position: _slideFor(0.1, 0.45),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pemasukan',
                value: formatRupiah(15000000),
                change: '+12.5%',
                isPositive: true,
                icon: Icons.arrow_downward_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Pengeluaran',
                value: formatRupiah(8500000),
                change: '+8.3%',
                isPositive: false,
                icon: Icons.arrow_upward_rounded,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard() {
    final maxY = 16.0;

    return FadeTransition(
      opacity: _fadeFor(0.2, 0.55),
      child: SlideTransition(
        position: _slideFor(0.2, 0.55),
        child: _ChartCard(
          title: 'Pemasukan vs Pengeluaran',
          subtitle: '6 bulan terakhir',
          legend: const [
            _LegendDot(color: AppColors.success, label: 'Pemasukan'),
            _LegendDot(color: AppColors.error, label: 'Pengeluaran'),
          ],
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 4,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.cardBorder, strokeWidth: 1),
                ),
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
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= _monthlyData.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _monthlyData[index]['label'],
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
                barGroups: List.generate(_monthlyData.length, (i) {
                  final d = _monthlyData[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: d['income'],
                        color: AppColors.success,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: d['expense'],
                        color: AppColors.error,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonutChartCard() {
    final total = _categorySpends.fold<int>(0, (sum, c) => sum + c.amount);
    final colors = [
      AppColors.accent,
      AppColors.info,
      AppColors.purple,
      AppColors.warning,
    ];

    return FadeTransition(
      opacity: _fadeFor(0.3, 0.65),
      child: SlideTransition(
        position: _slideFor(0.3, 0.65),
        child: _ChartCard(
          title: 'Distribusi Pengeluaran',
          subtitle: 'Per kategori',
          child: SizedBox(
            height: 200,
            child: Row(
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
                      sections: List.generate(_categorySpends.length, (i) {
                        final c = _categorySpends[i];
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
                    children: List.generate(_categorySpends.length, (i) {
                      final c = _categorySpends[i];
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailySpendingCard() {
    return FadeTransition(
      opacity: _fadeFor(0.4, 0.75),
      child: SlideTransition(
        position: _slideFor(0.4, 0.75),
        child: _ChartCard(
          title: 'Pengeluaran Harian',
          subtitle: 'Bulan ini',
          child: SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                minY: 0,
                maxY: 500,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.bgCardHover,
                    getTooltipItems: (spots) => spots.map((s) {
                      return LineTooltipItem(
                        'Rp ${s.y.toStringAsFixed(0)}K',
                        const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _dailySpending.length,
                      (i) => FlSpot(i.toDouble(), _dailySpending[i]),
                    ),
                    isCurved: true,
                    color: AppColors.accent,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accent.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryListCard() {
    return FadeTransition(
      opacity: _fadeFor(0.5, 0.9),
      child: SlideTransition(
        position: _slideFor(0.5, 0.9),
        child: Container(
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
              const Text(
                'Top Kategori',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ..._categorySpends.map((c) => CategoryProgressRow(item: c)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Sub Widgets ====================

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$change dari bulan lalu',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? legend;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.legend,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.tagline),
          const SizedBox(height: 16),
          child,
          if (legend != null) ...[
            const SizedBox(height: 14),
            Row(children: legend!),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
