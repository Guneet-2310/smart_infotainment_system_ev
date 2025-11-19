// lib/views/tyre_pms_view.dart
import 'package:flutter/material.dart';

class TyrePmsView extends StatelessWidget {
  const TyrePmsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tyre Pressure (PMS)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Live Tyre Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 300,
              height: 450,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TyreInfoBox(label: 'Front Left', pressure: 35.2),
                      _TyreInfoBox(label: 'Front Right', pressure: 35.1),
                    ],
                  ),
                  Icon(
                    Icons.directions_car,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 150,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TyreInfoBox(label: 'Rear Left', pressure: 34.9),
                      _TyreInfoBox(label: 'Rear Right', pressure: 35.0),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TyreInfoBox extends StatelessWidget {
  final String label;
  final double pressure;
  final bool isOk;

  const _TyreInfoBox({required this.label, required this.pressure})
      : isOk = (pressure >= 32 && pressure <= 36);

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isOk ? Colors.greenAccent : Colors.amber;

    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            pressure.toStringAsFixed(1),
            style: TextStyle(
              color: statusColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text('PSI', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
