// lib/views/map_view.dart
import 'package:flutter/material.dart';
// Import the new gauge package
import 'package:syncfusion_flutter_gauges/gauges.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Primary Area (Digital Twin Model)
          _buildDigitalTwinModel(),

          // 2. Data Overlays (Positioned on top of the twin)
          _buildDataOverlays(),

          // 3. Driving Efficiency Gauge (Bottom-left)
          _buildEfficiencyGauge(),

          // 4. Predictive Analytics Panel (Bottom-right)
          _buildPredictivePanel(),
        ],
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  /// 1. The main 3D model placeholder
  Widget _buildDigitalTwinModel() {
    return Container(
      color: Colors.grey[900], // Dark placeholder background
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, color: Colors.white24, size: 150),
            SizedBox(height: 20),
            Text(
              '3D/2D Digital Twin Model Area',
              style: TextStyle(color: Colors.white24, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Overlays for real-time sensor data
  Widget _buildDataOverlays() {
    return const Stack(
      children: [
        // Example: Motor Temperature
        Positioned(
          top: 100,
          left: 100,
          child: _DataOverlayChip(label: 'Motor Temp', value: '85°C'),
        ),
        // Example: Wheel Speed
        Positioned(
          bottom: 200,
          right: 150,
          child: _DataOverlayChip(label: 'Wheel Speed', value: '40 rpm'),
        ),
      ],
    );
  }

  /// 3. The gauge and power flow on the bottom-left
  Widget _buildEfficiencyGauge() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        width: 300,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'Driving Efficiency',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Efficiency Gauge (Using Syncfusion)
            SizedBox(
              height: 150,
              child: _buildRadialGauge(75, "kW", Colors.greenAccent),
            ),

            const SizedBox(height: 10),
            const Text(
              'Efficiency Score: 8.2/10',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const Divider(color: Colors.white24, height: 30),

            // Power Flow Graphic
            const Text(
              'Power Flow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(
                  Icons.battery_charging_full,
                  color: Colors.greenAccent,
                  size: 30,
                ),
                Icon(Icons.arrow_forward, color: Colors.greenAccent, size: 24),
                Icon(Icons.electric_bolt, color: Colors.greenAccent, size: 30),
                Icon(Icons.arrow_forward, color: Colors.greenAccent, size: 24),
                Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 30,
                ), // Motor/Wheels
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Battery -> Motor -> Wheels',
              style: TextStyle(color: Colors.greenAccent, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. The analytics panel on the bottom-right
  Widget _buildPredictivePanel() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        width: 300,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Predictive Analytics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(color: Colors.white24, height: 20),

            // Range Estimation
            Text(
              'Range Estimation: 315 km',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '- Based on current style, traffic, terrain',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),

            SizedBox(height: 16),

            // Battery Health
            Text(
              'Battery Health (SOH): 98%',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '- Optimal performance',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build the radial gauge
  Widget _buildRadialGauge(double value, String unit, Color pointerColor) {
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 100, // Placeholder max
          showLabels: false,
          showTicks: false,
          axisLineStyle: const AxisLineStyle(
            thickness: 0.2,
            cornerStyle: CornerStyle.bothCurve,
            color: Colors.white12,
            thicknessUnit: GaugeSizeUnit.factor,
          ),
          pointers: <GaugePointer>[
            RangePointer(
              value: value,
              width: 0.2,
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
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
              angle: 90,
              positionFactor: 0.1,
            ),
          ],
        ),
      ],
    );
  }
}

/// Helper widget for the data overlay chips
class _DataOverlayChip extends StatelessWidget {
  const _DataOverlayChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
