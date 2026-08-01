import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/animated_background.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AnimationController _entrance;
  bool _agreeToTerms = false;
  bool _isLoading = false;

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
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setujui syarat & ketentuan terlebih dahulu'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulated register call — replace with real API integration
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Register flow — connect to API next'),
        backgroundColor: AppColors.bgCardHover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // Back button
                FadeTransition(
                  opacity: _fadeFor(0.0, 0.3),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Heading
                FadeTransition(
                  opacity: _fadeFor(0.0, 0.4),
                  child: SlideTransition(
                    position: _slideFor(0.0, 0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
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
                            Icons.person_add_alt_1_rounded,
                            color: AppColors.bgDeep,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Buat akun baru',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Mulai kelola keuanganmu dengan lebih rapi',
                          style: AppTextStyles.tagline,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Full name
                FadeTransition(
                  opacity: _fadeFor(0.15, 0.5),
                  child: SlideTransition(
                    position: _slideFor(0.15, 0.5),
                    child: AppTextField(
                      label: 'Nama Lengkap',
                      icon: Icons.badge_outlined,
                      controller: _nameController,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Username
                FadeTransition(
                  opacity: _fadeFor(0.22, 0.57),
                  child: SlideTransition(
                    position: _slideFor(0.22, 0.57),
                    child: AppTextField(
                      label: 'Username',
                      icon: Icons.person_outline_rounded,
                      controller: _usernameController,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Email
                FadeTransition(
                  opacity: _fadeFor(0.29, 0.64),
                  child: SlideTransition(
                    position: _slideFor(0.29, 0.64),
                    child: AppTextField(
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Password
                FadeTransition(
                  opacity: _fadeFor(0.36, 0.71),
                  child: SlideTransition(
                    position: _slideFor(0.36, 0.71),
                    child: AppTextField(
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                      controller: _passwordController,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Confirm Password
                FadeTransition(
                  opacity: _fadeFor(0.43, 0.78),
                  child: SlideTransition(
                    position: _slideFor(0.43, 0.78),
                    child: AppTextField(
                      label: 'Konfirmasi Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                      controller: _confirmPasswordController,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Terms checkbox
                FadeTransition(
                  opacity: _fadeFor(0.5, 0.82),
                  child: GestureDetector(
                    onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(top: 2),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: _agreeToTerms
                                ? AppColors.accent
                                : Colors.transparent,
                            border: Border.all(
                              color: _agreeToTerms
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                              width: 1.4,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: _agreeToTerms
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: AppColors.bgDeep,
                                    key: ValueKey('checked'),
                                  )
                                : const SizedBox(key: ValueKey('unchecked')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(text: 'Saya menyetujui '),
                                TextSpan(
                                  text: 'Syarat & Ketentuan',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: ' serta '),
                                TextSpan(
                                  text: 'Kebijakan Privasi',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
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

                const SizedBox(height: 26),

                // Register button
                FadeTransition(
                  opacity: _fadeFor(0.58, 0.9),
                  child: SlideTransition(
                    position: _slideFor(0.58, 0.9),
                    child: PrimaryButton(
                      label: 'Daftar',
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login link
                FadeTransition(
                  opacity: _fadeFor(0.7, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Masuk',
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
    );
  }
}
