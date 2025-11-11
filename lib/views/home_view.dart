// lib/views/home_view.dart
import 'package:flutter/material.dart';
import 'dart:async'; // For the real-time clock
import 'package:intl/intl.dart'; // For formatting the time and date

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  // Your requested API key
  static const String mapsApiKey = "random_api_token_here";

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _currentDate = '';
  String _currentTime = '';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Update the time and date every second
    _updateDateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateDateTime(),
    );
  }

  @override
  void dispose() {
    _timer.cancel(); // Stop the timer when the widget is removed
    super.dispose();
  }

  void _updateDateTime() {
    setState(() {
      DateTime now = DateTime.now();
      _currentDate = DateFormat('EEE MMM d').format(now); // e.g., "Wed Jul 9"
      _currentTime = DateFormat('HH:mm').format(now); // e.g., "05:43"
    });
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

          // --- Bottom Bar (Media Controls) - unchanged but now part of Left Column ---
          // This will be handled inside _buildLeftColumn now
        ],
      ),
    );
  }

  // lib/views/home_view.dart

  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.topLeft, // Align to top-left
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          // This is the only change: .end is now .start
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
            Icon(Icons.wifi, color: Colors.white, size: 24),
            SizedBox(width: 16),
            Icon(Icons.bluetooth, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Container(
      width:
          MediaQuery.of(context).size.width *
          0.35, // Approx 35% of screen width
      padding: const EdgeInsets.fromLTRB(
        24,
        80,
        24,
        24,
      ), // Top padding for time/date
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Text(
            _currentDate,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),

          // Time
          Text(
            _currentTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 60, // Large time font
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 32),

          // EV Metrics (now in a row, below time)
          _buildEvMetricsRow(),
          const SizedBox(height: 32),

          // Expanded space to push media player to bottom
          const Spacer(),

          // Media Player (Bottom-left)
          _buildMediaPlayer(),
        ],
      ),
    );
  }

  Widget _buildEvMetricsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4), // Dark background for the row
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Metric: Speed
          _EvMetricItem(value: "88", unit: "km/h", label: "Speed"),
          // Metric: Range
          _EvMetricItem(value: "320", unit: "km", label: "Range"),
          // Metric: Battery (SoC)
          _EvMetricItem(
            value: "75%",
            label: "Battery",
            iconColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  // lib/views/home_view.dart

  Widget _buildMapPlaceholder() {
    return Expanded(
      child: Container(
        // Map placeholder will take remaining space
        margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.grey[900], // Map background
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, color: Colors.white24, size: 100),
                  const SizedBox(height: 20),
                  Text(
                    'Map API Placeholder\n(Using API Key: ${HomeView.mapsApiKey})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white24, fontSize: 20),
                  ),
                ],
              ),
            ),

            // Placeholder Search Bar
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: const [
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
            Positioned(
              bottom: 20, // 20 pixels from the bottom
              right: 20, // 20 pixels from the right
              child: Container(
                // The margin is no longer needed
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(height: 10),
                    Icon(Icons.remove, color: Colors.white),
                    Divider(color: Colors.white24, height: 20),
                    Icon(Icons.my_location, color: Colors.blueAccent),
                    SizedBox(height: 10),
                    Icon(Icons.traffic, color: Colors.white),
                    SizedBox(height: 10),
                    Icon(Icons.threed_rotation, color: Colors.white),
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
      margin: const EdgeInsets.only(bottom: 20), // Space from actual bottom
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(
          0.6,
        ), // Dark background for media player
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Song Name",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Artist Name / Station", // Placeholder for artist/station
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Playback progress bar
          LinearProgressIndicator(
            value: 0.5, // Example progress
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '00:56',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '-01:20',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Controls and Volume
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Icon(
                Icons.star_border,
                color: Colors.white70,
                size: 28,
              ), // Favorite
              const Icon(Icons.skip_previous, color: Colors.white, size: 38),
              const Icon(
                Icons.play_arrow,
                color: Colors.blueAccent,
                size: 50,
              ), // Play/Pause
              const Icon(Icons.skip_next, color: Colors.white, size: 38),
              const Icon(
                Icons.volume_up,
                color: Colors.white70,
                size: 28,
              ), // Volume icon
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            ),
            child: Slider(
              value: 0.7, // Placeholder value
              onChanged: (newValue) {
                // Handle volume change
              },
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.white30,
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
        color: Colors.black.withOpacity(0.4),
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
            fontSize: 30, // Slightly smaller for the row
            fontWeight: FontWeight.bold,
          ),
        ),
        if (unit != null)
          Text(
            unit!,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
