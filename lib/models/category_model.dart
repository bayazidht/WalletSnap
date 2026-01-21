
enum CategoryType { income, expense }

class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final CategoryType type;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.type,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      iconName: map['icon_name'] ?? '',
      type: map['type'] == 'income' ? CategoryType.income : CategoryType.expense,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type == CategoryType.income ? 'income' : 'expense',
      'icon_name': iconName,
    };
  }
}