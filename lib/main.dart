// lib/main.dart
import 'package:ev_smart_screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ev_smart_screen/services/platform_service.dart';
import 'package:ev_smart_screen/services/config_service.dart';
import 'package:ev_smart_screen/services/config_validator.dart';
import 'package:ev_smart_screen/services/logger_service.dart';
import 'package:ev_smart_screen/services/gps_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Initialize and validate platform detection
    final platform = PlatformService.instance;
    platform.printPlatformInfo();
    
    // Initialize logger
    await AppLogger.initialize();
    
    // Initialize configuration service
    final config = ConfigService.instance;
    config.printConfig();
    
    // Validate configuration
    final validation = ConfigValidator.validate();
    print(validation);
    
    // Check for critical errors
    if (!validation.isValid) {
      // Show error dialog and prevent app from starting
      runApp(_ErrorApp(validation: validation));
      return;
    }
    
    // Initialize GPS service (Phase 3)
    await GPSService.instance.initialize();

    // Start the app normally
    runApp(const MyApp());
    
  } catch (e, stackTrace) {
    // Handle initialization errors
    print('❌ FATAL ERROR during initialization:');
    print(e);
    print(stackTrace);
    
    runApp(_ErrorApp(
      validation: ValidationResult(
        isValid: false,
        errors: ['Failed to initialize app: $e'],
        warnings: [],
      ),
    ));
  }
}

/// Error app shown when configuration validation fails
class _ErrorApp extends StatelessWidget {
  final ValidationResult validation;

  const _ErrorApp({required this.validation});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EV Smart Screen - Configuration Error',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F1B2B),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Configuration Error',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The application failed to start due to configuration errors. '
                  'Please fix the following issues:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (validation.hasErrors) ...[
                            const Text(
                              'ERRORS:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...validation.errors.map((error) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('❌ ', style: TextStyle(fontSize: 16)),
                                      Expanded(
                                        child: Text(
                                          error,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                          if (validation.hasWarnings) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'WARNINGS:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...validation.warnings.map((warning) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('⚠️  ', style: TextStyle(fontSize: 16)),
                                      Expanded(
                                        child: Text(
                                          warning,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Please check your .env file and restart the application.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
