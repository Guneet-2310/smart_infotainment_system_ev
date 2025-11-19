// lib/views/settings_view.dart
import 'package:flutter/material.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  // --- State variables for our controls ---

  // Vehicle
  double _chargeLimit = 80.0;
  String _regenLevel = 'standard'; // 'low', 'standard'
  String _driveMode = 'eco'; // 'eco', 'sport'

  // Infotainment
  double _brightness = 60.0;
  bool _isLightTheme = false;

  // Digital Twin
  bool _predictionsOn = true;
  String _twinMode = '3d'; // '2d', '3d'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // This ListView holds all the settings sections
          ListView(
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              80,
            ), // Padding for footer
            children: [
              // --- Section 1: Vehicle ---
              _buildVehicleSection(),

              const SizedBox(height: 16),

              // --- Section 2: Infotainment ---
              _buildInfotainmentSection(),

              const SizedBox(height: 16),

              // --- Section 3: Digital Twin ---
              _buildDigitalTwinSection(),

              const SizedBox(height: 16),

              // --- Section 4: Updates & Diagnostics ---
              _buildUpdatesSection(),
            ],
          ),

          // --- Copyright Footer ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Developed by Guneet Chawla.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDER METHODS for Sections ---

  Widget _buildVehicleSection() {
    return _SettingsSection(
      title: 'Vehicle',
      icon: Icons.directions_car,
      children: [
        // Charging limits
        _SettingSlider(
          label: 'Charging Limit',
          value: _chargeLimit,
          displayValue: '${_chargeLimit.round()}%',
          min: 50,
          max: 100,
          divisions: 10,
          onChanged: (newValue) => setState(() => _chargeLimit = newValue),
        ),

        // Regenerative braking
        _SettingSegmentedButton<String>(
          label: 'Regenerative Braking',
          currentValue: _regenLevel,
          options: const {'low': 'Low', 'standard': 'Standard'},
          onChanged: (newValue) =>
              setState(() => _regenLevel = newValue!.first),
        ),

        // Driving modes
        _SettingSegmentedButton<String>(
          label: 'Driving Mode',
          currentValue: _driveMode,
          options: const {'eco': 'Eco', 'sport': 'Sport'},
          onChanged: (newValue) => setState(() => _driveMode = newValue!.first),
        ),
      ],
    );
  }

  Widget _buildInfotainmentSection() {
    return _SettingsSection(
      title: 'Infotainment',
      icon: Icons.devices,
      children: [
        // Display brightness
        _SettingSlider(
          label: 'Display Brightness',
          value: _brightness,
          displayValue: '${_brightness.round()}%',
          min: 10,
          max: 100,
          divisions: 9,
          onChanged: (newValue) => setState(() => _brightness = newValue),
        ),

        // Theme selection
        SwitchListTile(
          title: const Text(
            'Light Mode',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            _isLightTheme ? 'Enabled' : 'Disabled',
            style: const TextStyle(color: Colors.white70),
          ),
          value: _isLightTheme,
          onChanged: (newValue) {
            setState(() => _isLightTheme = newValue);
            // Here you would later call a theme service to change the theme
          },
          activeColor: Colors.blueAccent,
        ),

        // Bluetooth pairing
        ListTile(
          title: const Text(
            'Bluetooth Pairing',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Manage connected devices',
            style: TextStyle(color: Colors.white70),
          ),
          trailing: const Icon(Icons.bluetooth, color: Colors.blueAccent),
          onTap: () {
            // Logic to open Bluetooth settings
          },
        ),
      ],
    );
  }

  Widget _buildDigitalTwinSection() {
    return _SettingsSection(
      title: 'Digital Twin',
      icon: Icons.memory,
      children: [
        // Toggle prediction features
        SwitchListTile(
          title: const Text(
            'Prediction Features',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            _predictionsOn ? 'Active' : 'Inactive',
            style: const TextStyle(color: Colors.white70),
          ),
          value: _predictionsOn,
          onChanged: (newValue) => setState(() => _predictionsOn = newValue),
          activeColor: Colors.blueAccent,
        ),

        // Customize visualization (2D/3D)
        _SettingSegmentedButton<String>(
          label: 'Visualization Mode',
          currentValue: _twinMode,
          options: const {'2d': '2D', '3d': '3D'},
          onChanged: (newValue) => setState(() => _twinMode = newValue!.first),
        ),

        // Reset efficiency data
        ListTile(
          title: const Text(
            'Reset Efficiency Data',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Clears all historical driving data',
            style: TextStyle(color: Colors.white70),
          ),
          trailing: Icon(Icons.delete_forever, color: Colors.red[400]),
          onTap: () {
            // Logic to show a confirmation dialog
          },
        ),
      ],
    );
  }

  Widget _buildUpdatesSection() {
    return _SettingsSection(
      title: 'Updates & Diagnostics',
      icon: Icons.system_update,
      children: [
        // Software version
        const ListTile(
          title: Text(
            'Software Version',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'v1.0.0-alpha',
            style: TextStyle(color: Colors.white70),
          ),
        ),

        // System updates
        ListTile(
          title: const Text(
            'System Updates',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Check for new software',
            style: TextStyle(color: Colors.white70),
          ),
          trailing: const Icon(Icons.update, color: Colors.white70),
          onTap: () {
            // Logic to check for updates
          },
        ),

        // Diagnostic Log
        ListTile(
          title: const Text(
            'Diagnostic Log',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'View system error codes and health',
            style: TextStyle(color: Colors.white70),
          ),
          trailing: const Icon(Icons.description, color: Colors.white70),
          onTap: () {
            // Logic to open the log view
          },
        ),
      ],
    );
  }
}

// --- HELPER WIDGETS for clean settings ---

/// A helper for creating the main collapsible section
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      // This makes the tile themed correctly
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.grey[900]?.withOpacity(0.5),
      collapsedBackgroundColor: Colors.grey[900]?.withOpacity(0.5),

      // Header
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Content
      children: children,
    );
  }
}

/// A helper for a settings row with a Slider
class _SettingSlider extends StatelessWidget {
  final String label;
  final double value;
  final String displayValue;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SettingSlider({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                displayValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: displayValue,
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.white30,
          ),
        ],
      ),
    );
  }
}

/// A helper for a settings row with a SegmentedButton
class _SettingSegmentedButton<T> extends StatelessWidget {
  final String label;
  final T currentValue;
  final Map<T, String> options;
  final ValueChanged<Set<T>?> onChanged;

  const _SettingSegmentedButton({
    required this.label,
    required this.currentValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          SegmentedButton<T>(
            segments: options.entries.map((entry) {
              return ButtonSegment<T>(
                value: entry.key,
                label: Text(entry.value),
              );
            }).toList(),
            selected: {currentValue},
            onSelectionChanged: onChanged,
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white70,
              selectedBackgroundColor: Colors.blueAccent,
              selectedForegroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
