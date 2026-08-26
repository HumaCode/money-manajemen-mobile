import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/constants/api_url.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/database/database_helper.dart';
import 'package:money_manajemen/core/services/biometric_service.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/core/widgets/app_bottom_nav.dart';
import 'package:money_manajemen/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:money_manajemen/features/transactions/presentation/pages/transactions_screen.dart';
import 'package:money_manajemen/features/analytics/presentation/pages/analytics_screen.dart';
import 'package:money_manajemen/features/auth/presentation/pages/login_screen.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/datasources/auth_remote_data_source.dart';
import 'package:money_manajemen/data/models/user_model.dart';
import 'package:money_manajemen/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:money_manajemen/features/profile/presentation/widgets/change_password_sheet.dart';
import 'package:money_manajemen/features/profile/presentation/pages/help_screen.dart';
import 'package:money_manajemen/features/profile/presentation/pages/privacy_policy_screen.dart';
import 'package:money_manajemen/features/profile/presentation/pages/about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  final int _navIndex = 3;
  bool _notificationsOn = true;

  UserDetail? _user;
  int _accountsCount = 0;
  int _transactionsCount = 0;
  int _budgetsCount = 0;
  String _selectedCurrencyCode = 'IDR';

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
      duration: const Duration(milliseconds: 900),
    )..forward();

    _loadProfileData();
  }

  bool _biometricOn = false;

  Future<void> _loadProfileData() async {
    final localUser = await AuthLocalDataSourceImpl().getUser();
    final localAccs = await DatabaseHelper.instance.getAccounts();
    final localTxs = await DatabaseHelper.instance.getTransactions();
    final bioOn = await BiometricService.isBiometricEnabled();
    final savedCode = await AuthLocalDataSourceImpl().getSelectedCurrencyCode();

    if (mounted) {
      setState(() {
        _user = localUser;
        _accountsCount = localAccs.length;
        _transactionsCount = localTxs.length;
        _biometricOn = bioOn;
        _selectedCurrencyCode = savedCode;
      });
    }

    try {
      final token = await AuthLocalDataSourceImpl().getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token ?? ''}',
        'X-App-Key': ApiUrl.appKey,
        'x-api-key': ApiUrl.appKey,
      };

      final remoteDS = AuthRemoteDataSourceImpl(client: http.Client());
      final freshUser = await remoteDS.getProfile();

      // Fetch real counts from API
      try {
        final txRes = await http.get(Uri.parse(ApiUrl.transactions), headers: headers);
        if (txRes.statusCode == 200) {
          final txBody = jsonDecode(txRes.body);
          if (txBody['data'] is List) {
            _transactionsCount = (txBody['data'] as List).length;
          }
        }
      } catch (_) {}

      try {
        final accRes = await http.get(Uri.parse(ApiUrl.accounts), headers: headers);
        if (accRes.statusCode == 200) {
          final accBody = jsonDecode(accRes.body);
          if (accBody['data'] is List) {
            _accountsCount = (accBody['data'] as List).length;
          }
        }
      } catch (_) {}

      try {
        final bgRes = await http.get(Uri.parse(ApiUrl.budgets), headers: headers);
        if (bgRes.statusCode == 200) {
          final bgBody = jsonDecode(bgRes.body);
          if (bgBody['data'] is List) {
            _budgetsCount = (bgBody['data'] as List).length;
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _user = freshUser;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleBiometricToggle(bool value) async {
    setState(() => _biometricOn = value);
    await BiometricService.setBiometricEnabled(value);

    if (mounted) {
      if (value) {
        DynamicIslandToast.show(
          context,
          title: 'Biometrik Aktif',
          message: 'Login dengan sidik jari berhasil diaktifkan',
          type: DynamicToastType.success,
        );

        BiometricService.authenticate(
          reason: 'Verifikasi sidik jari untuk mengaktifkan login biometrik',
        );
      } else {
        DynamicIslandToast.show(
          context,
          title: 'Biometrik Nonaktif',
          message: 'Login dengan sidik jari telah dinonaktifkan',
          type: DynamicToastType.info,
        );
      }
    }
  }

  String get _userInitials {
    if (_user == null || _user!.name.trim().isEmpty) return 'U';
    final parts = _user!.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _user!.name.substring(0, 1).toUpperCase();
  }

  Future<void> _openEditProfile() async {
    if (_user == null) {
      final user = await AuthLocalDataSourceImpl().getUser();
      if (user == null) return;
      _user = user;
    }
    final updated = await EditProfileSheet.show(context, user: _user!);
    if (updated != null && mounted) {
      setState(() {
        _user = updated;
      });
    }
  }

  Future<void> _openCurrencyPickerModal() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.5)),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.attach_money_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pilih Mata Uang',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchCurrenciesFromApi(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.accent),
                      ),
                    );
                  }

                  final list = snapshot.data ?? [
                    {'id': '1', 'code': 'IDR', 'name': 'Rupiah Indonesia', 'symbol': 'Rp'},
                    {'id': '2', 'code': 'USD', 'name': 'Dolar Amerika', 'symbol': '\$'},
                    {'id': '3', 'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
                  ];

                  return Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final curr = list[index];
                        final id = curr['id']?.toString() ?? '';
                        final code = curr['code']?.toString() ?? 'IDR';
                        final name = curr['name']?.toString() ?? '';
                        final symbol = curr['symbol']?.toString() ?? '';
                        final isSelected = _selectedCurrencyCode == code;

                        return Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : AppColors.bgInput,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.cardBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            onTap: () async {
                              await AuthLocalDataSourceImpl().saveSelectedCurrency(id, code);
                              if (mounted) {
                                setState(() {
                                  _selectedCurrencyCode = code;
                                });
                                Navigator.pop(ctx);
                                DynamicIslandToast.show(
                                  context,
                                  title: 'Mata Uang Diperbarui',
                                  message: 'Mata uang $code ($name) berhasil disimpan',
                                  type: DynamicToastType.success,
                                );
                              }
                            },
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.bgCard,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                symbol,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.bgDeep
                                      : AppColors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            title: Text(
                              '$code — $name',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.accent,
                                    size: 22,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCurrenciesFromApi() async {
    try {
      final token = await AuthLocalDataSourceImpl().getToken();
      final response = await http.get(
        Uri.parse(ApiUrl.currencies),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
          'X-App-Key': ApiUrl.appKey,
          'x-api-key': ApiUrl.appKey,
        },
      ).timeout(const Duration(seconds: 8));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}

    return [
      {'id': '1', 'code': 'IDR', 'name': 'Rupiah Indonesia', 'symbol': 'Rp'},
      {'id': '2', 'code': 'USD', 'name': 'Dolar Amerika', 'symbol': '\$'},
      {'id': '3', 'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    ];
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _handleNavTap(int i) {
    if (i == _navIndex) return;
    if (i == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (i == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TransactionsScreen()),
      );
    } else if (i == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: AppColors.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keluar dari akun?',
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
                        side: BorderSide(color: AppColors.cardBorder),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: _handleNavTap,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildProfileCard(),
            const SizedBox(height: 22),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildMenuGroup(
              title: 'Keamanan & Akun',
              start: 0.25,
              end: 0.6,
              items: [
                _MenuTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profil',
                  color: AppColors.info,
                  onTap: _openEditProfile,
                ),
                _MenuTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Ubah Password Akun',
                  color: AppColors.purple,
                  onTap: () {
                    ChangePasswordSheet.show(context);
                  },
                ),
                _MenuTile(
                  icon: Icons.fingerprint_rounded,
                  label: 'Login Sidik Jari (Biometrik)',
                  color: AppColors.accent,
                  trailing: Switch(
                    value: _biometricOn,
                    onChanged: _handleBiometricToggle,
                    activeThumbColor: AppColors.accent,
                    inactiveTrackColor: AppColors.bgInput,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildMenuGroup(
              title: 'Preferensi',
              start: 0.35,
              end: 0.7,
              items: [
                _MenuTile(
                  icon: Icons.attach_money_rounded,
                  label: 'Mata Uang',
                  color: AppColors.accent,
                  trailingText: _selectedCurrencyCode,
                  onTap: _openCurrencyPickerModal,
                ),
                _MenuTile(
                  icon: Icons.language_rounded,
                  label: 'Bahasa',
                  color: AppColors.info,
                  trailingText: 'Indonesia',
                  onTap: () {},
                ),
                _MenuTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifikasi',
                  color: AppColors.warning,
                  trailing: Switch(
                    value: _notificationsOn,
                    onChanged: (v) => setState(() => _notificationsOn = v),
                    activeColor: AppColors.accent,
                    inactiveTrackColor: AppColors.bgInput,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildMenuGroup(
              title: 'Lainnya',
              start: 0.45,
              end: 0.8,
              items: [
                _MenuTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Bantuan',
                  color: AppColors.info,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    );
                  },
                ),
                _MenuTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Kebijakan Privasi',
                  color: AppColors.textSecondary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
                _MenuTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Tentang Aplikasi',
                  color: AppColors.textSecondary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildLogoutButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeFor(0.0, 0.3),
      child: const Text(
        'Profil',
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return FadeTransition(
      opacity: _fadeFor(0.05, 0.4),
      child: SlideTransition(
        position: _slideFor(0.05, 0.4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.accentGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _user?.avatar != null && _user!.avatar!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(42),
                            child: Image.network(
                              _user!.avatar!,
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                _userInitials,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.bgDeep,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            _userInitials,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.bgDeep,
                            ),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ganti foto profil — coming next'),
                            backgroundColor: AppColors.bgCardHover,
                          ),
                        );
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.bgDeep,
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _user?.name.isNotEmpty == true ? _user!.name : 'User',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 10,
                      color: AppColors.bgDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                _user?.email.isNotEmpty == true ? _user!.email : 'user@email.com',
                style: AppTextStyles.tagline,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _user?.username.isNotEmpty == true ? '@${_user!.username}' : 'Free Plan',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return FadeTransition(
      opacity: _fadeFor(0.15, 0.5),
      child: SlideTransition(
        position: _slideFor(0.15, 0.5),
        child: Row(
          children: [
            Expanded(
              child: _StatBox(
                icon: Icons.account_balance_wallet_outlined,
                value: '$_accountsCount',
                label: 'Akun',
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                icon: Icons.receipt_long_outlined,
                value: '$_transactionsCount',
                label: 'Transaksi',
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                icon: Icons.pie_chart_outline_rounded,
                value: '$_budgetsCount',
                label: 'Budget',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGroup({
    required String title,
    required double start,
    required double end,
    required List<_MenuTile> items,
  }) {
    return FadeTransition(
      opacity: _fadeFor(start, end),
      child: SlideTransition(
        position: _slideFor(start, end),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 2),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: List.generate(items.length, (i) {
                  return Column(
                    children: [
                      items[i],
                      if (i != items.length - 1)
                        Divider(
                          height: 1,
                          indent: 58,
                          color: AppColors.cardBorder,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return FadeTransition(
      opacity: _fadeFor(0.55, 0.9),
      child: SlideTransition(
        position: _slideFor(0.55, 0.9),
        child: GestureDetector(
          onTap: _confirmLogout,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Keluar',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== Sub Widgets ====================

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    this.trailingText,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else ...[
                if (trailingText != null)
                  Text(
                    trailingText!,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
