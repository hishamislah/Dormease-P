// ignore_for_file: use_build_context_synchronously

import 'package:dormease/helper/ui_elements.dart';
import 'package:dormease/services/supabase_auth_service.dart';
import 'package:dormease/services/supabase_admin_service.dart';
import 'package:dormease/providers/data_provider.dart';
import 'package:dormease/views/home/home_screen.dart';
import 'package:dormease/views/on_boarding/business_details.dart';
import 'package:dormease/views/admin/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var emailValid = true;
  var passwordValid = true;
  var isLoading = false;
  final SupabaseAuthService _authService = SupabaseAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset('assets/images/logo.png', height: 150, width: 150),
              const Text("Welcome to DormEase",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              const Text("Login with your email and password",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 32, 8, 16),
                child: Column(
                  children: [
                    InputText(
                      controller: emailController,
                      keyboard: TextInputType.emailAddress,
                      hint: "Email",
                      valid: emailValid,
                      error: "Please enter a valid email",
                      updateValid: (bool isValid) {
                        setState(() {
                          emailValid = isValid;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    InputText(
                      controller: passwordController,
                      keyboard: TextInputType.visiblePassword,
                      hint: "Password",
                      isPassword: true,
                      valid: passwordValid,
                      error: "Password must be at least 6 characters",
                      updateValid: (bool isValid) {
                        setState(() {
                          passwordValid = isValid;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ExpandedButton(
                    label: "Login",
                    onPressed: () async {
                      if (emailController.text.isEmpty) {
                        setState(() { emailValid = false; });
                        return;
                      }
                      if (passwordController.text.isEmpty) {
                        setState(() { passwordValid = false; });
                        return;
                      }
                      
                      setState(() { isLoading = true; });
                      
                      try {
                        String email = emailController.text.trim();
                        String password = passwordController.text.trim();
                        
                        // Check if admin credentials (super admin bypasses Supabase auth)
                        if (SupabaseAdminService.checkAdminCredentials(email, password)) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', true);
                          await prefs.setBool('isAdmin', true);
                          
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminDashboard()),
                            (route) => false,
                          );
                          return;
                        }
                        
                        // Regular user sign in using Supabase Auth
                        await _authService.signInWithPassword(email, password);
                        
                        // Save login status
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('isLoggedIn', true);
                        await prefs.setBool('isAdmin', false);
                        
                        // Reconnect data provider to fetch data for this user's organization
                        await context.read<DataProvider>().reconnect();
                        
                        bool hasBusinessInfo = await _authService.hasCompletedBusinessInfo();
                        
                        if (hasBusinessInfo) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                            (route) => false,
                          );
                        } else {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BusinessDetails(email: email),
                            ),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Login failed: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() { isLoading = false; });
                      }
                    },
                    isLoading: isLoading),
              )
            ]),
          ),
        ),
      ),
    );
  }
}