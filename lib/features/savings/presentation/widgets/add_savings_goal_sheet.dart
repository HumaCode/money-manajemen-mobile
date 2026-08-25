import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/core/database/database_helper.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/datasources/master_remote_data_source.dart';
import 'package:money_manajemen/data/datasources/savings_remote_data_source.dart';
import 'package:money_manajemen/data/models/account_model.dart';
import 'package:money_manajemen/data/models/savings_goal_model.dart';

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

  List<AccountModel> _accounts = [];
  AccountModel? _selectedAccount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.goalToEdit != null) {
      _titleController.text = widget.goalToEdit!.name;
      _targetAmountController.text = widget.goalToEdit!.targetAmount.toString();
      _currentAmountController.text = widget.goalToEdit!.currentAmount.toString();
      _notesController.text = widget.goalToEdit!.description;
    }
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final cached = await DatabaseHelper.instance.getAccounts();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _accounts = cached;
        _selectedAccount = cached.first;
      });
    }

    try {
      final masterDS = MasterRemoteDataSourceImpl(
        client: http.Client(),
        localDataSource: AuthLocalDataSourceImpl(),
      );
      final remoteAccs = await masterDS.getAccounts();
      if (remoteAccs.isNotEmpty && mounted) {
        setState(() {
          _accounts = remoteAccs;
          _selectedAccount = remoteAccs.firstWhere(
            (a) => a.id == widget.goalToEdit?.accountId,
            orElse: () => remoteAccs.first,
          );
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    _titleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
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

    setState(() => _isLoading = true);

    final targetAmount = parseAmountString(targetStr);
    final currentAmount = parseAmountString(_currentAmountController.text);

    final dataSource = SavingsRemoteDataSourceImpl(
      client: http.Client(),
      localDataSource: AuthLocalDataSourceImpl(),
    );

    Data? resultGoal;
    String errorMessage = 'Gagal menyimpan target tabungan ke server database';

    try {
      if (widget.goalToEdit != null) {
        resultGoal = await dataSource.updateSavingGoal(
          widget.goalToEdit!.id,
          name: title,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          description: _notesController.text.trim(),
        );
      } else {
        final profileCurrencyId = await AuthLocalDataSourceImpl().getSelectedCurrencyId();
        final currencyIdToUse = (profileCurrencyId != null && profileCurrencyId.isNotEmpty)
            ? profileCurrencyId
            : null;

        resultGoal = await dataSource.createSavingGoal(
          name: title,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          description: _notesController.text.trim(),
          accountId: _selectedAccount?.id,
          currencyId: currencyIdToUse,
        );
      }
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultGoal != null) {
      Navigator.of(context).pop(resultGoal);
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

            if (_accounts.isNotEmpty) ...[
              _buildAccountDropdown(),
              const SizedBox(height: 14),
            ],

            AppTextField(
              label: 'Target Nominal (Rp)',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              controller: _targetAmountController,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Saldo Awal Tabungan (Rp opsional)',
              icon: Icons.account_balance_wallet_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
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

  Widget _buildAccountDropdown() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                const Text(
                  'Pilih Akun / Rekening Sumber',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<AccountModel>(
                    value: _selectedAccount,
                    isExpanded: true,
                    dropdownColor: AppColors.bgCard,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    hint: const Text(
                      'Pilih Akun Sumber',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    items: _accounts.map((acc) {
                      return DropdownMenuItem<AccountModel>(
                        value: acc,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              acc.name.isNotEmpty ? acc.name : 'Akun ${acc.id}',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              formatRupiah(acc.balance),
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (acc) => setState(() => _selectedAccount = acc),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
