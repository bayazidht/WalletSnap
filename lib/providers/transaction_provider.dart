import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // সুপাবেস ইমপোর্ট
import 'package:wallet_snap/models/transaction_model.dart';
import 'dart:async';

import 'category_provider.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  DateTime _selectedDate = DateTime.now();

  double _totalIncome = 0.0;
  double _totalExpense = 0.0;

  final _supabase = Supabase.instance.client; // সুপাবেস ক্লায়েন্ট
  StreamSubscription<List<Map<String, dynamic>>>? _transactionSubscription;

  TransactionProvider(User? user) {
    if (user != null) {
      _startListeningToTransactions(user.id);
    } else {
      _transactions = [];
      _transactionSubscription?.cancel();
    }
  }

  DateTime get selectedDate => _selectedDate;
  List<TransactionModel> get allTransactions => _transactions;

  List<TransactionModel> get filteredTransactions {
    return _transactions.where((tx) {
      return tx.date.year == _selectedDate.year &&
          tx.date.month == _selectedDate.month;
    }).toList();
  }

  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get totalBalance => _totalIncome - _totalExpense;

  void changeMonth(int increment) {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + increment);
    _calculateSummary();
    notifyListeners();
  }

  void _startListeningToTransactions(String userId) {
    _transactionSubscription?.cancel();

    _transactionSubscription = _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
      _transactions = data.map((map) => TransactionModel.fromMap(map)).toList();
      _calculateSummary();
      notifyListeners();
    });
  }

  void _calculateSummary() {
    double income = 0.0;
    double expense = 0.0;

    for (var tx in filteredTransactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    _totalIncome = income;
    _totalExpense = expense;
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _supabase.from('transactions').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  Map<String, dynamic> getChartData(BuildContext context) {
    Map<String, double> categoryExpenses = {};
    double currentMonthTotalExpense = 0.0;

    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    for (var tx in filteredTransactions) {
      if (tx.type == TransactionType.expense) {
        currentMonthTotalExpense += tx.amount;
        final String categoryName = categoryProvider
            .getCategoryById(tx.categoryId)
            .name;
        categoryExpenses[categoryName] =
            (categoryExpenses[categoryName] ?? 0) + tx.amount;
      }
    }

    Map<String, Map<String, double>> monthlySummary = {};

    for (var tx in _transactions) {
      final monthKey = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';

      monthlySummary.putIfAbsent(monthKey, () => {'income': 0.0, 'expense': 0.0});

      if (tx.type == TransactionType.income) {
        monthlySummary[monthKey]!['income'] = monthlySummary[monthKey]!['income']! + tx.amount;
      } else {
        monthlySummary[monthKey]!['expense'] = monthlySummary[monthKey]!['expense']! + tx.amount;
      }
    }

    final sortedMonthlySummary = Map.fromEntries(
      monthlySummary.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)),
    );

    return {
      'categoryExpenses': categoryExpenses,
      'totalExpense': currentMonthTotalExpense,
      'monthlySummary': sortedMonthlySummary,
    };
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }
}