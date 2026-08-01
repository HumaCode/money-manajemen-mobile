import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_text_field.dart';
import 'package:money_manajemen/core/widgets/primary_button.dart';
import 'package:money_manajemen/features/transactions/data/models/transaction_model.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  static Future<TransactionModel?> show(BuildContext context) {
    return showModalBottomSheet<TransactionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Food & Dining';

  final Map<String, ({IconData icon, Color color})> _categories = {
    'Food & Dining': (icon: Icons.restaurant_rounded, color: AppColors.warning),
    'Transportation': (icon: Icons.local_gas_station_rounded, color: AppColors.info),
    'Shopping': (icon: Icons.shopping_bag_rounded, color: AppColors.purple),
    'Bills & Utilities': (icon: Icons.flash_on_rounded, color: AppColors.error),
    'Gaji / Income': (icon: Icons.work_rounded, color: AppColors.success),
  };

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) return;
    final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final amount = int.tryParse(amountText) ?? 0;
    if (amount <= 0) return;

    final catInfo = _categories[_selectedCategory] ??
        (icon: Icons.receipt_long_rounded, color: AppColors.accent);

    final newTransaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _selectedCategory,
      amount: _selectedType == TransactionType.expense ? -amount : amount,
      type: _selectedType,
      date: DateTime.now(),
      icon: catInfo.icon,
      color: catInfo.color,
    );

    Navigator.of(context).pop(newTransaction);
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
                const Text(
                  'Tambah Transaksi',
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
            const SizedBox(height: 16),
            // Tipe Selector Chips
            Row(
              children: [
                _TypeChip(
                  label: 'Pengeluaran',
                  isSelected: _selectedType == TransactionType.expense,
                  color: AppColors.error,
                  onTap: () => setState(() => _selectedType = TransactionType.expense),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Pemasukan',
                  isSelected: _selectedType == TransactionType.income,
                  color: AppColors.success,
                  onTap: () => setState(() => _selectedType = TransactionType.income),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Transfer',
                  isSelected: _selectedType == TransactionType.transfer,
                  color: AppColors.info,
                  onTap: () => setState(() => _selectedType = TransactionType.transfer),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Form fields
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.keys.map((cat) {
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
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
            PrimaryButton(
              label: 'Simpan Transaksi',
              onPressed: _submit,
            ),
          ],
        ),
      ),
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
