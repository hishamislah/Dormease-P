import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  final bool isConnecting;
  
  const LoadingScreen({super.key, this.isConnecting = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 100,
              width: 100,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              isConnecting 
                ? 'Connecting to Firebase...'
                : 'Loading data from Firebase...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}