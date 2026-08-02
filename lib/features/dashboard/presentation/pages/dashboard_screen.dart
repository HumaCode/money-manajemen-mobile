import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_bottom_nav.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/features/transactions/presentation/pages/transactions_screen.dart';
import 'package:money_manajemen/features/analytics/presentation/pages/analytics_screen.dart';
import 'package:money_manajemen/features/profile/presentation/pages/profile_screen.dart';
import 'package:money_manajemen/features/transactions/presentation/widgets/add_transaction_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  bool _balanceVisible = true;

  late final AnimationController _entrance;

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

  // ---- Dummy data (replace with real API data) ----
  final List<_QuickAction> _quickActions = const [
    _QuickAction('Income', Icons.arrow_downward_rounded, AppColors.success),
    _QuickAction('Expense', Icons.arrow_upward_rounded, AppColors.error),
    _QuickAction('Transfer', Icons.swap_horiz_rounded, AppColors.info),
    _QuickAction('Budget', Icons.pie_chart_rounded, AppColors.purple),
  ];

  final List<_CategorySpend> _categorySpends = const [
    _CategorySpend('Makanan', '🍔', 3200000, 0.85),
    _CategorySpend('Transportasi', '🚗', 2100000, 0.65),
    _CategorySpend('Belanja', '🛍️', 1800000, 0.50),
  ];

  final List<_TransactionItem> _transactions = const [
    _TransactionItem(
      'Gaji Bulanan',
      'Income',
      'Hari ini',
      15000000,
      true,
      Icons.work_rounded,
      AppColors.success,
    ),
    _TransactionItem(
      'Makan Siang',
      'Food & Dining',
      'Hari ini',
      -85000,
      false,
      Icons.restaurant_rounded,
      AppColors.warning,
    ),
    _TransactionItem(
      'Bensin Motor',
      'Transportation',
      'Kemarin',
      -50000,
      false,
      Icons.local_gas_station_rounded,
      AppColors.info,
    ),
    _TransactionItem(
      'Belanja Bulanan',
      'Shopping',
      'Kemarin',
      -320000,
      false,
      Icons.shopping_bag_rounded,
      AppColors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFab(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 1) {
            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (_, animation, __) => FadeTransition(
                  opacity: animation,
                  child: const TransactionsScreen(),
                ),
              ),
            ).then((_) => setState(() => _navIndex = 0));
          } else if (i == 2) {
            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (_, animation, __) => FadeTransition(
                  opacity: animation,
                  child: const AnalyticsScreen(),
                ),
              ),
            ).then((_) => setState(() => _navIndex = 0));
          } else if (i == 3) {
            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (_, animation, __) => FadeTransition(
                  opacity: animation,
                  child: const ProfileScreen(),
                ),
              ),
            ).then((_) => setState(() => _navIndex = 0));
          } else {
            setState(() => _navIndex = i);
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 28),
                    _buildBudgetOverview(),
                    const SizedBox(height: 28),
                    _buildRecentTransactions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return FadeTransition(
      opacity: _fadeFor(0.3, 0.7),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.accentGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
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
              if (newTx != null && mounted) {
                DynamicIslandToast.show(
                  context,
                  title: 'Transaksi Berhasil',
                  message: 'Transaksi baru berhasil ditambahkan',
                  type: DynamicToastType.success,
                );
              }
            },
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.bgDeep,
              size: 28,
            ),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selamat datang,', style: AppTextStyles.tagline),
                  const SizedBox(height: 2),
                  const Text(
                    'John Doe 👋',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.accentGradient,
              ),
              alignment: Alignment.center,
              child: const Text(
                'JD',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bgDeep,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return FadeTransition(
      opacity: _fadeFor(0.1, 0.45),
      child: SlideTransition(
        position: _slideFor(0.1, 0.45),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card + 2),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF16321F), Color(0xFF0F1E2C)],
            ),
            border: Border.all(color: AppColors.accent.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Total Saldo', style: AppTextStyles.tagline),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _balanceVisible = !_balanceVisible),
                    child: Icon(
                      _balanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _balanceVisible ? 'Rp 12.450.000' : 'Rp ••••••••',
                  key: ValueKey(_balanceVisible),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Pemasukan',
                      value: 'Rp 15.000.000',
                      color: AppColors.success,
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppColors.cardBorder),
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Pengeluaran',
                      value: 'Rp 8.500.000',
                      color: AppColors.error,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return FadeTransition(
      opacity: _fadeFor(0.2, 0.55),
      child: SlideTransition(
        position: _slideFor(0.2, 0.55),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _quickActions
              .map((a) => _QuickActionButton(action: a))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildBudgetOverview() {
    return FadeTransition(
      opacity: _fadeFor(0.3, 0.65),
      child: SlideTransition(
        position: _slideFor(0.3, 0.65),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pengeluaran Terbesar',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Lihat semua',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._categorySpends.map((c) => _CategoryRow(item: c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return FadeTransition(
      opacity: _fadeFor(0.4, 0.8),
      child: SlideTransition(
        position: _slideFor(0.4, 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaksi Terbaru',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _navIndex = 1),
                  child: const Text(
                    'Lihat semua',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._transactions.map((t) => _TransactionTile(item: t)),
          ],
        ),
      ),
    );
  }
}

// ==================== Data Models ====================

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  const _QuickAction(this.label, this.icon, this.color);
}

class _CategorySpend {
  final String name;
  final String emoji;
  final int amount;
  final double percentage;
  const _CategorySpend(this.name, this.emoji, this.amount, this.percentage);
}

class _TransactionItem {
  final String title;
  final String category;
  final String date;
  final int amount;
  final bool isIncome;
  final IconData icon;
  final Color color;
  const _TransactionItem(
    this.title,
    this.category,
    this.date,
    this.amount,
    this.isIncome,
    this.icon,
    this.color,
  );
}

// ==================== Sub Widgets ====================

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: alignEnd ? 16 : 0),
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!alignEnd) ...[
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (alignEnd) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 13, color: color),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final _QuickAction action;
  const _QuickActionButton({required this.action});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {},
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: widget.action.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.action.icon,
                color: widget.action.color,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.action.label,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final _CategorySpend item;
  const _CategoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Rp ${_formatNumber(item.amount)}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: item.percentage),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor: AppColors.bgInput,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final _TransactionItem item;
  const _TransactionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final sign = item.isIncome ? '+' : '-';
    final amountColor = item.isIncome ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.category} • ${item.date}',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign Rp ${_formatNumber(item.amount.abs())}',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
