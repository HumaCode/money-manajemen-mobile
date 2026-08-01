class CategoryModel {
  final bool success;
  final String message;
  final List<DataKategori> data;

  CategoryModel({
    required this.success,
    required this.message,
    required this.data,
  });
}

class DataKategori {
  final String id;
  final dynamic userId;
  final dynamic parentId;
  final String name;
  final String slug;
  final String type;
  final String icon;
  final String color;
  final bool isActive;
  final dynamic description;
  final DateTime createdAt;
  final DateTime updatedAt;

  DataKategori({
    required this.id,
    required this.userId,
    required this.parentId,
    required this.name,
    required this.slug,
    required this.type,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });
}
