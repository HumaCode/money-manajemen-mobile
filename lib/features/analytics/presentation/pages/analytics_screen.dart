import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_bottom_nav.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/datasources/analytics_remote_data_source.dart';
import 'package:money_manajemen/data/datasources/transaction_remote_data_source.dart';
import 'package:money_manajemen/data/datasources/budget_remote_data_source.dart';
import 'package:money_manajemen/data/datasources/savings_remote_data_source.dart';
import 'package:money_manajemen/data/models/analytics_model.dart';
import 'package:money_manajemen/data/models/category_spend_model.dart';
import 'package:money_manajemen/data/models/transaction_model.dart';
import 'package:money_manajemen/data/models/budget_model.dart';
import 'package:money_manajemen/data/models/savings_goal_model.dart' as saving_model;
import 'package:money_manajemen/core/database/database_helper.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:money_manajemen/features/transactions/presentation/pages/transactions_screen.dart';
import 'package:money_manajemen/features/profile/presentation/pages/profile_screen.dart';

import '../widgets/category_progress_row.dart';
import '../widgets/analytics_stat_card.dart';
import '../widgets/analytics_bar_chart_card.dart';
import '../widgets/analytics_donut_chart_card.dart';
import '../widgets/analytics_daily_spending_card.dart';
import '../widgets/analytics_budget_card.dart';
import '../widgets/analytics_savings_card.dart';
import '../widgets/analytics_skeletons.dart';

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

  late final AnalyticsRemoteDataSource _remoteDataSource;
  late final BudgetRemoteDataSource _budgetRemoteDataSource;
  late final SavingsRemoteDataSource _savingsRemoteDataSource;

  bool _isLoading = false;
  WalletSummaryModel? _walletSummary;

  final List<String> _periods = const ['Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

  List<CategorySpendModel> _categorySpends = [];
  List<Map<String, dynamic>> _monthlyData = [];
  List<double> _dailySpending = [];

  // Budget & Saving analytics state
  List<BudgetModel> _budgetsList = [];
  List<saving_model.Data> _savingsList = [];
  int _totalBudgeted = 0;
  int _totalBudgetSpent = 0;
  int _totalSavingsTarget = 0;
  int _totalSavingsCurrent = 0;

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

    final authLocal = AuthLocalDataSourceImpl();
    _remoteDataSource = AnalyticsRemoteDataSourceImpl(
      client: http.Client(),
      localDataSource: authLocal,
    );
    _budgetRemoteDataSource = BudgetRemoteDataSourceImpl(
      client: http.Client(),
      localDataSource: authLocal,
    );
    _savingsRemoteDataSource = SavingsRemoteDataSourceImpl(
      client: http.Client(),
      localDataSource: authLocal,
    );

    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData({bool showLoading = true}) async {
    if (!mounted) return;
    if (showLoading && _isLoading == false && _walletSummary == null) {
      setState(() => _isLoading = true);
    }

    // 1. Immediately render offline local data from SQLite & local DB
    await _calculateFromLocalTransactions();
    await _loadBudgetsAndSavingsLocal();

    // 2. Silently sync latest remote analytics from Web API in background
    _syncBackgroundAnalytics();
  }

  Future<void> _loadBudgetsAndSavingsLocal() async {
    try {
      final budgets = await _budgetRemoteDataSource.getBudgets();
      final savings = await _savingsRemoteDataSource.getSavingGoals();
      if (mounted) {
        _processBudgetsAndSavings(budgets, savings);
      }
    } catch (_) {}
  }

  void _processBudgetsAndSavings(
      List<BudgetModel> budgets, List<saving_model.Data> savings) {
    int bTotal = 0;
    int bSpent = 0;
    for (var b in budgets) {
      bTotal += b.totalAmount;
      bSpent += b.totalSpent;
    }

    int sTarget = 0;
    int sCurrent = 0;
    for (var s in savings) {
      sTarget += s.targetAmount;
      sCurrent += s.currentAmount;
    }

    setState(() {
      _budgetsList = budgets;
      _savingsList = savings;
      _totalBudgeted = bTotal;
      _totalBudgetSpent = bSpent;
      _totalSavingsTarget = sTarget;
      _totalSavingsCurrent = sCurrent;
    });
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

      final summary =
          await _remoteDataSource.getWalletSummary(period: periodParam);
      final topExpenses =
          await _remoteDataSource.getTopExpenses(period: periodParam);
      final budgets = await _budgetRemoteDataSource.getBudgets();
      final savings = await _savingsRemoteDataSource.getSavingGoals();

      if (mounted) {
        _processBudgetsAndSavings(budgets, savings);

        if (summary.totalIncome > 0 || summary.totalExpense > 0) {
          setState(() {
            _walletSummary = summary;
            if (topExpenses.isNotEmpty) {
              _categorySpends = topExpenses
                  .map((e) => CategorySpendModel(
                        name: e.categoryName,
                        emoji: e.emoji,
                        amount: e.amount.toInt(),
                        percentage: e.percentage > 1.0
                            ? e.percentage / 100.0
                            : e.percentage,
                      ))
                  .toList();
            }
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      // Offline mode fallback: keep rendered local state
    }
  }

  Future<void> _calculateFromLocalTransactions() async {
    try {
      final localTx = await DatabaseHelper.instance.getTransactions();

      // Calculate 6 months dynamic bar data
      final now = DateTime.now();
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      List<Map<String, dynamic>> calculatedMonthlyData = [];

      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthLabel = monthNames[date.month - 1];

        final mTx = localTx.where(
            (t) => t.date.year == date.year && t.date.month == date.month);
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
        periodTx = localTx
            .where((t) => now.difference(t.date).inDays.abs() <= 7)
            .toList();
      } else if (_activePeriod == 'Bulan Ini') {
        periodTx = localTx
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();
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
          categoryTotals[tx.category] =
              (categoryTotals[tx.category] ?? 0) + absAmount;
        }
      }

      List<CategorySpendModel> localCategories = [];
      if (expense > 0) {
        categoryTotals.forEach((cat, amt) {
          String emoji = '💰';
          final lower = cat.toLowerCase();
          if (lower.contains('makan') ||
              lower.contains('food') ||
              lower.contains('kuliner')) {
            emoji = '🍔';
          } else if (lower.contains('trans') ||
              lower.contains('bensin') ||
              lower.contains('car')) {
            emoji = '🚗';
          } else if (lower.contains('belanja') || lower.contains('shop')) {
            emoji = '🛍️';
          } else if (lower.contains('tagihan') ||
              lower.contains('bill') ||
              lower.contains('listrik')) {
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
                pageBuilder: (_, animation, secondaryAnimation) => FadeTransition(
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
                const SummaryCardsSkeleton(),
                const SizedBox(height: 24),
                const BarChartSkeleton(),
                const SizedBox(height: 20),
                const DonutChartSkeleton(),
                const SizedBox(height: 20),
                const CategoryListSkeleton(),
              ] else ...[
                _buildSummaryCards(),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeFor(0.2, 0.55),
                  child: SlideTransition(
                    position: _slideFor(0.2, 0.55),
                    child: AnalyticsBarChartCard(monthlyData: _monthlyData),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeFor(0.3, 0.65),
                  child: SlideTransition(
                    position: _slideFor(0.3, 0.65),
                    child: AnalyticsDonutChartCard(
                        categorySpends: _categorySpends),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeFor(0.4, 0.75),
                  child: SlideTransition(
                    position: _slideFor(0.4, 0.75),
                    child: AnalyticsDailySpendingCard(
                        dailySpending: _dailySpending),
                  ),
                ),
                const SizedBox(height: 20),
                _buildCategoryListCard(),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeFor(0.55, 0.92),
                  child: SlideTransition(
                    position: _slideFor(0.55, 0.92),
                    child: AnalyticsBudgetCard(
                      budgetsList: _budgetsList,
                      totalBudgeted: _totalBudgeted,
                      totalBudgetSpent: _totalBudgetSpent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeFor(0.6, 0.95),
                  child: SlideTransition(
                    position: _slideFor(0.6, 0.95),
                    child: AnalyticsSavingsCard(
                      savingsList: _savingsList,
                      totalSavingsCurrent: _totalSavingsCurrent,
                      totalSavingsTarget: _totalSavingsTarget,
                    ),
                  ),
                ),
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
    final incomeVal =
        _walletSummary != null ? _walletSummary!.totalIncome.toInt() : 0;
    final expenseVal =
        _walletSummary != null ? _walletSummary!.totalExpense.toInt() : 0;
    final incomeChange =
        _walletSummary != null && _walletSummary!.totalIncome > 0
            ? '${_walletSummary!.incomeChangePercentage >= 0 ? '+' : ''}${_walletSummary!.incomeChangePercentage.toStringAsFixed(1)}%'
            : '0%';
    final expenseChange =
        _walletSummary != null && _walletSummary!.totalExpense > 0
            ? '${_walletSummary!.expenseChangePercentage >= 0 ? '+' : ''}${_walletSummary!.expenseChangePercentage.toStringAsFixed(1)}%'
            : '0%';

    return FadeTransition(
      opacity: _fadeFor(0.1, 0.45),
      child: SlideTransition(
        position: _slideFor(0.1, 0.45),
        child: Row(
          children: [
            Expanded(
              child: AnalyticsStatCard(
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
              child: AnalyticsStatCard(
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
