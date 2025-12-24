import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';

class SupabaseTicketsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseAuthService _authService = SupabaseAuthService();

  // Stream of tickets for current profile
  Stream<List<Map<String, dynamic>>> ticketsStream() async* {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) {
      yield [];
      return;
    }

    yield* _supabase
        .from('tickets')
        .stream(primaryKey: ['id'])
        .eq('profile_id', profileId)
        .map((data) => data.map((item) {
              return {
                'id': item['id'].toString(),
                ...item,
              };
            }).toList());
  }

  // Fetch tickets
  Future<List<Map<String, dynamic>>> fetchTickets() async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return [];

    try {
      final tickets = await _supabase
          .from('tickets')
          .select('*')
          .eq('profile_id', profileId)
          .order('date', ascending: false);

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
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return;

    try {
      ticket['profile_id'] = profileId;
      
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
