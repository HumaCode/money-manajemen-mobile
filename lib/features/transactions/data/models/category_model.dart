class CategoryModel {
  final String id;
  final String name;
  final String type; // 'expense' or 'income'
  final String icon;
  final String color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['category_name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'expense',
      icon: json['icon']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
    };
  }
}
