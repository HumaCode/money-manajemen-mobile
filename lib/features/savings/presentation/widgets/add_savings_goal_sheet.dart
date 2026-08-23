import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import '../../data/models/savings_goal_model.dart';

class AddSavingsGoalSheet extends StatefulWidget {
  final Data? goalToEdit;

  const AddSavingsGoalSheet({super.key, this.goalToEdit});

  static Future<Data?> show(
    BuildContext context, {
    Data? goalToEdit,
  }) {
    return showModalBottomSheet<Data>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSavingsGoalSheet(goalToEdit: goalToEdit),
    );
  }

  @override
  State<AddSavingsGoalSheet> createState() => _AddSavingsGoalSheetState();
}

class _AddSavingsGoalSheetState extends State<AddSavingsGoalSheet> {
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  final _notesController = TextEditingController();

  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      _titleController.text = widget.goalToEdit!.name;
      _targetAmountController.text = widget.goalToEdit!.targetAmount.toString();
      _currentAmountController.text = widget.goalToEdit!.currentAmount.toString();
      _notesController.text = widget.goalToEdit!.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();
    final targetStr = _targetAmountController.text.trim();

    if (title.isEmpty || targetStr.isEmpty) {
      DynamicIslandToast.show(
        context,
        title: 'Form Belum Lengkap',
        message: 'Nama target dan nominal target wajib diisi',
        type: DynamicToastType.warning,
      );
      return;
    }

    final targetAmount = int.tryParse(targetStr.replaceAll('.', '')) ?? 0;
    final currentAmount = int.tryParse(_currentAmountController.text.replaceAll('.', '')) ?? 0;
    final remaining = targetAmount - currentAmount;
    final pct = targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;

    final goal = Data(
      id: widget.goalToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: title,
      description: _notesController.text.trim(),
      accountId: widget.goalToEdit?.accountId ?? '',
      accountName: widget.goalToEdit?.accountName ?? 'Kas Utama',
      currencyId: widget.goalToEdit?.currencyId ?? 'IDR',
      currencyCode: widget.goalToEdit?.currencyCode ?? 'IDR',
      currencySymbol: widget.goalToEdit?.currencySymbol ?? 'Rp',
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      remainingAmount: remaining < 0 ? 0 : remaining,
      monthlyTarget: widget.goalToEdit?.monthlyTarget ?? 0,
      progressPercentage: pct > 1.0 ? 1.0 : pct,
      targetDate: widget.goalToEdit?.targetDate ?? DateTime.now().add(const Duration(days: 30)),
      status: widget.goalToEdit?.status ?? 'active',
      icon: widget.goalToEdit?.icon ?? 'savings',
      color: widget.goalToEdit?.color ?? '#00FFA3',
      createdAt: widget.goalToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(goal);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goalToEdit != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Edit Target Tabungan' : 'Tambah Target Tabungan',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Input Fields
            AppTextField(
              label: 'Nama Target (contoh: Beli Laptop / Liburan)',
              icon: Icons.flag_outlined,
              controller: _titleController,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Target Nominal (Rp)',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              controller: _targetAmountController,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Saldo Awal Tabungan (Rp opsional)',
              icon: Icons.account_balance_wallet_outlined,
              keyboardType: TextInputType.number,
              controller: _currentAmountController,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Catatan / Deskripsi (opsional)',
              icon: Icons.notes_rounded,
              controller: _notesController,
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              label: isEditing ? 'Simpan Perubahan' : 'Buat Target Tabungan',
              isLoading: _isLoading,
              onPressed: _handleSave,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
