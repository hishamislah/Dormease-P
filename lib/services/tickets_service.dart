import 'package:cloud_firestore/cloud_firestore.dart';

class TicketsService {
  final _collection = FirebaseFirestore.instance.collection('tickets');

  Stream<QuerySnapshot> ticketsStream() => _collection.snapshots();

  Future<List<Map<String, dynamic>>> fetchTickets() async {
    final querySnapshot = await _collection.get();
    return querySnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> addTicket(Map<String, dynamic> ticket) async {
    await _collection.add(ticket);
  }

  Future<void> updateTicket(String ticketId, Map<String, dynamic> data) async {
    await _collection.doc(ticketId).set(data, SetOptions(merge: true));
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    await _collection.doc(ticketId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTicket(String ticketId) async {
    await _collection.doc(ticketId).delete();
  }
}