
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _transactionsRef {
    final uid = _userId;

    if (uid == null) return null;

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions');
  }

  Future<void> backupTransaction({
    required String cloudId,
    required Map<String, dynamic> data,
  }) async {
    final ref = _transactionsRef;

    if (ref == null) {
      throw Exception('আগে Google বা Email দিয়ে লগইন করো।');
    }

    await ref.doc(cloudId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchCloudTransactions() async {
    final ref = _transactionsRef;

    if (ref == null) {
      throw Exception('আগে লগইন করো।');
    }

    final snapshot = await ref.get();

    return snapshot.docs.map((doc) {
      return {
        'cloudId': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  Future<void> deleteCloudTransaction(String cloudId) async {
    final ref = _transactionsRef;

    if (ref == null) {
      throw Exception('আগে লগইন করো।');
    }

    await ref.doc(cloudId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? watchCloudTransactions() {
    return _transactionsRef?.snapshots();
  }
}
