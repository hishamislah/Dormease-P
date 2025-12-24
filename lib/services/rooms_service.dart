import 'package:cloud_firestore/cloud_firestore.dart';

class RoomsService {
  final _collection = FirebaseFirestore.instance.collection('rooms');

  Stream<QuerySnapshot> roomsStream() => _collection.snapshots();

  Future<List<Map<String, dynamic>>> fetchRooms() async {
    final querySnapshot = await _collection.get();
    return querySnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> addRoom(Map<String, dynamic> room) async {
    await _collection.add(room);
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    await _collection.doc(roomId).set(data, SetOptions(merge: true));
  }

  Future<void> deleteRoom(String roomId) async {
    await _collection.doc(roomId).delete();
  }
}