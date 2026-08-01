import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_bottom_nav.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/features/analytics/presentation/pages/analytics_screen.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/add_transaction_sheet.dart';
import '../models/transaction_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  final TextEditingController _searchController = TextEditingController();

  int _navIndex = 1;
  String _activeFilter = 'Semua';
  String _searchQuery = '';
  DateTime _monthCursor = DateTime.now();

  final List<String> _filters = const ['Semua', 'Income', 'Expense'];

  late List<TransactionModel> _allTransactions;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    final now = DateTime.now();
    _allTransactions = [
      TransactionModel(
        id: '1',
        title: 'Gaji Bulanan',
        category: 'Income',
        date: now,
        amount: 15000000,
        type: TransactionType.income,
        icon: Icons.work_rounded,
        color: AppColors.success,
      ),
      TransactionModel(
        id: '2',
        title: 'Makan Siang',
        category: 'Food & Dining',
        date: now,
        amount: -85000,
        type: TransactionType.expense,
        icon: Icons.restaurant_rounded,
        color: AppColors.warning,
      ),
      TransactionModel(
        id: '3',
        title: 'Bensin Motor',
        category: 'Transportation',
        date: now.subtract(const Duration(days: 1)),
        amount: -50000,
        type: TransactionType.expense,
        icon: Icons.local_gas_station_rounded,
        color: AppColors.info,
      ),
      TransactionModel(
        id: '4',
        title: 'Belanja Bulanan',
        category: 'Shopping',
        date: now.subtract(const Duration(days: 1)),
        amount: -320000,
        type: TransactionType.expense,
        icon: Icons.shopping_bag_rounded,
        color: AppColors.purple,
      ),
      TransactionModel(
        id: '5',
        title: 'Transfer ke Tabungan',
        category: 'Transfer',
        date: now.subtract(const Duration(days: 2)),
        amount: -1000000,
        type: TransactionType.transfer,
        icon: Icons.swap_horiz_rounded,
        color: AppColors.info,
      ),
      TransactionModel(
        id: '6',
        title: 'Bonus Proyek',
        category: 'Income',
        date: now.subtract(const Duration(days: 3)),
        amount: 2500000,
        type: TransactionType.income,
        icon: Icons.card_giftcard_rounded,
        color: AppColors.success,
      ),
      TransactionModel(
        id: '7',
        title: 'Tagihan Listrik',
        category: 'Bills & Utilities',
        date: now.subtract(const Duration(days: 5)),
        amount: -450000,
        type: TransactionType.expense,
        icon: Icons.bolt_rounded,
        color: AppColors.warning,
      ),
    ];
  }

  @override
  void dispose() {
    _entrance.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> get _filteredTransactions {
    return _allTransactions.where((t) {
      final matchesFilter =
          _activeFilter == 'Semua' ||
          (_activeFilter == 'Income' && t.type == TransactionType.income) ||
          (_activeFilter == 'Expense' && t.type == TransactionType.expense);

      final matchesSearch =
          _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesMonth =
          t.date.year == _monthCursor.year &&
          t.date.month == _monthCursor.month;

      return matchesFilter && matchesSearch && matchesMonth;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, List<TransactionModel>> get _groupedTransactions {
    final Map<String, List<TransactionModel>> groups = {};
    for (final t in _filteredTransactions) {
      final key = formatDateGroup(t.date);
      groups.putIfAbsent(key, () => []).add(t);
    }
    return groups;
  }

  double get _totalIncome => _filteredTransactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _filteredTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount.abs());

  void _changeMonth(int delta) {
    setState(() {
      _monthCursor = DateTime(_monthCursor.year, _monthCursor.month + delta, 1);
    });
  }

  void _removeTransaction(String id) {
    setState(() {
      _allTransactions.removeWhere((t) => t.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaksi dihapus'),
        backgroundColor: AppColors.bgCardHover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedTransactions;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFab(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 0) {
            Navigator.of(context).pop();
          } else if (i == 2) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (_, animation, __) => FadeTransition(
                  opacity: animation,
                  child: const AnalyticsScreen(),
                ),
              ),
            );
          } else {
            setState(() => _navIndex = i);
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaksi',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Semua riwayat pemasukan dan pengeluaran',
                      style: AppTextStyles.tagline,
                    ),
                    const SizedBox(height: 18),
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    _buildMonthSelector(),
                    const SizedBox(height: 14),
                    _buildSummaryRow(),
                    const SizedBox(height: 14),
                    _buildFilterChips(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: grouped.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        children: grouped.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 10,
                                  top: 6,
                                ),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              ...entry.value.map(
                                (t) => TransactionTile(
                                  item: t,
                                  onDismissed: () => _removeTransaction(t.id),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.accentGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            final newTx = await AddTransactionSheet.show(context);
            if (newTx != null) {
              setState(() {
                _allTransactions.insert(0, newTx);
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaksi berhasil ditambahkan'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          child: const Icon(
            Icons.add_rounded,
            color: AppColors.bgDeep,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          hintText: 'Cari transaksi...',
          hintStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _monthArrow(Icons.chevron_left_rounded, () => _changeMonth(-1)),
        Text(
          formatMonthYear(_monthCursor),
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        _monthArrow(Icons.chevron_right_rounded, () => _changeMonth(1)),
      ],
    );
  }

  Widget _monthArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            label: 'Pemasukan',
            value: formatRupiah(_totalIncome),
            icon: Icons.arrow_downward_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            label: 'Pengeluaran',
            value: formatRupiah(_totalExpense),
            icon: Icons.arrow_upward_rounded,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isActive = filter == _activeFilter;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : AppColors.bgInput,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isActive ? AppColors.accent : AppColors.cardBorder,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.bgDeep : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coba ubah filter atau kata kunci pencarian',
            style: AppTextStyles.tagline,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
