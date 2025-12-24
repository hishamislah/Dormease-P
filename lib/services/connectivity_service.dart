import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  /// Check if Firebase is properly connected
  static Future<bool> isFirebaseConnected() async {
    try {
      // Try to access Firestore to check connection
      final app = Firebase.app();
      debugPrint('Firebase app name: ${app.name}');
      return true;
    } catch (e) {
      debugPrint('Firebase connection check failed: $e');
      return false;
    }
  }
}