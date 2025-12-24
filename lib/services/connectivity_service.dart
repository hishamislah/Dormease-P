import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectivityService {
  /// Check if Supabase is properly connected
  static Future<bool> isSupabaseConnected() async {
    try {
      // Try to access Supabase to check connection
      final client = Supabase.instance.client;
      // Perform a simple query to verify connection
      await client.from('profiles').select('id').limit(1);
      debugPrint('Supabase connected successfully');
      return true;
    } catch (e) {
      debugPrint('Supabase connection check failed: $e');
      return false;
    }
  }
  
  /// Legacy method for backward compatibility
  static Future<bool> isFirebaseConnected() async {
    return isSupabaseConnected();
  }
}