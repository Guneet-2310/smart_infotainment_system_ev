import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Backend service for WebSocket communication with Python backend
///
/// Handles real-time telemetry data and command execution
/// Author: Guneet Chawla
class BackendService {
  // WebSocket URL - change based on environment
  static const String _wsUrl = 'ws://localhost:8765'; // Windows/same machine
  // For Raspberry Pi, use: 'ws://192.168.1.XXX:8765' (replace with Pi's IP)

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _telemetryController;
  bool _isConnected = false;

  /// Stream of telemetry data from backend
  Stream<Map<String, dynamic>> get telemetryStream =>
      _telemetryController!.stream;

  /// Check if connected to backend
  bool get isConnected => _isConnected;

  /// Connect to backend WebSocket server with retry logic
  Future<void> connect() async {
    // Only create controller if it doesn't exist or is closed
    if (_telemetryController == null || _telemetryController!.isClosed) {
      _telemetryController = StreamController<Map<String, dynamic>>.broadcast();
    }
    await _connectWithRetry();
  }

  /// Connect with automatic retry logic
  Future<void> _connectWithRetry({int retryCount = 0}) async {
    const maxRetries = 5;
    const retryDelay = Duration(seconds: 2);

    try {
      print('Connecting to backend: $_wsUrl (attempt ${retryCount + 1})');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);

            // Handle different message types
            if (data['type'] == 'connection') {
              print('✓ Connected to backend: ${data['message']}');
              _isConnected = true;
            } else if (data['type'] == 'telemetry') {
              // Broadcast telemetry data to listeners
              if (_telemetryController != null &&
                  !_telemetryController!.isClosed) {
                _telemetryController!.add(data);
              }
            } else if (data['type'] == 'response') {
              print('Command response: ${data['action']} - ${data['status']}');
            } else if (data['type'] == 'error') {
              print('Backend error: ${data['message']}');
            }
          } catch (e) {
            print('Error parsing message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _handleDisconnection(retryCount);
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          _handleDisconnection(retryCount);
        },
      );

      print('✓ WebSocket connection established');
    } catch (e) {
      print('✗ Failed to connect to backend: $e');
      _isConnected = false;

      if (retryCount < maxRetries) {
        print('Retrying connection in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
        await _connectWithRetry(retryCount: retryCount + 1);
      } else {
        print('✗ Max retries reached. Connection failed.');
      }
    }
  }

  /// Handle disconnection and attempt reconnection
  void _handleDisconnection(int currentRetryCount) {
    if (currentRetryCount < 5) {
      print('Connection lost. Attempting to reconnect...');
      Future.delayed(const Duration(seconds: 2), () {
        _connectWithRetry(retryCount: currentRetryCount + 1);
      });
    }
  }

  /// Send a command to the backend
  void sendCommand(String action, {Map<String, dynamic>? params}) {
    if (!_isConnected || _channel == null) {
      print('✗ Cannot send command: Not connected to backend');
      return;
    }

    final command = {'action': action, ...?params};
    try {
      _channel!.sink.add(jsonEncode(command));
      print('→ Sent command: $action');
    } catch (e) {
      print('✗ Error sending command: $e');
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
    _channel?.sink.close();
    if (_telemetryController != null && !_telemetryController!.isClosed) {
      _telemetryController?.close();
    }
    print('Backend service disposed');
  }
}
