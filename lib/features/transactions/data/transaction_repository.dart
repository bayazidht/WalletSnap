import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_snap/features/transactions/data/transaction_model.dart';

class TransactionRepository {
  final Box<TransactionModel> _box = Hive.box<TransactionModel>('transactions');
  final _supabase = Supabase.instance.client;

  List<TransactionModel> getAllLocal() {
    return _box.values.where((tx) => !tx.isDeleted).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveToHive(TransactionModel tx) async {
    await _box.put(tx.id, tx);
  }

  Future<void> markAsDeleted(String id) async {
    final tx = _box.get(id);
    if (tx != null) {
      tx.isDeleted = true;
      tx.isSynced = false;
      await tx.save();
    }
  }

  Future<void> syncWithSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final unsynced = _box.values.where((tx) => !tx.isSynced && !tx.isDeleted).toList();
    if (unsynced.isNotEmpty) {
      final List<Map<String, dynamic>> uploadData = unsynced.map((item) {
        final map = item.toMap();
        map['user_id'] = user.id;
        return map;
      }).toList();

      await _supabase.from('transactions').upsert(uploadData);

      for (var item in unsynced) {
        item.isSynced = true;
        await item.save();
      }
    }

    final deleted = _box.values.where((tx) => tx.isDeleted).toList();
    for (var item in deleted) {
      try {
        await _supabase.from('transactions').delete().eq('id', item.id);
        await item.delete();
      } catch (e) {
        debugPrint("Sync delete error: $e");
      }
    }

    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', user.id);

      for (var cloudData in response) {
        final tx = TransactionModel.fromMap(cloudData);
        tx.isSynced = true;
        await _box.put(tx.id, tx);
      }
        } catch (e) {
      debugPrint("Sync download error: $e");
    }
  }

  Future<void> deleteTransactionsByCategory(String categoryId) async {
    final keysToDelete = _box.keys.where((key) {
      final tx = _box.get(key);
      return tx?.categoryId == categoryId;
    }).toList();

    await _box.deleteAll(keysToDelete);

    try {
      await _supabase
          .from('transactions')
          .delete()
          .eq('category_id', categoryId);
    } catch (e) {
      debugPrint("Error deleting transactions from Supabase: $e");
    }
  }
}