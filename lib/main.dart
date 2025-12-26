import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'providers/user_provider.dart';
import 'providers/data_provider.dart';
import 'views/on_boarding/splash_screen.dart';
import 'views/on_boarding/on_boarding.dart';
import 'translations/codegen_loader.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add error handling for the entire app
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };
  
  try {
    await EasyLocalization.ensureInitialized();
  } catch (e) {
    debugPrint('EasyLocalization init error: $e');
  }
  
  try {
    await Supabase.initialize(
      url: 'https://bjvxjaqlelsmuhmtqync.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqdnhqYXFsZWxzbXVobXRxeW5jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1OTUxNDYsImV4cCI6MjA4MjE3MTE0Nn0.oUP4e6EwHx5m7mXaVzNVyeFYgNAbOxypHzxn1JNFo2c',
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: const CodegenLoader(),
      child: const DormEase(),
    ),
  );
}

class DormEase extends StatelessWidget {
  const DormEase({super.key});

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
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const SplashScreen(),
        builder: (context, child) {
          // Wrap with error handler
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return Material(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const OnBoarding()),
                          (route) => false,
                        );
                      },
                      child: const Text('Restart App'),
                    ),
                  ],
                ),
              ),
            );
          };
          return child ?? const SizedBox();
        },
      ),
    );
  }
}
