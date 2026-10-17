
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:my_manager/models/transaction.dart';

class TransactionService {
  final Box transactionsBox = Hive.box('transactions');
  final Box cloudIdsBox = Hive.box('transaction_cloud_ids');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current signed-in user's transactions collection.
  CollectionReference<Map<String, dynamic>> get _cloudTransactions {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in before syncing transactions.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions');
  }

  // Add a transaction locally, then sync it to Firestore.
  Future<void> addTransaction(Transaction transaction) async {
    final key = await transactionsBox.add(transaction.toMap());
    await _syncTransaction(key, transaction);
  }

  // Get all local transactions.
  List<Transaction> getTransactions() {
    return transactionsBox.values.map((item) {
      return Transaction.fromMap(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  // Get local transactions along with their Hive keys.
  List<Map<String, dynamic>> getTransactionsWithKeys() {
    final List<Map<String, dynamic>> result = [];

    for (final key in transactionsBox.keys) {
      final item = transactionsBox.get(key);

      if (item is Map) {
        result.add({
          'key': key,
          'transaction': Transaction.fromMap(
            Map<String, dynamic>.from(item),
          ),
        });
      }
    }

    return result;
  }

  // Update a transaction locally and in the cloud.
  Future<void> updateTransaction(
      dynamic key,
      Transaction transaction,
      ) async {
    await transactionsBox.put(key, transaction.toMap());
    await _syncTransaction(key, transaction);
  }

  // Delete a transaction locally and in the cloud.
  Future<void> deleteTransaction(dynamic key) async {
    final ref = _cloudTransactions;
    final localKey = key.toString();
    final cloudId = cloudIdsBox.get(localKey)?.toString();

    // Delete from Firestore first, so a failed cloud delete
    // does not silently remove the local record.
    if (cloudId != null) {
      await ref.doc(cloudId).delete();
    }

    await transactionsBox.delete(key);
    await cloudIdsBox.delete(localKey);
  }

  // Sync one local transaction to Firestore.
  Future<void> _syncTransaction(
      dynamic key,
      Transaction transaction,
      ) async {
    final ref = _cloudTransactions;
    final localKey = key.toString();

    String? cloudId = cloudIdsBox.get(localKey)?.toString();

    // Create a stable cloud document ID for this local record.
    if (cloudId == null || cloudId.isEmpty) {
      cloudId = ref.doc().id;
      await cloudIdsBox.put(localKey, cloudId);
    }

    // Await the Firestore write. Errors are deliberately rethrown.
    await ref.doc(cloudId).set({
      ...transaction.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Back up all existing local transactions.
  // Returns the number successfully uploaded.
  Future<int> backupExistingTransactions() async {
    final records = getTransactionsWithKeys();

    if (records.isEmpty) {
      return 0;
    }

    // Verify authentication before beginning the backup.
    _cloudTransactions;

    var uploadedCount = 0;

    for (final entry in records) {
      final key = entry['key'];
      final transaction = entry['transaction'] as Transaction;

      await _syncTransaction(key, transaction);
      uploadedCount++;
    }

    return uploadedCount;
  }

  // Restore cloud transactions without importing duplicates.
  Future<void> restoreCloudTransactions() async {
    final ref = _cloudTransactions;
    final snapshot = await ref.get();

    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data.remove('updatedAt');

      final cloudId = doc.id;

      // Find whether this cloud document is already mapped locally.
      dynamic existingHiveKey;

      for (final key in cloudIdsBox.keys) {
        if (cloudIdsBox.get(key)?.toString() == cloudId) {
          existingHiveKey = key;
          break;
        }
      }

      if (existingHiveKey != null) {
        // Update the corresponding local transaction.
        final localKey = transactionsBox.keys.cast<dynamic>().where(
              (key) => key.toString() == existingHiveKey.toString(),
        );

        if (localKey.isNotEmpty) {
          await transactionsBox.put(localKey.first, data);
        }
      } else {
        // Import a cloud record that is not mapped locally.
        final newKey = await transactionsBox.add(data);
        await cloudIdsBox.put(newKey.toString(), cloudId);
      }
    }
  }
}
