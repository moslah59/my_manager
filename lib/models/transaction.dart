class Transaction {
  final String type;
  final String description;
  final double amount;
  final DateTime date;
  final String category;

  Transaction({
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    this.category = 'General',
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      type: map['type'] as String? ?? 'Expense',
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: map['category'] as String? ?? 'General',
    );
  }
}