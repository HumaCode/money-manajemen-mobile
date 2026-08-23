import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/models/savings_contribution_model.dart' hide Data;
import 'add_savings_contribution_sheet.dart';

class SavingsGoalDetailSheet extends StatefulWidget {
  final Data goal;

  const SavingsGoalDetailSheet({super.key, required this.goal});

  static Future<Contribution?> show(
    BuildContext context, {
    required Data goal,
  }) {
    return showModalBottomSheet<Contribution>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavingsGoalDetailSheet(goal: goal),
    );
  }

  @override
  State<SavingsGoalDetailSheet> createState() => _SavingsGoalDetailSheetState();
}

class _SavingsGoalDetailSheetState extends State<SavingsGoalDetailSheet> {
  late Data _currentGoal;

  // Mock initial contribution history list for rich demonstration
  late List<Contribution> _history;

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.goal;

    final now = DateTime.now();
    _history = [
      Contribution(
        id: 'c1',
        savingsGoalId: widget.goal.id,
        amount: '5000000',
        notes: 'Setoran Awal Tabungan',
        contributedAt: now.subtract(const Duration(days: 45)),
        savingsGoal: _buildSavingsGoalObj(),
      ),
      Contribution(
        id: 'c2',
        savingsGoalId: widget.goal.id,
        amount: '6500000',
        notes: 'Alokasi Gaji Bulanan',
        contributedAt: now.subtract(const Duration(days: 20)),
        savingsGoal: _buildSavingsGoalObj(),
      ),
      Contribution(
        id: 'c3',
        savingsGoalId: widget.goal.id,
        amount: '5000000',
        notes: 'Bonus Projek Sampingan',
        contributedAt: now.subtract(const Duration(days: 5)),
        savingsGoal: _buildSavingsGoalObj(),
      ),
    ];
  }

  SavingsGoal _buildSavingsGoalObj() {
    return SavingsGoal(
      id: widget.goal.id,
      userId: '',
      accountId: widget.goal.accountId,
      currencyId: widget.goal.currencyId,
      name: widget.goal.name,
      description: widget.goal.description,
      targetAmount: widget.goal.targetAmount.toString(),
      currentAmount: widget.goal.currentAmount.toString(),
      monthlyTarget: widget.goal.monthlyTarget.toString(),
      targetDate: widget.goal.targetDate,
      status: widget.goal.status,
      icon: widget.goal.icon,
      color: widget.goal.color,
      createdAt: widget.goal.createdAt,
      updatedAt: widget.goal.updatedAt,
    );
  }

  void _openAddContribution() async {
    final contribution = await AddSavingsContributionSheet.show(
      context,
      savingsGoalId: _currentGoal.id,
      goalTitle: _currentGoal.name,
    );

    if (contribution != null) {
      final addedAmt = int.tryParse(contribution.amount) ?? 0;
      final newCurrent = _currentGoal.currentAmount + addedAmt;
      final newRemaining = _currentGoal.targetAmount - newCurrent;
      final newPct = _currentGoal.targetAmount > 0 ? (newCurrent / _currentGoal.targetAmount) : 0.0;

      setState(() {
        _history.insert(0, contribution);
        _currentGoal = Data(
          id: _currentGoal.id,
          name: _currentGoal.name,
          description: _currentGoal.description,
          accountId: _currentGoal.accountId,
          accountName: _currentGoal.accountName,
          currencyId: _currentGoal.currencyId,
          currencyCode: _currentGoal.currencyCode,
          currencySymbol: _currentGoal.currencySymbol,
          targetAmount: _currentGoal.targetAmount,
          currentAmount: newCurrent,
          remainingAmount: newRemaining < 0 ? 0 : newRemaining,
          monthlyTarget: _currentGoal.monthlyTarget,
          progressPercentage: newPct > 1.0 ? 1.0 : newPct,
          targetDate: _currentGoal.targetDate,
          status: newPct >= 1.0 ? 'completed' : _currentGoal.status,
          icon: _currentGoal.icon,
          color: _currentGoal.color,
          createdAt: _currentGoal.createdAt,
          updatedAt: DateTime.now(),
        );
      });

      if (mounted) {
        DynamicIslandToast.show(
          context,
          title: 'Setoran Berhasil 💰',
          message: 'Setoran ${formatRupiah(addedAmt)} ditambahkan ke "${_currentGoal.name}"',
          type: DynamicToastType.success,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _currentGoal.progressPercentage >= 1.0 || _currentGoal.status == 'completed';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.5)),
      ),
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

          // Header Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDone ? Icons.check_circle_rounded : Icons.savings_rounded,
                      color: isDone ? AppColors.success : AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentGoal.name,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target Total: ${formatRupiah(_currentGoal.targetAmount)}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary Progress Card Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.12),
                  AppColors.bgDeep,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terkumpul Saat Ini',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatRupiah(_currentGoal.currentAmount),
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDone ? AppColors.success : AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Sisa Kekurangan',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatRupiah(_currentGoal.remainingAmount),
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _currentGoal.progressPercentage.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.bgCard,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? AppColors.success : AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_currentGoal.progressPercentage * 100).toStringAsFixed(0)}% Terkumpul',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDone ? AppColors.success : AppColors.accent,
                      ),
                    ),
                    Text(
                      isDone ? '🎉 Target Tercapai!' : 'Status: Sedang Berjalan',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // History Section Header & Add Contribution Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Setoran (${_history.length})',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!isDone)
                GestureDetector(
                  onTap: _openAddContribution,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.add_rounded, size: 16, color: AppColors.bgDeep),
                        SizedBox(width: 4),
                        Text(
                          'Tambah Setoran',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.bgDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Scrollable Contribution List
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textSecondary),
                        SizedBox(height: 8),
                        Text(
                          'Belum Ada Catatan Setoran',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      final amt = parseAmountString(item.amount);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgDeep.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                color: AppColors.success,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.notes.isNotEmpty ? item.notes : 'Setoran Tabungan',
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatDateFull(item.contributedAt),
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+${formatRupiah(amt)}',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
