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

import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _entrance;
  bool _rememberMe = false;

  Animation<double> _fadeFor(double start, double end) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(start, end, curve: Curves.easeOut),
  );

  Animation<Offset> _slideFor(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
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
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
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
            DynamicIslandToast.show(
              context,
              message: state.userModel.message.isNotEmpty
                  ? state.userModel.message
                  : 'Login Berhasil!',
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
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),

                        // Logo + heading
                        FadeTransition(
                          opacity: _fadeFor(0.0, 0.4),
                          child: SlideTransition(
                            position: _slideFor(0.0, 0.4),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.accentGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent.withOpacity(0.3),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.show_chart_rounded,
                                    color: AppColors.bgDeep,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Selamat datang kembali',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Masuk untuk lanjut kelola keuanganmu',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.tagline,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Username field
                        FadeTransition(
                          opacity: _fadeFor(0.2, 0.6),
                          child: SlideTransition(
                            position: _slideFor(0.2, 0.6),
                            child: AppTextField(
                              label: 'Username / Email',
                              icon: Icons.person_outline_rounded,
                              controller: _usernameController,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password field
                        FadeTransition(
                          opacity: _fadeFor(0.3, 0.7),
                          child: SlideTransition(
                            position: _slideFor(0.3, 0.7),
                            child: AppTextField(
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: true,
                              controller: _passwordController,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Remember me + Forgot password
                        FadeTransition(
                          opacity: _fadeFor(0.4, 0.75),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _rememberMe = !_rememberMe),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: _rememberMe
                                            ? AppColors.accent
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: _rememberMe
                                              ? AppColors.accent
                                              : AppColors.textSecondary,
                                          width: 1.4,
                                        ),
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 150),
                                        child: _rememberMe
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 15,
                                                color: AppColors.bgDeep,
                                                key: ValueKey('checked'),
                                              )
                                            : const SizedBox(
                                                key: ValueKey('unchecked'),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Ingat saya',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 13,
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Login button
                        FadeTransition(
                          opacity: _fadeFor(0.5, 0.85),
                          child: SlideTransition(
                            position: _slideFor(0.5, 0.85),
                            child: PrimaryButton(
                              label: 'Masuk',
                              isLoading: isLoading,
                              onPressed: isLoading ? () {} : _handleLogin,
                            ),
                          ),
                        ),

                        const Spacer(),
                        const SizedBox(height: 24),

                        // Register link
                        FadeTransition(
                          opacity: _fadeFor(0.65, 1.0),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Belum punya akun? ',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        transitionDuration: const Duration(
                                          milliseconds: 450,
                                        ),
                                        pageBuilder: (_, animation, __) =>
                                            FadeTransition(
                                          opacity: animation,
                                          child: const RegisterScreen(),
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Daftar',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}
