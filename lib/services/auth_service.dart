import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Fixed account email for Firebase authentication
  static const String fixedEmail = 'islahsa@gmail.com';
  static const String fixedPassword = 'Password@123'; // Updated with stronger password
  
  // Key for storing current user profile ID
  static const String currentProfileKey = 'current_profile_id';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with fixed account
  Future<UserCredential?> signInWithFixedAccount() async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: fixedEmail,
        password: fixedPassword
      );
    } catch (e) {
      debugPrint('Error signing in with fixed account: $e');
      // If we can't sign in, we'll work with anonymous data
      return null;
    }
  }

  // Ensure fixed account exists or create it
  Future<UserCredential> ensureFixedAccountExists() async {
    try {
      // Try to sign in with fixed account
      UserCredential? userCredential = await signInWithFixedAccount();
      if (userCredential == null) {
        throw Exception('Failed to sign in with fixed account');
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // If user doesn't exist, create it
      if (e.code == 'user-not-found') {
        try {
          UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
            email: fixedEmail,
            password: fixedPassword,
          );
          
          // Create user document in Firestore
          await _createUserDocument(userCredential.user!.uid, fixedEmail);
          
          // Save login status
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          
          return userCredential;
        } catch (createError) {
          debugPrint('Error creating fixed account: $createError');
          throw _handleAuthException(createError as FirebaseAuthException);
        }
      } else {
        debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
        throw _handleAuthException(e);
      }
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(String uid, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'hasCompletedBusinessInfo': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Find profile by email
  Future<String?> findProfileByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('profiles')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('Error finding profile by email: $e');
      return null;
    }
  }
  
  // Get or create a user profile under the fixed account
  Future<String> createUserProfile(String profileEmail) async {
    try {
      // Ensure we're using the fixed account
      if (_auth.currentUser == null || _auth.currentUser!.email != fixedEmail) {
        await signInWithFixedAccount();
      }
      
      // Check if profile already exists for this email
      String? existingProfileId = await findProfileByEmail(profileEmail);
      if (existingProfileId != null) {
        // Save current profile ID
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(currentProfileKey, existingProfileId);
        return existingProfileId;
      }
      
      // Generate a unique profile ID
      String profileId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create profile document
      await _firestore.collection('profiles').doc(profileId).set({
        'profileId': profileId,
        'email': profileEmail,
        'hasCompletedBusinessInfo': false,
        'createdAt': FieldValue.serverTimestamp(),
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

  // Check if user has completed business info
  Future<bool> hasCompletedBusinessInfo() async {
    try {
      // Check if we have saved this info in SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('hasCompletedBusinessInfo')) {
        return prefs.getBool('hasCompletedBusinessInfo') ?? false;
      }
      
      // If not in SharedPreferences, check Firestore
      String? profileId = await getCurrentProfileId();
      if (profileId == null) return false;
      
      DocumentSnapshot doc = await _firestore.collection('profiles').doc(profileId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bool completed = data['hasCompletedBusinessInfo'] ?? false;
        
        // Save to SharedPreferences for future quick access
        await prefs.setBool('hasCompletedBusinessInfo', completed);
        
        return completed;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking business info: $e');
      return false;
    }
  }

  // Update business info completion status
  Future<void> updateBusinessInfoStatus(bool status) async {
    try {
      String? profileId = await getCurrentProfileId();
      if (profileId == null) return;
      
      await _firestore.collection('profiles').doc(profileId).update({
        'hasCompletedBusinessInfo': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Also update in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedBusinessInfo', status);
    } catch (e) {
      debugPrint('Error updating business info status: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    // First check if current user exists
    if (_auth.currentUser != null) {
      return true;
    }
    
    // Then check shared preferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await _auth.signOut();
  }
  
  // Auto login with fixed account
  Future<bool> autoLogin() async {
    try {
      if (await isLoggedIn()) {
        if (_auth.currentUser == null) {
          await signInWithFixedAccount();
        }
        return true; // Consider logged in even if Firebase auth fails
      }
      return false; // Not logged in previously
    } catch (e) {
      debugPrint('Auto login error: $e');
      return false;
    }
  }
  
  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The email address is already in use.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}