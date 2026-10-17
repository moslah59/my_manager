
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_manager/services/transaction_service.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  final TransactionService _service = TransactionService();

  bool _loading = false;

  Future<void> _runBackup() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('আগে লগইন করো।');
      return;
    }

    setState(() => _loading = true);

    try {
      // Check the signed-in account.
      await user.reload();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('Login session পাওয়া যায়নি। আবার লগইন করো।');
      }

      debugPrint('Backup account: ${currentUser.email}');
      debugPrint('Backup UID: ${currentUser.uid}');

      // Upload all local transactions and get the uploaded count.
      final uploadedCount =
      await _service.backupExistingTransactions();

      if (uploadedCount == 0) {
        if (mounted) {
          _showMessage(
            'Backup হয়নি: লোকাল storage-এ কোনো transaction পাওয়া যায়নি।',
          );
        }
        return;
      }

      // Verify that the uploaded documents exist in the
      // currently signed-in user's Firestore collection.
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('transactions')
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception(
          'Firestore-এ কোনো transaction পাওয়া যায়নি। '
              'UID: ${currentUser.uid}',
        );
      }

      if (!mounted) return;

      _showMessage(
        'Backup যাচাই সফল! '
            '$uploadedCount টি transaction আপলোডের কাজ সম্পন্ন হয়েছে। '
            'Firestore-এ মোট ${snapshot.docs.length} টি document পাওয়া গেছে।',
      );
    } catch (e, stackTrace) {
      debugPrint('Cloud backup error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage('Backup ব্যর্থ হয়েছে: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _runRestore() async {
    if (FirebaseAuth.instance.currentUser == null) {
      _showMessage('আগে লগইন করো।');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Cloud Data?'),
        content: const Text(
          'Cloud-এর transaction-গুলো Local ডেটার সঙ্গে যুক্ত হবে। '
              'Restore করার আগে তোমার ডেটা Backup রাখা ভালো।',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);

    try {
      await _service.restoreCloudTransactions();

      if (mounted) {
        _showMessage('Cloud Restore সম্পন্ন হয়েছে!');
      }
    } catch (e, stackTrace) {
      debugPrint('Cloud restore error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage('Restore ব্যর্থ হয়েছে: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backup & Sync'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_sync,
                size: 90,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Cloud Backup',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user?.email ?? 'Not signed in',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              if (user != null)
                SelectableText(
                  'UID: ${user.uid}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _runBackup,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Backup Now'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _runRestore,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Restore Data'),
                ),
              ),
              if (_loading) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                const Text('Cloud operation চলছে...'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
