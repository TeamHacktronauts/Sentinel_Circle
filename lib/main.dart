import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentinel_circle/core/theme_provider.dart';
import 'package:sentinel_circle/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp();
  
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initializeNotifications();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SentinelCircleApp(),
    ),
  );
}
