// lib/services/config_validator.dart
import 'package:ev_smart_screen/services/config_service.dart';
import 'package:ev_smart_screen/services/platform_service.dart';

/// Configuration validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== Configuration Validation ===');
    buffer.writeln('Valid: $isValid');
    
    if (hasErrors) {
      buffer.writeln('\nERRORS:');
      for (var error in errors) {
        buffer.writeln('  ❌ $error');
      }
    }
    
    if (hasWarnings) {
      buffer.writeln('\nWARNINGS:');
      for (var warning in warnings) {
        buffer.writeln('  ⚠️  $warning');
      }
    }
    
    if (!hasErrors && !hasWarnings) {
      buffer.writeln('✅ All configuration checks passed!');
    }
    
    buffer.writeln('==============================');
    return buffer.toString();
  }
}

/// Configuration validator.
/// 
/// Validates all required configuration at app startup and provides
/// clear error messages for missing or invalid values.
/// 
/// Example:
/// ```dart
/// final result = ConfigValidator.validate();
/// if (!result.isValid) {
///   print(result);
///   // Show error dialog or exit
/// }
/// ```
class ConfigValidator {
  static final List<String> _errors = [];
  static final List<String> _warnings = [];

  /// Validate all configuration
  static ValidationResult validate() {
    _errors.clear();
    _warnings.clear();

    final config = ConfigService.instance;
    final platform = PlatformService.instance;

    // Validate backend configuration
    _validateBackend(config, platform);

    // Validate Mapbox configuration
    _validateMapbox(config);

    // Validate hardware configuration (only for Raspberry Pi)
    if (platform.isRaspberryPi) {
      _validateHardware(config);
    }

    // Validate feature flags
    _validateFeatures(config);

    // Validate UI configuration
    _validateUI(config);

    final isValid = _errors.isEmpty;
    return ValidationResult(
      isValid: isValid,
      errors: List.from(_errors),
      warnings: List.from(_warnings),
    );
  }

  /// Validate backend configuration
  static void _validateBackend(ConfigService config, PlatformService platform) {
    // Check if backend URL is set for current platform
    final backendUrl = platform.backendWebSocketUrl;
    
    if (backendUrl.isEmpty) {
      _errors.add('Backend URL is not configured for platform: ${platform.platformName}');
    } else if (!_isValidWebSocketUrl(backendUrl)) {
      _errors.add('Invalid backend WebSocket URL: $backendUrl (must start with ws:// or wss://)');
    }

    // Warn if using localhost on mobile
    if (platform.isMobile && backendUrl.contains('localhost')) {
      _warnings.add(
        'Backend URL uses localhost on mobile platform. '
        'This will not work unless using an emulator. '
        'Consider setting BACKEND_URL_MOBILE to your computer\'s IP address.'
      );
    }
  }

  /// Validate Mapbox configuration
  static void _validateMapbox(ConfigService config) {
    final token = config.mapboxAccessToken;
    
    if (token.isEmpty) {
      _errors.add(
        'Mapbox access token is not set. '
        'Please set MAPBOX_ACCESS_TOKEN in .env file. '
        'Get your token from https://account.mapbox.com/access-tokens/'
      );
    } else if (token.length < 50) {
      _warnings.add(
        'Mapbox access token seems too short. '
        'Valid tokens are typically 80+ characters. '
        'Please verify your token is correct.'
      );
    } else if (!token.startsWith('pk.') && !token.startsWith('sk.')) {
      _warnings.add(
        'Mapbox access token should start with "pk." (public) or "sk." (secret). '
        'Your token may be invalid.'
      );
    }

    final styleUrl = config.mapboxStyleUrl;
    if (!styleUrl.startsWith('mapbox://')) {
      _warnings.add(
        'Mapbox style URL should start with "mapbox://". '
        'Current value: $styleUrl'
      );
    }
  }

  /// Validate hardware configuration (Raspberry Pi only)
  static void _validateHardware(ConfigService config) {
    // CAN interface validation
    final canInterface = config.canInterface;
    if (canInterface.isEmpty) {
      _warnings.add('CAN interface is not configured (ENABLE_MOCK_CAN will be used)');
    } else if (!canInterface.startsWith('can') && !canInterface.startsWith('vcan')) {
      _warnings.add(
        'CAN interface "$canInterface" doesn\'t follow standard naming (can0, vcan0, etc.)'
      );
    }

    // GPS device validation
    final gpsDevice = config.gpsDevice;
    if (gpsDevice.isEmpty) {
      _warnings.add('GPS device is not configured (ENABLE_MOCK_GPS will be used)');
    } else if (!gpsDevice.startsWith('/dev/')) {
      _warnings.add(
        'GPS device "$gpsDevice" doesn\'t look like a valid device path (should start with /dev/)'
      );
    }

    // GPS baud rate validation
    final gpsBaudRate = config.gpsBaudRate;
    final validBaudRates = [4800, 9600, 19200, 38400, 57600, 115200];
    if (!validBaudRates.contains(gpsBaudRate)) {
      _warnings.add(
        'GPS baud rate $gpsBaudRate is unusual. '
        'Common values: ${validBaudRates.join(", ")}'
      );
    }
  }

  /// Validate feature flags
  static void _validateFeatures(ConfigService config) {
    // Warn if all features are disabled
    final hasAnyFeature = config.enableNavigation ||
        config.enableMedia ||
        config.enableClimate ||
        config.enableVehicleSettings ||
        config.enableCharging;

    if (!hasAnyFeature) {
      _warnings.add(
        'All features are disabled. '
        'Enable at least one feature in .env file (ENABLE_NAVIGATION, ENABLE_MEDIA, etc.)'
      );
    }
  }

  /// Validate UI configuration
  static void _validateUI(ConfigService config) {
    // Theme mode validation
    final themeMode = config.themeMode.toLowerCase();
    if (!['light', 'dark', 'auto'].contains(themeMode)) {
      _warnings.add(
        'Invalid theme mode: "$themeMode". '
        'Valid values: light, dark, auto. '
        'Defaulting to dark.'
      );
    }

    // Screen brightness validation
    final brightness = config.screenBrightness;
    if (brightness < 0.0 || brightness > 1.0) {
      _warnings.add(
        'Screen brightness $brightness is out of range. '
        'Must be between 0.0 and 1.0. '
        'Defaulting to 0.8.'
      );
    }

    // Log level validation
    final logLevel = config.logLevel.toLowerCase();
    if (!['debug', 'info', 'warning', 'error'].contains(logLevel)) {
      _warnings.add(
        'Invalid log level: "$logLevel". '
        'Valid values: debug, info, warning, error. '
        'Defaulting to info.'
      );
    }
  }

  /// Validate WebSocket URL format
  static bool _isValidWebSocketUrl(String url) {
    return url.startsWith('ws://') || url.startsWith('wss://');
  }

  /// Quick validation check (returns true if valid)
  static bool isValid() {
    return validate().isValid;
  }

  /// Print validation results
  static void printValidation() {
    print(validate());
  }
}
