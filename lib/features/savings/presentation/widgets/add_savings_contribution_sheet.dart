import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/datasources/master_remote_data_source.dart';
import 'package:money_manajemen/data/datasources/savings_remote_data_source.dart';
import 'package:money_manajemen/data/models/account_model.dart';
import 'package:money_manajemen/data/models/savings_contribution_model.dart';

class AddSavingsContributionSheet extends StatefulWidget {
  final String savingsGoalId;
  final String goalTitle;
  final String? destinationAccountId;
  final Contribution? contributionToEdit;

  const AddSavingsContributionSheet({
    super.key,
    required this.savingsGoalId,
    required this.goalTitle,
    this.destinationAccountId,
    this.contributionToEdit,
  });

  static Future<Contribution?> show(
    BuildContext context, {
    required String savingsGoalId,
    required String goalTitle,
    String? destinationAccountId,
    Contribution? contributionToEdit,
  }) {
    return showModalBottomSheet<Contribution>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSavingsContributionSheet(
        savingsGoalId: savingsGoalId,
        goalTitle: goalTitle,
        destinationAccountId: destinationAccountId,
        contributionToEdit: contributionToEdit,
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

  List<AccountModel> _sourceAccounts = [];
  AccountModel? _selectedSourceAccount;

  @override
  void initState() {
    super.initState();
    if (widget.contributionToEdit != null) {
      final initialAmt = parseAmountString(widget.contributionToEdit!.amount);
      _amountController.text = ThousandsSeparatorInputFormatter.formatNumberWithDots(initialAmt.toString());
      _notesController.text = widget.contributionToEdit!.notes;
      _selectedDate = widget.contributionToEdit!.contributedAt;
    }
    _dateController = TextEditingController(text: formatDateFull(_selectedDate));
    _loadSourceAccounts();
  }

  Future<void> _loadSourceAccounts() async {
    try {
      final masterDS = MasterRemoteDataSourceImpl(
        client: http.Client(),
        localDataSource: AuthLocalDataSourceImpl(),
      );
      final allAccounts = await masterDS.getAccounts();
      final validSourceAccounts = allAccounts.where((a) => a.id != widget.destinationAccountId).toList();

      if (mounted) {
        setState(() {
          _sourceAccounts = validSourceAccounts;
          if (validSourceAccounts.isNotEmpty) {
            _selectedSourceAccount = validSourceAccounts.first;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
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

    if (_selectedSourceAccount != null && amount > _selectedSourceAccount!.balance) {
      DynamicIslandToast.show(
        context,
        title: 'Saldo Tidak Cukup ⚠️',
        message:
            'Nominal setoran (${formatRupiah(amount)}) melebihi saldo ${_selectedSourceAccount!.name} (${formatRupiah(_selectedSourceAccount!.balance)})',
        type: DynamicToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final dataSource = SavingsRemoteDataSourceImpl(
      client: http.Client(),
      localDataSource: AuthLocalDataSourceImpl(),
    );

    Contribution? remoteContrib;
    String errorMessage = 'Gagal menyimpan setoran tabungan ke server database';

    try {
      if (widget.contributionToEdit != null) {
        remoteContrib = await dataSource.updateSavingContribution(
          widget.savingsGoalId,
          widget.contributionToEdit!.id,
          amount: amount,
          contributedAt: _selectedDate,
          notes: _notesController.text.trim(),
        );
      } else {
        remoteContrib = await dataSource.addSavingContribution(
          widget.savingsGoalId,
          amount: amount,
          contributedAt: _selectedDate,
          notes: _notesController.text.trim(),
          accountId: _selectedSourceAccount?.id,
        );
      }
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (remoteContrib != null) {
      // 🔄 Replace local SQLite database table with fresh server data
      await dataSource.getSavingGoals();
      if (!mounted) return;
      Navigator.of(context).pop(remoteContrib);
    } else {
      DynamicIslandToast.show(
        context,
        title: 'Gagal Menyimpan ❌',
        message: errorMessage,
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
                      Text(
                        widget.contributionToEdit != null ? 'Edit Setoran Tabungan' : 'Setor Tabungan',
                        style: const TextStyle(
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

            // Pilih Rekening Sumber (Hanya saat tambah setoran baru)
            if (widget.contributionToEdit == null && _sourceAccounts.isNotEmpty) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rekening Sumber (Asal Dana)',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AccountModel>(
                        value: _selectedSourceAccount,
                        isExpanded: true,
                        dropdownColor: AppColors.bgCard,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                        items: _sourceAccounts.map((acc) {
                          final balStr = formatRupiah(acc.balance);
                          return DropdownMenuItem<AccountModel>(
                            value: acc,
                            child: Text(
                              '${acc.name} — $balStr',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSourceAccount = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

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
              label: widget.contributionToEdit != null ? 'Simpan Perubahan Setoran' : 'Tambah Setoran Tabungan',
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
