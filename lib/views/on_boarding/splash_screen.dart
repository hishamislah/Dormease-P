// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dormease/services/auth_service.dart';
import 'package:dormease/views/home/home_screen.dart';
import 'package:dormease/views/on_boarding/on_boarding.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }
  
  Future<void> _navigateToOnboarding() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    try {
      // Check if user is already logged in
      if (isLoggedIn) {
        // Check if we have a current profile
        String? profileId = prefs.getString(AuthService.currentProfileKey);
        
        if (profileId != null) {
          // Verify the profile exists
          final firestore = FirebaseFirestore.instance;
          final profileDoc = await firestore.collection('profiles').doc(profileId).get();
          
          if (profileDoc.exists) {
            // User has logged in before, go directly to home screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false
            );
            return;
          }
        }
        
        // No valid profile, show onboarding
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnBoarding()),
          (route) => false
        );
      } else {
        // First time user, show onboarding
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnBoarding()),
          (route) => false
        );
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Fallback to onboarding on error
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OnBoarding()),
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset("assets/images/logo.png", height: 200, width: 200),
          const SizedBox(height: 20),
          const Text('DormEase', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Hostel & PG Management', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ]),
      ),
    );
  }
}