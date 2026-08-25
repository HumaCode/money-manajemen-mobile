import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/datasources/budget_remote_data_source.dart';
import 'package:money_manajemen/data/datasources/master_remote_data_source.dart';
import 'package:money_manajemen/data/models/budget_model.dart';
import 'package:money_manajemen/data/models/category_model.dart';

class AddBudgetExpenseSheet extends StatefulWidget {
  final BudgetModel budget;

  const AddBudgetExpenseSheet({super.key, required this.budget});

  static Future<bool?> show(
    BuildContext context, {
    required BudgetModel budget,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBudgetExpenseSheet(budget: budget),
    );
  }

  @override
  State<AddBudgetExpenseSheet> createState() => _AddBudgetExpenseSheetState();
}

class _AddBudgetExpenseSheetState extends State<AddBudgetExpenseSheet> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final masterDS = MasterRemoteDataSourceImpl(
        client: http.Client(),
        localDataSource: AuthLocalDataSourceImpl(),
      );
      final categories = await masterDS.getCategories();
      final expenseCategories = categories.where((c) => c.type == 'expense').toList();

      if (mounted) {
        setState(() {
          _categories = expenseCategories.isNotEmpty ? expenseCategories : categories;
          if (_categories.isNotEmpty) {
            _selectedCategory = _categories.first;
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
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    if (_selectedCategory == null) {
      DynamicIslandToast.show(
        context,
        title: 'Kategori Pengeluaran',
        message: 'Pilih kategori pengeluaran terlebih dahulu',
        type: DynamicToastType.warning,
      );
      return;
    }

    final amountStr = _amountController.text.trim();
    final amount = int.tryParse(amountStr.replaceAll('.', '').replaceAll(',', '')) ?? 0;

    if (amount <= 0) {
      DynamicIslandToast.show(
        context,
        title: 'Nominal Pengeluaran',
        message: 'Masukkan nominal pengeluaran yang valid',
        type: DynamicToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final remoteDS = BudgetRemoteDataSourceImpl(
        client: http.Client(),
        localDataSource: AuthLocalDataSourceImpl(),
      );

      final success = await remoteDS.addBudgetExpense(
        widget.budget.id,
        categoryId: _selectedCategory!.id,
        spentAmount: amount,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          DynamicIslandToast.show(
            context,
            title: 'Pengeluaran Dicatat',
            message: 'Pengeluaran berhasil ditambahkan ke ${widget.budget.name}',
            type: DynamicToastType.success,
          );
          Navigator.of(context).pop(true);
        } else {
          DynamicIslandToast.show(
            context,
            title: 'Gagal Menyimpan',
            message: 'Periksa koneksi atau data yang Anda masukkan',
            type: DynamicToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        DynamicIslandToast.show(
          context,
          title: 'Terjadi Kesalahan',
          message: e.toString(),
          type: DynamicToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: AppColors.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catat Pengeluaran Anggaran',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Anggaran: ${widget.budget.name} (${widget.budget.totalAmountFormatted})',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Selector
              const Text(
                'Kategori Pengeluaran',
                style: TextStyle(
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
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CategoryModel>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: AppColors.bgCard,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    items: _categories.map((c) {
                      return DropdownMenuItem<CategoryModel>(
                        value: c,
                        child: Text('${c.icon} ${c.name}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
              AppTextField(
                controller: _amountController,
                label: 'Nominal Pengeluaran (Rp)',
                icon: Icons.payments_outlined,
                hintText: 'Misal: 50.000',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  ThousandsSeparatorInputFormatter(),
                ],
              ),

              const SizedBox(height: 16),
              AppTextField(
                controller: _notesController,
                label: 'Catatan Opsional',
                icon: Icons.notes_rounded,
                hintText: 'Misal: Makan siang bakso paket komplit',
                maxLines: 2,
              ),

              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Catat Pengeluaran',
                isLoading: _isLoading,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
