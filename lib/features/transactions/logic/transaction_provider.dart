import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../data/transaction_model.dart';
import '../data/transaction_repository.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final transactionRepositoryProvider = Provider(
  (ref) => TransactionRepository(),
);

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<TransactionModel>>((ref) {
      return TransactionNotifier(ref.read(transactionRepositoryProvider));
    });

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final TransactionRepository _repo;

  TransactionNotifier(this._repo) : super([]) {
    loadLocalData();
  }

  void loadLocalData() {
    final data = _repo.getAllLocal();
    state = [...data.where((tx) => !tx.isDeleted)]
      ..sort((a, b) => b.date.compareTo(a.date));
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

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final allTransactions = ref.watch(transactionProvider);
  final selectedDate = ref.watch(selectedDateProvider);

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
  final transactions = ref.watch(filteredTransactionsProvider);
  final now = DateTime.now();
  double income = 0;
  double expense = 0;

  final todayTxs = transactions.where(
    (tx) =>
        tx.date.year == now.year &&
        tx.date.month == now.month &&
        tx.date.day == now.day,
  );

  for (var tx in todayTxs) {
    if (tx.type == TransactionType.income) {
      income += tx.amount;
    } else {
      expense += tx.amount;
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
