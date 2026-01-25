import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../../transactions/logic/transaction_provider.dart';
import '../data/category_model.dart';
import '../data/category_repository.dart';

final categoryRepositoryProvider = Provider(
        (ref) => CategoryRepository()
);

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, List<CategoryModel>>((ref) {
      return CategoryNotifier(ref.read(categoryRepositoryProvider), ref);
    });

class CategoryNotifier extends StateNotifier<List<CategoryModel>> {
  final CategoryRepository _repo;
  final Ref _ref;

  CategoryNotifier(this._repo, this._ref) : super([]) {
    loadLocalData();
  }

  void loadLocalData() {
    final data = _repo.getAllLocal();
    state = data;
  }

  Future<void> addCategory(
    String name,
    CategoryType type,
    String iconName,
  ) async {
    final newCat = CategoryModel(
      id: const Uuid().v4(),
      name: name,
      iconName: iconName,
      type: type,
      isSynced: false,
      isDeleted: false,
    );

    await _repo.saveToHive(newCat);
    loadLocalData();
  }

  Future<void> deleteCategory(String id) async {
    await _ref.read(transactionRepositoryProvider).deleteTransactionsByCategory(id);
    await _repo.markAsDeleted(id);
    loadLocalData();
    _ref.invalidate(transactionProvider);
  }

  Future<void> syncEverything() async {
    try {
      await _repo.syncWithSupabase();
      loadLocalData();
    } catch (e) {
      rethrow;
    }
  }

  final incomeCategoriesProvider = Provider((ref) {
    final categories = ref.watch(categoryProvider);
    return categories.where((c) => c.type == CategoryType.income).toList();
  });

  final expenseCategoriesProvider = Provider((ref) {
    final categories = ref.watch(categoryProvider);
    return categories.where((c) => c.type == CategoryType.expense).toList();
  });
}
