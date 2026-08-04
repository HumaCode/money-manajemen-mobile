import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/services/biometric_service.dart';

class BiometricModalSheet extends StatefulWidget {
  const BiometricModalSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const BiometricModalSheet(),
    );
  }

  @override
  State<BiometricModalSheet> createState() => _BiometricModalSheetState();
}

class _BiometricModalSheetState extends State<BiometricModalSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAuthenticating = false;
  String _statusText = 'Tempelkan jari terdaftar Anda pada sensor HP';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Delay 400ms to allow bottom sheet transition to complete before triggering native prompt
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _startBiometricCheck();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startBiometricCheck() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _hasError = false;
      _statusText = 'Menycan sidik jari pada HP Anda...';
    });

    final success = await BiometricService.authenticate(
      reason: 'Verifikasi sidik jari untuk login Money Manajemen',
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isAuthenticating = false;
        _hasError = false;
        _statusText = 'Sidik jari cocok! Membuka aplikasi...';
      });
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _isAuthenticating = false;
        _hasError = false;
        _statusText = 'Tempelkan jari terdaftar Anda pada sensor HP atau sentuh ikon di bawah';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
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
          const SizedBox(height: 24),
          const Text(
            'Autentikasi Sidik Jari',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _hasError ? AppColors.error : AppColors.accent,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _startBiometricCheck,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_hasError ? AppColors.error : AppColors.accent).withValues(alpha: 0.15),
                  border: Border.all(
                    color: _hasError ? AppColors.error : AppColors.accent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_hasError ? AppColors.error : AppColors.accent).withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  size: 52,
                  color: _hasError ? AppColors.error : AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _hasError ? 'Tekan ikon untuk mencoba lagi' : 'Sentuh sensor HP atau tekan ikon di atas',
            style: AppTextStyles.tagline,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
