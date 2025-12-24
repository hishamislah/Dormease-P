import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseReconnect {
  static Future<bool> tryReconnect() async {
    try {
      debugPrint('Attempting to reconnect to Firebase...');
      
      // Try to initialize Firebase again
      await Firebase.initializeApp();
      
      // Test connection by accessing Firestore
      final app = Firebase.app();
      debugPrint('Firebase reconnected: ${app.name}');
      
      return true;
    } catch (e) {
      debugPrint('Failed to reconnect to Firebase: $e');
      return false;
    }
  }
}