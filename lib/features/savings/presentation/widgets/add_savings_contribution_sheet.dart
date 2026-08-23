import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/features/auth/data/datasources/auth_local_data_source.dart';
import '../../data/models/savings_contribution_model.dart';
import '../../data/datasources/savings_remote_data_source.dart';

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
  late final TextEditingController _dateController;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: formatDateFull(_selectedDate));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
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

    final amount = parseAmountString(amountStr);
    if (amount <= 0) {
      DynamicIslandToast.show(
        context,
        title: 'Nominal Tidak Valid',
        message: 'Nominal setoran harus lebih besar dari 0',
        type: DynamicToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final dataSource = SavingsRemoteDataSourceImpl(
      client: http.Client(),
      localDataSource: AuthLocalDataSourceImpl(),
    );

    final remoteContrib = await dataSource.addSavingContribution(
      widget.savingsGoalId,
      amount: amount,
      contributedAt: _selectedDate,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (remoteContrib != null) {
      Navigator.of(context).pop(remoteContrib);
    } else {
      DynamicIslandToast.show(
        context,
        title: 'Gagal Menyimpan ❌',
        message: 'Gagal menyimpan setoran tabungan ke server database',
        type: DynamicToastType.error,
      );
    }
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

            // Input Nominal Setoran
            AppTextField(
              label: 'Nominal Setoran (Rp)',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              controller: _amountController,
            ),
            const SizedBox(height: 14),

            // Input Tanggal Setoran (Default: Tanggal Berjalan)
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.accent,
                          onPrimary: AppColors.bgDeep,
                          surface: AppColors.bgCard,
                          onSurface: AppColors.textPrimary,
                        ),
                        dialogBackgroundColor: AppColors.bgCard,
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _dateController.text = formatDateFull(picked);
                  });
                }
              },
              child: AbsorbPointer(
                child: AppTextField(
                  label: 'Tanggal Setoran',
                  icon: Icons.calendar_today_rounded,
                  controller: _dateController,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Input Catatan Setoran
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
