import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Sign in with email and password using Supabase Auth
  Future<User> signInWithPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Login failed: No user returned');
      }
      
      return response.user!;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }
  
  // Sign up with email and password using Supabase Auth
  Future<User> signUpWithPassword(String email, String password, {Map<String, dynamic>? metadata}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      
      if (response.user == null) {
        throw Exception('Sign up failed: No user returned');
      }
      
      return response.user!;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }
  
  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
  
  // Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }
  
  // Get current profile ID (from profiles table)
  Future<String?> getCurrentProfileId() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    
    try {
      final result = await _supabase
          .from('profiles')
          .select('profile_id')
          .eq('user_id', userId)
          .maybeSingle();
      
      return result?['profile_id'];
    } catch (e) {
      debugPrint('Error getting profile ID: $e');
      return null;
    }
  }
  
  // Check if business info is completed
  Future<bool> hasCompletedBusinessInfo() async {
    final userId = getCurrentUserId();
    if (userId == null) return false;
    
    try {
      final result = await _supabase
          .from('profiles')
          .select('has_completed_business_info')
          .eq('user_id', userId)
          .maybeSingle();
      
      return result?['has_completed_business_info'] ?? false;
    } catch (e) {
      debugPrint('Error checking business info: $e');
      return false;
    }
  }
  
  // Update business info completion status
  Future<void> setBusinessInfoCompleted(bool completed) async {
    final userId = getCurrentUserId();
    if (userId == null) return;
    
    await _supabase
        .from('profiles')
        .update({'has_completed_business_info': completed})
        .eq('user_id', userId);
  }

  // Get current organization ID
  Future<String?> getCurrentOrganizationId() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    try {
      final membership = await _supabase
          .from('organization_members')
          .select('organization_id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      return membership?['organization_id']?.toString();
    } catch (e) {
      debugPrint('Error getting organization ID: $e');
      return null;
    }
  }

  // Check if user has an organization
  Future<bool> hasOrganization() async {
    final orgId = await getCurrentOrganizationId();
    return orgId != null;
  }
  
  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }
  
  // Check if user is currently signed in
  bool isSignedIn() {
    return _supabase.auth.currentUser != null;
  }
}
