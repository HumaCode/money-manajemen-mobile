import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/animated_background.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:money_manajemen/features/auth/presentation/bloc/auth_event.dart';
import 'package:money_manajemen/features/auth/presentation/bloc/auth_state.dart';
import 'package:money_manajemen/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'register_screen.dart';

import 'package:money_manajemen/core/services/biometric_service.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/features/auth/presentation/widgets/login_2fa_otp_sheet.dart';

class _FeatureSlide {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String tag;

  const _FeatureSlide({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.tag,
  });
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _entrance;
  late final PageController _pageController;
  Timer? _carouselTimer;

  int _activeSlide = 0;
  bool _rememberMe = false;
  bool _biometricAvailable = false;

  static const List<_FeatureSlide> _slides = [
    _FeatureSlide(
      icon: Icons.document_scanner_rounded,
      color: AppColors.accent,
      title: 'AI Receipt Scanner',
      description: 'Pindai & hitung struk belanja otomatis dengan Gemini AI',
      tag: 'AI POWERED',
    ),
    _FeatureSlide(
      icon: Icons.shield_rounded,
      color: AppColors.success,
      title: '2FA WhatsApp Security',
      description: 'Perlindungan login & otentikasi 2 langkah via WA OTP',
      tag: 'SECURE 2.0',
    ),
    _FeatureSlide(
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.purple,
      title: 'Multi-Account Sync',
      description: 'Sinkronisasi saldo rekening BCA, BRI, & E-Wallet real-time',
      tag: 'REALTIME',
    ),
    _FeatureSlide(
      icon: Icons.pie_chart_rounded,
      color: AppColors.warning,
      title: 'Smart Financial Target',
      description: 'Analisis pengeluaran cerdas & pencapaian tabungan otomatis',
      tag: 'ANALYTICS',
    ),
  ];

  Animation<double> _fadeFor(double start, double end) => CurvedAnimation(
        parent: _entrance,
        curve: Interval(start, end, curve: Curves.easeOut),
      );

  Animation<Offset> _slideFor(double start, double end) => Tween<Offset>(
        begin: const Offset(0, 0.15),
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
    _pageController = PageController();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _checkBiometricStatus();

    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _slides.isNotEmpty && _pageController.hasClients) {
        final next = (_activeSlide + 1) % _slides.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _checkBiometricStatus() async {
    final isHardwareAvailable = await BiometricService.isBiometricAvailable();
    if (mounted) {
      setState(() => _biometricAvailable = isHardwareAvailable || true);
    }
  }

  Future<void> _handleBiometricLogin() async {
    final isEnabled = await BiometricService.isBiometricEnabled();
    if (!isEnabled) {
      if (!mounted) return;
      DynamicIslandToast.show(
        context,
        title: 'Biometrik Tidak Aktif',
        message: 'Aktifkan fitur Login Sidik Jari di menu Pengaturan Profil terlebih dahulu.',
        type: DynamicToastType.warning,
      );
      return;
    }

    final authenticated = await BiometricService.authenticate(
      reason: 'Pindai sidik jari Anda untuk login',
    );
    if (authenticated && mounted) {
      final authDS = AuthLocalDataSourceImpl();
      String? token = await authDS.getToken();
      token ??= await authDS.getBiometricToken();

      if (token != null && token.isNotEmpty) {
        await authDS.saveToken(token);
        if (!mounted) return;

        DynamicIslandToast.show(
          context,
          title: 'Login Sidik Jari Berhasil',
          message: 'Selamat datang kembali!',
          type: DynamicToastType.success,
        );

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: const DashboardScreen(),
            ),
          ),
        );
      } else {
        DynamicIslandToast.show(
          context,
          title: 'Sesi Belum Tersimpan',
          message: 'Silakan masuk dengan Username & Password sekali terlebih dahulu',
          type: DynamicToastType.info,
        );
      }
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _entrance.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    FocusScope.of(context).unfocus();

    final loginText = _usernameController.text.trim();
    final passwordText = _passwordController.text;

    if (loginText.isEmpty || passwordText.isEmpty) {
      DynamicIslandToast.show(
        context,
        message: 'Username/Email dan Password wajib diisi',
        type: DynamicToastType.warning,
      );
      return;
    }

    context.read<AuthBloc>().add(
          LoginSubmittedEvent(
            login: loginText,
            password: passwordText,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            DynamicIslandToast.show(
              context,
              message: state.errorMessage,
              type: DynamicToastType.error,
            );
          } else if (state is AuthSuccess) {
            if (state.userModel.data?.requires2fa == true) {
              Login2faOtpSheet.show(
                context,
                userId: state.userModel.data!.userId,
                maskedPhone: state.userModel.data!.maskedPhone,
                onSuccess: (userModel) {
                  DynamicIslandToast.show(
                    context,
                    message: 'Login 2FA Berhasil!',
                    type: DynamicToastType.success,
                  );
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 500),
                      pageBuilder: (_, animation, __) => FadeTransition(
                        opacity: animation,
                        child: const DashboardScreen(),
                      ),
                    ),
                  );
                },
              );
              return;
            }

            DynamicIslandToast.show(
              context,
              message: state.userModel.message.isNotEmpty ? state.userModel.message : 'Login Berhasil!',
              type: DynamicToastType.success,
            );

            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (_, animation, __) => FadeTransition(
                  opacity: animation,
                  child: const DashboardScreen(),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AnimatedBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),

                    // Top Hero Banner Carousel
                    FadeTransition(
                      opacity: _fadeFor(0.0, 0.4),
                      child: SlideTransition(
                        position: _slideFor(0.0, 0.4),
                        child: _buildHeroCarousel(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Glassmorphism Login Card Form
                    FadeTransition(
                      opacity: _fadeFor(0.2, 0.7),
                      child: SlideTransition(
                        position: _slideFor(0.2, 0.7),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Selamat Datang',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Masuk ke akun Money Management Anda',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Username / Email input
                              AppTextField(
                                label: 'Username / Email',
                                icon: Icons.person_outline_rounded,
                                controller: _usernameController,
                              ),
                              const SizedBox(height: 14),

                              // Password input
                              AppTextField(
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: true,
                                controller: _passwordController,
                              ),
                              const SizedBox(height: 14),

                              // Remember Me & Forgot Password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                                    behavior: HitTestBehavior.opaque,
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            color: _rememberMe ? AppColors.accent : Colors.transparent,
                                            border: Border.all(
                                              color: _rememberMe ? AppColors.accent : AppColors.textSecondary,
                                              width: 1.4,
                                            ),
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 150),
                                            child: _rememberMe
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    size: 13,
                                                    color: AppColors.bgDeep,
                                                  )
                                                : const SizedBox(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Ingat saya',
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      'Lupa password?',
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
                              const SizedBox(height: 22),

                              // Login button & Biometric Button
                              Row(
                                children: [
                                  Expanded(
                                    child: PrimaryButton(
                                      label: 'Masuk',
                                      isLoading: isLoading,
                                      onPressed: isLoading ? () {} : _handleLogin,
                                    ),
                                  ),
                                  if (_biometricAvailable) ...[
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: _handleBiometricLogin,
                                      child: Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(AppRadius.button),
                                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                                        ),
                                        child: const Icon(
                                          Icons.fingerprint_rounded,
                                          color: AppColors.accent,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Modern Security Badges Highlights
                    FadeTransition(
                      opacity: _fadeFor(0.5, 0.9),
                      child: SlideTransition(
                        position: _slideFor(0.5, 0.9),
                        child: _buildFooterHighlights(),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RegisterScreen(),
                ),
              );
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bgCard.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(text: 'Belum punya akun? '),
                      TextSpan(
                        text: 'Daftar Sekarang',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCarousel() {
    return Column(
      children: [
        // App Logo & Brand Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.accentGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.show_chart_rounded,
                color: AppColors.bgDeep,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => AppColors.accentGradient.createShader(bounds),
              child: const Text(
                'Money Management V2',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Carousel Card Container
        Container(
          height: 125,
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _activeSlide = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: slide.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: slide.color.withValues(alpha: 0.3)),
                      ),
                      child: Icon(slide.icon, color: slide.color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: slide.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              slide.tag,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: slide.color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slide.title,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            slide.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (index) {
            final isActive = index == _activeSlide;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFooterHighlights() {
    return Column(
      children: [
        // 3 Modern Security Chips
        Row(
          children: [
            Expanded(
              child: _buildChip(
                icon: Icons.lock_outline_rounded,
                label: '256-Bit SSL',
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChip(
                icon: Icons.storage_rounded,
                label: 'SQLite Sync',
                color: AppColors.purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChip(
                icon: Icons.chat_rounded,
                label: 'WA OTP 2FA',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Platform Trust Note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Sistem Keuangan Aman & Terenkripsi Realtime',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
