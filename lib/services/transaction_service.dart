
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


  List<Map<String, dynamic>> getTransactionsWithKeys() {
    final List<Map<String, dynamic>> transactions = [];

    for (final key in transactionsBox.keys) {
      final item = transactionsBox.get(key);

      if (item is Map) {
        final Map<String, dynamic> data =
        Map<String, dynamic>.from(item);

        transactions.add({
          'key': key,
          'transaction': Transaction.fromMap(data),
        });
      }
    }

    return transactions;
  }


  Future<void> updateTransaction(
      dynamic key,
      Transaction transaction,
      ) async {
    await transactionsBox.put(key, transaction.toMap());
  }

  Future<void> deleteTransaction(dynamic key) async {
    await transactionsBox.delete(key);
  }
}
