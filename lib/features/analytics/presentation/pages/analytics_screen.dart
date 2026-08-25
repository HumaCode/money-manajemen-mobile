import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_bottom_nav.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/datasources/analytics_remote_data_source.dart';
import 'package:money_manajemen/data/datasources/transaction_remote_data_source.dart';
import 'package:money_manajemen/data/models/analytics_model.dart';
import 'package:money_manajemen/data/models/category_spend_model.dart';
import 'package:money_manajemen/data/models/transaction_model.dart';
import '../widgets/category_progress_row.dart';
import 'package:money_manajemen/core/database/database_helper.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/core/widgets/app_empty_state.dart';
import 'package:money_manajemen/core/widgets/app_skeleton.dart';
import 'package:money_manajemen/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:money_manajemen/features/transactions/presentation/pages/transactions_screen.dart';
import 'package:money_manajemen/features/profile/presentation/pages/profile_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  final int _navIndex = 2;
  String _activePeriod = 'Bulan Ini';
  int _touchedPieIndex = -1;

  late final AnalyticsRemoteDataSource _remoteDataSource;
  bool _isLoading = false;
  WalletSummaryModel? _walletSummary;

  final List<String> _periods = const ['Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

  List<CategorySpendModel> _categorySpends = [];
  List<Map<String, dynamic>> _monthlyData = [];
  List<double> _dailySpending = [];

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

    _remoteDataSource = AnalyticsRemoteDataSourceImpl(
      client: http.Client(),
      localDataSource: AuthLocalDataSourceImpl(),
    );

    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData({bool showLoading = true}) async {
    if (!mounted) return;
    if (showLoading && _isLoading == false && _walletSummary == null) {
      setState(() => _isLoading = true);
    }

    // 1. Immediately render offline local data from SQLite
    await _calculateFromLocalTransactions();

    // 2. Silently sync latest remote analytics from Web API in background
    _syncBackgroundAnalytics();
  }

  Future<void> _syncBackgroundAnalytics() async {
    String periodParam = 'month';
    if (_activePeriod == 'Minggu Ini') periodParam = 'week';
    if (_activePeriod == 'Tahun Ini') periodParam = 'year';

    try {
      final txRemoteDS = TransactionRemoteDataSourceImpl(
        client: http.Client(),
        localDataSource: AuthLocalDataSourceImpl(),
      );
      await txRemoteDS.getTransactions();

      if (mounted) {
        await _calculateFromLocalTransactions();
      }

      final summary = await _remoteDataSource.getWalletSummary(period: periodParam);
      final topExpenses = await _remoteDataSource.getTopExpenses(period: periodParam);

      if (mounted) {
        if (summary.totalIncome > 0 || summary.totalExpense > 0) {
          setState(() {
            _walletSummary = summary;
            if (topExpenses.isNotEmpty) {
              _categorySpends = topExpenses.map((e) => CategorySpendModel(
                name: e.categoryName,
                emoji: e.emoji,
                amount: e.amount.toInt(),
                percentage: e.percentage > 1.0 ? e.percentage / 100.0 : e.percentage,
              )).toList();
            }
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      // Offline mode fallback: keep rendered SQLite local state
    }
  }

  Future<void> _calculateFromLocalTransactions() async {
    try {
      final localTx = await DatabaseHelper.instance.getTransactions();

      // Calculate 6 months dynamic bar data
      final now = DateTime.now();
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
      List<Map<String, dynamic>> calculatedMonthlyData = [];

      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthLabel = monthNames[date.month - 1];

        final mTx = localTx.where((t) => t.date.year == date.year && t.date.month == date.month);
        double mInc = 0;
        double mExp = 0;
        for (var t in mTx) {
          final absAmount = t.amount.abs().toDouble();
          if (t.isIncome) mInc += absAmount;
          if (t.type == TransactionType.expense) mExp += absAmount;
        }

        calculatedMonthlyData.add({
          'label': monthLabel,
          'income': mInc / 1000000.0,
          'expense': mExp / 1000000.0,
        });
      }

      if (localTx.isEmpty) {
        if (mounted) {
          setState(() {
            _monthlyData = calculatedMonthlyData;
            _dailySpending = List.filled(7, 0.0);
            _walletSummary = WalletSummaryModel(
              totalBalance: 0,
              totalIncome: 0,
              totalExpense: 0,
              incomeChangePercentage: 0,
              expenseChangePercentage: 0,
            );
            _categorySpends = [];
            _isLoading = false;
          });
        }
        return;
      }

      List<TransactionModel> periodTx = localTx;
      if (_activePeriod == 'Minggu Ini') {
        periodTx = localTx.where((t) => now.difference(t.date).inDays.abs() <= 7).toList();
      } else if (_activePeriod == 'Bulan Ini') {
        periodTx = localTx.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
      } else if (_activePeriod == 'Tahun Ini') {
        periodTx = localTx.where((t) => t.date.year == now.year).toList();
      }

      if (periodTx.isEmpty) {
        periodTx = localTx;
      }

      double income = 0;
      double expense = 0;
      Map<String, double> categoryTotals = {};

      for (var tx in periodTx) {
        final absAmount = tx.amount.abs().toDouble();
        if (tx.isIncome) {
          income += absAmount;
        } else if (tx.type == TransactionType.expense) {
          expense += absAmount;
          categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + absAmount;
        }
      }

      List<CategorySpendModel> localCategories = [];
      if (expense > 0) {
        categoryTotals.forEach((cat, amt) {
          String emoji = '💰';
          final lower = cat.toLowerCase();
          if (lower.contains('makan') || lower.contains('food') || lower.contains('kuliner')) {
            emoji = '🍔';
          } else if (lower.contains('trans') || lower.contains('bensin') || lower.contains('car')) {
            emoji = '🚗';
          } else if (lower.contains('belanja') || lower.contains('shop')) {
            emoji = '🛍️';
          } else if (lower.contains('tagihan') || lower.contains('bill') || lower.contains('listrik')) {
            emoji = '💡';
          }

          localCategories.add(CategorySpendModel(
            name: cat,
            emoji: emoji,
            amount: amt.toInt(),
            percentage: amt / expense,
          ));
        });
        localCategories.sort((a, b) => b.amount.compareTo(a.amount));
      }

      List<double> calculatedDailySpending = List.filled(7, 0.0);
      for (var tx in localTx) {
        if (tx.type == TransactionType.expense) {
          final diffDays = now.difference(tx.date).inDays;
          if (diffDays >= 0 && diffDays < 7) {
            final index = 6 - diffDays;
            calculatedDailySpending[index] += (tx.amount.abs() / 1000.0);
          }
        }
      }

      if (mounted) {
        setState(() {
          _monthlyData = calculatedMonthlyData;
          _dailySpending = calculatedDailySpending;
          _walletSummary = WalletSummaryModel(
            totalBalance: income - expense,
            totalIncome: income,
            totalExpense: expense,
            incomeChangePercentage: 0,
            expenseChangePercentage: 0,
          );
          if (localCategories.isNotEmpty) {
            _categorySpends = localCategories;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (_, animation, __) => FadeTransition(
                  opacity: animation,
                  child: const ProfileScreen(),
                ),
              ),
            );
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadAnalyticsData,
          color: AppColors.accent,
          backgroundColor: AppColors.bgCard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildPeriodChips(),
              const SizedBox(height: 20),
              if (_isLoading) ...[
                _buildSummaryCardsSkeleton(),
                const SizedBox(height: 24),
                _buildBarChartSkeleton(),
                const SizedBox(height: 20),
                _buildDonutChartSkeleton(),
                const SizedBox(height: 20),
                _buildCategoryListSkeleton(),
              ] else ...[
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
            ],
          ),
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
              onTap: () {
                if (_activePeriod != p) {
                  setState(() => _activePeriod = p);
                  _loadAnalyticsData();
                }
              },
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
    final incomeVal = _walletSummary != null ? _walletSummary!.totalIncome.toInt() : 0;
    final expenseVal = _walletSummary != null ? _walletSummary!.totalExpense.toInt() : 0;
    final incomeChange = _walletSummary != null && _walletSummary!.totalIncome > 0
        ? '${_walletSummary!.incomeChangePercentage >= 0 ? '+' : ''}${_walletSummary!.incomeChangePercentage.toStringAsFixed(1)}%'
        : '0%';
    final expenseChange = _walletSummary != null && _walletSummary!.totalExpense > 0
        ? '${_walletSummary!.expenseChangePercentage >= 0 ? '+' : ''}${_walletSummary!.expenseChangePercentage.toStringAsFixed(1)}%'
        : '0%';

    return FadeTransition(
      opacity: _fadeFor(0.1, 0.45),
      child: SlideTransition(
        position: _slideFor(0.1, 0.45),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pemasukan',
                value: formatRupiah(incomeVal),
                change: incomeChange,
                isPositive: true,
                icon: Icons.arrow_downward_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Pengeluaran',
                value: formatRupiah(expenseVal),
                change: expenseChange,
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
    double maxVal = 1.0;
    for (var d in _monthlyData) {
      final inc = (d['income'] as num).toDouble();
      final exp = (d['expense'] as num).toDouble();
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    final maxY = maxVal * 1.2;

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

    Widget content;
    if (_categorySpends.isEmpty || total == 0) {
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
      );
    }

    return FadeTransition(
      opacity: _fadeFor(0.3, 0.65),
      child: SlideTransition(
        position: _slideFor(0.3, 0.65),
        child: _ChartCard(
          title: 'Distribusi Pengeluaran',
          subtitle: 'Per kategori',
          child: SizedBox(
            height: 200,
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildDailySpendingCard() {
    double maxVal = 0.0;
    for (var val in _dailySpending) {
      if (val > maxVal) maxVal = val;
    }
    final maxY = maxVal > 0 ? (maxVal * 1.35) : 100.0;

    final now = DateTime.now();
    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    Widget content;
    if (_dailySpending.isEmpty || maxVal == 0) {
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
                  if (index < 0 || index >= _dailySpending.length) {
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
                _dailySpending.length,
                (i) => FlSpot(i.toDouble(), _dailySpending[i]),
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

    return FadeTransition(
      opacity: _fadeFor(0.4, 0.75),
      child: SlideTransition(
        position: _slideFor(0.4, 0.75),
        child: _ChartCard(
          title: 'Pengeluaran Harian',
          subtitle: '7 Hari Terakhir',
          child: SizedBox(
            height: 180,
            child: content,
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

  Widget _buildSummaryCardsSkeleton() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppSkeleton(width: 70, height: 12),
                    AppSkeleton(width: 24, height: 24, borderRadius: 6),
                  ],
                ),
                SizedBox(height: 12),
                AppSkeleton(width: 100, height: 20),
                SizedBox(height: 8),
                AppSkeleton(width: 60, height: 10),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppSkeleton(width: 70, height: 12),
                    AppSkeleton(width: 24, height: 24, borderRadius: 6),
                  ],
                ),
                SizedBox(height: 12),
                AppSkeleton(width: 100, height: 20),
                SizedBox(height: 8),
                AppSkeleton(width: 60, height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeleton(width: 160, height: 18),
          const SizedBox(height: 6),
          const AppSkeleton(width: 100, height: 12),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (i) {
                final heights = [70.0, 110.0, 50.0, 95.0, 120.0, 85.0];
                return Row(
                  children: [
                    AppSkeleton(width: 8, height: heights[i], borderRadius: 4),
                    const SizedBox(width: 4),
                    AppSkeleton(width: 8, height: heights[i] * 0.6, borderRadius: 4),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChartSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeleton(width: 150, height: 18),
          const SizedBox(height: 6),
          const AppSkeleton(width: 80, height: 12),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                flex: 5,
                child: Center(
                  child: AppSkeleton(
                    width: 90,
                    height: 90,
                    borderRadius: 45,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(3, (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: AppSkeleton(width: 90, height: 12),
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryListSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeleton(width: 140, height: 18),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                AppSkeleton(width: 36, height: 36, borderRadius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton(width: 100, height: 14),
                      SizedBox(height: 6),
                      AppSkeleton(width: 130, height: 8),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                AppSkeleton(width: 60, height: 14),
              ],
            ),
          )),
        ],
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
            change == '0%' ? 'Belum ada data transaksi' : '$change dari bulan lalu',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              color: change == '0%'
                  ? AppColors.textMuted
                  : (isPositive ? AppColors.success : AppColors.error),
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
