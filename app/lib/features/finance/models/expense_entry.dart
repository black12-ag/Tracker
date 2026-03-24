class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.expenseDate,
    required this.category,
    required this.amount,
    this.note,
  });

  final String id;
  final DateTime expenseDate;
  final String category;
  final double amount;
  final String? note;

  factory ExpenseEntry.fromMap(Map<String, dynamic> map) {
    return ExpenseEntry(
      id: map['id'] as String,
      expenseDate:
          DateTime.tryParse(map['expense_date'] as String? ?? '') ??
          DateTime.now(),
      category: map['category'] as String? ?? 'Expense',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_date': expenseDate.toIso8601String(),
      'category': category,
      'amount': amount,
      'note': note,
    };
  }
}
