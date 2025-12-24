import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/data_provider.dart';
import 'views/on_boarding/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Supabase.initialize(
      url: 'https://bjvxjaqlelsmuhmtqync.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqdnhqYXFsZWxzbXVobXRxeW5jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzUxMjUzNzgsImV4cCI6MjA1MDcwMTM3OH0.nGzZ8_bwL3tQqLGlVVPnPCFTNYKqOwGxd5eH7GJQNho',
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }
  
  runApp(DormEase());
}

class DormEase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: MaterialApp(
        title: 'DormEase',
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
