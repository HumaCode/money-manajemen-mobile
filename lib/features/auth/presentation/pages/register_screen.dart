import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/animated_background.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';

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

    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      DynamicIslandToast.show(
        context,
        title: 'Form Belum Lengkap',
        message: 'Harap isi seluruh data pendaftaran',
        type: DynamicToastType.warning,
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      DynamicIslandToast.show(
        context,
        title: 'Password Tidak Sama',
        message:
            'Konfirmasi password tidak cocok dengan password yang dimasukkan',
        type: DynamicToastType.error,
      );
      return;
    }

    if (!_agreeToTerms) {
      DynamicIslandToast.show(
        context,
        title: 'Syarat & Ketentuan',
        message:
            'Setujui Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu',
        type: DynamicToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _isLoading = false);

    DynamicIslandToast.show(
      context,
      title: 'Pendaftaran Berhasil',
      message: 'Akun berhasil dibuat. Silakan masuk!',
      type: DynamicToastType.success,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Brand Hero Banner
                FadeTransition(
                  opacity: _fadeFor(0.0, 0.4),
                  child: SlideTransition(
                    position: _slideFor(0.0, 0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.accentGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: AppColors.bgDeep,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Buat Akun Baru',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Mulai kelola keuanganmu dengan rapi',
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Glassmorphism Form Card
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
                          // Full name
                          AppTextField(
                            label: 'Nama Lengkap',
                            icon: Icons.badge_outlined,
                            controller: _nameController,
                          ),
                          const SizedBox(height: 12),

                          // Username
                          AppTextField(
                            label: 'Username',
                            icon: Icons.person_outline_rounded,
                            controller: _usernameController,
                          ),
                          const SizedBox(height: 12),

                          // Email
                          AppTextField(
                            label: 'Email',
                            icon: Icons.mail_outline_rounded,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),

                          // Password
                          AppTextField(
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                            controller: _passwordController,
                          ),
                          const SizedBox(height: 12),

                          // Confirm Password
                          AppTextField(
                            label: 'Konfirmasi Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                            controller: _confirmPasswordController,
                          ),
                          const SizedBox(height: 16),

                          // Terms & Conditions Checkbox
                          GestureDetector(
                            onTap: () =>
                                setState(() => _agreeToTerms = !_agreeToTerms),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
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
                                            size: 13,
                                            color: AppColors.bgDeep,
                                          )
                                        : const SizedBox(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 12,
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
                          const SizedBox(height: 22),

                          // Submit Register Button
                          PrimaryButton(
                            label: 'Daftar',
                            isLoading: _isLoading,
                            onPressed: _isLoading ? () {} : _handleRegister,
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
      ),

      // Fixed Floating Footer Bar at bottom
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bgCard.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
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
                      TextSpan(text: 'Sudah punya akun? '),
                      TextSpan(
                        text: 'Masuk Sekarang',
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

  Widget _buildFooterHighlights() {
    return Column(
      children: [
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
        const SizedBox(height: 12),
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
              'Pendaftaran Akun Terenkripsi & Aman',
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
