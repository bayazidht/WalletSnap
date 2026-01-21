import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_snap/models/category_model.dart';
import '../data/default_categories.dart';

class CategoryService {
  final _supabase = Supabase.instance.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User is not logged in.");
    return user.id;
  }

  Stream<List<CategoryModel>> getCategories() {
    return _supabase
        .from('categories')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId)
        .order('name', ascending: true)
        .map((data) => data.map((map) => CategoryModel.fromMap(map)).toList());
  }

  Future<void> addCategory(CategoryModel category) async {
    final data = category.toMap();
    data['user_id'] = _currentUserId;

    await _supabase.from('categories').insert(data);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _supabase
        .from('categories')
        .delete()
        .eq('id', categoryId)
        .eq('user_id', _currentUserId);
  }

  Future<void> saveDefaultCategories(String userId) async {
    final List<Map<String, dynamic>> categoriesToInsert = allDefaultCategories.map((cat) {
      return {
        'user_id': userId,
        'name': cat.name,
        'icon_name': cat.iconName,
        'type': cat.type == CategoryType.income ? 'income' : 'expense',
      };
    }).toList();

    await _supabase.from('categories').insert(categoriesToInsert);
  }
}