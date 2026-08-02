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

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _loaderController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _brandOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _loaderOpacity;
  late final Animation<double> _loaderProgress;

  @override
  void initState() {
    super.initState();

    // Staged entrance: logo -> brand text -> tagline -> loader
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _brandSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
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

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );

    _loaderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Logo subtle breathing glow, loops forever until navigation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Progress bar fill 0 -> 100%
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _loaderProgress = CurvedAnimation(
      parent: _loaderController,
      curve: Curves.easeInOutCubic,
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await _entranceController.forward();
    await _loaderController.forward(); // fills to 100%
    if (!mounted) return;

    // Small hold at 100% before transitioning
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final token = await AuthLocalDataSourceImpl().getToken();
    final Widget targetScreen = (token != null && token.isNotEmpty)
        ? const DashboardScreen()
        : const LoginScreen();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, __) =>
            FadeTransition(opacity: animation, child: targetScreen),
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _loaderController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Logo
              FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final glow = 0.25 + (_pulseController.value * 0.25);
                      return Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.accentGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(glow),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: const Icon(
                      Icons.show_chart_rounded,
                      size: 52,
                      color: AppColors.bgDeep,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Brand name
              ClipRect(
                child: SlideTransition(
                  position: _brandSlide,
                  child: FadeTransition(
                    opacity: _brandOpacity,
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Money',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: 'Flow',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              FadeTransition(
                opacity: _taglineOpacity,
                child: const Text(
                  'Kelola keuanganmu dengan cerdas',
                  style: AppTextStyles.tagline,
                ),
              ),

              const Spacer(flex: 3),

              // Loader
              FadeTransition(
                opacity: _loaderOpacity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _loaderProgress,
                        builder: (context, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 6,
                              width: double.infinity,
                              color: AppColors.bgInput,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: _loaderProgress.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: AppColors.accentGradient,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withOpacity(
                                            0.5,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _loaderProgress,
                        builder: (context, _) {
                          final pct = (_loaderProgress.value * 100)
                              .clamp(0, 100)
                              .toStringAsFixed(0);
                          return Text(
                            'Loading  $pct%',
                            style: AppTextStyles.loaderLabel,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
