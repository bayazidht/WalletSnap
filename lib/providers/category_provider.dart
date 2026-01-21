import 'package:flutter/material.dart';
import 'package:wallet_snap/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../data/default_categories.dart';

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _categories = [];
  final _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _categorySubscription;

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get incomeCategories => _categories.where((c) => c.type == CategoryType.income).toList();
  List<CategoryModel> get expenseCategories => _categories.where((c) => c.type == CategoryType.expense).toList();


  CategoryProvider(User? user) {
    if (user != null) {
      _startListeningToCategories(user.id);
    } else {
      _categories = [];
      _categorySubscription?.cancel();
    }
  }

  void _startListeningToCategories(String userId) {
    _categorySubscription?.cancel();

    _categorySubscription = _supabase
        .from('categories')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((List<Map<String, dynamic>> data) {
      _categories = data.map((map) => CategoryModel.fromMap(map)).toList();

      if (_categories.isEmpty) {
        _setDefaultCategories(userId);
      }
      notifyListeners();
    });
  }

  Future<void> _setDefaultCategories(String userId) async {
    final List<Map<String, dynamic>> categoriesToInsert = allDefaultCategories.map((cat) {
      return {
        'user_id': userId,
        'name': cat.name,
        'icon_name': cat.iconName,
        'type': cat.type == CategoryType.income ? 'income' : 'expense',
      };
    }).toList();

    try {
      await _supabase.from('categories').insert(categoriesToInsert);
    } catch (e) {
      debugPrint('Default Category Insert Error: $e');
    }
  }

  CategoryModel getCategoryById(String id) {
    return _categories.firstWhere(
          (cat) => cat.id == id,
      orElse: () => CategoryModel(
        id: 'uncategorized',
        name: 'Uncategorized',
        type: CategoryType.expense,
        iconName: 'general',
      ),
    );
  }

  Future<void> addCategory(String name, CategoryType type, String iconName) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase.from('categories').insert({
        'user_id': userId,
        'name': name,
        'type': type == CategoryType.income ? 'income' : 'expense',
        'icon_name': iconName,
      });
    }
  }


  Future<void> deleteCategory(String id) async {
    await _supabase.from('categories').delete().eq('id', id);
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    super.dispose();
  }
}