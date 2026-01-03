// ignore_for_file: use_build_context_synchronously

import 'package:dormease/services/supabase_auth_service.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/views/home/home_screen.dart';
import 'package:dormease/views/on_boarding/on_boarding.dart';
import 'package:dormease/views/admin/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToOnboarding();
    });
  }
  
  Future<void> _navigateToOnboarding() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (e) {
        debugPrint('SharedPreferences error: $e');
      }
      
      final bool isLoggedIn = prefs?.getBool('isLoggedIn') ?? false;
      
      // Check if user is already logged in
      if (isLoggedIn) {
        try {
          final authService = SupabaseAuthService();
          
          // Check if admin user (admin doesn't require Supabase auth)
          final isAdmin = prefs?.getBool('isAdmin') ?? false;
          if (isAdmin && mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
              (route) => false
            );
            return;
          }
          
          // Check if user is authenticated with Supabase
          if (authService.isSignedIn()) {
            // Check if they have completed business info
            bool hasBusinessInfo = await authService.hasCompletedBusinessInfo();
            
            if (hasBusinessInfo && mounted) {
              // Reconnect data provider to fetch data for this user's organization
              await context.read<DataProvider>().reconnect();
              
              // User has logged in before, go directly to home screen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false
              );
              return;
            }
          }
        } catch (e) {
          debugPrint('Auth check error: $e');
        }
      }
      
      // First time user or error, show onboarding
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnBoarding()),
          (route) => false
        );
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Fallback to onboarding on error
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnBoarding()),
          (route) => false
        );
      }
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