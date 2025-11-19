// lib/main.dart
import 'package:ev_smart_screen/splash_screen.dart'; // We will create this next
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EV Smart Screen',
      debugShowCheckedModeBanner: false, // Hides the "debug" banner
      theme: ThemeData.dark().copyWith(
        // Using a dark theme as a base for an EV screen
        scaffoldBackgroundColor: const Color(0xFF0F1B2B),
        primaryColor: Colors.blueAccent,
      ),
      home: const SplashScreen(), // This is the first screen the user sees
    );
  }
}
