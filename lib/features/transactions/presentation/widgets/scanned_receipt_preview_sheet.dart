import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/features/transactions/data/datasources/master_remote_data_source.dart';
import 'package:money_manajemen/features/transactions/data/models/account_model.dart';
import 'package:money_manajemen/features/transactions/data/models/category_model.dart';
import 'package:money_manajemen/features/transactions/data/services/receipt_scanner_service.dart';
import 'package:money_manajemen/core/utils/formatters.dart';

class ScannedReceiptSubmitResult {
  final List<ReceiptItem> selectedItems;
  final AccountModel account;
  final CategoryModel category;
  final int totalAmount;

  ScannedReceiptSubmitResult({
    required this.selectedItems,
    required this.account,
    required this.category,
    required this.totalAmount,
  });
}

class ScannedReceiptPreviewSheet extends StatefulWidget {
  final ScannedReceiptResult receipt;

  const ScannedReceiptPreviewSheet({
    super.key,
    required this.receipt,
  });

  static Future<ScannedReceiptSubmitResult?> show(
    BuildContext context,
    ScannedReceiptResult receipt,
  ) {
    return showModalBottomSheet<ScannedReceiptSubmitResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScannedReceiptPreviewSheet(receipt: receipt),
    );
  }

  @override
  State<ScannedReceiptPreviewSheet> createState() => _ScannedReceiptPreviewSheetState();
}

class _ScannedReceiptPreviewSheetState extends State<ScannedReceiptPreviewSheet> {
  late Set<int> _selectedIndices;

  List<CategoryModel> _allCategories = [];
  List<AccountModel> _allAccounts = [];
  bool _isLoadingMaster = true;

  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  bool _isDiscountExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedIndices = Set.from(Iterable.generate(widget.receipt.items.length));
    _fetchMasterData();
  }

  Future<void> _fetchMasterData() async {
    final masterDS = MasterRemoteDataSourceImpl(
      client: http.Client(),
      localDataSource: AuthLocalDataSourceImpl(),
    );

    // 1. Cached load
    final cachedCats = await masterDS.getCachedCategories();
    final cachedAccs = await masterDS.getCachedAccounts();

    if ((cachedCats.isNotEmpty || cachedAccs.isNotEmpty) && mounted) {
      setState(() {
        _allCategories = cachedCats.where((c) => c.type == 'expense').toList();
        _allAccounts = cachedAccs;
        _isLoadingMaster = false;
        _applyDefaults();
      });
    }

    // 2. Fresh load
    try {
      final results = await Future.wait([
        masterDS.getCategories(),
        masterDS.getAccounts(),
      ]);

      if (mounted) {
        final cats = (results[0] as List<CategoryModel>).where((c) => c.type == 'expense').toList();
        final accs = results[1] as List<AccountModel>;
        setState(() {
          _allCategories = cats;
          _allAccounts = accs;
          _isLoadingMaster = false;
          _applyDefaults();
        });
      }
    } catch (_) {
      if (mounted && _allCategories.isEmpty) {
        setState(() => _isLoadingMaster = false);
      }
    }
  }

  void _applyDefaults() {
    if (_allCategories.isNotEmpty) {
      if (_selectedCategory == null || !_allCategories.any((c) => c.id == _selectedCategory!.id)) {
        final match = _allCategories.firstWhere(
          (c) => c.name.toLowerCase().contains(widget.receipt.category.toLowerCase()) ||
                 widget.receipt.category.toLowerCase().contains(c.name.toLowerCase()),
          orElse: () => _allCategories.first,
        );
        _selectedCategory = match;
      } else {
        _selectedCategory = _allCategories.firstWhere((c) => c.id == _selectedCategory!.id);
      }
    }
    if (_allAccounts.isNotEmpty) {
      if (_selectedAccount == null || !_allAccounts.any((a) => a.id == _selectedAccount!.id)) {
        _selectedAccount = _allAccounts.first;
      } else {
        _selectedAccount = _allAccounts.firstWhere((a) => a.id == _selectedAccount!.id);
      }
    }
  }

  int get _calculatedSubtotal {
    if (widget.receipt.items.isEmpty) return widget.receipt.amount;
    int sum = 0;
    for (int i = 0; i < widget.receipt.items.length; i++) {
      if (_selectedIndices.contains(i)) {
        sum += widget.receipt.items[i].totalPrice;
      }
    }
    return sum;
  }

  int get _appliedDiscount {
    if (_selectedIndices.length == widget.receipt.items.length) {
      return widget.receipt.discount;
    } else if (widget.receipt.items.isNotEmpty && _selectedIndices.isNotEmpty) {
      final ratio = _selectedIndices.length / widget.receipt.items.length;
      return (widget.receipt.discount * ratio).round();
    }
    return 0;
  }

  int get _calculatedTotal {
    final netTotal = _calculatedSubtotal - _appliedDiscount;
    return netTotal < 0 ? 0 : netTotal;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final items = widget.receipt.items;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview Struk',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.receipt.title,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Selector Akun & Kategori
          if (_isLoadingMaster)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                // Akun
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Akun / Rekening',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bgCardHover,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<AccountModel>(
                            value: _selectedAccount,
                            isExpanded: true,
                            dropdownColor: AppColors.bgCard,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                            items: _allAccounts.map((acc) {
                              return DropdownMenuItem<AccountModel>(
                                value: acc,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      acc.name,
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
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedAccount = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Kategori
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kategori Transaksi',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bgCardHover,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CategoryModel>(
                            value: _selectedCategory,
                            isExpanded: true,
                            dropdownColor: AppColors.bgCard,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                            items: _allCategories.map((cat) {
                              return DropdownMenuItem<CategoryModel>(
                                value: cat,
                                child: Text(
                                  cat.name,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 8),

          // Subtitle / Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item Terdeteksi (${items.length})',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (items.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedIndices.length == items.length) {
                        _selectedIndices.clear();
                      } else {
                        _selectedIndices = Set.from(Iterable.generate(items.length));
                      }
                    });
                  },
                  child: Text(
                    _selectedIndices.length == items.length ? 'Batal Pilih' : 'Pilih Semua',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // List of items
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada rincian item terpisah.\nTotal transaksi: ${formatRupiah(_calculatedTotal)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = _selectedIndices.contains(index);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIndices.remove(index);
                            } else {
                              _selectedIndices.add(index);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.bgCardHover,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.5)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedIndices.add(index);
                                    } else {
                                      _selectedIndices.remove(index);
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.qty} pcs x ${formatRupiah(item.price)}',
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatRupiah(item.totalPrice),
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 8),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 6),

          // Subtotal & Discount Calculation Details
          if (_appliedDiscount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Harga Jual (Subtotal)',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  formatRupiah(_calculatedSubtotal),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            InkWell(
              onTap: () {
                setState(() {
                  _isDiscountExpanded = !_isDiscountExpanded;
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Diskon / Hemat Struk',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isDiscountExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                      ],
                    ),
                    Text(
                      '- ${formatRupiah(_appliedDiscount)}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isDiscountExpanded) ...[
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: widget.receipt.discounts.isNotEmpty
                      ? widget.receipt.discounts.map((disc) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '• ${disc.name}',
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '- ${formatRupiah(disc.amount)}',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList()
                      : [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '• ${widget.receipt.discountTitle ?? "Potongan / Diskon Struk"}',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                '- ${formatRupiah(_appliedDiscount)}',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                ),
              ),
            ],
            const SizedBox(height: 6),
          ],

          // Total Summary & Submit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total (${_selectedIndices.length} Item)',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    formatRupiah(_calculatedTotal),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: (_selectedIndices.isEmpty || _selectedAccount == null || _selectedCategory == null)
                    ? null
                    : () {
                        final selectedItems = items
                            .asMap()
                            .entries
                            .where((e) => _selectedIndices.contains(e.key))
                            .map((e) => e.value)
                            .toList();

                        Navigator.pop(
                          context,
                          ScannedReceiptSubmitResult(
                            selectedItems: selectedItems,
                            account: _selectedAccount!,
                            category: _selectedCategory!,
                            totalAmount: _calculatedTotal,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Simpan ${_selectedIndices.length} Transaksi',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
