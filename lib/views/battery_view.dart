// lib/views/battery_view.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class BatteryView extends StatelessWidget {
  const BatteryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- SOC & Temperature Gauges ---
            Row(
              children: [
                Expanded(
                  child: _buildRadialGauge(
                    title: 'SOC (State of Charge)',
                    value: 75, // Placeholder value
                    unit: '%',
                    max: 100,
                    pointerColor: Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildRadialGauge(
                    title: 'Battery Temperature',
                    value: 28, // Placeholder value
                    unit: '°C',
                    max: 60, // Max safe temp
                    pointerColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),

            const Divider(color: Colors.white24, height: 48),

            // --- SOH, Connectivity & Warnings ---
            _buildInfoList(),
          ],
        ),
      ),
    );
  }

  /// Helper for building the radial gauges
  Widget _buildRadialGauge({
    required String title,
    required double value,
    required String unit,
    required double max,
    required Color pointerColor,
  }) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: max,
                showLabels: false,
                showTicks: false,
                axisLineStyle: const AxisLineStyle(
                  thickness: 0.15,
                  cornerStyle: CornerStyle.bothCurve,
                  color: Colors.white12,
                  thicknessUnit: GaugeSizeUnit.factor,
                ),
                pointers: <GaugePointer>[
                  RangePointer(
                    value: value,
                    width: 0.15,
                    color: pointerColor,
                    cornerStyle: CornerStyle.bothCurve,
                    sizeUnit: GaugeSizeUnit.factor,
                  ),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    widget: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    angle: 90,
                    positionFactor: 0.1,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ],
    );
  }

  /// Helper for building the list of other info
  Widget _buildInfoList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _InfoListTile(
            title: 'SOH (State of Health)',
            value: '98%', // Placeholder
            icon: Icons.health_and_safety,
            iconColor: Colors.greenAccent,
          ),
          const Divider(color: Colors.white24),
          _InfoListTile(
            title: 'Battery Connectivity',
            value: 'Connected', // Placeholder
            icon: Icons.power,
            iconColor: Colors.blueAccent,
          ),
          const Divider(color: Colors.white24),
          _InfoListTile(
            title: 'System Warnings',
            value: 'None', // Placeholder
            icon: Icons.warning,
            iconColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}

/// Helper widget for the list items
class _InfoListTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _InfoListTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
