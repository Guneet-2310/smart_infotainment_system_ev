// lib/services/platform_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Platform detection and configuration service.
/// 
/// Provides platform-specific settings for WebSocket URLs, mock data flags,
/// and hardware capabilities. Singleton pattern ensures consistent detection
/// across the app.
/// 
/// Example:
/// ```dart
/// final platform = PlatformService.instance;
/// if (platform.isWindows) {
///   // Use mock data for development
/// } else if (platform.isRaspberryPi) {
///   // Use real hardware
/// }
/// ```
class PlatformService {
  // Singleton instance
  static final PlatformService _instance = PlatformService._internal();
  static PlatformService get instance => _instance;

  // Platform flags (computed once at startup)
  late final bool isWindows;
  late final bool isLinux;
  late final bool isRaspberryPi;
  late final bool isLinuxDesktop;
  late final bool isMacOS;
  late final bool isAndroid;
  late final bool isIOS;
  late final bool isMobile;
  late final bool isDesktop;
  late final bool isWeb;

  // Configuration
  late final String backendWebSocketUrl;
  late final bool shouldUseMockData;
  late final bool shouldUseMockGPS;

  PlatformService._internal() {
    _detectPlatform();
    _loadConfiguration();
  }

  /// Detect the current platform
  void _detectPlatform() {
    // Check if running on web
    isWeb = kIsWeb;

    if (isWeb) {
      // Web platform
      isWindows = false;
      isLinux = false;
      isRaspberryPi = false;
      isLinuxDesktop = false;
      isMacOS = false;
      isAndroid = false;
      isIOS = false;
      isMobile = false;
      isDesktop = false;
      return;
    }

    // Detect OS
    isWindows = Platform.isWindows;
    isLinux = Platform.isLinux;
    isMacOS = Platform.isMacOS;
    isAndroid = Platform.isAndroid;
    isIOS = Platform.isIOS;

    // Categorize
    isMobile = isAndroid || isIOS;
    isDesktop = isWindows || isMacOS || isLinux;

    // Detect Raspberry Pi specifically (only on Linux)
    if (isLinux) {
      isRaspberryPi = _detectRaspberryPi();
      isLinuxDesktop = !isRaspberryPi;
    } else {
      isRaspberryPi = false;
      isLinuxDesktop = false;
    }
  }

  /// Detect if running on Raspberry Pi hardware
  /// 
  /// Checks /proc/cpuinfo for Raspberry Pi identifiers:
  /// - Hardware: BCM2XXX
  /// - Model: Raspberry Pi
  bool _detectRaspberryPi() {
    try {
      final cpuInfo = File('/proc/cpuinfo');
      if (!cpuInfo.existsSync()) {
        return false;
      }

      final content = cpuInfo.readAsStringSync().toLowerCase();

      // Check for Raspberry Pi markers
      final isRPi = content.contains('raspberry pi') ||
          content.contains('bcm27') ||
          content.contains('bcm28') ||
          content.contains('bcm2835') ||
          content.contains('bcm2836') ||
          content.contains('bcm2837') ||
          content.contains('bcm2711');

      return isRPi;
    } catch (e) {
      // If we can't read /proc/cpuinfo, assume not a Pi
      return false;
    }
  }

  /// Load platform-specific configuration from .env
  void _loadConfiguration() {
    // Determine WebSocket URL based on platform
    if (isWindows) {
      backendWebSocketUrl = dotenv.env['BACKEND_URL_WINDOWS'] ?? 'ws://localhost:8765';
    } else if (isRaspberryPi) {
      backendWebSocketUrl = dotenv.env['BACKEND_URL_PI'] ?? 'ws://localhost:8765';
    } else if (isMobile) {
      backendWebSocketUrl = dotenv.env['BACKEND_URL_MOBILE'] ?? 'ws://192.168.1.100:8765';
    } else if (isLinuxDesktop) {
      backendWebSocketUrl = dotenv.env['BACKEND_URL_LINUX'] ?? 'ws://localhost:8765';
    } else if (isMacOS) {
      backendWebSocketUrl = dotenv.env['BACKEND_URL_MAC'] ?? 'ws://localhost:8765';
    } else {
      backendWebSocketUrl = 'ws://localhost:8765'; // Default fallback
    }

    // Mock data flags
    final forceMock = dotenv.env['ENABLE_MOCK_MODE']?.toLowerCase() == 'true';
    shouldUseMockData = forceMock || isWindows;

    final forceMockGPS = dotenv.env['ENABLE_MOCK_GPS']?.toLowerCase() == 'true';
    shouldUseMockGPS = forceMockGPS;
  }

  /// Get a human-readable platform description
  String get platformName {
    if (isRaspberryPi) return 'Raspberry Pi';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinuxDesktop) return 'Linux Desktop';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWeb) return 'Web';
    return 'Unknown';
  }

  /// Get platform details for debugging
  Map<String, dynamic> get platformDetails => {
        'name': platformName,
        'isWindows': isWindows,
        'isLinux': isLinux,
        'isRaspberryPi': isRaspberryPi,
        'isLinuxDesktop': isLinuxDesktop,
        'isMacOS': isMacOS,
        'isAndroid': isAndroid,
        'isIOS': isIOS,
        'isMobile': isMobile,
        'isDesktop': isDesktop,
        'isWeb': isWeb,
        'backendUrl': backendWebSocketUrl,
        'useMockData': shouldUseMockData,
        'useMockGPS': shouldUseMockGPS,
      };

  /// Print platform information (for debugging)
  void printPlatformInfo() {
    print('=== Platform Detection ===');
    print('Platform: $platformName');
    print('Backend URL: $backendWebSocketUrl');
    print('Use Mock Data: $shouldUseMockData');
    print('Use Mock GPS: $shouldUseMockGPS');
    print('Details: $platformDetails');
    print('========================');
  }
}
