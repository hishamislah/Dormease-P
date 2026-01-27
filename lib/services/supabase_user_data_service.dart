import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';

class SupabaseUserDataService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseAuthService _authService = SupabaseAuthService();

  // Fetch user data for current profile
  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return null;

    try {
      final result = await _supabase
          .from('profiles')
          .select('id, profile_id, user_id, email, has_completed_business_info, created_at, updated_at')
          .eq('profile_id', profileId)
          .single();

      return result;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  // Set user data
  Future<void> setUserData(String uid, Map<String, dynamic> data) async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return;

    try {
      // Convert camelCase to snake_case
      final mappedData = _mapToSnakeCase(data);
      
      await _supabase
          .from('profiles')
          .update(mappedData)
          .eq('profile_id', profileId);
    } catch (e) {
      debugPrint('Error setting user data: $e');
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return;

    try {
      final mappedData = _mapToSnakeCase(data);
      
      await _supabase
          .from('profiles')
          .update(mappedData)
          .eq('profile_id', profileId);
    } catch (e) {
      debugPrint('Error updating user data: $e');
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
