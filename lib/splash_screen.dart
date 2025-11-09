// lib/splash_screen.dart
import 'dart:async';
import 'package:ev_smart_screen/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart'; // Import the new package

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
    // Wait for 3-4 seconds, then navigate
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
    // Get the total screen size
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      // Use the dark background color from main.dart
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        // This box constrains the content as you requested
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenSize.width * 0.5, // Not more than 50% width
            maxHeight: screenSize.height * 0.5, // Not more than 50% height
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Make column only as tall as its children
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Your BMU Image
              Image.asset('assets/images/bmu.png'),

              const SizedBox(height: 32), // Space between image and loader
              // 2. The progressive dots loader
              const SizedBox(
                width: 100, // Give the loader a set width
                child: LoadingIndicator(
                  // This is a nice progressive dot-style animation
                  indicatorType: Indicator.lineScaleParty,
                  colors: [Colors.blueAccent],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
