import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/home_screen.dart';
import 'screens/help_support_screen.dart';
import 'theme/theme.dart';
import 'core/theme_provider.dart';

class SentinelCircleApp extends StatelessWidget {
  const SentinelCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Use a default theme while loading
          final themeData = themeProvider.isDarkMode 
              ? AppTheme.darkTheme 
              : AppTheme.lightTheme;
          
          return MaterialApp(
            title: 'Sentinel Circle',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginPage(),
              '/signup': (context) => const SignupPage(),
              '/forgot-password': (context) => const ForgotPasswordPage(),
              '/home': (context) => const HomeScreen(),
              '/help-support': (context) => const HelpSupportScreen(),
            },
          );
        },
      ),
    );
  }
}
