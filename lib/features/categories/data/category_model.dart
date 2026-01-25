import 'package:hive_flutter/adapters.dart';

part 'category_model.g.dart';

@HiveType(typeId: 2)
enum CategoryType {
  @HiveField(0) income,
  @HiveField(1) expense
}

@HiveType(typeId: 3)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String iconName;
  @HiveField(3)
  final CategoryType type;

  @HiveField(4)
  bool isSynced;
  @HiveField(5)
  bool isDeleted;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.type,
    this.isSynced = false,
    this.isDeleted = false
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      iconName: map['icon_name'] ?? '',
      type: map['type'] == 'income' ? CategoryType.income : CategoryType.expense,
      isSynced: true,
      isDeleted: false
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type == CategoryType.income ? 'income' : 'expense',
      'icon_name': iconName,
      'is_synced': isSynced,
      'is_deleted': isDeleted
    };
  }
}