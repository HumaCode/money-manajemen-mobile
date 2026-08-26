import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/services/export_service.dart';
import 'package:money_manajemen/core/widgets/app_loader.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/data/models/transaction_model.dart';

class ExportBottomSheet extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String periodName;

  const ExportBottomSheet({
    super.key,
    required this.transactions,
    required this.periodName,
  });

  static void show(BuildContext context, {required List<TransactionModel> transactions, required String periodName}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ExportBottomSheet(
        transactions: transactions,
        periodName: periodName,
      ),
    );
  }

  @override
  State<ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<ExportBottomSheet> {
  bool _isExporting = false;

  Future<void> _handleExportPdf() async {
    setState(() {
      _isExporting = true;
    });
    try {
      final file = await ExportService.exportToPdf(
        transactions: widget.transactions,
        periodName: widget.periodName,
      );
      if (mounted) {
        Navigator.pop(context);
        final fileName = file.path.split('/').last.split('\\').last;
        DynamicIslandToast.show(
          context,
          title: 'File PDF Berhasil Dibuat',
          message: 'Telah dibuka untuk preview ($fileName)',
          type: DynamicToastType.success,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (mounted) {
        DynamicIslandToast.show(
          context,
          title: 'Gagal Membuka PDF',
          message: '$e',
          type: DynamicToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder),
          left: BorderSide(color: AppColors.cardBorder),
          right: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Ekspor Laporan Keuangan',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unduh laporan keuangan PDF (${widget.periodName}) berisikan ${widget.transactions.length} transaksi.',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          if (_isExporting)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF161F2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.08),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const AppLoader(
                    size: 64,
                    message: '',
                    icon: Icons.picture_as_pdf_rounded,
                    iconColor: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sedang Membuat File PDF...',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Menyiapkan ${widget.transactions.length} transaksi untuk diunduh',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // PDF Export Card Option
            _ExportOptionTile(
              icon: Icons.picture_as_pdf_rounded,
              iconBgColor: AppColors.error.withValues(alpha: 0.15),
              iconColor: AppColors.error,
              title: 'Dokumen PDF (.pdf)',
              subtitle: 'Laporan keuangan tercetak rapi dengan tabel dan ringkasan',
              onTap: _handleExportPdf,
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161F2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
