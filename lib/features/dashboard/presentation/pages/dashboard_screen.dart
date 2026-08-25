import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_skeleton.dart';
import 'package:money_manajemen/core/widgets/app_bottom_nav.dart';
import 'package:money_manajemen/core/widgets/app_empty_state.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/features/dashboard/presentation/widgets/notification_sheet.dart';
import 'package:money_manajemen/features/transactions/presentation/pages/transactions_screen.dart';
import 'package:money_manajemen/features/analytics/presentation/pages/analytics_screen.dart';
import 'package:money_manajemen/features/profile/presentation/pages/profile_screen.dart';
import 'package:money_manajemen/features/savings/presentation/pages/savings_screen.dart';
import 'package:money_manajemen/features/budgets/presentation/pages/budgets_screen.dart';
import 'package:money_manajemen/features/auth/presentation/pages/login_screen.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/datasources/master_remote_data_source.dart';
import 'package:money_manajemen/data/datasources/savings_remote_data_source.dart';
import 'package:money_manajemen/data/datasources/transaction_remote_data_source.dart';
import 'package:money_manajemen/data/models/account_model.dart';
import 'package:money_manajemen/data/models/transaction_model.dart';
import 'package:money_manajemen/data/models/user_model.dart';
import 'package:money_manajemen/data/services/receipt_scanner_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:money_manajemen/core/widgets/ai_scanning_loading_dialog.dart';
import 'package:money_manajemen/features/transactions/presentation/widgets/scanned_receipt_preview_sheet.dart';
import 'package:money_manajemen/core/database/database_helper.dart';
import 'package:money_manajemen/core/utils/formatters.dart';

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

  UserDetail? _user;

  bool _isLoading = true;
  int _totalBalance = 0;
  int _totalIncome = 0;
  int _totalExpense = 0;
  List<_CategorySpend> _categorySpends = [];
  List<_TransactionItem> _transactions = [];
  List<AccountModel> _accounts = [];

  List<NotificationItem> _notifications = [];

  bool get _hasUnreadNotifications => _notifications.any((n) => !n.isRead);

  void _openNotifications() {
    NotificationSheet.show(
      context,
      notifications: _notifications,
      onAllRead: () {
        setState(() {
          for (var n in _notifications) {
            n.isRead = true;
          }
        });
      },
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keluar dari Akun?',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kamu perlu login kembali untuk mengakses akunmu.',
                textAlign: TextAlign.center,
                style: AppTextStyles.tagline,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: const Text(
                        'Keluar',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await AuthLocalDataSourceImpl().clearToken();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _openUserMenuSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.accentGradient,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _userInitials,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bgDeep,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _user?.email ?? 'Pengguna Money Management',
                        style: AppTextStyles.tagline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              leading: const Icon(Icons.person_outline_rounded, color: AppColors.info),
              title: const Text(
                'Lihat / Edit Profil',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: AppColors.bgInput.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                _handleLogout();
              },
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text(
                'Keluar dari Akun (Logout)',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: AppColors.error.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _loadUser();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool showLoading = true}) async {
    if (showLoading && _isLoading == false && _accounts.isEmpty) {
      setState(() => _isLoading = true);
    }

    // 1. Immediately render offline local data from SQLite
    await _renderLocalDashboardState();

    // 2. Silently sync latest data from Web API in background
    _syncBackgroundData();
  }

  Future<void> _renderLocalDashboardState() async {
    final localAccounts = await DatabaseHelper.instance.getAccounts();
    final localTx = await DatabaseHelper.instance.getTransactions();

    int income = 0;
    int expense = 0;
    Map<String, int> categoryTotals = {};

    for (var tx in localTx) {
      final absAmount = tx.amount.abs();
      if (tx.isIncome) {
        income += absAmount;
      } else if (tx.type == TransactionType.expense) {
        expense += absAmount;
        categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + absAmount;
      }
    }

    List<_CategorySpend> categories = [];
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

        categories.add(_CategorySpend(cat, emoji, amt, amt / expense));
      });
      categories.sort((a, b) => b.amount.compareTo(a.amount));
    }

    List<_TransactionItem> recentList = localTx.take(5).map((tx) {
      return _TransactionItem(
        tx.title,
        tx.category,
        'Hari ini',
        tx.amount,
        tx.isIncome,
        tx.icon,
        tx.color,
      );
    }).toList();

    int baseAccountsBalance = 0;
    for (var acc in localAccounts) {
      baseAccountsBalance += acc.balance;
    }

    int netTotalBalance = baseAccountsBalance;

    final dynamicNotifs = await DatabaseHelper.instance.getActivities();

    if (mounted) {
      setState(() {
        _accounts = localAccounts;
        _totalIncome = income;
        _totalExpense = expense;
        _totalBalance = netTotalBalance;
        _categorySpends = categories;
        _transactions = recentList;
        _notifications = dynamicNotifs;
        _isLoading = false;
      });
    }
  }

  Future<void> _syncBackgroundData() async {
    try {
      final txRemoteDS = TransactionRemoteDataSourceImpl(
        client: http.Client(),
        localDataSource: AuthLocalDataSourceImpl(),
      );
      await txRemoteDS.getTransactions();

      final masterDS = MasterRemoteDataSourceImpl(
        client: http.Client(),
        localDataSource: AuthLocalDataSourceImpl(),
      );
      await masterDS.getAccounts();
      await masterDS.getCategories();

      final savingsDS = SavingsRemoteDataSourceImpl(
        client: http.Client(),
        localDataSource: AuthLocalDataSourceImpl(),
      );
      await savingsDS.getSavingGoals();

      if (mounted) {
        await _renderLocalDashboardState();
      }
    } catch (_) {
      // Offline mode fallback: keep rendered SQLite local state
    }
  }

  Future<void> _loadUser() async {
    final u = await AuthLocalDataSourceImpl().getUser();
    if (mounted && u != null) {
      setState(() => _user = u);
    }
  }

  String get _userName => _user?.name.isNotEmpty == true ? _user!.name : 'User';
  String get _userInitials {
    if (_user == null || _user!.name.trim().isEmpty) return 'U';
    final parts = _user!.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _user!.name.substring(0, 1).toUpperCase();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  final List<_QuickAction> _quickActions = const [
    _QuickAction('Income', Icons.arrow_downward_rounded, AppColors.success),
    _QuickAction('Expense', Icons.arrow_upward_rounded, AppColors.error),
    _QuickAction('Transfer', Icons.swap_horiz_rounded, AppColors.info),
    _QuickAction('Budget', Icons.pie_chart_rounded, AppColors.purple),
    _QuickAction('Saving', Icons.savings_rounded, AppColors.warning),
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
                    _isLoading ? _buildBalanceCardSkeleton() : _buildBalanceCard(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 28),
                    _isLoading ? _buildBudgetOverviewSkeleton() : _buildBudgetOverview(),
                    const SizedBox(height: 28),
                    _isLoading ? _buildRecentTransactionsSkeleton() : _buildRecentTransactions(),
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
            onTap: _handleScanReceipt,
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

  Future<void> _handleScanReceipt() async {
    final picker = ImagePicker();

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Pindai Struk',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih sumber foto nota/struk belanja Anda',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.accent),
              ),
              title: const Text(
                'Kamera (Scan Struk)',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: const Text('Ambil foto struk langsung', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.info),
              ),
              title: const Text(
                'Galeri Foto',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: const Text('Pilih foto struk dari galeri', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (image == null || !mounted) return;

    AiScanningLoadingDialog.show(context);

    ScannedReceiptResult? scanResult;
    try {
      scanResult = await ReceiptScannerService.scanReceipt(image);
    } catch (e) {
      if (mounted) {
        DynamicIslandToast.show(
          context,
          title: 'Gagal Pindai Struk',
          message: e.toString().replaceAll('Exception: ', ''),
          type: DynamicToastType.error,
        );
      }
    } finally {
      if (mounted) {
        AiScanningLoadingDialog.hide(context);
      }
    }

    if (scanResult != null && mounted) {
      // 1. Show preview, item selection, account & category chooser
      final submitResult = await ScannedReceiptPreviewSheet.show(
        context,
        scanResult,
      );

      if (submitResult == null || submitResult.selectedItems.isEmpty || !mounted) return;

      // Show loading feedback
      DynamicIslandToast.show(
        context,
        title: 'Menyimpan Transaksi Struk',
        message: 'Sedang menyimpan ${submitResult.selectedItems.length} item transaksi...',
        type: DynamicToastType.info,
      );

      try {
        final masterDS = MasterRemoteDataSourceImpl(
          client: http.Client(),
          localDataSource: AuthLocalDataSourceImpl(),
        );

        final now = DateTime.now();
        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final items = submitResult.selectedItems;
        final totalDiscount = scanResult.discount;
        final totalSubtotal = items.fold(0, (sum, i) => sum + i.totalPrice);

        // Pre-process items: Merge zero-price modifier/option items (e.g. +Level 2 Rp 0) into preceding item
        final List<Map<String, dynamic>> processedItems = [];
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          int itemNetPrice = item.totalPrice;
          if (totalSubtotal > 0 && totalDiscount > 0) {
            final itemDiscount = ((item.totalPrice / totalSubtotal) * totalDiscount).round();
            itemNetPrice = item.totalPrice - itemDiscount;
            if (itemNetPrice < 0) itemNetPrice = 0;
          }

          final itemTitle = item.qty > 1 ? '${item.name} (${item.qty}x)' : item.name;

          if (itemNetPrice <= 0 && processedItems.isNotEmpty) {
            final prevTitle = processedItems.last['title'] as String;
            processedItems.last['title'] = '$prevTitle ($itemTitle)';
            processedItems.last['description'] = processedItems.last['title'];
          } else if (itemNetPrice > 0) {
            processedItems.add({
              'title': itemTitle,
              'description': itemTitle,
              'amount': itemNetPrice,
              'type': 'expense',
              'transaction_date': dateStr,
              'account_id': submitResult.account.id,
              'category_id': submitResult.category.id,
            });
          }
        }

        // Fallback: If no item had > 0 net price, create a single transaction for total amount
        if (processedItems.isEmpty && submitResult.totalAmount > 0) {
          processedItems.add({
            'title': scanResult.title.isNotEmpty ? scanResult.title : 'Struk Belanja',
            'description': 'Transaksi Struk Belanja',
            'amount': submitResult.totalAmount,
            'type': 'expense',
            'transaction_date': dateStr,
            'account_id': submitResult.account.id,
            'category_id': submitResult.category.id,
          });
        }

        int savedCount = 0;
        for (final payload in processedItems) {
          final success = await masterDS.createTransaction(payload);
          if (success) savedCount++;
        }

        await DatabaseHelper.instance.addActivity(
          title: 'Pindai Struk',
          message: 'Berhasil menyimpan $savedCount item transaksi dari struk belanja.',
          iconType: 'scan',
          colorHex: '#00FFA3',
        );

        if (mounted) {
          DynamicIslandToast.show(
            context,
            title: 'Berhasil Disimpan 🎉',
            message: '$savedCount transaksi struk berhasil ditambahkan',
            type: DynamicToastType.success,
          );
          _loadDashboardData();
        }
      } catch (e) {
        if (mounted) {
          DynamicIslandToast.show(
            context,
            title: 'Gagal Menyimpan',
            message: e.toString().replaceAll('Exception: ', ''),
            type: DynamicToastType.error,
          );
        }
      }
    }
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
                  Text(
                    '$_userName 👋',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _openNotifications,
              behavior: HitTestBehavior.opaque,
              child: Stack(
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
                  if (_hasUnreadNotifications)
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
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _openUserMenuSheet,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.accentGradient,
                ),
                alignment: Alignment.center,
                child: _user?.avatar != null && _user!.avatar!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: Image.network(
                          _user!.avatar!,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            _userInitials,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.w700,
                              color: AppColors.bgDeep,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        _userInitials,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w700,
                          color: AppColors.bgDeep,
                          fontSize: 14,
                        ),
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
              GestureDetector(
                onTap: () => _showAccountDetailsModal(context),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Total Saldo', style: AppTextStyles.tagline),
                        const SizedBox(width: 6),
                        const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.accent),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            DynamicIslandToast.show(
                              context,
                              title: 'Menyinkronkan Data',
                              message: 'Mengunduh data server & me-replace SQLite local...',
                              type: DynamicToastType.info,
                            );
                            await _loadDashboardData();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.refresh_rounded,
                              size: 19,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _balanceVisible = !_balanceVisible),
                          child: Icon(
                            _balanceVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _balanceVisible ? formatRupiah(_totalBalance) : 'Rp ••••••••',
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
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Pemasukan',
                      value: formatRupiah(_totalIncome),
                      color: AppColors.success,
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppColors.cardBorder),
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Pengeluaran',
                      value: formatRupiah(_totalExpense),
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

  Widget _buildBalanceCardSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card + 2),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 90, height: 14),
          SizedBox(height: 12),
          AppSkeleton(width: 180, height: 32),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(width: 70, height: 12),
                    SizedBox(height: 6),
                    AppSkeleton(width: 110, height: 16),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppSkeleton(width: 70, height: 12),
                    SizedBox(height: 6),
                    AppSkeleton(width: 110, height: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetOverviewSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              AppSkeleton(width: 150, height: 16),
              AppSkeleton(width: 60, height: 14),
            ],
          ),
          SizedBox(height: 16),
          AppSkeleton(width: double.infinity, height: 36),
          SizedBox(height: 10),
          AppSkeleton(width: double.infinity, height: 36),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppSkeleton(width: 140, height: 16),
            AppSkeleton(width: 60, height: 14),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: AppSkeleton(width: double.infinity, height: 60),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return FadeTransition(
      opacity: _fadeFor(0.2, 0.55),
      child: SlideTransition(
        position: _slideFor(0.2, 0.55),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _quickActions.map((a) {
            return _QuickActionButton(
              action: a,
              onTap: () {
                if (a.label == 'Income' || a.label == 'Expense' || a.label == 'Transfer') {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (_, animation, __) => FadeTransition(
                        opacity: animation,
                        child: TransactionsScreen(initialFilter: a.label),
                      ),
                    ),
                  ).then((_) => _loadDashboardData(showLoading: false));
                } else if (a.label == 'Budget') {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (_, animation, __) => FadeTransition(
                        opacity: animation,
                        child: const BudgetsScreen(),
                      ),
                    ),
                  ).then((_) => _loadDashboardData(showLoading: false));
                } else if (a.label == 'Saving') {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (_, animation, __) => FadeTransition(
                        opacity: animation,
                        child: const SavingsScreen(),
                      ),
                    ),
                  ).then((_) => _loadDashboardData(showLoading: false));
                }
              },
            );
          }).toList(),
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
              if (_categorySpends.isEmpty)
                const AppEmptyState(
                  compact: true,
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'Belum Ada Pengeluaran',
                  message: 'Rincian pengeluaran per kategori akan muncul secara otomatis di sini.',
                )
              else
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
            if (_transactions.isEmpty)
              AppEmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'Belum Ada Transaksi',
                message: 'Catatan transaksimu masih kosong. Gunakan tombol + di bawah atau scan struk untuk mulai mencatat!',
                buttonText: 'Pindai Struk',
                onButtonPressed: _handleScanReceipt,
              )
            else
              ..._transactions.map((t) => _TransactionTile(item: t)),
          ],
        ),
      ),
    );
  }

  void _showAccountDetailsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rincian Saldo Akun',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Detail saldo seluruh rekening & akun',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 16),
              if (_accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Belum ada akun/rekening terdaftar',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              else
                ..._accounts.map((acc) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _showAccountTransactionsSheet(context, acc);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: AppColors.info,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      acc.name,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (acc.accountNumber.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        acc.accountNumber,
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    formatRupiah(acc.balance),
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Saldo (Keseluruhan)',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    formatRupiah(_totalBalance),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAccountTransactionsSheet(BuildContext context, AccountModel acc) async {
    final allLocalTx = await DatabaseHelper.instance.getTransactions();
    final accountTx = allLocalTx.where((tx) {
      if (tx.accountId != null && tx.accountId!.isNotEmpty) {
        return tx.accountId == acc.id || tx.toAccountId == acc.id;
      }
      final lowerName = acc.name.toLowerCase();
      return tx.title.toLowerCase().contains(lowerName) ||
          tx.category.toLowerCase().contains(lowerName);
    }).toList();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Histori Transaksi ${acc.name}',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Saldo: ${formatRupiah(acc.balance)}',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: accountTx.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada transaksi untuk akun ${acc.name}',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: accountTx.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tx = accountTx[index];
                          final isIncome = tx.isIncome;
                          final isTransfer = tx.type == TransactionType.transfer;

                          final signStr = isIncome ? '+' : (isTransfer ? '' : '-');
                          final amountColor = isIncome
                              ? AppColors.success
                              : (isTransfer ? AppColors.info : AppColors.warning);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgInput,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: tx.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    tx.icon,
                                    color: tx.color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.title,
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${tx.category} • ${formatDateFull(tx.date)}',
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$signStr${formatRupiah(tx.amount.abs())}',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: amountColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
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
  final VoidCallback onTap;
  const _QuickActionButton({required this.action, required this.onTap});

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
      onTap: widget.onTap,
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
