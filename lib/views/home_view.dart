// lib/views/home_view.dart
import 'package:flutter/material.dart';
import 'dart:async'; // For the real-time clock
import 'package:intl/intl.dart'; // For formatting the time

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  // Your requested API key
  static const String mapsApiKey = "random_api_token_here";

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _currentTime = '';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Update the time every second
    _currentTime = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateTime(),
    );
  }

  @override
  void dispose() {
    _timer.cancel(); // Stop the timer when the widget is removed
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = _formatDateTime(DateTime.now());
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm a').format(dateTime); // e.g., "14:30 PM"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- 1. Primary Area (Map) ---
          _buildMapPlaceholder(),

          // --- 2. Top Bar (Time & Status) ---
          _buildTopBar(),

          // --- 3. Left Rail (EV Metrics) ---
          _buildLeftRail(),

          // --- 4. Bottom Bar (Media Controls) ---
          _buildBottomBar(),
        ],
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildMapPlaceholder() {
    // This Container is the placeholder for your map API
    return Container(
      color: Colors.grey[800], // Dark grey placeholder
      child: const Center(
        child: Text(
          'Map API Placeholder\n(Using API Key: ${HomeView.mapsApiKey})',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Current Time
            Text(
              _currentTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Status Icons
            const Row(
              children: [
                Icon(Icons.wifi, color: Colors.white, size: 24),
                SizedBox(width: 16),
                Icon(Icons.bluetooth, color: Colors.white, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftRail() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(24), // Margin from the edge
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7), // High-contrast dark pill
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min, // Fit the content
          children: [
            // Metric: Speed
            _MetricItem(
              value: "88",
              unit: "km/h",
              label: "Speed",
              icon: Icons.speed,
            ),
            SizedBox(height: 24),
            // Metric: Range
            _MetricItem(
              value: "320",
              unit: "km",
              label: "Range",
              icon: Icons.route,
            ),
            SizedBox(height: 24),
            // Metric: Battery (SoC)
            _MetricItem(
              value: "75%",
              label: "Battery",
              icon: Icons.battery_charging_full,
              iconColor: Colors.greenAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7), // High-contrast dark bar
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Song Title
            const Text(
              "Current Playing Song - Station Name",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            // 2. Controls and Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Media Buttons
                const Icon(Icons.skip_previous, color: Colors.white, size: 30),
                const SizedBox(width: 20),
                const Icon(Icons.pause, color: Colors.white, size: 40),
                const SizedBox(width: 20),
                const Icon(Icons.skip_next, color: Colors.white, size: 30),

                const SizedBox(width: 30),

                // Volume Slider
                const Icon(Icons.volume_down, color: Colors.white),
                Expanded(
                  child: Slider(
                    value: 0.5, // Placeholder value
                    onChanged: (newValue) {
                      // Handle volume change
                    },
                    activeColor: Colors.blueAccent,
                    inactiveColor: Colors.white30,
                  ),
                ),
                const Icon(Icons.volume_up, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- HELPER WIDGET for Left Rail Metrics ---

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.value,
    required this.label,
    required this.icon,
    this.unit,
    this.iconColor = Colors.white,
  });

  final String value;
  final String? unit;
  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 30),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit != null)
              Text(
                " $unit",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
