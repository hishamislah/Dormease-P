import 'package:cloud_firestore/cloud_firestore.dart';

class TenantsService {
  final _collection = FirebaseFirestore.instance.collection('tenants');

  Stream<QuerySnapshot> tenantsStream() => _collection.snapshots();

  Future<List<Map<String, dynamic>>> fetchTenants() async {
    final querySnapshot = await _collection.get();
    return querySnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> addTenant(Map<String, dynamic> tenant) async {
    await _collection.add(tenant);
  }

  Future<void> updateTenant(String tenantId, Map<String, dynamic> data) async {
    await _collection.doc(tenantId).set(data, SetOptions(merge: true));
  }

  Future<void> deleteTenant(String tenantId) async {
    await _collection.doc(tenantId).delete();
  }

  Future<void> markRentPaid(String tenantId, String month, [String paymentMethod = 'Cash']) async {
    // Get current tenant data
    final doc = await _collection.doc(tenantId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final paymentHistory = List<Map<String, dynamic>>.from(data['paymentHistory'] ?? []);
      final monthlyRent = (data['monthlyRent'] ?? 0).toDouble();
      
      // Find and update the specific payment record
      bool paymentFound = false;
      for (int i = 0; i < paymentHistory.length; i++) {
        if (paymentHistory[i]['month'] == month) {
          paymentHistory[i]['status'] = 'Paid';
          paymentHistory[i]['date'] = Timestamp.now();
          paymentHistory[i]['paymentMethod'] = paymentMethod;
          paymentFound = true;
          break;
        }
      }
      
      // If payment record doesn't exist, create it
      if (!paymentFound) {
        paymentHistory.add({
          'id': '${tenantId}_${month.replaceAll(' ', '_')}',
          'month': month,
          'amount': monthlyRent,
          'status': 'Paid',
          'date': Timestamp.now(),
          'paymentMethod': paymentMethod,
        });
      }
      
      // Check if any payments are still pending
      final hasPendingPayments = paymentHistory.any((p) => p['status'] == 'Pending');
      
      // Update tenant document
      await _collection.doc(tenantId).update({
        'paymentHistory': paymentHistory,
        'rentDue': hasPendingPayments,
        'lastPaymentDate': FieldValue.serverTimestamp(),
        'lastPaymentMonth': month,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('Payment marked as paid and saved to Firebase: $month for tenant $tenantId');
    }
  }
}