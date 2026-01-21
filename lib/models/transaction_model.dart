
enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final String notes;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    required this.notes
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      categoryId: map['category_id'] ?? '',
      date: DateTime.parse(map['date']),
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'title': title,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}