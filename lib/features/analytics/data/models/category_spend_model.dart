class CategorySpendModel {
  final String name;
  final String emoji;
  final int amount;
  final double percentage; // 0.0 - 1.0

  const CategorySpendModel({
    required this.name,
    required this.emoji,
    required this.amount,
    required this.percentage,
  });
}
