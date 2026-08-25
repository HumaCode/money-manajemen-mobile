import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/features/auth/data/datasources/auth_local_data_source.dart';
import '../../data/models/budget_model.dart';
import '../../data/datasources/budget_remote_data_source.dart';

class AddBudgetSheet extends StatefulWidget {
  final BudgetModel? budgetToEdit;

  const AddBudgetSheet({super.key, this.budgetToEdit});

  static Future<BudgetModel?> show(
    BuildContext context, {
    BudgetModel? budgetToEdit,
  }) {
    return showModalBottomSheet<BudgetModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBudgetSheet(budgetToEdit: budgetToEdit),
    );
  }

  @override
  State<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<AddBudgetSheet> {
  final _nameController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPeriod = 'monthly';
  bool _rolloverUnused = false;
  bool _isLoading = false;

  final List<Map<String, String>> _periods = [
    {'id': 'weekly', 'name': 'Mingguan (Weekly)'},
    {'id': 'monthly', 'name': 'Bulanan (Monthly)'},
    {'id': 'quarterly', 'name': 'Triwulan (Quarterly)'},
    {'id': 'yearly', 'name': 'Tahunan (Yearly)'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.budgetToEdit != null) {
      _nameController.text = widget.budgetToEdit!.name;
      _totalAmountController.text = ThousandsSeparatorInputFormatter.formatNumberWithDots(widget.budgetToEdit!.totalAmount.toString());
      _selectedPeriod = widget.budgetToEdit!.period.isNotEmpty ? widget.budgetToEdit!.period : 'monthly';
      _rolloverUnused = widget.budgetToEdit!.rolloverUnused;
      _notesController.text = widget.budgetToEdit!.notes;
    }
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    _nameController.dispose();
    _totalAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final amountStr = _totalAmountController.text.trim();

    if (name.isEmpty) {
      DynamicIslandToast.show(
        context,
        title: 'Nama Anggaran',
        message: 'Masukkan nama anggaran terlebih dahulu',
        type: DynamicToastType.warning,
      );
      return;
    }

    final amount = int.tryParse(amountStr.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      DynamicIslandToast.show(
        context,
        title: 'Total Anggaran',
        message: 'Masukkan nominal anggaran yang valid',
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

      BudgetModel? result;

      if (widget.budgetToEdit != null) {
        result = await remoteDS.updateBudget(
          widget.budgetToEdit!.id,
          name: name,
          currencyId: widget.budgetToEdit!.currencyId.isNotEmpty
              ? widget.budgetToEdit!.currencyId
              : '9b1deb4d-3b7d-418d-9a80-123456789abc',
          totalAmount: amount,
          period: _selectedPeriod,
          rolloverUnused: _rolloverUnused,
          notes: _notesController.text.trim(),
        );
      } else {
        result = await remoteDS.createBudget(
          name: name,
          currencyId: '9b1deb4d-3b7d-418d-9a80-123456789abc',
          totalAmount: amount,
          period: _selectedPeriod,
          rolloverUnused: _rolloverUnused,
          notes: _notesController.text.trim(),
        );
      }

      if (mounted) {
        if (result != null) {
          DynamicIslandToast.show(
            context,
            title: widget.budgetToEdit != null ? 'Berhasil Diperbarui' : 'Berhasil Dibuat',
            message: 'Anggaran $name telah disimpan',
            type: DynamicToastType.success,
          );
          Navigator.of(context).pop(result);
        } else {
          DynamicIslandToast.show(
            context,
            title: 'Gagal Menyimpan',
            message: 'Periksa koneksi atau inputan Anda',
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
    final isEdit = widget.budgetToEdit != null;

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
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      Icons.calendar_view_week_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Anggaran' : 'Tambah Anggaran Baru',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEdit ? 'Perbarui batas pengeluaran Anda' : 'Tetapkan plafon batas pengeluaran',
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
              AppTextField(
                controller: _totalAmountController,
                label: 'Total Batas Anggaran (Rp)',
                hintText: 'Misal: 2.000.000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_outlined,
                inputFormatters: [
                  ThousandsSeparatorInputFormatter(),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _nameController,
                label: 'Nama Anggaran',
                hintText: 'Misal: Makan Bulanan, Bensin, Hiburan',
                prefixIcon: Icons.label_outline_rounded,
              ),
              const SizedBox(height: 16),

              // Period Dropdown
              const Text(
                'Periode Anggaran',
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
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    dropdownColor: AppColors.bgCard,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    items: _periods.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text(p['name']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPeriod = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Rollover Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.autorenew_rounded, color: AppColors.accent, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rollover Sisa Anggaran',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Pindahkan sisa anggaran ke periode berikutnya',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _rolloverUnused,
                      activeColor: AppColors.accent,
                      onChanged: (val) => setState(() => _rolloverUnused = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              AppTextField(
                controller: _notesController,
                label: 'Catatan Opsional',
                hintText: 'Misal: Batas pengeluaran makan per hari Rp 65.000',
                prefixIcon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: isEdit ? 'Simpan Perubahan' : 'Buat Anggaran',
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
