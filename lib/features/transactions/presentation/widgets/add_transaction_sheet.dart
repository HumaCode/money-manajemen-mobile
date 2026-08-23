import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/core/database/database_helper.dart';
import 'package:money_manajemen/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/features/transactions/data/datasources/master_remote_data_source.dart';
import 'package:money_manajemen/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:money_manajemen/features/transactions/data/models/category_model.dart';
import 'package:money_manajemen/features/transactions/data/models/account_model.dart';
import 'package:money_manajemen/features/transactions/data/models/transaction_model.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionModel? transactionToEdit;
  final String? initialTitle;
  final int? initialAmount;
  final String? initialCategory;

  const AddTransactionSheet({
    super.key,
    this.transactionToEdit,
    this.initialTitle,
    this.initialAmount,
    this.initialCategory,
  });

  static Future<TransactionModel?> show(
    BuildContext context, {
    TransactionModel? transactionToEdit,
    String? initialTitle,
    int? initialAmount,
    String? initialCategory,
  }) {
    return showModalBottomSheet<TransactionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        transactionToEdit: transactionToEdit,
        initialTitle: initialTitle,
        initialAmount: initialAmount,
        initialCategory: initialCategory,
      ),
    );
  }

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  TransactionType _selectedType = TransactionType.expense;
  
  List<CategoryModel> _allCategories = [];
  List<AccountModel> _allAccounts = [];
  bool _isLoadingMaster = true;
  bool _isSubmitting = false;

  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount; // For Income / Expense
  AccountModel? _fromAccount;     // For Transfer
  AccountModel? _toAccount;       // For Transfer

  @override
  void initState() {
    super.initState();
    final editItem = widget.transactionToEdit;
    _titleController = TextEditingController(text: editItem?.title ?? widget.initialTitle ?? '');
    final rawAmt = editItem != null
        ? editItem.amount.abs()
        : (widget.initialAmount != null && widget.initialAmount! > 0
            ? widget.initialAmount
            : null);
    _amountController = TextEditingController(
      text: rawAmt != null ? ThousandsSeparatorInputFormatter.formatNumberWithDots(rawAmt.toString()) : '',
    );
    if (editItem != null) {
      _selectedType = editItem.type;
    }
    _fetchMasterData();
  }

  void _applyDefaultSelections() {
    final filteredCats = _filteredCategories;
    if (filteredCats.isNotEmpty && (_selectedCategory == null || !filteredCats.contains(_selectedCategory))) {
      if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
        final match = filteredCats.firstWhere(
          (c) => c.name.toLowerCase().contains(widget.initialCategory!.toLowerCase()) ||
                 widget.initialCategory!.toLowerCase().contains(c.name.toLowerCase()),
          orElse: () => filteredCats.first,
        );
        _selectedCategory = match;
      } else {
        _selectedCategory = filteredCats.first;
      }
    }
    if (_allAccounts.isNotEmpty) {
      if (_selectedAccount == null || !_allAccounts.contains(_selectedAccount)) {
        _selectedAccount = _allAccounts.first;
      }
      if (_fromAccount == null || !_allAccounts.contains(_fromAccount)) {
        _fromAccount = _allAccounts.first;
      }
      if (_toAccount == null || !_allAccounts.contains(_toAccount)) {
        _toAccount = _allAccounts.length > 1 ? _allAccounts[1] : _allAccounts.first;
      }
    }
  }

  Future<void> _fetchMasterData() async {
    final masterDS = MasterRemoteDataSourceImpl(
      client: http.Client(),
      localDataSource: AuthLocalDataSourceImpl(),
    );

    // 1. Instant load from local cache (0ms wait)
    final cachedCats = await masterDS.getCachedCategories();
    final cachedAccs = await masterDS.getCachedAccounts();

    if ((cachedCats.isNotEmpty || cachedAccs.isNotEmpty) && mounted) {
      setState(() {
        _allCategories = cachedCats;
        _allAccounts = cachedAccs;
        _isLoadingMaster = false;
        _applyDefaultSelections();
      });
    }

    // 2. Silent background revalidation from database/API
    try {
      final results = await Future.wait([
        masterDS.getCategories(),
        masterDS.getAccounts(),
      ]);

      if (mounted) {
        setState(() {
          _allCategories = results[0] as List<CategoryModel>;
          _allAccounts = results[1] as List<AccountModel>;
          _isLoadingMaster = false;
          _applyDefaultSelections();
        });
      }
    } catch (_) {
      if (mounted && _allCategories.isEmpty) {
        setState(() => _isLoadingMaster = false);
      }
    }
  }

  List<CategoryModel> get _filteredCategories {
    if (_selectedType == TransactionType.expense) {
      return _allCategories.where((c) => c.type.toLowerCase() == 'expense').toList();
    } else if (_selectedType == TransactionType.income) {
      return _allCategories.where((c) => c.type.toLowerCase() == 'income').toList();
    }
    return [];
  }

  void _onTypeChanged(TransactionType newType) {
    setState(() {
      _selectedType = newType;
      final filteredCats = _filteredCategories;
      if (filteredCats.isNotEmpty) {
        _selectedCategory = filteredCats.first;
      } else {
        _selectedCategory = null;
      }
    });
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Harap masukkan judul transaksi');
      return;
    }
    final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final amount = int.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      _showSnackBar('Nominal transaksi tidak boleh kosong');
      return;
    }

    if (_selectedType != TransactionType.transfer && _selectedAccount == null) {
      _showSnackBar('Harap pilih akun/rekening');
      return;
    }

    if (_selectedType != TransactionType.transfer && _selectedCategory == null) {
      _showSnackBar('Harap pilih kategori transaksi');
      return;
    }

    if (_selectedType == TransactionType.transfer) {
      if (_fromAccount == null || _toAccount == null) {
        _showSnackBar('Harap pilih akun asal dan akun tujuan');
        return;
      }
      if (_fromAccount!.id == _toAccount!.id) {
        _showSnackBar('Akun asal dan akun tujuan tidak boleh sama');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    String typeString = 'expense';
    if (_selectedType == TransactionType.income) typeString = 'income';
    if (_selectedType == TransactionType.transfer) typeString = 'transfer';

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final payload = <String, dynamic>{
      'description': _titleController.text.trim(),
      'title': _titleController.text.trim(),
      'amount': amount,
      'type': typeString,
      'transaction_date': dateStr,
    };

    if (_selectedType == TransactionType.transfer) {
      payload['account_id'] = _fromAccount?.id;
      payload['to_account_id'] = _toAccount?.id;
    } else {
      payload['account_id'] = _selectedAccount?.id;
      if (_selectedCategory != null) {
        payload['category_id'] = _selectedCategory?.id;
      }
    }

    try {
      final masterDS = MasterRemoteDataSourceImpl(
        client: http.Client(),
        localDataSource: AuthLocalDataSourceImpl(),
      );
      
      if (widget.transactionToEdit != null) {
        await masterDS.updateTransaction(widget.transactionToEdit!.id, payload);
      } else {
        await masterDS.createTransaction(payload);
      }

      final isEdit = widget.transactionToEdit != null;
      await DatabaseHelper.instance.addActivity(
        title: isEdit ? 'Edit Transaksi' : 'Transaksi Baru',
        message: isEdit
            ? 'Transaksi "${_titleController.text.trim()}" sebesar ${formatRupiah(amount)} berhasil diperbarui.'
            : 'Transaksi "${_titleController.text.trim()}" sebesar ${formatRupiah(amount)} berhasil ditambahkan.',
        iconType: 'transaction',
        colorHex: _selectedType == TransactionType.income ? '#34d399' : '#f87171',
      );

      // Re-sync SQFlite database with latest data from server (transactions & account balances)
      try {
        final txRemoteDS = TransactionRemoteDataSourceImpl(
          client: http.Client(),
          localDataSource: AuthLocalDataSourceImpl(),
        );
        await Future.wait([
          txRemoteDS.getTransactions(),
          masterDS.getAccounts(),
        ]);
      } catch (_) {}

      if (!mounted) return;
      final resultTx = TransactionModel(
        id: widget.transactionToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        category: _selectedType == TransactionType.transfer
            ? 'Transfer'
            : (_selectedCategory?.name ?? 'Umum'),
        amount: _selectedType == TransactionType.expense ? -amount : amount,
        type: _selectedType,
        date: widget.transactionToEdit?.date ?? DateTime.now(),
        icon: _selectedType == TransactionType.transfer
            ? Icons.swap_horiz_rounded
            : (_selectedType == TransactionType.income ? Icons.work_rounded : Icons.restaurant_rounded),
        color: _selectedType == TransactionType.transfer
            ? AppColors.info
            : (_selectedType == TransactionType.income ? AppColors.success : AppColors.warning),
      );

      Navigator.of(context).pop(resultTx);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showSnackBar(String text) {
    DynamicIslandToast.show(
      context,
      message: text,
      type: DynamicToastType.error,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.transactionToEdit != null ? 'Edit Transaksi' : 'Tambah Transaksi',
                  style: const TextStyle(
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
            const SizedBox(height: 16),

            // Tipe Selector Chips
            Row(
              children: [
                _TypeChip(
                  label: 'Pengeluaran',
                  isSelected: _selectedType == TransactionType.expense,
                  color: AppColors.error,
                  onTap: () => _onTypeChanged(TransactionType.expense),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Pemasukan',
                  isSelected: _selectedType == TransactionType.income,
                  color: AppColors.success,
                  onTap: () => _onTypeChanged(TransactionType.income),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Transfer',
                  isSelected: _selectedType == TransactionType.transfer,
                  color: AppColors.info,
                  onTap: () => _onTypeChanged(TransactionType.transfer),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form Fields
            AppTextField(
              controller: _titleController,
              label: 'Judul Transaksi',
              icon: Icons.edit_note_rounded,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _amountController,
              label: 'Nominal (Rp)',
              icon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
            ),
            const SizedBox(height: 20),

            // Akun Selector Section
            if (_selectedType == TransactionType.transfer) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildAccountDropdown(
                      label: 'Dari Akun',
                      selected: _fromAccount,
                      onChanged: (acc) => setState(() => _fromAccount = acc),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAccountDropdown(
                      label: 'Ke Akun',
                      selected: _toAccount,
                      onChanged: (acc) => setState(() => _toAccount = acc),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ] else ...[
              _buildAccountDropdown(
                label: 'Pilih Akun / Rekening',
                selected: _selectedAccount,
                onChanged: (acc) => setState(() => _selectedAccount = acc),
              ),
              const SizedBox(height: 20),
            ],

            // Kategori Section (Sembunyi jika Transfer)
            if (_selectedType != TransactionType.transfer) ...[
              const Text(
                'Kategori',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              if (_isLoadingMaster)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                  ),
                )
              else if (categories.isEmpty)
                const Text(
                  'Tidak ada kategori tersedia',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final isSelected = cat.id == _selectedCategory?.id;
                    return ChoiceChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      selectedColor: AppColors.accent.withValues(alpha: 0.2),
                      backgroundColor: AppColors.bgDeep,
                      labelStyle: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: isSelected ? AppColors.accent : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.accent : AppColors.cardBorder,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
            ],

            PrimaryButton(
              label: _isSubmitting
                  ? 'Menyimpan...'
                  : (widget.transactionToEdit != null ? 'Simpan Perubahan' : 'Simpan Transaksi'),
              onPressed: _isSubmitting ? () {} : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDropdown({
    required String label,
    required AccountModel? selected,
    required ValueChanged<AccountModel?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.bgDeep,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AccountModel>(
              value: selected,
              isExpanded: true,
              dropdownColor: AppColors.bgCard,
              hint: const Text('Pilih Akun', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              items: _allAccounts.map((acc) {
                return DropdownMenuItem<AccountModel>(
                  value: acc,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        acc.name.isNotEmpty ? acc.name : 'Akun ${acc.id}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        formatRupiah(acc.balance),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.bgDeep,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
