import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      // Use platform-default config (google-services.json / GoogleService-Info.plist)
      await Firebase.initializeApp();
    }
  } catch (e) {
    // ignore duplicate-init or other non-fatal init errors
    debugPrint('Firebase init skipped: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirebaseService()),
      ],
      child: MaterialApp(
        title: 'Energy Monitor',
        theme: AppTheme.lightTheme,
         debugShowCheckedModeBanner: false, 
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return authService.currentUser != null
            ? const DashboardScreen()
            : const LoginScreen();
      },
    );
  }
}