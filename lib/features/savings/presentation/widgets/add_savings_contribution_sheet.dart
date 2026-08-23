import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import '../../data/models/savings_contribution_model.dart';

class AddSavingsContributionSheet extends StatefulWidget {
  final String savingsGoalId;
  final String goalTitle;

  const AddSavingsContributionSheet({
    super.key,
    required this.savingsGoalId,
    required this.goalTitle,
  });

  static Future<Contribution?> show(
    BuildContext context, {
    required String savingsGoalId,
    required String goalTitle,
  }) {
    return showModalBottomSheet<Contribution>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSavingsContributionSheet(
        savingsGoalId: savingsGoalId,
        goalTitle: goalTitle,
      ),
    );
  }

  @override
  State<AddSavingsContributionSheet> createState() => _AddSavingsContributionSheetState();
}

class _AddSavingsContributionSheetState extends State<AddSavingsContributionSheet> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  final bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    FocusScope.of(context).unfocus();

    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      DynamicIslandToast.show(
        context,
        title: 'Form Belum Lengkap',
        message: 'Nominal setoran tabungan wajib diisi',
        type: DynamicToastType.warning,
      );
      return;
    }

    final amount = int.tryParse(amountStr.replaceAll('.', '')) ?? 0;
    if (amount <= 0) {
      DynamicIslandToast.show(
        context,
        title: 'Nominal Tidak Valid',
        message: 'Nominal setoran harus lebih besar dari 0',
        type: DynamicToastType.warning,
      );
      return;
    }

    final now = DateTime.now();

    final contribution = Contribution(
      id: now.millisecondsSinceEpoch.toString(),
      savingsGoalId: widget.savingsGoalId,
      amount: amount.toString(),
      notes: _notesController.text.trim(),
      contributedAt: now,
      savingsGoal: SavingsGoal(
        id: widget.savingsGoalId,
        userId: '',
        accountId: '',
        currencyId: 'IDR',
        name: widget.goalTitle,
        description: '',
        targetAmount: '0',
        currentAmount: amount.toString(),
        monthlyTarget: '0',
        targetDate: now.add(const Duration(days: 30)),
        status: 'active',
        icon: 'savings',
        color: '#00FFA3',
        createdAt: now,
        updatedAt: now,
      ),
    );

    Navigator.of(context).pop(contribution);
  }

  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_task_rounded,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Setor Tabungan',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: ${widget.goalTitle}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Input Fields
            AppTextField(
              label: 'Nominal Setoran (Rp)',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              controller: _amountController,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Catatan Setoran (opsional)',
              icon: Icons.notes_rounded,
              controller: _notesController,
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              label: 'Tambah Setoran Tabungan',
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
