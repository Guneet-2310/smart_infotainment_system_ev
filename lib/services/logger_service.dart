// lib/services/logger_service.dart
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ev_smart_screen/services/platform_service.dart';

/// Centralized logging service with level filtering and optional file output.
/// 
/// Usage:
/// ```dart
/// AppLogger.debug('Connecting to backend');
/// AppLogger.info('Connected successfully');
/// AppLogger.warning('Retrying connection', error: 'Timeout');
/// AppLogger.error('Connection failed', error: exception, stackTrace: stack);
/// ```
class AppLogger {
  static Logger? _logger;
  static File? _logFile;
  static final List<String> _logBuffer = [];
  static const int _maxBufferSize = 1000;

  /// Initialize the logger (call once at app startup)
  static Future<void> initialize() async {
    final levelStr = dotenv.env['LOG_LEVEL']?.toUpperCase() ?? 'INFO';
    final level = _parseLogLevel(levelStr);

    // On Raspberry Pi, enable file logging
    if (PlatformService.instance.isRaspberryPi) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final logDir = Directory('${directory.path}/logs');
        if (!logDir.existsSync()) {
          logDir.createSync(recursive: true);
        }
        
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        _logFile = File('${logDir.path}/app_$timestamp.log');
        
        // Rotate old logs (keep last 5)
        await _rotateLogFiles(logDir);
      } catch (e) {
        print('Failed to initialize log file: $e');
      }
    }

    _logger = Logger(
      filter: _CustomFilter(level),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTime,
      ),
      output: _MultiOutput(),
    );

    info('Logger initialized at level: $levelStr');
    info('Platform: ${PlatformService.instance.platformName}');
    if (_logFile != null) {
      info('Logging to file: ${_logFile!.path}');
    }
  }

  /// Parse log level string to Logger.Level
  static Level _parseLogLevel(String levelStr) {
    switch (levelStr) {
      case 'TRACE':
        return Level.trace;
      case 'DEBUG':
        return Level.debug;
      case 'INFO':
        return Level.info;
      case 'WARNING':
        return Level.warning;
      case 'ERROR':
        return Level.error;
      case 'FATAL':
        return Level.fatal;
      default:
        return Level.info;
    }
  }

  /// Rotate log files (keep last 5)
  static Future<void> _rotateLogFiles(Directory logDir) async {
    try {
      final files = logDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.log'))
          .toList();

      // Sort by modification time (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      // Delete all but the 5 most recent
      for (var i = 5; i < files.length; i++) {
        await files[i].delete();
      }
    } catch (e) {
      print('Log rotation failed: $e');
    }
  }

  // Logging methods
  static void trace(String message, {Object? error, StackTrace? stackTrace}) {
    _logger?.t(message, error: error, stackTrace: stackTrace);
  }

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _logger?.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message) {
    _logger?.i(message);
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger?.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {required Object error, StackTrace? stackTrace}) {
    _logger?.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(String message, {required Object error, StackTrace? stackTrace}) {
    _logger?.f(message, error: error, stackTrace: stackTrace);
  }

  /// Get recent logs (for in-app log viewer)
  static List<String> getRecentLogs() => List.from(_logBuffer);

  /// Clear log buffer
  static void clearLogs() => _logBuffer.clear();
}

/// Custom filter for log level filtering
class _CustomFilter extends LogFilter {
  final Level _level;

  _CustomFilter(this._level);

  @override
  bool shouldLog(LogEvent event) {
    return event.level.index >= _level.index;
  }
}

/// Custom output that writes to both console and file
class _MultiOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // Console output
    for (var line in event.lines) {
      print(line);
      
      // Buffer for in-app viewer
      AppLogger._logBuffer.add(line);
      if (AppLogger._logBuffer.length > AppLogger._maxBufferSize) {
        AppLogger._logBuffer.removeAt(0);
      }
      
      // File output (Pi only)
      if (AppLogger._logFile != null) {
        try {
          AppLogger._logFile!.writeAsStringSync(
            '$line\n',
            mode: FileMode.append,
            flush: true,
          );
        } catch (e) {
          // Silently fail file writes to avoid recursion
        }
      }
    }
  }
}
