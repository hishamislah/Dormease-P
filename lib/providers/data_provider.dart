import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/room.dart';
import '../models/tenant.dart';
import '../models/ticket.dart';
import '../services/supabase_rooms_service.dart';
import '../services/supabase_tenants_service.dart';
import '../services/supabase_tickets_service.dart';

class DataProvider extends ChangeNotifier {
  final SupabaseRoomsService _roomsService = SupabaseRoomsService();
  final SupabaseTenantsService _tenantsService = SupabaseTenantsService();
  final SupabaseTicketsService _ticketsService = SupabaseTicketsService();
  
  List<Room> _rooms = [];
  List<Tenant> _tenants = [];
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  bool _isConnected = false;
  
  // Stream subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _roomsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _tenantsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _ticketsSubscription;

  DataProvider() {
    _setupStreams();
  }
  
  void _setupStreams() {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Listen to rooms stream
      _roomsSubscription = _roomsService.roomsStream().listen(
        (data) {
          _rooms = data.map((item) {
            return Room(
              id: item['id'].toString(),
              roomNumber: item['room_number'] ?? '',
              type: item['type'] ?? 'Standard',
              totalBeds: item['total_beds'] ?? 0,
              occupiedBeds: item['occupied_beds'] ?? 0,
              rent: (item['rent'] ?? 0).toDouble(),
              underNotice: item['under_notice'] ?? 0,
              rentDue: item['rent_due'] ?? 0,
              activeTickets: item['active_tickets'] ?? 0,
              status: item['status'] ?? 'Available',
              bathroomType: item['bathroom_type'] ?? 'Non-attached',
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
        (data) async {
          final now = DateTime.now();
          
          // First, create tenant objects with empty payment history
          List<Tenant> tenantsList = data.map((item) {
            return Tenant(
              id: item['id'].toString(),
              name: item['name'] ?? '',
              phone: item['phone'] ?? '',
              emergencyContact: item['emergency_contact'] ?? '',
              description: item['description'] ?? '',
              roomNumber: item['room_number'] ?? '',
              joinedDate: item['joined_date'] != null 
                  ? DateTime.parse(item['joined_date'])
                  : DateTime.now(),
              monthlyRent: (item['monthly_rent'] ?? 0).toDouble(),
              securityDeposit: (item['security_deposit'] ?? 0).toDouble(),
              underNotice: item['under_notice'] ?? false,
              rentDue: item['rent_due'] ?? false,
              imagePath: item['image_path'] ?? 'assets/images/dp.png',
              rentDueDate: item['rent_due_date'] != null 
                  ? DateTime.parse(item['rent_due_date'])
                  : null,
              leavingDate: item['leaving_date'] != null 
                  ? DateTime.parse(item['leaving_date'])
                  : null,
              partialRent: item['partial_rent']?.toDouble(),
              paymentHistory: [],
            );
          }).toList();
          
          // Then, fetch payment history for each tenant
          for (int i = 0; i < tenantsList.length; i++) {
            final tenant = tenantsList[i];
            try {
              final payments = await _tenantsService.fetchPaymentHistory(tenant.id);
              final paymentRecords = payments.map((p) => PaymentRecord(
                id: p['id'].toString(),
                date: DateTime.parse(p['date']),
                amount: (p['amount'] ?? 0).toDouble(),
                status: p['status'] ?? 'Pending',
                month: p['month'] ?? '',
                paymentMethod: p['payment_method'] ?? 'Cash',
              )).toList();
              
              tenantsList[i] = Tenant(
                id: tenant.id,
                name: tenant.name,
                phone: tenant.phone,
                emergencyContact: tenant.emergencyContact,
                description: tenant.description,
                roomNumber: tenant.roomNumber,
                joinedDate: tenant.joinedDate,
                monthlyRent: tenant.monthlyRent,
                securityDeposit: tenant.securityDeposit,
                underNotice: tenant.underNotice,
                rentDue: tenant.rentDue,
                imagePath: tenant.imagePath,
                rentDueDate: tenant.rentDueDate,
                leavingDate: tenant.leavingDate,
                partialRent: tenant.partialRent,
                paymentHistory: paymentRecords,
              );
            } catch (e) {
              debugPrint('Error loading payment history for tenant ${tenant.id}: $e');
            }
          }
          
          _tenants = tenantsList;
          
          // Auto-update rent due status for tenants
          for (var tenant in _tenants) {
            if (tenant.rentDueDate != null) {
              final isRentDue = now.isAfter(tenant.rentDueDate!) || 
                               now.year == tenant.rentDueDate!.year &&
                               now.month == tenant.rentDueDate!.month &&
                               now.day == tenant.rentDueDate!.day;
              
              // Check if current month has been paid
              final currentMonthYear = DateFormat('MMMM yyyy').format(now);
              final hasPaymentForCurrentMonth = tenant.paymentHistory.any((payment) {
                return payment.month.toLowerCase().trim() == currentMonthYear.toLowerCase() &&
                       payment.status.toLowerCase() == 'paid';
              });
              
              // Only update database if rent is due, not marked yet, AND current month hasn't been paid
              if (isRentDue && !tenant.rentDue && !hasPaymentForCurrentMonth) {
                try {
                  await _tenantsService.updateTenant(tenant.id, {'rentDue': true});
                } catch (e) {
                  debugPrint('Error auto-updating rent due status: $e');
                }
              }
              // If rent is marked as due but current month is paid, set it to false
              else if (tenant.rentDue && hasPaymentForCurrentMonth) {
                try {
                  await _tenantsService.updateTenant(tenant.id, {'rentDue': false});
                } catch (e) {
                  debugPrint('Error clearing rent due status: $e');
                }
              }
            }
          }
          
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
        (data) {
          _tickets = data.map((item) {
            return Ticket(
              id: item['id'].toString(),
              title: item['title'] ?? '',
              description: item['description'] ?? '',
              raisedBy: item['raised_by'] ?? '',
              roomNumber: item['room_number'] ?? '',
              date: item['date'] != null 
                  ? DateTime.parse(item['date'])
                  : DateTime.now(),
              status: item['status'] ?? 'Open',
              priority: item['priority'] ?? 'Medium',
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
      debugPrint('Error setting up Supabase streams: $e');
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
    });
    // Refresh data to ensure UI updates
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
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
    });
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
  }

  Future<void> deleteRoom(String id) async {
    await _roomsService.deleteRoom(id);
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
  }

  Future<void> addTenant(Tenant tenant) async {
    await _tenantsService.addTenant({
      'name': tenant.name,
      'phone': tenant.phone,
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
    });
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
  }

  Future<void> updateTenant(Tenant updatedTenant) async {
    await _tenantsService.updateTenant(updatedTenant.id, {
      'name': updatedTenant.name,
      'phone': updatedTenant.phone,
      'emergencyContact': updatedTenant.emergencyContact,
      'description': updatedTenant.description,
      'roomNumber': updatedTenant.roomNumber,
      'joinedDate': updatedTenant.joinedDate,
      'monthlyRent': updatedTenant.monthlyRent,
      'securityDeposit': updatedTenant.securityDeposit,
      'underNotice': updatedTenant.underNotice,
      'rentDue': updatedTenant.rentDue,
      'imagePath': updatedTenant.imagePath,
      'rentDueDate': updatedTenant.rentDueDate,
      'leavingDate': updatedTenant.leavingDate,
      'partialRent': updatedTenant.partialRent,
    });
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
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

  Future<void> markRentUnpaid(String tenantId, String month) async {
    await _tenantsService.markRentUnpaid(tenantId, month);
    
    // Update local tenant data
    final tenantIndex = _tenants.indexWhere((t) => t.id == tenantId);
    if (tenantIndex != -1) {
      final tenant = _tenants[tenantIndex];
      
      // Remove payment from history
      tenant.paymentHistory.removeWhere((p) => p.month == month);
      
      // Update tenant with new rentDue status
      _tenants[tenantIndex] = Tenant(
        id: tenant.id,
        name: tenant.name,
        phone: tenant.phone,
        emergencyContact: tenant.emergencyContact,
        description: tenant.description,
        roomNumber: tenant.roomNumber,
        joinedDate: tenant.joinedDate,
        monthlyRent: tenant.monthlyRent,
        securityDeposit: tenant.securityDeposit,
        underNotice: tenant.underNotice,
        rentDue: true, // Mark as due since payment is reverted
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
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
  }

  Future<void> addTicket(Ticket ticket) async {
    await _ticketsService.addTicket({
      'title': ticket.title,
      'description': ticket.description,
      'raisedBy': ticket.raisedBy,
      'roomNumber': ticket.roomNumber,
      'date': ticket.date,
      'status': ticket.status,
      'priority': ticket.priority,
    });
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
  }

  Future<void> deleteTicket(String id) async {
    await _ticketsService.deleteTicket(id);
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
  }

  Future<void> updateTicketStatus(String id, String status) async {
    await _ticketsService.updateTicketStatus(id, status);
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
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