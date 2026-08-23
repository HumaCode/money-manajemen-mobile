import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/animated_background.dart';
import 'package:money_manajemen/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _loaderController;
  late final AnimationController _pulseController;
  late final AnimationController _rotationController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _brandOpacity;
  late final Animation<double> _loaderOpacity;
  late final Animation<double> _loaderProgress;

  final List<String> _loadingSteps = [
    'Memuat Database SQLite Lokal...',
    'Menyiapkan Engine AI Gemini...',
    'Verifikasi Keamanan Enkripsi 2FA...',
    'Menghubungkan Sesi Akun...',
  ];

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _brandSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _brandOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );

    _loaderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _loaderProgress = CurvedAnimation(
      parent: _loaderController,
      curve: Curves.easeInOutCubic,
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await _entranceController.forward();
    await _loaderController.forward();
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final token = await AuthLocalDataSourceImpl().getToken();
    final Widget targetScreen = (token != null && token.isNotEmpty) ? const DashboardScreen() : const LoginScreen();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: targetScreen),
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _loaderController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  String _getStepLabel(double progress) {
    if (progress < 0.28) return _loadingSteps[0];
    if (progress < 0.58) return _loadingSteps[1];
    if (progress < 0.88) return _loadingSteps[2];
    return _loadingSteps[3];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Animated Glowing Logo Icon with Rotating Orbit Rings
              FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating Outer Radar Ring
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, _) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * math.pi,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 4,
                                    left: 60,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.accent,
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Pulsing Mid Ring
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final scale = 1.0 + (_pulseController.value * 0.08);
                          final opacity = 0.15 + (_pulseController.value * 0.15);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent.withValues(alpha: opacity),
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Main Glowing Icon Inner Box
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.accentGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.show_chart_rounded,
                          size: 46,
                          color: AppColors.bgDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Brand Title & Tagline
              SlideTransition(
                position: _brandSlide,
                child: FadeTransition(
                  opacity: _brandOpacity,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Money ',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => AppColors.accentGradient.createShader(bounds),
                            child: const Text(
                              'Management',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'PREMIUM FINANCIAL PLATFORM 2.0',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Interactive Progress Glass Card (Bottom Loader)
              FadeTransition(
                opacity: _loaderOpacity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _loaderProgress,
                      builder: (context, _) {
                        final progress = _loaderProgress.value;
                        final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
                        final stepText = _getStepLabel(progress);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header Row: Live step label & Percentage
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      stepText,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$pct%',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Multi-color Gradient Progress Track
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.bgInput,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: AppColors.accentGradient,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withValues(alpha: 0.6),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
