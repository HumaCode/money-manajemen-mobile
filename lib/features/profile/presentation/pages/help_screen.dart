import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/animated_background.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';

class _FaqItem {
  final String category;
  final String question;
  final String answer;

  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  final _searchController = TextEditingController();

  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  int? _expandedIndex;

  static const List<String> _categories = [
    'Semua',
    'Keamanan & 2FA',
    'AI Scanner Struk',
    'Rekening & Akun',
    'Anggaran & Tabungan',
  ];

  static const List<_FaqItem> _faqList = [
    _FaqItem(
      category: 'Keamanan & 2FA',
      question: 'Bagaimana cara mengaktifkan 2FA WhatsApp?',
      answer:
          'Buka menu Profil > Keamanan & 2FA. Masukkan nomor WhatsApp aktif Anda, lalu klik "Kirim Kode OTP". Masukkan 6-digit kode OTP yang dikirimkan via WhatsApp untuk mengaktifkan perlindungan 2FA.',
    ),
    _FaqItem(
      category: 'Keamanan & 2FA',
      question: 'Apa yang terjadi jika saya tidak menerima kode OTP?',
      answer:
          'Pastikan nomor WhatsApp Anda aktif dan terhubung ke internet. Jika timer berakhir, Anda dapat mengeklik tombol "Kirim Ulang Kode OTP" pada lembar verifikasi.',
    ),
    _FaqItem(
      category: 'AI Scanner Struk',
      question: 'Bagaimana cara kerja Pemindaian Struk AI?',
      answer:
          'Klik tombol tambah transaksi > Pindai Struk AI. Ambil foto struk belanja Anda. AI Gemini akan mengekstrak nama toko, tanggal, daftar item, dan total belanja secara otomatis.',
    ),
    _FaqItem(
      category: 'AI Scanner Struk',
      question: 'Apakah hasil ekstraksi struk belanja bisa diedit?',
      answer:
          'Tentu saja! Sebelum menyimpan transaksi, Anda dapat memeriksa dan merubah nominal, kategori, maupun nama transaksi sesuai kebutuhan Anda.',
    ),
    _FaqItem(
      category: 'Rekening & Akun',
      question: 'Apakah data saya tersimpan secara offline?',
      answer:
          'Ya! Money Management V2 menggunakan database SQLite lokal pada perangkat Android Anda, sehingga Anda dapat mencatat dan melihat transaksi bahkan saat offline.',
    ),
    _FaqItem(
      category: 'Rekening & Akun',
      question: 'Bagaimana cara menambah rekening bank atau e-wallet?',
      answer:
          'Masuk ke menu Dashboard > Pilih Kelola Akun / Tambah Akun. Pilih jenis rekening (BCA, Mandiri, GoPay, OVO, dll) dan masukkan saldo awal Anda.',
    ),
    _FaqItem(
      category: 'Anggaran & Tabungan',
      question: 'Bagaimana cara membuat target tabungan (Saving Goal)?',
      answer:
          'Masuk ke menu Analisis > Target Tabungan > Tambah Target. Masukkan nama target, nominal yang ingin dicapai, dan tanggal batas waktu pencapaian.',
    ),
  ];

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

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _entrance.dispose();
    super.dispose();
  }

  List<_FaqItem> get _filteredFaqs {
    return _faqList.where((item) {
      final matchesCat = _selectedCategory == 'Semua' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.question.toLowerCase().contains(_searchQuery) ||
          item.answer.toLowerCase().contains(_searchQuery);
      return matchesCat && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFaqs;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: FadeTransition(
                  opacity: _fadeFor(0.0, 0.3),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.bgCard.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Pusat Bantuan & FAQ',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Hero Card Section
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
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.help_center_rounded,
                                    color: AppColors.accent,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Ada yang bisa dibantu?',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Cari jawaban atau temukan panduan penggunaan aplikasi Money Management.',
                                        style: TextStyle(
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
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Search Input
                      FadeTransition(
                        opacity: _fadeFor(0.2, 0.5),
                        child: AppTextField(
                          label: 'Cari topik bantuan...',
                          icon: Icons.search_rounded,
                          controller: _searchController,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Category Chips Horizontal Scroll
                      FadeTransition(
                        opacity: _fadeFor(0.3, 0.6),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((cat) {
                              final isSelected = cat == _selectedCategory;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = cat;
                                      _expandedIndex = null;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.accent
                                          : AppColors.bgCard.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.accent
                                            : AppColors.cardBorder,
                                      ),
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? AppColors.bgDeep : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // FAQ List Title
                      FadeTransition(
                        opacity: _fadeFor(0.4, 0.7),
                        child: const Text(
                          'Pertanyaan Sering Diajukan (FAQ)',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Filtered Accordion List
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: const [
                              Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
                              SizedBox(height: 12),
                              Text(
                                'Topik bantuan tidak ditemukan',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final isExpanded = _expandedIndex == index;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isExpanded
                                      ? AppColors.accent.withValues(alpha: 0.4)
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ExpansionTile(
                                  key: Key('faq_$index'),
                                  initiallyExpanded: isExpanded,
                                  onExpansionChanged: (expanded) {
                                    setState(() {
                                      _expandedIndex = expanded ? index : null;
                                    });
                                  },
                                  iconColor: AppColors.accent,
                                  collapsedIconColor: AppColors.textSecondary,
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  title: Text(
                                    item.question,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 13.5,
                                      fontWeight: isExpanded ? FontWeight.bold : FontWeight.w600,
                                      color: isExpanded ? AppColors.accent : AppColors.textPrimary,
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.bgDeep.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.accent.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Text(
                                        item.answer,
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 12.5,
                                          color: AppColors.textPrimary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 24),

                      // Live Support Card
                      FadeTransition(
                        opacity: _fadeFor(0.6, 0.9),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Butuh Bantuan Lebih Lanjut?',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tim Customer Support HumaCode siap membantu Anda 24/7.',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // WhatsApp Support Button
                              GestureDetector(
                                onTap: () {
                                  DynamicIslandToast.show(
                                    context,
                                    title: 'Menghubungkan Support',
                                    message: 'Membuka layanan WhatsApp Customer Service...',
                                    type: DynamicToastType.info,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.chat_rounded, color: AppColors.success, size: 20),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Chat WhatsApp Support (+62 823-2411-8692)',
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.success),
                                    ],
                                  ),
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
