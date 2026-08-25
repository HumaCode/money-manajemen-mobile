import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/core/widgets/animated_background.dart';
import 'package:money_manajemen/core/widgets/app_skeleton.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/features/profile/presentation/widgets/profile_header_bar.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/budget_expense_model.dart';
import '../../data/datasources/budget_remote_data_source.dart';
import '../widgets/add_budget_sheet.dart';
import '../widgets/add_budget_expense_sheet.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  String _activeTab = 'Semua';
  bool _isLoading = false;

  final List<BudgetModel> _budgets = [];

  Animation<double> _fadeFor(double start, double end) => CurvedAnimation(
        parent: _entrance,
        curve: Interval(start, end, curve: Curves.easeOut),
      );

  Animation<Offset> _slideFor(double start, double end) => Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
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

    _fetchBudgets();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _fetchBudgets() async {
    if (_budgets.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final remoteDS = BudgetRemoteDataSourceImpl(
        client: http.Client(),
        localDataSource: AuthLocalDataSourceImpl(),
      );

      final list = await remoteDS.getBudgets(status: 'all', period: 'all');
      if (mounted) {
        setState(() {
          _budgets.clear();
          _budgets.addAll(list);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<BudgetModel> get _filteredBudgets {
    if (_activeTab == 'Aktif') {
      return _budgets.where((b) => b.isActive).toList();
    } else if (_activeTab == 'Mingguan') {
      return _budgets.where((b) => b.period.toLowerCase() == 'weekly').toList();
    } else if (_activeTab == 'Bulanan') {
      return _budgets.where((b) => b.period.toLowerCase() == 'monthly').toList();
    }
    return _budgets;
  }

  int get _totalAllocated => _budgets.fold(0, (sum, item) => sum + item.totalAmount);
  int get _totalSpent => _budgets.fold(0, (sum, item) => sum + item.totalSpent);
  int get _totalRemaining => _totalAllocated - _totalSpent;

  Future<void> _handleDelete(BudgetModel budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Anggaran?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus anggaran "${budget.name}"?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final remoteDS = BudgetRemoteDataSourceImpl(
        client: http.Client(),
        localDataSource: AuthLocalDataSourceImpl(),
      );
      final ok = await remoteDS.deleteBudget(budget.id);
      if (ok && mounted) {
        DynamicIslandToast.show(
          context,
          title: 'Anggaran Dihapus',
          message: 'Anggaran ${budget.name} berhasil dihapus',
          type: DynamicToastType.success,
        );
        _fetchBudgets();
      }
    }
  }

  void _showExpensesListModal(BudgetModel budget) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BudgetExpensesListSheet(budget: budget),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: AnimatedBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchBudgets,
            color: AppColors.accent,
            backgroundColor: AppColors.bgCard,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: FadeTransition(
                      opacity: _fadeFor(0.0, 0.3),
                      child: SlideTransition(
                        position: _slideFor(0.0, 0.3),
                        child: const ProfileHeaderBar(),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FadeTransition(
                      opacity: _fadeFor(0.1, 0.4),
                      child: SlideTransition(
                        position: _slideFor(0.1, 0.4),
                        child: _buildHeaderBanner(),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: FadeTransition(
                      opacity: _fadeFor(0.2, 0.5),
                      child: SlideTransition(
                        position: _slideFor(0.2, 0.5),
                        child: _buildTotalSummaryCard(),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: FadeTransition(
                      opacity: _fadeFor(0.3, 0.6),
                      child: SlideTransition(
                        position: _slideFor(0.3, 0.6),
                        child: _buildTabs(),
                      ),
                    ),
                  ),
                ),

                if (_isLoading && _budgets.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: 14),
                          child: AppSkeleton(height: 140, borderRadius: 20),
                        ),
                        childCount: 3,
                      ),
                    ),
                  )
                else if (_filteredBudgets.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_view_week_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          const Text('Belum ada Anggaran', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Klik tombol + di bawah untuk membuat plafon anggaran baru', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _filteredBudgets[index];
                          return FadeTransition(
                            opacity: _fadeFor(0.4 + (index * 0.05).clamp(0.0, 0.4), 0.8),
                            child: SlideTransition(
                              position: _slideFor(0.4 + (index * 0.05).clamp(0.0, 0.4), 0.8),
                              child: _buildBudgetCard(item),
                            ),
                          );
                        },
                        childCount: _filteredBudgets.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await AddBudgetSheet.show(context);
          if (created != null) {
            _fetchBudgets();
          }
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: const Text(
          'Tambah Budget',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.calendar_month_rounded, color: AppColors.accent, size: 22),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perencanaan Anggaran',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Atur plafon & batasi pengeluaran bulanan',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Plafon Anggaran', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_budgets.length} Budget',
                  style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.formatRupiah(_totalAllocated),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Terpakai', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatRupiah(_totalSpent),
                      style: const TextStyle(color: AppColors.warning, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sisa Batas Budget', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatRupiah(_totalRemaining < 0 ? 0 : _totalRemaining),
                      style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Semua', 'Aktif', 'Mingguan', 'Bulanan'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSel = _activeTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? AppColors.accent : AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSel ? AppColors.accent : AppColors.cardBorder),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isSel ? Colors.black : AppColors.textSecondary,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel item) {
    final pct = (item.progressPercentage * 100).clamp(0.0, 100.0);
    final isOver = item.status == 'over_budget' || item.totalSpent > item.totalAmount;
    final isNear = item.status == 'near_limit' || pct >= 80;

    final progressColor = isOver ? AppColors.error : (isNear ? AppColors.warning : AppColors.accent);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOver ? AppColors.error.withValues(alpha: 0.5) : AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Periode: ${item.period.toUpperCase()} • ${item.dateRangeFormatted}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: progressColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(color: progressColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.bgInput,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terpakai: ${Formatters.formatRupiah(item.totalSpent)}',
                style: TextStyle(color: isOver ? AppColors.error : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                'Plafon: ${Formatters.formatRupiah(item.totalAmount)}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _showExpensesListModal(item),
                icon: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.accent),
                label: const Text('Rincian', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.warning, size: 20),
                    tooltip: 'Catat Pengeluaran',
                    onPressed: () async {
                      final added = await AddBudgetExpenseSheet.show(context, budget: item);
                      if (added == true) {
                        _fetchBudgets();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                    tooltip: 'Edit Budget',
                    onPressed: () async {
                      final updated = await AddBudgetSheet.show(context, budgetToEdit: item);
                      if (updated != null) {
                        _fetchBudgets();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    tooltip: 'Hapus Budget',
                    onPressed: () => _handleDelete(item),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetExpensesListSheet extends StatefulWidget {
  final BudgetModel budget;

  const _BudgetExpensesListSheet({required this.budget});

  @override
  State<_BudgetExpensesListSheet> createState() => _BudgetExpensesListSheetState();
}

class _BudgetExpensesListSheetState extends State<_BudgetExpensesListSheet> {
  List<BudgetExpenseModel> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    try {
      final remoteDS = BudgetRemoteDataSourceImpl(
        client: http.Client(),
        localDataSource: AuthLocalDataSourceImpl(),
      );
      final list = await remoteDS.getBudgetExpenses(widget.budget.id);
      if (mounted) {
        setState(() {
          _expenses = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.15),
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: AppColors.accent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rincian Pengeluaran: ${widget.budget.name}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Total Terpakai: ${widget.budget.spentAmountFormatted}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _expenses.isEmpty
                      ? const Center(child: Text('Belum ada rincian pengeluaran', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          itemCount: _expenses.length,
                          itemBuilder: (context, index) {
                            final exp = _expenses[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.bgInput,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Text(exp.categoryIcon, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(exp.categoryName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                        if (exp.notes.isNotEmpty)
                                          Text(exp.notes, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Text(Formatters.formatRupiah(exp.spentAmount), style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
