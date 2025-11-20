// lib/services/config_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration service.
/// 
/// Provides typed access to all configuration values from the .env file.
/// Validates and parses environment variables with appropriate defaults.
/// 
/// Example:
/// ```dart
/// final config = ConfigService.instance;
/// final mapboxToken = config.mapboxAccessToken;
/// final backend = config.backendWebSocketUrl;
/// ```
class ConfigService {
  // Singleton instance
  static final ConfigService _instance = ConfigService._internal();
  static ConfigService get instance => _instance;

  ConfigService._internal();

  // ============================================================================
  // BACKEND CONFIGURATION
  // ============================================================================

  /// Default backend WebSocket URL (overridden by platform-specific URLs)
  String get backendWebSocketUrl => 
      _getString('BACKEND_URL', 'ws://localhost:8765');

  /// Windows-specific backend URL
  String get backendUrlWindows => 
      _getString('BACKEND_URL_WINDOWS', 'ws://localhost:8765');

  /// Raspberry Pi backend URL
  String get backendUrlPi => 
      _getString('BACKEND_URL_PI', 'ws://localhost:8765');

  /// Linux desktop backend URL
  String get backendUrlLinux => 
      _getString('BACKEND_URL_LINUX', 'ws://localhost:8765');

  /// macOS backend URL
  String get backendUrlMac => 
      _getString('BACKEND_URL_MAC', 'ws://localhost:8765');

  /// Mobile backend URL (for testing on phones/tablets)
  String get backendUrlMobile => 
      _getString('BACKEND_URL_MOBILE', 'ws://192.168.1.100:8765');

  // ============================================================================
  // MAPBOX CONFIGURATION
  // ============================================================================

  /// Mapbox access token (required for maps)
  String get mapboxAccessToken => 
      _getString('MAPBOX_ACCESS_TOKEN', '');

  /// Mapbox style URL for map appearance
  String get mapboxStyleUrl => 
      _getString('MAPBOX_STYLE_URL', 'mapbox://styles/mapbox/dark-v11');

  // ============================================================================
  // MOCK DATA CONFIGURATION
  // ============================================================================

  /// Enable mock mode for development/testing
  bool get enableMockMode => 
      _getBool('ENABLE_MOCK_MODE', false);

  /// Enable mock GPS data
  bool get enableMockGps => 
      _getBool('ENABLE_MOCK_GPS', false);

  /// Enable mock CAN bus data
  bool get enableMockCan => 
      _getBool('ENABLE_MOCK_CAN', false);

  /// Enable mock vehicle sensors
  bool get enableMockSensors => 
      _getBool('ENABLE_MOCK_SENSORS', false);

  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================

  /// Enable navigation features
  bool get enableNavigation => 
      _getBool('ENABLE_NAVIGATION', true);

  /// Enable media player features
  bool get enableMedia => 
      _getBool('ENABLE_MEDIA', true);

  /// Enable climate control features
  bool get enableClimate => 
      _getBool('ENABLE_CLIMATE', true);

  /// Enable vehicle settings
  bool get enableVehicleSettings => 
      _getBool('ENABLE_VEHICLE_SETTINGS', true);

  /// Enable charging management
  bool get enableCharging => 
      _getBool('ENABLE_CHARGING', true);

  // ============================================================================
  // HARDWARE CONFIGURATION
  // ============================================================================

  /// CAN bus interface (e.g., can0, vcan0)
  String get canInterface => 
      _getString('CAN_INTERFACE', 'can0');

  /// GPS device path (e.g., /dev/ttyUSB0)
  String get gpsDevice => 
      _getString('GPS_DEVICE', '/dev/ttyUSB0');

  /// GPS baud rate
  int get gpsBaudRate => 
      _getInt('GPS_BAUD_RATE', 9600);

  // ============================================================================
  // UI CONFIGURATION
  // ============================================================================

  /// UI theme mode (light, dark, auto)
  String get themeMode => 
      _getString('THEME_MODE', 'dark');

  /// Enable animations
  bool get enableAnimations => 
      _getBool('ENABLE_ANIMATIONS', true);

  /// Screen brightness (0.0 - 1.0)
  double get screenBrightness => 
      _getDouble('SCREEN_BRIGHTNESS', 0.8);

  // ============================================================================
  // LOGGING & DEBUG
  // ============================================================================

  /// Log level (debug, info, warning, error)
  String get logLevel => 
      _getString('LOG_LEVEL', 'info');

  /// Enable verbose logging
  bool get enableVerboseLogging => 
      _getBool('ENABLE_VERBOSE_LOGGING', false);

  /// Enable performance monitoring
  bool get enablePerformanceMonitoring => 
      _getBool('ENABLE_PERFORMANCE_MONITORING', false);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get string value from .env with fallback
  String _getString(String key, String defaultValue) {
    return dotenv.env[key] ?? defaultValue;
  }

  /// Get boolean value from .env with fallback
  bool _getBool(String key, bool defaultValue) {
    final value = dotenv.env[key]?.toLowerCase();
    if (value == null) return defaultValue;
    return value == 'true' || value == '1' || value == 'yes';
  }

  /// Get integer value from .env with fallback
  int _getInt(String key, int defaultValue) {
    final value = dotenv.env[key];
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// Get double value from .env with fallback
  double _getDouble(String key, double defaultValue) {
    final value = dotenv.env[key];
    if (value == null) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  /// Check if a configuration key exists
  bool hasKey(String key) {
    return dotenv.env.containsKey(key);
  }

  /// Get raw value from .env (returns null if not found)
  String? getRaw(String key) {
    return dotenv.env[key];
  }

  /// Get all configuration as a map (for debugging)
  Map<String, dynamic> get allConfig => {
        'backend': {
          'url': backendWebSocketUrl,
          'windows': backendUrlWindows,
          'pi': backendUrlPi,
          'linux': backendUrlLinux,
          'mac': backendUrlMac,
          'mobile': backendUrlMobile,
        },
        'mapbox': {
          'token': mapboxAccessToken.isNotEmpty ? '***${mapboxAccessToken.substring(mapboxAccessToken.length - 8)}' : 'NOT_SET',
          'styleUrl': mapboxStyleUrl,
        },
        'mock': {
          'enableMode': enableMockMode,
          'enableGps': enableMockGps,
          'enableCan': enableMockCan,
          'enableSensors': enableMockSensors,
        },
        'features': {
          'navigation': enableNavigation,
          'media': enableMedia,
          'climate': enableClimate,
          'vehicleSettings': enableVehicleSettings,
          'charging': enableCharging,
        },
        'hardware': {
          'canInterface': canInterface,
          'gpsDevice': gpsDevice,
          'gpsBaudRate': gpsBaudRate,
        },
        'ui': {
          'themeMode': themeMode,
          'enableAnimations': enableAnimations,
          'screenBrightness': screenBrightness,
        },
        'logging': {
          'logLevel': logLevel,
          'verboseLogging': enableVerboseLogging,
          'performanceMonitoring': enablePerformanceMonitoring,
        },
      };

  /// Print all configuration (for debugging)
  void printConfig() {
    print('=== Configuration ===');
    print('Backend URL: $backendWebSocketUrl');
    print('Mapbox Token: ${mapboxAccessToken.isNotEmpty ? "SET" : "NOT SET"}');
    print('Mock Mode: $enableMockMode');
    print('Mock GPS: $enableMockGps');
    print('Features: Navigation=$enableNavigation, Media=$enableMedia, Climate=$enableClimate');
    print('Log Level: $logLevel');
    print('==================');
  }
}
