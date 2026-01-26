import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/default_categories.dart';
import '../data/category_model.dart';

class CategoryRepository {
  final Box<CategoryModel> _box = Hive.box<CategoryModel>('categories');
  final _supabase = Supabase.instance.client;

  List<CategoryModel> getAllLocal() {
    return _box.values.where((cat) => !cat.isDeleted).toList();
  }

  Future<void> saveToHive(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  Future<void> markAsDeleted(String id) async {
    final cat = _box.get(id);
    if (cat != null) {
      cat.isDeleted = true;
      cat.isSynced = false;
      await cat.save();
    }
  }

  Future<void> syncWithSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final unsynced = _box.values
        .where((cat) => !cat.isSynced && !cat.isDeleted)
        .toList();
    if (unsynced.isNotEmpty) {
      final uploadData = unsynced.map((item) {
        final map = item.toMap();
        map['user_id'] = user.id;
        return map;
      }).toList();

      await _supabase.from('categories').upsert(uploadData);

      for (var item in unsynced) {
        item.isSynced = true;
        await item.save();
      }
    }

    final deleted = _box.values.where((cat) => cat.isDeleted).toList();
    for (var item in deleted) {
      try {
        await _supabase.from('categories').delete().eq('id', item.id);
        await item.delete();
      } catch (e) {
        debugPrint("Category sync error: $e");
      }
    }

    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('user_id', user.id);
      if (response.isNotEmpty) {
        for (var cloudData in response) {
          final cat = CategoryModel.fromMap(cloudData);
          cat.isSynced = true;
          await _box.put(cat.id, cat);
        }
      } else {
        await initDefaultCategories();
      }
    } catch (e) {
      debugPrint("Category download error: $e");
    }
  }

  Future<void> initDefaultCategories() async {
    if (_box.isEmpty) {
      for (var cat in allDefaultCategories) {
        await _box.put(cat.id, cat);
      }
    }
  }
}
