import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';

class AiScanningLoadingDialog extends StatefulWidget {
  const AiScanningLoadingDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const AiScanningLoadingDialog(),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  State<AiScanningLoadingDialog> createState() => _AiScanningLoadingDialogState();
}

class _AiScanningLoadingDialogState extends State<AiScanningLoadingDialog> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  int _statusIndex = 0;

  final List<String> _statusMessages = [
    'Membaca gambar struk...',
    'Menganalisis teks & merchant dengan Gemini AI...',
    'Mendapatkan rincian item & diskon...',
    'Menyiapkan preview transaksi...',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _cycleMessages();
  }

  void _cycleMessages() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _statusMessages.length;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated AI Scanner Icon with Glow
              AnimatedBuilder(
                animation: Listenable.merge([_pulseController, _rotationController]),
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow Ring
                      Container(
                        width: 90 + (_pulseController.value * 12),
                        height: 90 + (_pulseController.value * 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1 + (_pulseController.value * 0.1)),
                        ),
                      ),
                      // Rotating Dashed Border / Gradient Accent Ring
                      Transform.rotate(
                        angle: _rotationController.value * 2 * 3.14159,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // Inner Icon Badge
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.8),
                              AppColors.success,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Sedang Proses Scanning',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Animated Status Subtitle
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusMessages[_statusIndex],
                  key: ValueKey<int>(_statusIndex),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.cardBorder,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
