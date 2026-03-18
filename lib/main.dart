import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'theme/app_theme.dart';
import 'services/peak_monitor_service.dart';
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  // Initialize notification service
  await LocalNotificationService().init();

  runApp(const MyApp());
}

// Global peak monitor instance
PeakMonitorService? _globalPeakMonitor;

void startPeakMonitor(BuildContext context) {
  if (_globalPeakMonitor != null) return;
  final firebaseService = Provider.of<FirebaseService>(context, listen: false);
  _globalPeakMonitor = PeakMonitorService(firebaseService, LocalNotificationService());
  _globalPeakMonitor?.start();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirebaseService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Builder(
        builder: (context) {
          // Start peak monitor globally
          startPeakMonitor(context);
          return Consumer<ThemeService>(
            builder: (context, themeService, child) {
              return MaterialApp(
                title: 'Energy Monitor',
                theme: AppTheme.lightTheme,
                debugShowCheckedModeBanner: false,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeService.themeMode,
                home: const AuthWrapper(),
                routes: {
                  '/login': (context) => const LoginScreen(),
                  '/register': (context) => const RegisterScreen(),
                  '/forgot-password': (context) => const ForgotPasswordScreen(),
                  '/dashboard': (context) => const DashboardScreen(),
                },
              );
            },
          );
        },
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