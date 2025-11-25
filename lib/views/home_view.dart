// lib/views/home_view.dart
import 'package:flutter/material.dart';
import 'dart:async'; // For the real-time clock
import 'package:intl/intl.dart'; // For formatting the time and date
import 'package:ev_smart_screen/services/backend_service.dart'; // Backend service
import 'package:ev_smart_screen/services/notification_service.dart'; // Notification service
import 'package:flutter_map/flutter_map.dart'; // Map widget
import 'package:latlong2/latlong.dart'; // GPS coordinates
import 'package:ev_smart_screen/views/map_view.dart'; // Map view
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  // Mapbox API key loaded from .env (MAPS_API_KEY)
  static String get mapsApiKey => dotenv.env['MAPS_API_KEY'] ?? '';



  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _currentDate = '';
  String _currentTime = '';
  late Timer _timer;

  // Backend service
  final BackendService _backend = BackendService();
  Map<String, dynamic> _telemetry = {}; // Real-time data from backend
  bool _isConnected = false;
  bool _showReverseOverlay = false; // Parking reverse camera overlay trigger

  // Notification service
  final NotificationService _notificationService = NotificationService();
  int _unreadNotifications = 0;

  // Volume state
  double _volume = 0.7; // Current volume level

  @override
  void initState() {
    super.initState();
    // Update the time and date every second
    _updateDateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateDateTime(),
    );

    // Connect to backend
    _connectToBackend();
  }

  @override
  void dispose() {
    _timer.cancel(); // Stop the timer when the widget is removed
    _backend.dispose(); // Disconnect from backend
    _notificationService.dispose(); // Dispose notification service
    super.dispose();
  }

  /// Show toast notification
  void _showToastNotification(AppNotification notification) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(notification.icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    notification.message,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: notification.color.withValues(alpha: 0.9),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Connect to backend and listen for telemetry data
  Future<void> _connectToBackend() async {
    await _backend.connect();

    // Listen for telemetry updates
    _backend.telemetryStream.listen((data) {
      final parking = data['parking'] ?? {};
      final reverseEngaged = parking['reverse_engaged'] == true;
      setState(() {
        _telemetry = data;
        _isConnected = true;
        _showReverseOverlay = reverseEngaged;
        _notificationService.checkTelemetry(data);
      });
    });

    // Listen for new notifications
    _notificationService.notificationStream.listen((notification) {
      setState(() {
        _unreadNotifications = _notificationService.unreadCount;
      });

      // Show toast notification
      _showToastNotification(notification);
    });
  }

  void _updateDateTime() {
    setState(() {
      DateTime now = DateTime.now();
      _currentDate = DateFormat('EEE MMM d').format(now); // e.g., "Wed Jul 9"
      _currentTime = DateFormat('HH:mm').format(now); // e.g., "05:43"
    });
  }

  /// Calculate media playback progress (0.0 to 1.0)
  double _calculateProgress() {
    final duration = _telemetry['media']?['duration'] ?? 1;
    final position = _telemetry['media']?['position'] ?? 0;
    if (duration == 0) return 0.0;
    return (position / duration).clamp(0.0, 1.0);
  }

  /// Format time in MM:SS format
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main layout: Row with Left Panel and Map
          Positioned.fill(
            child: Row(
              children: [
                // --- Left Panel ---
                _buildLeftColumn(),

                // --- Major Map Section (Right) ---
                _buildMapPlaceholder(),
              ],
            ),
          ),

          // --- Top Bar (Time & Status) - unchanged ---
          _buildTopBar(),

          // --- Reverse Overlay (covers screen when active) ---
          if (_showReverseOverlay)
            Positioned.fill(
              child: _buildReverseOverlay(),
            ),

          // --- Bottom Bar (Media Controls) - unchanged but now part of Left Column ---
          // This will be handled inside _buildLeftColumn now
        ],
      ),
    );
  }

  // lib/views/home_view.dart

  Widget _buildTopBar() {
    // Get connectivity status from backend
    final wifiConnected = _telemetry['connectivity']?['wifi'] ?? false;
    final bluetoothConnected =
        _telemetry['connectivity']?['bluetooth'] ?? false;

    return Align(
      alignment: Alignment.topLeft, // Align to top-left
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Backend connection status
            Icon(
              _isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _isConnected ? Colors.greenAccent : Colors.redAccent,
              size: 24,
            ),
            const SizedBox(width: 16),
            // WiFi status
            Icon(
              Icons.wifi,
              color: wifiConnected ? Colors.white : Colors.white30,
              size: 24,
            ),
            const SizedBox(width: 16),
            // Bluetooth status
            Icon(
              Icons.bluetooth,
              color: bluetoothConnected ? Colors.blueAccent : Colors.white30,
              size: 24,
            ),
            const SizedBox(width: 16),
            // Notification bell
            GestureDetector(
              onTap: () {
                _showNotificationPanel();
              },
              child: Stack(
                children: [
                  const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 24,
                  ),
                  if (_unreadNotifications > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadNotifications > 9
                              ? '9+'
                              : '$_unreadNotifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show notification panel
  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1B2B),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _notificationService.markAllAsRead();
                        _unreadNotifications = 0;
                      });
                    },
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // Notification list
            Expanded(
              child: _notificationService.notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notificationService.notifications.length,
                      itemBuilder: (context, index) {
                        final notification =
                            _notificationService.notifications[index];
                        return ListTile(
                          leading: Icon(
                            notification.icon,
                            color: notification.color,
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.message,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(notification.timestamp),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _notificationService.markAsRead(notification.id);
                              _unreadNotifications =
                                  _notificationService.unreadCount;
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format timestamp for notification
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildLeftColumn() {
    return Container(
      width:
          MediaQuery.of(context).size.width *
          0.35, // Approx 35% of screen width
      padding: const EdgeInsets.fromLTRB(
        24,
        70,
        24,
        16,
      ), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Text(
            _currentDate,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),

          // Time
          Text(
            _currentTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56, // Slightly smaller time font
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // EV Metrics (now in a row, below time)
          _buildEvMetricsRow(),
          const SizedBox(height: 12),
          _buildCabinRow(),
          const SizedBox(height: 12),

          // Expanded space to push media player to bottom
          const Spacer(),

          // Media Player (Bottom-left)
          _buildMediaPlayer(),
        ],
      ),
    );
  }

  Widget _buildEvMetricsRow() {
    // Get real-time data from backend
    final speed = _telemetry['speed']?.toStringAsFixed(0) ?? '--';
    final range = _telemetry['range_km']?.toStringAsFixed(0) ?? '--';
    final battery = _telemetry['battery_soc']?.toStringAsFixed(0) ?? '--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4), // Dark background for the row
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Metric: Speed (real-time from backend)
          _EvMetricItem(value: speed, unit: "km/h", label: "Speed"),
          // Metric: Range (real-time from backend)
          _EvMetricItem(value: range, unit: "km", label: "Range"),
          // Metric: Battery (real-time from backend)
          _EvMetricItem(
            value: "$battery%",
            label: "Battery",
            iconColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildCabinRow() {
    final cabin = _telemetry['cabin'] ?? {};
    final temp = (cabin['temperature_c'] ?? _telemetry['ambient_temp'])?.toStringAsFixed(1) ?? '--';
    final hum = (cabin['humidity_pct'] ?? _telemetry['humidity'])?.toStringAsFixed(0) ?? '--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CompactMetricItem(value: temp, unit: '°C', label: 'Cabin'),
          _CompactMetricItem(value: hum, unit: '%', label: 'Humidity'),
        ],
      ),
    );
  }

  // lib/views/home_view.dart

  Widget _buildMapPlaceholder() {
    // Get GPS coordinates from telemetry
    final gps = _telemetry['gps'];
    final lat = gps?['latitude']?.toDouble() ?? 28.4595;
    final lon = gps?['longitude']?.toDouble() ?? 77.0266;
    final vehiclePosition = LatLng(lat, lon);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Real map widget
            FlutterMap(
              options: MapOptions(
                initialCenter: vehiclePosition,
                initialZoom: 14.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bmu.ev_smart_screen',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: vehiclePosition,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.blueAccent,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Search bar overlay
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  // Navigate to full map view
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapView()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.white70),
                      SizedBox(width: 10),
                      Text(
                        'Search for a place',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Map controls
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: () {
                        // Navigate to full map view
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapView(),
                          ),
                        );
                      },
                      tooltip: 'Full screen map',
                    ),
                    const Icon(
                      Icons.my_location,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPlayer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Reduced bottom margin
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6), // Dark background for media player
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _telemetry['media']?['track_title'] ?? "No Track Playing",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _telemetry['media']?['track_artist'] ?? "Unknown Artist",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Playback progress bar (LIVE)
          LinearProgressIndicator(
            value: _calculateProgress(),
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(_telemetry['media']?['position'] ?? 0),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '-01:20',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Controls and Volume
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.star_border,
                  color: Colors.white70,
                  size: 28,
                ),
                onPressed: () {
                  // Favorite functionality
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 38,
                ),
                onPressed: () => _backend.previousTrack(), // Backend command
              ),
              IconButton(
                icon: Icon(
                  _telemetry['media']?['is_playing'] == true
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.blueAccent,
                  size: 50,
                ),
                onPressed: () {
                  // Toggle play/pause
                  if (_telemetry['media']?['is_playing'] == true) {
                    _backend.pauseMusic();
                  } else {
                    _backend.playMusic();
                  }
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 38,
                ),
                onPressed: () => _backend.nextTrack(), // Backend command
              ),
              const Icon(Icons.volume_up, color: Colors.white70, size: 26),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            ),
            child: Slider(
              value: _volume, // Dynamic volume level
              onChanged: (newValue) {
                setState(() {
                  _volume = newValue; // Update UI immediately
                });
                _backend.setVolume(newValue); // Send to backend
              },
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReverseOverlay() {
    final parking = _telemetry['parking'] ?? {};
    final motion = parking['motion_detected'] == true;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Left side: Car diagram with 2 rear sensors (40%)
          Expanded(
            flex: 4,
            child: _buildCarDiagramWithSensors(parking, motion),
          ),
          const SizedBox(width: 16),
          // Right side: Camera placeholder (60% width, 3:1 aspect ratio)
          Expanded(
            flex: 6,
            child: AspectRatio(
              aspectRatio: 3 / 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'REVERSE CAMERA FEED\n(placeholder)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarDiagramWithSensors(Map<String, dynamic> parking, bool motion) {
    // Extract rear sensor data
    final rearLeftDist = parking['rear_left_distance_cm'];
    final rearRightDist = parking['rear_right_distance_cm'];
    final rearLeftWarn = parking['rear_left_warning'];
    final rearRightWarn = parking['rear_right_warning'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          // Title
          const Text(
            'REAR SENSORS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Car icon
          Expanded(
            child: Center(
              child: Icon(
                Icons.directions_car,
                color: Colors.white.withValues(alpha: 0.3),
                size: 100,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Two rear sensors side by side
          Row(
            children: [
              Expanded(
                child: _buildSensorDisplay(
                  label: 'REAR LEFT',
                  distance: rearLeftDist,
                  warning: rearLeftWarn,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSensorDisplay(
                  label: 'REAR RIGHT',
                  distance: rearRightDist,
                  warning: rearRightWarn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Motion detection
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  motion ? Icons.directions_run : Icons.accessibility_new,
                  color: motion ? Colors.purpleAccent : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  motion ? 'MOTION' : 'NO MOTION',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Close button
          ElevatedButton(
            onPressed: () {
              setState(() => _showReverseOverlay = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDisplay({
    required String label,
    required dynamic distance,
    required dynamic warning,
  }) {
    Color warnColor;
    String warnText;
    
    switch (warning) {
      case 'high':
        warnColor = Colors.redAccent;
        warnText = 'CLOSE';
        break;
      case 'medium':
        warnColor = Colors.orangeAccent;
        warnText = 'NEAR';
        break;
      case 'low':
        warnColor = Colors.yellowAccent;
        warnText = 'ALERT';
        break;
      case 'clear':
        warnColor = Colors.greenAccent;
        warnText = 'CLEAR';
        break;
      default:
        warnColor = Colors.grey;
        warnText = '—';
    }
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: warnColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: warnColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: warnColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            distance != null ? '${distance.toStringAsFixed(1)}cm' : '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            warnText,
            style: TextStyle(
              color: warnColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// --- HELPER WIDGETS ---

/// Helper for the weather/connectivity pills
class _WeatherConnectivityPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherConnectivityPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Helper for the EV metric items (Speed, Range, Battery)
class _EvMetricItem extends StatelessWidget {
  const _EvMetricItem({
    required this.value,
    required this.label,
    this.unit,
    this.iconColor = Colors.white,
  });

  final String value;
  final String? unit;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // No explicit icon as per the image
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28, // Reduced size
            fontWeight: FontWeight.bold,
          ),
        ),
        if (unit != null)
          Text(
            unit!,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

/// Compact metric item for cabin row (smaller font sizes)
class _CompactMetricItem extends StatelessWidget {
  const _CompactMetricItem({
    required this.value,
    required this.label,
    this.unit,
    this.iconColor = Colors.white,
  });

  final String value;
  final String? unit;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (unit != null)
          Text(
            unit!,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
