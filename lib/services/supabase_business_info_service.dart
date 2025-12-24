import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';

class SupabaseBusinessInfoService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseAuthService _authService = SupabaseAuthService();

  // Fetch business info for current profile
  Future<Map<String, dynamic>?> fetchBusinessInfo() async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return null;

    try {
      final result = await _supabase
          .from('business_info')
          .select('*')
          .eq('profile_id', profileId)
          .maybeSingle();

      // Convert snake_case to camelCase for app use
      if (result != null) {
        return _mapToCamelCase(result);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching business info: $e');
      return null;
    }
  }

  // Set/update business info
  Future<void> setBusinessInfo(Map<String, dynamic> info) async {
    String? profileId = await _authService.getCurrentProfileId();
    if (profileId == null) return;

    try {
      // Check if business info already exists
      final existing = await _supabase
          .from('business_info')
          .select('id')
          .eq('profile_id', profileId)
          .maybeSingle();

      // Convert camelCase to snake_case
      final mappedInfo = _mapToSnakeCase(info);
      mappedInfo['profile_id'] = profileId;

      if (existing != null) {
        // Update existing
        await _supabase
            .from('business_info')
            .update(mappedInfo)
            .eq('profile_id', profileId);
      } else {
        // Insert new
        await _supabase.from('business_info').insert(mappedInfo);
      }
      
      // Update profile to mark business info as completed
      await _authService.setBusinessInfoCompleted(true);
    } catch (e) {
      debugPrint('Error setting business info: $e');
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

  // Helper method to convert snake_case to camelCase
  Map<String, dynamic> _mapToCamelCase(Map<String, dynamic> data) {
    final mapped = <String, dynamic>{};
    data.forEach((key, value) {
      // Convert snake_case to camelCase
      final camelKey = key.replaceAllMapped(
        RegExp(r'_([a-z])'),
        (match) => match.group(1)!.toUpperCase(),
      );
      mapped[camelKey] = value;
    });
    return mapped;
  }
}
