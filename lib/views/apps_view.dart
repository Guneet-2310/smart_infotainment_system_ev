// lib/views/apps_view.dart
import 'package:ev_smart_screen/views/map_view.dart';
import 'package:ev_smart_screen/views/settings_view.dart';
import 'package:ev_smart_screen/views/stats_view.dart';
import 'package:ev_smart_screen/views/battery_view.dart';
import 'package:ev_smart_screen/views/motor_view.dart';
import 'package:ev_smart_screen/views/systems_view.dart';
import 'package:ev_smart_screen/views/tyre_pms_view.dart';
import 'package:flutter/material.dart';

// A simple class to hold our app info
class AppItem {
  final String title;
  final IconData icon;
  final Widget page;

  AppItem({required this.title, required this.icon, required this.page});
}

class AppsView extends StatelessWidget {
  const AppsView({super.key});

  @override
  Widget build(BuildContext context) {
    // This is the list of all your "apps"
    // We can add more here later
    final List<AppItem> apps = [
      AppItem(title: 'Maps', icon: Icons.map, page: const MapView()),
      AppItem(
        title: 'Diagnostics',
        icon: Icons.bar_chart,
        page: const StatsView(),
      ),
      AppItem(
        title: 'Settings',
        icon: Icons.settings,
        page: const SettingsView(),
      ),
      // Newly integrated functional views
      AppItem(
        title: 'Battery',
        icon: Icons.battery_full,
        page: const BatteryView(),
      ),
      AppItem(
        title: 'Motor',
        icon: Icons.electric_bolt,
        page: const MotorView(),
      ),
      AppItem(
        title: 'Vehicle Systems',
        icon: Icons.car_crash,
        page: const SystemsView(),
      ),
      AppItem(
        title: 'Tyre Pressure',
        icon: Icons.tire_repair,
        page: const TyrePmsView(),
      ),
      // Placeholders (still in progress)
      AppItem(
        title: 'Music',
        icon: Icons.music_note,
        page: const PlaceholderPage(title: 'Music App'),
      ),
      AppItem(
        title: 'Weather',
        icon: Icons.cloud,
        page: const PlaceholderPage(title: 'Weather App'),
      ),
      AppItem(
        title: 'Connectivity',
        icon: Icons.wifi,
        page: const PlaceholderPage(title: 'Connectivity App'),
      ),
    ];

    return Scaffold(
      // Add a simple header for the Apps page
      appBar: AppBar(
        title: const Text('All Apps'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        // This controls the layout of the grid
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4 apps per row
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return _AppIcon(
            title: app.title,
            icon: app.icon,
            onTap: () {
              // This is how we "open" the app
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => app.page),
              );
            },
          );
        },
      ),
    );
  }
}

// A helper widget for the app icon in the grid
class _AppIcon extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AppIcon({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// A simple placeholder page for apps we haven't built
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.black),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
