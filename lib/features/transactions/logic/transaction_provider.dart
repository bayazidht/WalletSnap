import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../data/transaction_model.dart';
import '../data/transaction_repository.dart';

final transactionRepositoryProvider = Provider(
  (ref) => TransactionRepository(),
);

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>((ref) {
      return TransactionNotifier(ref.read(transactionRepositoryProvider));
    });

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final TransactionRepository _repo;
  DateTime _selectedDate = DateTime.now();

  TransactionNotifier(this._repo) : super([]) {
    loadLocalData();
  }

  DateTime get selectedDate => _selectedDate;

  void loadLocalData() {
    final data = _repo.getAllLocal();
    data.sort((a, b) => b.date.compareTo(a.date));
    state = data;
  }

  void changeMonth(int increment) {
    _selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month + increment,
    );
    state = [...state];
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String categoryId,
    required DateTime date,
    String notes = '',
  }) async {
    final newTx = TransactionModel(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      type: type,
      categoryId: categoryId,
      date: date,
      notes: notes,
      isSynced: false,
    );

    await _repo.saveToHive(newTx);
    loadLocalData();
  }

  Future<void> updateTransaction(TransactionModel updatedTx) async {
    await _repo.saveToHive(updatedTx);
    loadLocalData();
  }

  Future<void> deleteTransaction(String id) async {
    await _repo.markAsDeleted(id);
    loadLocalData();
  }

  Future<void> syncEverything() async {
    try {
      await _repo.syncWithSupabase();
      loadLocalData();
    } catch (e) {
      rethrow;
    }
  }
}

final filteredTransactionsProvider = Provider((ref) {
  final allTransactions = ref.watch(transactionProvider);
  final selectedDate = ref.watch(transactionProvider.notifier).selectedDate;

  return allTransactions.where((tx) {
    return tx.date.year == selectedDate.year &&
        tx.date.month == selectedDate.month;
  }).toList();
});

final monthSummaryProvider = Provider((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  double income = 0;
  double expense = 0;

  for (var tx in transactions) {
    if (tx.type == TransactionType.income) {
      income += tx.amount;
    } else {
      expense += tx.amount;
    }
  }
  return {'income': income, 'expense': expense};
});

final todaySummaryProvider = Provider((ref) {
  final allTransactions = ref.watch(transactionProvider);
  final now = DateTime.now();
  double income = 0;
  double expense = 0;

  for (var tx in allTransactions) {
    if (tx.date.year == now.year &&
        tx.date.month == now.month &&
        tx.date.day == now.day) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
  }
  return {'income': income, 'expense': expense};
});

final chartDataProvider = Provider((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);

  Map<String, Map<String, dynamic>> categoryExpenses = {};
  double totalExpense = 0.0;
  Map<String, Map<String, double>> dailySummary = {};

  for (var tx in transactions) {
    if (tx.type == TransactionType.expense) {
      totalExpense += tx.amount;
      categoryExpenses.update(
        tx.categoryId,
        (val) => {
          'amount': val['amount'] + tx.amount,
          'icon': val['icon'] ?? tx.categoryId,
        },
        ifAbsent: () => {'amount': tx.amount, 'icon': tx.categoryId},
      );
    }

    final String dayKey = tx.date.day.toString().padLeft(2, '0');
    dailySummary.putIfAbsent(dayKey, () => {'income': 0.0, 'expense': 0.0});
    if (tx.type == TransactionType.income) {
      dailySummary[dayKey]!['income'] =
          dailySummary[dayKey]!['income']! + tx.amount;
    } else {
      dailySummary[dayKey]!['expense'] =
          dailySummary[dayKey]!['expense']! + tx.amount;
    }
  }
  return {
    'categoryExpenses': categoryExpenses,
    'totalExpense': totalExpense,
    'dailySummary': dailySummary,
  };
});
