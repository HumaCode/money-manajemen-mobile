import 'package:flutter/material.dart';
import 'package:money_manajemen/app/theme/app_theme.dart';
import 'package:money_manajemen/core/widgets/app_skeleton.dart';

class SummaryCardsSkeleton extends StatelessWidget {
  const SummaryCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppSkeleton(width: 70, height: 12),
                    AppSkeleton(width: 24, height: 24, borderRadius: 6),
                  ],
                ),
                SizedBox(height: 12),
                AppSkeleton(width: 100, height: 20),
                SizedBox(height: 8),
                AppSkeleton(width: 60, height: 10),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppSkeleton(width: 70, height: 12),
                    AppSkeleton(width: 24, height: 24, borderRadius: 6),
                  ],
                ),
                SizedBox(height: 12),
                AppSkeleton(width: 100, height: 20),
                SizedBox(height: 8),
                AppSkeleton(width: 60, height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BarChartSkeleton extends StatelessWidget {
  const BarChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeleton(width: 160, height: 18),
          const SizedBox(height: 6),
          const AppSkeleton(width: 100, height: 12),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (i) {
                final heights = [70.0, 110.0, 50.0, 95.0, 120.0, 85.0];
                return Row(
                  children: [
                    AppSkeleton(width: 8, height: heights[i], borderRadius: 4),
                    const SizedBox(width: 4),
                    AppSkeleton(width: 8, height: heights[i] * 0.6, borderRadius: 4),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartSkeleton extends StatelessWidget {
  const DonutChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeleton(width: 150, height: 18),
          const SizedBox(height: 6),
          const AppSkeleton(width: 80, height: 12),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                flex: 5,
                child: Center(
                  child: AppSkeleton(
                    width: 90,
                    height: 90,
                    borderRadius: 45,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(3, (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: AppSkeleton(width: 90, height: 12),
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryListSkeleton extends StatelessWidget {
  const CategoryListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeleton(width: 140, height: 18),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                AppSkeleton(width: 36, height: 36, borderRadius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton(width: 100, height: 14),
                      SizedBox(height: 6),
                      AppSkeleton(width: 130, height: 8),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                AppSkeleton(width: 60, height: 14),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
