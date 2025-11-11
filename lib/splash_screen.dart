// lib/splash_screen.dart
import 'dart:async';
import 'package:ev_smart_screen/main_screen.dart';
import 'package:flutter/material.dart';
// We no longer need the loading_indicator package here

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    startTimer();
  }

  startTimer() {
    // Wait for 4 seconds, then navigate
    var duration = const Duration(seconds: 4);
    return Timer(duration, navigateToHome);
  }

  navigateToHome() {
    // Replace the SplashScreen with the MainScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This is the new, simple build method.
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // Center widget will center its child horizontally and vertically.
      body: Center(
        child: Image.asset(
          'assets/images/bmu.png',

          // We constrain the HEIGHT to 50% of the screen.
          // This will prevent all vertical overflow errors.
          // The image's width will scale down automatically.
          height: MediaQuery.of(context).size.height * 0.5,

          // This ensures the image scales down nicely within the box
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
