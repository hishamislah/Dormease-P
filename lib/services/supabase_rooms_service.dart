import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';

class SupabaseRoomsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseAuthService _authService = SupabaseAuthService();

  // Stream of rooms for current profile
  Stream<List<Map<String, dynamic>>> roomsStream() async* {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) {
      yield [];
      return;
    }

    yield* _supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('profile_id', profileId)
        .map((data) => data.map((item) {
              return {
                'id': item['id'].toString(),
                ...item,
              };
            }).toList());
  }

  // Fetch rooms
  Future<List<Map<String, dynamic>>> fetchRooms() async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return [];

    try {
      final rooms = await _supabase
          .from('rooms')
          .select('*')
          .eq('profile_id', profileId);

      return rooms.map((room) {
        return {
          'id': room['id'].toString(),
          ...room,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching rooms: $e');
      return [];
    }
  }

  // Add room
  Future<void> addRoom(Map<String, dynamic> room) async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return;

    try {
      room['profile_id'] = profileId;
      
      // Convert camelCase to snake_case
      final mappedRoom = _mapToSnakeCase(room);
      
      await _supabase.from('rooms').insert(mappedRoom);
    } catch (e) {
      debugPrint('Error adding room: $e');
      rethrow;
    }
  }

  // Update room
  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    try {
      final mappedData = _mapToSnakeCase(data);
      
      await _supabase
          .from('rooms')
          .update(mappedData)
          .eq('id', roomId);
    } catch (e) {
      debugPrint('Error updating room: $e');
      rethrow;
    }
  }

  // Delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      await _supabase
          .from('rooms')
          .delete()
          .eq('id', roomId);
    } catch (e) {
      debugPrint('Error deleting room: $e');
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
