import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Key for storing current user profile ID
  static const String currentProfileKey = 'current_profile_id';

  // Get or create a user profile
  Future<String> createUserProfile(String profileEmail) async {
    try {
      // Check if profile already exists for this email
      final existingProfile = await _supabase
          .from('profiles')
          .select('profile_id')
          .eq('email', profileEmail)
          .maybeSingle();
      
      if (existingProfile != null) {
        // Save current profile ID
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(currentProfileKey, existingProfile['profile_id']);
        return existingProfile['profile_id'];
      }
      
      // Generate a unique profile ID
      String profileId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create profile document
      await _supabase.from('profiles').insert({
        'profile_id': profileId,
        'email': profileEmail,
        'has_completed_business_info': false,
      });
      
      // Save current profile ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(currentProfileKey, profileId);
      
      return profileId;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }
  
  // Find profile by email
  Future<String?> findProfileByEmail(String email) async {
    try {
      final result = await _supabase
          .from('profiles')
          .select('profile_id')
          .eq('email', email)
          .maybeSingle();
      
      return result?['profile_id'];
    } catch (e) {
      debugPrint('Error finding profile by email: $e');
      return null;
    }
  }
  
  // Get current profile ID
  Future<String?> getCurrentProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(currentProfileKey);
  }
  
  // Set current profile ID
  Future<void> setCurrentProfileId(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(currentProfileKey, profileId);
  }
  
  // Check if business info is completed
  Future<bool> hasCompletedBusinessInfo() async {
    String? profileId = await getCurrentProfileId();
    if (profileId == null) return false;
    
    try {
      final result = await _supabase
          .from('profiles')
          .select('has_completed_business_info')
          .eq('profile_id', profileId)
          .single();
      
      return result['has_completed_business_info'] ?? false;
    } catch (e) {
      debugPrint('Error checking business info: $e');
      return false;
    }
  }
  
  // Update business info completion status
  Future<void> setBusinessInfoCompleted(bool completed) async {
    String? profileId = await getCurrentProfileId();
    if (profileId == null) return;
    
    await _supabase
        .from('profiles')
        .update({'has_completed_business_info': completed})
        .eq('profile_id', profileId);
  }
  
  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(currentProfileKey);
    await prefs.setBool('isLoggedIn', false);
  }
}
