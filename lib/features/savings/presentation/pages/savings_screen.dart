import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/database/database_helper.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/core/widgets/animated_background.dart';
import 'package:money_manajemen/core/widgets/app_skeleton.dart';
import 'package:money_manajemen/core/widgets/dynamic_island_toast.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/datasources/savings_remote_data_source.dart';
import 'package:money_manajemen/data/models/savings_goal_model.dart';
import 'package:money_manajemen/features/profile/presentation/widgets/profile_header_bar.dart';
import '../widgets/add_savings_goal_sheet.dart';
import '../widgets/savings_goal_detail_sheet.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  String _activeTab = 'Semua';
  bool _isLoading = false;

  final List<Data> _goals = [];

  Animation<double> _fadeFor(double start, double end) => CurvedAnimation(
        parent: _entrance,
        curve: Interval(start, end, curve: Curves.easeOut),
      );

  Animation<Offset> _slideFor(double start, double end) => Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entrance,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    if (_goals.isEmpty) {
      setState(() => _isLoading = true);
    }

    final dataSource = SavingsRemoteDataSourceImpl(
      client: http.Client(),
      localDataSource: AuthLocalDataSourceImpl(),
    );

    // 1. Instantly load & render cached data from local SQLite
    final localGoals = await dataSource.getLocalSavingGoals();
    if (mounted && localGoals.isNotEmpty) {
      setState(() {
        _goals.clear();
        _goals.addAll(localGoals);
        _isLoading = false;
      });
    }

    // 2. Fetch fresh data from Web API server & auto-replace SQLite database
    final remoteGoals = await dataSource.getSavingGoals();
    if (mounted) {
      setState(() {
        _goals.clear();
        _goals.addAll(remoteGoals);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  List<Data> get _filteredGoals {
    if (_activeTab == 'Berjalan') {
      return _goals.where((g) => g.progressPercentage < 1.0 && g.status != 'completed').toList();
    } else if (_activeTab == 'Selesai') {
      return _goals.where((g) => g.progressPercentage >= 1.0 || g.status == 'completed').toList();
    }
    return _goals;
  }

  int get _totalCurrentSavings => _goals.fold(0, (sum, g) => sum + g.currentAmount);
  int get _totalTargetSavings => _goals.fold(0, (sum, g) => sum + g.targetAmount);
  double get _overallProgress =>
      _totalTargetSavings > 0 ? (_totalCurrentSavings / _totalTargetSavings) : 0.0;

  void _openAddOrEditSheet({Data? goalToEdit}) async {
    final result = await AddSavingsGoalSheet.show(context, goalToEdit: goalToEdit);
    FocusManager.instance.primaryFocus?.unfocus();
    if (result != null) {
      setState(() {
        if (goalToEdit != null) {
          final index = _goals.indexWhere((g) => g.id == goalToEdit.id);
          if (index != -1) _goals[index] = result;
        } else {
          _goals.insert(0, result);
        }
      });

      await DatabaseHelper.instance.replaceSavingGoals(_goals);
      _fetchGoals();

      if (mounted) {
        DynamicIslandToast.show(
          context,
          title: goalToEdit != null ? 'Target Diperbarui' : 'Target Dibuat 🎉',
          message: 'Target tabungan "${result.name}" berhasil disimpan',
          type: DynamicToastType.success,
        );
      }
    }
  }

  void _openContributionSheet(Data goal) async {
    await SavingsGoalDetailSheet.show(
      context,
      goal: goal,
    );
    FocusManager.instance.primaryFocus?.unfocus();

    // 🔄 Always sync goals list & replace local SQLite table with fresh server data live
    if (mounted) {
      _fetchGoals();
    }
  }

  void _deleteGoal(Data goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Target Tabungan?',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus target "${goal.name}"? Data yang dihapus tidak dapat dikembalikan.',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final dataSource = SavingsRemoteDataSourceImpl(
                client: http.Client(),
                localDataSource: AuthLocalDataSourceImpl(),
              );
              await dataSource.deleteSavingGoal(goal.id);
              await dataSource.getSavingGoals();
              if (mounted) {
                _fetchGoals();
                DynamicIslandToast.show(
                  context,
                  title: 'Target Dihapus',
                  message: 'Target tabungan telah dihapus',
                  type: DynamicToastType.success,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGoals;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header Navigation Bar
              FadeTransition(
                opacity: _fadeFor(0.0, 0.3),
                child: const ProfileHeaderBar(title: 'Target Tabungan'),
              ),

              // Scrollable Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchGoals,
                  color: AppColors.accent,
                  backgroundColor: AppColors.bgCard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Overall Savings Summary Banner
                      FadeTransition(
                        opacity: _fadeFor(0.1, 0.4),
                        child: SlideTransition(
                          position: _slideFor(0.1, 0.4),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.2),
                                  AppColors.bgCard,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.savings_rounded,
                                            color: AppColors.accent,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Tabungan Terkumpul',
                                              style: TextStyle(
                                                fontFamily: AppTextStyles.fontFamily,
                                                fontSize: 11.5,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              formatRupiah(_totalCurrentSavings),
                                              style: const TextStyle(
                                                fontFamily: AppTextStyles.fontFamily,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.accent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Add Goal Action Button
                                    GestureDetector(
                                      onTap: () => _openAddOrEditSheet(),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.accent.withValues(alpha: 0.4),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.add_rounded,
                                          color: AppColors.bgDeep,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),
                                const Divider(color: AppColors.cardBorder, height: 1),
                                const SizedBox(height: 14),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Target: ${formatRupiah(_totalTargetSavings)}',
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${(_overallProgress * 100).toStringAsFixed(0)}% Tercapai',
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Progress Indicator Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: _overallProgress.clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: AppColors.bgDeep,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Filter Tabs Row
                      FadeTransition(
                        opacity: _fadeFor(0.2, 0.5),
                        child: Row(
                          children: ['Semua', 'Berjalan', 'Selesai'].map((tab) {
                            final isSelected = tab == _activeTab;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () => setState(() => _activeTab = tab),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.accent : AppColors.bgCard.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? AppColors.accent : AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    tab,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? AppColors.bgDeep : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Saving Goals List
                      if (_isLoading)
                        _buildSavingsSkeletonList()
                      else if (filtered.isEmpty)
                        FadeTransition(
                          opacity: _fadeFor(0.3, 0.6),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accent.withValues(alpha: 0.12),
                                  ),
                                  child: const Icon(
                                    Icons.savings_outlined,
                                    size: 30,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Belum Ada Target Tabungan',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Mulai rencanakan keuangan Anda dengan membuat target tabungan baru!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => _openAddOrEditSheet(),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Buat Target Tabungan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: AppColors.bgDeep,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final goal = filtered[index];
                            final isDone = goal.progressPercentage >= 1.0 || goal.status == 'completed';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDone
                                      ? AppColors.success.withValues(alpha: 0.4)
                                      : AppColors.cardBorder,
                                  width: isDone ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title & Actions Row
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? AppColors.success.withValues(alpha: 0.15)
                                              : AppColors.accent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          isDone ? Icons.check_circle_rounded : Icons.flag_rounded,
                                          color: isDone ? AppColors.success : AppColors.accent,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              goal.name,
                                              style: const TextStyle(
                                                fontFamily: AppTextStyles.fontFamily,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            if (goal.description.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                goal.description,
                                                style: const TextStyle(
                                                  fontFamily: AppTextStyles.fontFamily,
                                                  fontSize: 11.5,
                                                  color: AppColors.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Popup Menu Options (Edit / Delete)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded,
                                            color: AppColors.textSecondary, size: 20),
                                        color: AppColors.bgCard,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          side: const BorderSide(color: AppColors.cardBorder),
                                        ),
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _openAddOrEditSheet(goalToEdit: goal);
                                          } else if (val == 'delete') {
                                            _deleteGoal(goal);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_outlined,
                                                    size: 18, color: AppColors.textPrimary),
                                                SizedBox(width: 8),
                                                Text('Edit Target',
                                                    style: TextStyle(color: AppColors.textPrimary)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded,
                                                    size: 18, color: AppColors.error),
                                                SizedBox(width: 8),
                                                Text('Hapus',
                                                    style: TextStyle(color: AppColors.error)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Nominal Status Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Terkumpul',
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              fontSize: 10.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            formatRupiah(goal.currentAmount),
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              fontSize: 14,
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
                                            'Target Nominal',
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              fontSize: 10.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            formatRupiah(goal.targetAmount),
                                            style: const TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
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
                                      value: goal.progressPercentage.clamp(0.0, 1.0),
                                      minHeight: 7,
                                      backgroundColor: AppColors.bgDeep,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDone ? AppColors.success : AppColors.accent,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Bottom Controls: Deposit Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? AppColors.success.withValues(alpha: 0.15)
                                              : AppColors.accent.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isDone
                                              ? '🎉 Target Selesai!'
                                              : '${(goal.progressPercentage * 100).toStringAsFixed(0)}% Selesai',
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isDone ? AppColors.success : AppColors.accent,
                                          ),
                                        ),
                                      ),
                                      if (!isDone)
                                        GestureDetector(
                                          onTap: () => _openContributionSheet(goal),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.accent.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                  color: AppColors.accent.withValues(alpha: 0.4)),
                                            ),
                                            child: Row(
                                              children: const [
                                                Icon(Icons.add_rounded,
                                                    size: 16, color: AppColors.accent),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Setor Tabungan',
                                                  style: TextStyle(
                                                    fontFamily: AppTextStyles.fontFamily,
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.accent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildSavingsSkeletonList() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppSkeleton(width: 42, height: 42, borderRadius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AppSkeleton(width: 160, height: 16),
                        SizedBox(height: 6),
                        AppSkeleton(width: 200, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton(width: 60, height: 10),
                      SizedBox(height: 4),
                      AppSkeleton(width: 100, height: 16),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppSkeleton(width: 80, height: 10),
                      SizedBox(height: 4),
                      AppSkeleton(width: 100, height: 16),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const AppSkeleton(width: double.infinity, height: 8, borderRadius: 4),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  AppSkeleton(width: 80, height: 22, borderRadius: 8),
                  AppSkeleton(width: 120, height: 32, borderRadius: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
