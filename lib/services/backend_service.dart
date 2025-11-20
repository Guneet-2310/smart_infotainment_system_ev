import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ev_smart_screen/services/logger_service.dart';

/// Backend service for WebSocket communication with Python backend
///
/// Handles real-time telemetry data and command execution
/// Author: Guneet Chawla
/// Connection status for backend WebSocket
enum BackendConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

class BackendService {
  // WebSocket URL - change based on environment
  static const String _wsUrl = 'ws://localhost:8765'; // Windows/same machine
  // For Raspberry Pi, use: 'ws://192.168.1.XXX:8765' (replace with Pi's IP)

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _telemetryController;
  bool _isConnected = false;
  BackendConnectionStatus _status = BackendConnectionStatus.disconnected;
  Timer? _mockTimer; // Fallback mock telemetry generator
  final Random _rand = Random();

  /// Stream of telemetry data from backend
  Stream<Map<String, dynamic>> get telemetryStream {
    // Ensure controller exists to avoid null crash
    if (_telemetryController == null || _telemetryController!.isClosed) {
      _telemetryController = StreamController<Map<String, dynamic>>.broadcast();
      // If currently disconnected and not attempting connection, start mock telemetry
      if (_status != BackendConnectionStatus.connected) {
        _startMockTelemetry();
      }
    }
    return _telemetryController!.stream;
  }

  /// Check if connected to backend
  bool get isConnected => _isConnected;
  BackendConnectionStatus get status => _status;

  /// Connect to backend WebSocket server with retry logic
  Future<void> connect() async {
    // Only create controller if it doesn't exist or is closed
    if (_telemetryController == null || _telemetryController!.isClosed) {
      _telemetryController = StreamController<Map<String, dynamic>>.broadcast();
    }
    _status = BackendConnectionStatus.connecting;
    await _connectWithRetry();
  }

  /// Connect with automatic retry logic
  Future<void> _connectWithRetry({int retryCount = 0}) async {
    const maxRetries = 5;
    const retryDelay = Duration(seconds: 2);

    try {
      AppLogger.info('Connecting to backend: $_wsUrl (attempt ${retryCount + 1})');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);

            // Handle different message types
            if (data['type'] == 'connection') {
              AppLogger.info('✓ Connected to backend: ${data['message']}');
              _isConnected = true;
              _status = BackendConnectionStatus.connected;
              _stopMockTelemetry();
            } else if (data['type'] == 'telemetry') {
              // Broadcast telemetry data to listeners
              if (_telemetryController != null &&
                  !_telemetryController!.isClosed) {
                _telemetryController!.add(data);
              }
            } else if (data['type'] == 'command_response') {
              AppLogger.debug('Command response: ${data['action']} - ${data['status']}');
            } else if (data['type'] == 'error') {
              AppLogger.warning('Backend error: ${data['message']}');
            }
          } catch (e) {
            AppLogger.error('Error parsing message', error: e);
          }
        },
        onError: (error) {
          AppLogger.error('WebSocket error', error: error);
          _isConnected = false;
          _status = BackendConnectionStatus.reconnecting;
          _handleDisconnection(retryCount);
        },
        onDone: () {
          AppLogger.warning('WebSocket connection closed');
          _isConnected = false;
          _status = BackendConnectionStatus.reconnecting;
          _handleDisconnection(retryCount);
        },
      );

      AppLogger.info('✓ WebSocket connection established');
    } catch (e) {
      AppLogger.error('✗ Failed to connect to backend', error: e);
      _isConnected = false;
      _status = BackendConnectionStatus.reconnecting;

      if (retryCount < maxRetries) {
        AppLogger.info('Retrying connection in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
        await _connectWithRetry(retryCount: retryCount + 1);
      } else {
        AppLogger.error('✗ Max retries reached. Connection failed.', error: 'Timeout');
        _status = BackendConnectionStatus.failed;
        // Start mock telemetry fallback
        _startMockTelemetry();
      }
    }
  }

  /// Handle disconnection and attempt reconnection
  void _handleDisconnection(int currentRetryCount) {
    if (currentRetryCount < 5) {
      AppLogger.warning('Connection lost. Attempting to reconnect...');
      _status = BackendConnectionStatus.reconnecting;
      Future.delayed(const Duration(seconds: 2), () {
        _connectWithRetry(retryCount: currentRetryCount + 1);
      });
    } else {
      AppLogger.error('Connection lost. Max retry attempts reached. Using mock telemetry.', error: 'Max retries');
      _status = BackendConnectionStatus.failed;
      _startMockTelemetry();
    }
  }

  /// Send a command to the backend
  void sendCommand(String action, {Map<String, dynamic>? params}) {
    if (!_isConnected || _channel == null) {
      AppLogger.warning('✗ Cannot send command: Not connected to backend');
      return;
    }

    final command = {'action': action, ...?params};
    try {
      _channel!.sink.add(jsonEncode(command));
      AppLogger.debug('→ Sent command: $action');
    } catch (e) {
      AppLogger.error('✗ Error sending command', error: e);
    }
  }

  // Media control commands
  void playMusic() => sendCommand('play_music');
  void pauseMusic() => sendCommand('pause_music');
  void nextTrack() => sendCommand('next_track');
  void previousTrack() => sendCommand('previous_track');
  void setVolume(double volume) =>
      sendCommand('set_volume', params: {'volume': volume});

  // Vehicle settings commands
  void setChargeLimit(int limit) =>
      sendCommand('set_charge_limit', params: {'value': limit});
  void setRegenLevel(String level) =>
      sendCommand('set_regen_level', params: {'value': level});
  void setDriveMode(String mode) =>
      sendCommand('set_drive_mode', params: {'value': mode});

  // Drivetrain commands
  /// Set the current drive direction/gear: one of 'P', 'R', 'N', 'D'
  void setDriveDirection(String direction) =>
      sendCommand('set_drive_direction', params: {'value': direction});

  // GPS coordinate upload
  void sendGPSCoordinate(double latitude, double longitude, {
    double? altitude,
    double? speed,
    double? heading,
    double? accuracy,
    String? source,
  }) {
    sendCommand('update_gps', params: {
      'latitude': latitude,
      'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (accuracy != null) 'accuracy': accuracy,
      if (source != null) 'source': source,
    });
  }

  // Infotainment settings commands
  void setBrightness(int brightness) =>
      sendCommand('set_brightness', params: {'value': brightness});
  void setTheme(bool lightTheme) =>
      sendCommand('set_theme', params: {'value': lightTheme});

  // Digital Twin settings commands
  void togglePredictions(bool enabled) =>
      sendCommand('toggle_predictions', params: {'value': enabled});
  void setTwinMode(String mode) =>
      sendCommand('set_twin_mode', params: {'value': mode});

  // Bluetooth commands
  void connectBluetooth(String deviceAddress) => sendCommand(
    'connect_bluetooth',
    params: {'device_address': deviceAddress},
  );

  /// Disconnect from backend
  void dispose() {
    _isConnected = false;
    _status = BackendConnectionStatus.disconnected;
    _stopMockTelemetry();
    _channel?.sink.close();
    if (_telemetryController != null && !_telemetryController!.isClosed) {
      _telemetryController?.close();
    }
    AppLogger.info('Backend service disposed');
  }

  /// Start mock telemetry generator (1Hz)
  void _startMockTelemetry() {
    if (_mockTimer != null && _mockTimer!.isActive) return;
    AppLogger.info('Starting mock telemetry fallback...');
    _mockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_telemetryController == null || _telemetryController!.isClosed) return;
      final soc = 80 + _rand.nextDouble() * 5; // 80-85%
      final speed = _rand.nextDouble() * 15; // 0-15 km/h
      final rpm = (speed * 40).round();
      final temp = 25 + _rand.nextDouble() * 5;
      final mock = {
        'type': 'telemetry',
        'data': {
          'battery': {
            'soc': double.parse(soc.toStringAsFixed(1)),
            'temperature': double.parse(temp.toStringAsFixed(1)),
            'charging': false,
          },
          'vehicle': {
            'speed_kmh': double.parse(speed.toStringAsFixed(1)),
            'gear': 'P',
            'range_km': double.parse((soc / 100 * 45).toStringAsFixed(1)),
          },
          'motor': {
            'rpm': rpm,
            'temperature': 35 + speed / 10,
          },
          'environment': {
            'temperature': temp,
            'humidity': 50 + _rand.nextDouble() * 10,
          },
        },
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'mock',
      };
      _telemetryController!.add(mock);
    });
  }

  void _stopMockTelemetry() {
    _mockTimer?.cancel();
    _mockTimer = null;
    AppLogger.info('Stopped mock telemetry');
  }
}
