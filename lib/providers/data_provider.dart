import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';
import '../models/tenant.dart';
import '../models/ticket.dart';
import '../services/rooms_service.dart';
import '../services/tenants_service.dart';
import '../services/tickets_service.dart';

class DataProvider extends ChangeNotifier {
  final RoomsService _roomsService = RoomsService();
  final TenantsService _tenantsService = TenantsService();
  final TicketsService _ticketsService = TicketsService();
  
  List<Room> _rooms = [];
  List<Tenant> _tenants = [];
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  bool _isConnected = false;
  
  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _roomsSubscription;
  StreamSubscription<QuerySnapshot>? _tenantsSubscription;
  StreamSubscription<QuerySnapshot>? _ticketsSubscription;

  DataProvider() {
    _setupStreams();
  }
  
  void _setupStreams() {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Listen to rooms stream
      _roomsSubscription = _roomsService.roomsStream().listen(
        (snapshot) {
          _rooms = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Room(
              id: doc.id,
              roomNumber: data['roomNumber'] ?? '',
              type: data['type'] ?? 'Standard',
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
          _isConnected = true;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error in rooms stream: $error');
          _isConnected = false;
          _isLoading = false;
          notifyListeners();
        }
      );
      
      // Listen to tenants stream
      _tenantsSubscription = _tenantsService.tenantsStream().listen(
        (snapshot) {
          _tenants = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Tenant(
              id: doc.id,
              name: data['name'] ?? '',
              phone: data['phone'] ?? '',
              email: data['email'] ?? '',
              emergencyContact: data['emergencyContact'] ?? '',
              description: data['description'] ?? '',
              roomNumber: data['roomNumber'] ?? '',
              joinedDate: (data['joinedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              monthlyRent: (data['monthlyRent'] ?? 0).toDouble(),
              securityDeposit: (data['securityDeposit'] ?? 0).toDouble(),
              underNotice: data['underNotice'] ?? false,
              rentDue: data['rentDue'] ?? false,
              imagePath: data['imagePath'] ?? 'assets/images/dp.png',
              rentDueDate: (data['rentDueDate'] as Timestamp?)?.toDate(),
              leavingDate: (data['leavingDate'] as Timestamp?)?.toDate(),
              partialRent: data['partialRent']?.toDouble(),
              paymentHistory: (data['paymentHistory'] as List?)?.map((p) => PaymentRecord(
                id: p['id'] ?? '',
                date: (p['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
                amount: (p['amount'] ?? 0).toDouble(),
                status: p['status'] ?? 'Pending',
                month: p['month'] ?? '',
                paymentMethod: p['paymentMethod'] ?? 'Cash',
              )).toList() ?? [],
            );
          }).toList();
          _isConnected = true;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error in tenants stream: $error');
          _isConnected = false;
          _isLoading = false;
          notifyListeners();
        }
      );
      
      // Listen to tickets stream
      _ticketsSubscription = _ticketsService.ticketsStream().listen(
        (snapshot) {
          _tickets = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Ticket(
              id: doc.id,
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              raisedBy: data['raisedBy'] ?? '',
              roomNumber: data['roomNumber'] ?? '',
              date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
              status: data['status'] ?? 'Open',
              priority: data['priority'] ?? 'Medium',
            );
          }).toList();
          _isConnected = true;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error in tickets stream: $error');
          _isConnected = false;
          _isLoading = false;
          notifyListeners();
        }
      );
    } catch (e) {
      debugPrint('Error setting up Firebase streams: $e');
      _isConnected = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _roomsSubscription?.cancel();
    _tenantsSubscription?.cancel();
    _ticketsSubscription?.cancel();
    super.dispose();
  }

  List<Room> get rooms => _rooms;
  List<Tenant> get tenants => _tenants;
  List<Ticket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;

  Future<void> addRoom(Room room) async {
    await _roomsService.addRoom({
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
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRoom(Room updatedRoom) async {
    await _roomsService.updateRoom(updatedRoom.id, {
      'roomNumber': updatedRoom.roomNumber,
      'type': updatedRoom.type,
      'totalBeds': updatedRoom.totalBeds,
      'occupiedBeds': updatedRoom.occupiedBeds,
      'rent': updatedRoom.rent,
      'underNotice': updatedRoom.underNotice,
      'rentDue': updatedRoom.rentDue,
      'activeTickets': updatedRoom.activeTickets,
      'status': updatedRoom.status,
      'bathroomType': updatedRoom.bathroomType,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRoom(String id) async {
    await _roomsService.deleteRoom(id);
  }

  Future<void> addTenant(Tenant tenant) async {
    await _tenantsService.addTenant({
      'name': tenant.name,
      'phone': tenant.phone,
      'email': tenant.email,
      'emergencyContact': tenant.emergencyContact,
      'description': tenant.description,
      'roomNumber': tenant.roomNumber,
      'joinedDate': Timestamp.fromDate(tenant.joinedDate),
      'monthlyRent': tenant.monthlyRent,
      'securityDeposit': tenant.securityDeposit,
      'underNotice': tenant.underNotice,
      'rentDue': tenant.rentDue,
      'imagePath': tenant.imagePath,
      'rentDueDate': tenant.rentDueDate != null ? Timestamp.fromDate(tenant.rentDueDate!) : null,
      'leavingDate': tenant.leavingDate != null ? Timestamp.fromDate(tenant.leavingDate!) : null,
      'partialRent': tenant.partialRent,
      'paymentHistory': tenant.paymentHistory.map((p) => {
        'id': p.id,
        'date': Timestamp.fromDate(p.date),
        'amount': p.amount,
        'status': p.status,
        'month': p.month,
        'paymentMethod': p.paymentMethod,
      }).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTenant(Tenant updatedTenant) async {
    await _tenantsService.updateTenant(updatedTenant.id, {
      'name': updatedTenant.name,
      'phone': updatedTenant.phone,
      'email': updatedTenant.email,
      'emergencyContact': updatedTenant.emergencyContact,
      'description': updatedTenant.description,
      'roomNumber': updatedTenant.roomNumber,
      'joinedDate': Timestamp.fromDate(updatedTenant.joinedDate),
      'monthlyRent': updatedTenant.monthlyRent,
      'securityDeposit': updatedTenant.securityDeposit,
      'underNotice': updatedTenant.underNotice,
      'rentDue': updatedTenant.rentDue,
      'imagePath': updatedTenant.imagePath,
      'rentDueDate': updatedTenant.rentDueDate != null ? Timestamp.fromDate(updatedTenant.rentDueDate!) : null,
      'leavingDate': updatedTenant.leavingDate != null ? Timestamp.fromDate(updatedTenant.leavingDate!) : null,
      'partialRent': updatedTenant.partialRent,
      'paymentHistory': updatedTenant.paymentHistory.map((p) => {
        'id': p.id,
        'date': Timestamp.fromDate(p.date),
        'amount': p.amount,
        'status': p.status,
        'month': p.month,
        'paymentMethod': p.paymentMethod,
      }).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markRentPaid(String tenantId, String month, [String paymentMethod = 'Cash']) async {
    await _tenantsService.markRentPaid(tenantId, month, paymentMethod);
    
    // Update local tenant data
    final tenantIndex = _tenants.indexWhere((t) => t.id == tenantId);
    if (tenantIndex != -1) {
      final tenant = _tenants[tenantIndex];
      
      // Update payment history
      final paymentIndex = tenant.paymentHistory.indexWhere((p) => p.month == month);
      if (paymentIndex != -1) {
        tenant.paymentHistory[paymentIndex] = PaymentRecord(
          id: tenant.paymentHistory[paymentIndex].id,
          date: DateTime.now(),
          amount: tenant.paymentHistory[paymentIndex].amount,
          status: 'Paid',
          month: month,
          paymentMethod: paymentMethod,
        );
      }
      
      // Check if all payments are paid to update rentDue status
      final hasPendingPayments = tenant.paymentHistory.any((p) => p.status == 'Pending');
      
      // Update tenant with new rentDue status
      _tenants[tenantIndex] = Tenant(
        id: tenant.id,
        name: tenant.name,
        phone: tenant.phone,
        email: tenant.email,
        emergencyContact: tenant.emergencyContact,
        description: tenant.description,
        roomNumber: tenant.roomNumber,
        joinedDate: tenant.joinedDate,
        monthlyRent: tenant.monthlyRent,
        securityDeposit: tenant.securityDeposit,
        underNotice: tenant.underNotice,
        rentDue: hasPendingPayments,
        imagePath: tenant.imagePath,
        rentDueDate: tenant.rentDueDate,
        leavingDate: tenant.leavingDate,
        partialRent: tenant.partialRent,
        paymentHistory: tenant.paymentHistory,
      );
      
      notifyListeners();
    }
  }

  Future<void> deleteTenant(String id) async {
    await _tenantsService.deleteTenant(id);
  }

  Future<void> addTicket(Ticket ticket) async {
    await _ticketsService.addTicket({
      'title': ticket.title,
      'description': ticket.description,
      'raisedBy': ticket.raisedBy,
      'roomNumber': ticket.roomNumber,
      'date': Timestamp.fromDate(ticket.date),
      'status': ticket.status,
      'priority': ticket.priority,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTicket(String id) async {
    await _ticketsService.deleteTicket(id);
  }

  Future<void> updateTicketStatus(String id, String status) async {
    await _ticketsService.updateTicketStatus(id, status);
  }
  
  Future<void> reconnect() async {
    // Cancel existing subscriptions
    _roomsSubscription?.cancel();
    _tenantsSubscription?.cancel();
    _ticketsSubscription?.cancel();
    
    // Clear data
    _rooms = [];
    _tenants = [];
    _tickets = [];
    
    // Set up streams again
    _setupStreams();
  }
}