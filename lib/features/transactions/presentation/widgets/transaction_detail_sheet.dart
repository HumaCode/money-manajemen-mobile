import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import '../models/transaction_model.dart';

class TransactionDetailSheet extends StatelessWidget {
  final TransactionModel item;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const TransactionDetailSheet({
    super.key,
    required this.item,
    required this.onDelete,
    this.onEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required TransactionModel item,
    required VoidCallback onDelete,
    VoidCallback? onEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailSheet(
        item: item,
        onDelete: onDelete,
        onEdit: onEdit,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text(
              'Hapus Transaksi',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus transaksi "${item.title}"?',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop(); // Close alert
              Navigator.of(context).pop();  // Close sheet
              onDelete();
              DynamicIslandToast.show(
                context,
                title: 'Dihapus',
                message: 'Transaksi "${item.title}" berhasil dihapus',
                type: DynamicToastType.info,
              );
            },
            child: const Text(
              'Hapus',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sign = item.isIncome ? '+' : '-';
    final amountColor = item.isIncome ? AppColors.success : AppColors.error;
    final typeName = item.isIncome
        ? 'Pemasukan'
        : (item.type == TransactionType.transfer ? 'Transfer' : 'Pengeluaran');

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail Transaksi',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Glowing Icon & Amount Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: item.color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  '$sign ${formatRupiah(item.amount.abs())}',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    typeName,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.title_rounded,
                  label: 'Judul',
                  value: item.title,
                ),
                const Divider(color: AppColors.cardBorder, height: 20),
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Kategori',
                  value: item.category,
                ),
                const Divider(color: AppColors.cardBorder, height: 20),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Tanggal',
                  value: formatDateFull(item.date),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons: Edit & Delete
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit!();
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.bgDeep,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
