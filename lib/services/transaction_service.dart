
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_manager/models/transaction.dart';

class TransactionService {
  final Box transactionsBox = Hive.box('transactions');

  Future<void> addTransaction(Transaction transaction) async {
    await transactionsBox.add(transaction.toMap());
  }

  List<Transaction> getTransactions() {
    final List<Transaction> transactions = [];

    for (final item in transactionsBox.values) {
      final Map<String, dynamic> data =
      Map<String, dynamic>.from(item as Map);

      transactions.add(Transaction.fromMap(data));
    }

    return transactions;
  }
}
