import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/animated_background.dart';
import 'package:money_manajemen/features/profile/presentation/widgets/profile_header_bar.dart';
import 'package:money_manajemen/features/profile/presentation/widgets/info_section_card.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  Animation<double> _fadeFor(double start, double end) => CurvedAnimation(
        parent: _entrance,
        curve: Interval(start, end, curve: Curves.easeOut),
      );

  Animation<Offset> _slideFor(double start, double end) => Tween<Offset>(
        begin: const Offset(0, 0.12),
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
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Reusable Header Navigation Bar
              FadeTransition(
                opacity: _fadeFor(0.0, 0.3),
                child: const ProfileHeaderBar(title: 'Kebijakan Privasi'),
              ),

              // Scrollable Policy Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Hero Header Card
                      FadeTransition(
                        opacity: _fadeFor(0.1, 0.4),
                        child: SlideTransition(
                          position: _slideFor(0.1, 0.4),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.15),
                                  AppColors.bgCard,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.privacy_tip_rounded,
                                        color: AppColors.accent,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Komitmen Privasi Data',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Money Management V2 berkomitmen penuh untuk melindungi privasi dan keamanan data finansial pengguna. Kebijakan ini menjelaskan bagaimana data Anda dikelola secara aman.',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Terakhir Diperbarui: 23 Agustus 2026',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Reusable Info Section Cards
                      const InfoSectionCard(
                        title: 'Pengumpulan & Penggunaan Data',
                        icon: Icons.folder_shared_rounded,
                        color: AppColors.accent,
                        content:
                            'Kami hanya mengumpulkan informasi yang diperlukan untuk mengoperasikan aplikasi, seperti Nama, Email, Username, Nomor WhatsApp (untuk 2FA), dan catatan transaksi keuangan Anda. Data ini tidak akan dijual atau disebarluaskan kepada pihak ketiga.',
                      ),
                      const InfoSectionCard(
                        title: 'Keamanan & Enkripsi Data',
                        icon: Icons.shield_rounded,
                        color: AppColors.success,
                        content:
                            'Seluruh komunikasi data antara aplikasi Android dan server dienkripsi menggunakan protokol HTTPS 256-Bit SSL. Data transaksi Anda juga disimpan secara lokal pada database SQLite terenkripsi di dalam perangkat Anda.',
                      ),
                      const InfoSectionCard(
                        title: 'Pemrosesan Struk AI (Gemini)',
                        icon: Icons.auto_awesome_rounded,
                        color: AppColors.purple,
                        content:
                            'Saat Anda menggunakan fitur Pindai Struk AI, foto struk dikirim secara aman ke API Gemini untuk mengekstrak teks nominal dan nama transaksi. Foto struk diproses secara transient dan tidak disimpan secara permanen pada server AI.',
                      ),
                      const InfoSectionCard(
                        title: 'Otentikasi 2FA WhatsApp',
                        icon: Icons.chat_rounded,
                        color: AppColors.info,
                        content:
                            'Nomor WhatsApp Anda hanya digunakan untuk mengirimkan Kode OTP 6-Digit saat otentikasi login 2FA via WhatsApp Gateway SIGATE. Kode OTP berlaku terbatas selama 5 menit dan tidak digunakan untuk pesan promosi.',
                      ),
                      const InfoSectionCard(
                        title: 'Hak & Kontrol Pengguna',
                        icon: Icons.manage_accounts_rounded,
                        color: AppColors.warning,
                        content:
                            'Anda memiliki kendali penuh atas akun Anda. Anda berhak memperbarui profil, mengubah password, mengaktifkan/menonaktifkan 2FA, serta menghapus data transaksi lokal kapan saja melalui menu Pengaturan.',
                      ),

                      const SizedBox(height: 24),

                      // Footer Trust Badge
                      FadeTransition(
                        opacity: _fadeFor(0.6, 0.9),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.verified_user_rounded, color: AppColors.accent, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Dilindungi oleh HumaCode Security Engine',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
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
