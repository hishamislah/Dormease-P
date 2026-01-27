import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';

class SupabaseTicketsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseAuthService _authService = SupabaseAuthService();

  // Stream of tickets for current organization
  Stream<List<Map<String, dynamic>>> ticketsStream() async* {
    String? organizationId = await _authService.getCurrentOrganizationId();
    String? profileId = await _authService.getCurrentProfileId();
    
    if (organizationId == null && profileId == null) {
      yield [];
      return;
    }

    // Use organization_id if available, fallback to profile_id for backward compatibility
    if (organizationId != null) {
      yield* _supabase
          .from('tickets')
          .stream(primaryKey: ['id'])
          .eq('organization_id', organizationId)
          .map((data) => data.map((item) {
                return {
                  'id': item['id'].toString(),
                  ...item,
                };
              }).toList());
    } else {
      yield* _supabase
          .from('tickets')
          .stream(primaryKey: ['id'])
          .eq('profile_id', profileId!)
          .map((data) => data.map((item) {
                return {
                  'id': item['id'].toString(),
                  ...item,
                };
              }).toList());
    }
  }

  // Fetch tickets
  Future<List<Map<String, dynamic>>> fetchTickets() async {
    String? organizationId = await _authService.getCurrentOrganizationId();
    String? profileId = await _authService.getCurrentProfileId();
    
    if (organizationId == null && profileId == null) return [];

    try {
      List<Map<String, dynamic>> tickets;
      
      if (organizationId != null) {
        tickets = await _supabase
            .from('tickets')
            .select('*')
            .eq('organization_id', organizationId)
            .order('date', ascending: false);
      } else {
        tickets = await _supabase
            .from('tickets')
            .select('*')
            .eq('profile_id', profileId!)
            .order('date', ascending: false);
      }

      return tickets.map((ticket) {
        return {
          'id': ticket['id'].toString(),
          ...ticket,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
      return [];
    }
  }

  // Add ticket
  Future<void> addTicket(Map<String, dynamic> ticket) async {
    String? organizationId = await _authService.getCurrentOrganizationId();
    String? profileId = await _authService.getCurrentProfileId();
    
    if (organizationId == null && profileId == null) return;

    try {
      ticket['profile_id'] = profileId;
      ticket['organization_id'] = organizationId;
      
      // Convert DateTime to ISO string
      if (ticket['date'] != null && ticket['date'] is DateTime) {
        ticket['date'] = (ticket['date'] as DateTime).toIso8601String();
      }
      
      // Convert camelCase to snake_case
      final mappedTicket = _mapToSnakeCase(ticket);
      
      await _supabase.from('tickets').insert(mappedTicket);
    } catch (e) {
      debugPrint('Error adding ticket: $e');
      rethrow;
    }
  }

  // Update ticket
  Future<void> updateTicket(String ticketId, Map<String, dynamic> data) async {
    try {
      // Convert DateTime to ISO string
      if (data['date'] != null && data['date'] is DateTime) {
        data['date'] = (data['date'] as DateTime).toIso8601String();
      }
      
      final mappedData = _mapToSnakeCase(data);
      
      await _supabase
          .from('tickets')
          .update(mappedData)
          .eq('id', ticketId);
    } catch (e) {
      debugPrint('Error updating ticket: $e');
      rethrow;
    }
  }

  // Update ticket status
  Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      await _supabase
          .from('tickets')
          .update({'status': status})
          .eq('id', ticketId);
    } catch (e) {
      debugPrint('Error updating ticket status: $e');
      rethrow;
    }
  }

  // Update ticket priority
  Future<void> updateTicketPriority(String ticketId, String priority) async {
    try {
      await _supabase
          .from('tickets')
          .update({'priority': priority})
          .eq('id', ticketId);
    } catch (e) {
      debugPrint('Error updating ticket priority: $e');
      rethrow;
    }
  }

  // Delete ticket
  Future<void> deleteTicket(String ticketId) async {
    try {
      await _supabase
          .from('tickets')
          .delete()
          .eq('id', ticketId);
    } catch (e) {
      debugPrint('Error deleting ticket: $e');
      rethrow;
    }
  }

  // Helper method to convert camelCase to snake_case
  Map<String, dynamic> _mapToSnakeCase(Map<String, dynamic> data) {
    final mapped = <String, dynamic>{};
    data.forEach((key, value) {
      final snakeKey = key.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      );
      mapped[snakeKey] = value;
    });
    return mapped;
  }
}
