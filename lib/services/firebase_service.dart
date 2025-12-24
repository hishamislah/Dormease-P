import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dormease/models/room.dart';
import 'package:dormease/models/tenant.dart';
import 'package:dormease/models/ticket.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  final CollectionReference _roomsCollection = 
      FirebaseFirestore.instance.collection('rooms');
  final CollectionReference _tenantsCollection = 
      FirebaseFirestore.instance.collection('tenants');
  final CollectionReference _ticketsCollection = 
      FirebaseFirestore.instance.collection('tickets');

  // ROOMS CRUD
  Stream<List<Room>> roomsStream() {
    return _roomsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Room(
          id: doc.id,
          roomNumber: data['roomNumber'] ?? '',
          type: data['type'] ?? '',
          totalBeds: data['totalBeds'] ?? 0,
          occupiedBeds: data['occupiedBeds'] ?? 0,
          rent: (data['rent'] ?? 0).toDouble(),
          underNotice: data['underNotice'] ?? 0,
          rentDue: data['rentDue'] ?? 0,
          activeTickets: data['activeTickets'] ?? 0,
          status: data['status'] ?? 'Available',
          bathroomType: data['bathroomType'] ?? 'Non-attached',
        );
      }).toList();
    });
  }

  Future<void> addRoom(Room room) async {
    await _roomsCollection.add({
      'roomNumber': room.roomNumber,
      'type': room.type,
      'totalBeds': room.totalBeds,
      'occupiedBeds': room.occupiedBeds,
      'rent': room.rent,
      'underNotice': room.underNotice,
      'rentDue': room.rentDue,
      'activeTickets': room.activeTickets,
      'status': room.status,
      'bathroomType': room.bathroomType,
    });
  }

  Future<void> updateRoom(Room room) async {
    await _roomsCollection.doc(room.id).update({
      'roomNumber': room.roomNumber,
      'type': room.type,
      'totalBeds': room.totalBeds,
      'occupiedBeds': room.occupiedBeds,
      'rent': room.rent,
      'underNotice': room.underNotice,
      'rentDue': room.rentDue,
      'activeTickets': room.activeTickets,
      'status': room.status,
      'bathroomType': room.bathroomType,
    });
  }

  Future<void> deleteRoom(String id) async {
    await _roomsCollection.doc(id).delete();
  }

  // TENANTS CRUD
  Stream<List<Tenant>> tenantsStream() {
    return _tenantsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Convert payment history from Firestore
        List<PaymentRecord> paymentHistory = [];
        if (data['paymentHistory'] != null) {
          for (var payment in data['paymentHistory']) {
            paymentHistory.add(PaymentRecord(
              id: payment['id'] ?? '',
              date: payment['date'] is Timestamp ? 
                  (payment['date'] as Timestamp).toDate() : DateTime.now(),
              amount: (payment['amount'] ?? 0).toDouble(),
              status: payment['status'] ?? '',
              month: payment['month'] ?? '',
              paymentMethod: payment['paymentMethod'] ?? '',
            ));
          }
        }
        
        return Tenant(
          id: doc.id,
          name: data['name'] ?? '',
          phone: data['phone'] ?? '',
          email: data['email'] ?? '',
          emergencyContact: data['emergencyContact'] ?? '',
          description: data['description'] ?? '',
          roomNumber: data['roomNumber'] ?? '',
          joinedDate: data['joinedDate'] is Timestamp ? 
              (data['joinedDate'] as Timestamp).toDate() : DateTime.now(),
          monthlyRent: (data['monthlyRent'] ?? 0).toDouble(),
          securityDeposit: (data['securityDeposit'] ?? 0).toDouble(),
          underNotice: data['underNotice'] ?? false,
          rentDue: data['rentDue'] ?? false,
          imagePath: data['imagePath'] ?? 'assets/images/dp.png',
          rentDueDate: data['rentDueDate'] != null && data['rentDueDate'] is Timestamp ? 
              (data['rentDueDate'] as Timestamp).toDate() : null,
          leavingDate: data['leavingDate'] != null && data['leavingDate'] is Timestamp ? 
              (data['leavingDate'] as Timestamp).toDate() : null,
          partialRent: data['partialRent'] != null ? 
              (data['partialRent']).toDouble() : null,
          paymentHistory: paymentHistory,
        );
      }).toList();
    });
  }

  Future<void> addTenant(Tenant tenant) async {
    // Convert payment history for Firestore
    List<Map<String, dynamic>> paymentHistoryMaps = tenant.paymentHistory.map((payment) => {
      'id': payment.id,
      'date': payment.date,
      'amount': payment.amount,
      'status': payment.status,
      'month': payment.month,
      'paymentMethod': payment.paymentMethod,
    }).toList();
    
    await _tenantsCollection.add({
      'name': tenant.name,
      'phone': tenant.phone,
      'email': tenant.email,
      'emergencyContact': tenant.emergencyContact,
      'description': tenant.description,
      'roomNumber': tenant.roomNumber,
      'joinedDate': tenant.joinedDate,
      'monthlyRent': tenant.monthlyRent,
      'securityDeposit': tenant.securityDeposit,
      'underNotice': tenant.underNotice,
      'rentDue': tenant.rentDue,
      'imagePath': tenant.imagePath,
      'rentDueDate': tenant.rentDueDate,
      'leavingDate': tenant.leavingDate,
      'partialRent': tenant.partialRent,
      'paymentHistory': paymentHistoryMaps,
    });
  }

  Future<void> updateTenant(Tenant tenant) async {
    // Convert payment history for Firestore
    List<Map<String, dynamic>> paymentHistoryMaps = tenant.paymentHistory.map((payment) => {
      'id': payment.id,
      'date': payment.date,
      'amount': payment.amount,
      'status': payment.status,
      'month': payment.month,
      'paymentMethod': payment.paymentMethod,
    }).toList();
    
    await _tenantsCollection.doc(tenant.id).update({
      'name': tenant.name,
      'phone': tenant.phone,
      'email': tenant.email,
      'emergencyContact': tenant.emergencyContact,
      'description': tenant.description,
      'roomNumber': tenant.roomNumber,
      'joinedDate': tenant.joinedDate,
      'monthlyRent': tenant.monthlyRent,
      'securityDeposit': tenant.securityDeposit,
      'underNotice': tenant.underNotice,
      'rentDue': tenant.rentDue,
      'imagePath': tenant.imagePath,
      'rentDueDate': tenant.rentDueDate,
      'leavingDate': tenant.leavingDate,
      'partialRent': tenant.partialRent,
      'paymentHistory': paymentHistoryMaps,
    });
  }

  Future<void> deleteTenant(String id) async {
    await _tenantsCollection.doc(id).delete();
  }

  Future<void> markRentPaid(String tenantId, String month) async {
    // Get the tenant document
    DocumentSnapshot tenantDoc = await _tenantsCollection.doc(tenantId).get();
    Map<String, dynamic> tenantData = tenantDoc.data() as Map<String, dynamic>;
    
    // Update the payment history
    List<dynamic> paymentHistory = tenantData['paymentHistory'] ?? [];
    for (int i = 0; i < paymentHistory.length; i++) {
      if (paymentHistory[i]['month'] == month) {
        paymentHistory[i]['status'] = 'Paid';
        paymentHistory[i]['date'] = DateTime.now();
        paymentHistory[i]['paymentMethod'] = 'Cash';
        break;
      }
    }
    
    // Update the tenant document
    await _tenantsCollection.doc(tenantId).update({
      'paymentHistory': paymentHistory,
    });
  }

  // TICKETS CRUD
  Stream<List<Ticket>> ticketsStream() {
    return _ticketsCollection.orderBy('priority').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Ticket(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          raisedBy: data['raisedBy'] ?? '',
          roomNumber: data['roomNumber'] ?? '',
          date: data['date'] is Timestamp ? 
              (data['date'] as Timestamp).toDate() : DateTime.now(),
          status: data['status'] ?? '',
          priority: data['priority'] ?? 'Medium',
        );
      }).toList();
    });
  }

  Future<void> addTicket(Ticket ticket) async {
    // Get count of existing tickets for issue number
    QuerySnapshot ticketCount = await _ticketsCollection.get();
    int issueNumber = ticketCount.docs.length + 1;
    
    // Add # to title
    String titleWithNumber = "#$issueNumber ${ticket.title}";
    
    await _ticketsCollection.add({
      'title': titleWithNumber,
      'description': ticket.description,
      'raisedBy': ticket.raisedBy,
      'roomNumber': ticket.roomNumber,
      'date': ticket.date,
      'status': ticket.status,
      'priority': ticket.priority,
    });
  }

  Future<void> updateTicketStatus(String id, String status) async {
    await _ticketsCollection.doc(id).update({
      'status': status,
    });
  }

  Future<void> deleteTicket(String id) async {
    await _ticketsCollection.doc(id).delete();
  }
}