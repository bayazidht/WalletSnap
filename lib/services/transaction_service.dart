import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_snap/models/transaction_model.dart';

class TransactionService {
  final _supabase = Supabase.instance.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User is not logged in.");
    return user.id;
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final data = transaction.toMap();
    data['user_id'] = _currentUserId;

    await _supabase.from('transactions').insert(data);
  }

  Stream<List<TransactionModel>> getTransactions() {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId)
        .order('date', ascending: false)
        .map((data) => data.map((map) => TransactionModel.fromMap(map)).toList());
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _supabase
        .from('transactions')
        .update(transaction.toMap())
        .eq('id', transaction.id)
        .eq('user_id', _currentUserId);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _supabase
        .from('transactions')
        .delete()
        .eq('id', transactionId)
        .eq('user_id', _currentUserId);
  }

  Future<void> deleteTransactionsByCategory(String categoryId) async {
    await _supabase
        .from('transactions')
        .delete()
        .eq('category_id', categoryId)
        .eq('user_id', _currentUserId);
  }
}