// lib/views/motor_view.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class MotorView extends StatefulWidget {
  const MotorView({super.key});

  @override
  State<MotorView> createState() => _MotorViewState();
}

class _MotorViewState extends State<MotorView> {
  String _currentDirection = 'D';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motor Systems'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildRadialGauge(
              title: 'Motor RPM',
              value: 3450, // Placeholder value
              unit: 'RPM',
              max: 10000,
              pointerColor: Colors.blueAccent,
            ),
            const Divider(color: Colors.white24, height: 48),
            _buildDirectionSelector(),
            const Divider(color: Colors.white24, height: 48),
            _buildInfoList(),
          ],
        ),
      ),
    );
  }

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
          height: 200,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: max,
                showLabels: true,
                showTicks: true,
                axisLabelStyle: const GaugeTextStyle(color: Colors.white70),
                labelOffset: 15,
                tickOffset: 10,
                minorTicksPerInterval: 4,
                majorTickStyle: const MajorTickStyle(color: Colors.white70),
                minorTickStyle: const MinorTickStyle(
                  color: Colors.white70,
                  thickness: 1,
                ),
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

  Widget _buildDirectionSelector() {
    return Column(
      children: [
        const Text(
          'Direction',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment<String>(value: 'P', label: Text('P', style: TextStyle(fontSize: 20))),
            ButtonSegment<String>(value: 'R', label: Text('R', style: TextStyle(fontSize: 20))),
            ButtonSegment<String>(value: 'N', label: Text('N', style: TextStyle(fontSize: 20))),
            ButtonSegment<String>(value: 'D', label: Text('D', style: TextStyle(fontSize: 20))),
          ],
          selected: {_currentDirection},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _currentDirection = newSelection.first;
            });
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white70,
            selectedBackgroundColor: Colors.blueAccent,
            selectedForegroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          _InfoListTile(
            title: 'Motor Temperature',
            value: '45°C', // Placeholder
            icon: Icons.thermostat,
            iconColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}

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
