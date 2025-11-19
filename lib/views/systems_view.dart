// lib/views/systems_view.dart
import 'package:flutter/material.dart';

class SystemsView extends StatelessWidget {
  const SystemsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Core Systems'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _SystemPanel(
              title: 'Brakes',
              icon: Icons.car_crash,
              children: const [
                _StatusTile(
                  label: 'Brake Fluid',
                  status: 'OK',
                  statusColor: Colors.greenAccent,
                ),
                _StatusTile(label: 'Pad Wear (Front)', status: '90%'),
                _StatusTile(label: 'Pad Wear (Rear)', status: '85%'),
              ],
            ),
            const SizedBox(height: 24),
            _SystemPanel(
              title: 'Steering & Stability',
              icon: Icons.sync_problem,
              children: const [
                _StatusTile(
                  label: 'Steering Hydraulics',
                  status: 'OK',
                  statusColor: Colors.greenAccent,
                ),
                _StatusTile(
                  label: 'Vehicle Stability Control',
                  status: 'Active',
                  statusColor: Colors.blueAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SystemPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final String label;
  final String status;
  final Color statusColor;

  const _StatusTile({
    required this.label,
    required this.status,
    this.statusColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
