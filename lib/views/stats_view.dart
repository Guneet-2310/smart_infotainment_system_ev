// lib/views/stats_view.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the new chart package
import 'package:syncfusion_flutter_gauges/gauges.dart'; // Import the gauge package

class StatsView extends StatelessWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    // This makes the whole view scrollable in case content overflows
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Primary Area (Gauges) ---
            _buildSectionTitle('Core Metrics (Real-Time)'),
            _buildGaugesSection(),

            const Divider(color: Colors.white24, height: 40),

            // --- 2. Historical Charts ---
            _buildSectionTitle('Historical Trends (Last 5 Mins)'),
            _buildChartsSection(),

            const Divider(color: Colors.white24, height: 40),

            // --- 3. Data Tables & GPS ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 3a. Data Tables ---
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Detailed Sensor Data'),
                      _buildDataTablesSection(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // --- 3b. GPS/Location Data ---
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('GPS / Location Status'),
                      _buildGpsSection(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 1. The main gauges for core metrics
  Widget _buildGaugesSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _MetricGauge(title: 'Battery Voltage', value: 400, unit: 'V', max: 500),
        _MetricGauge(title: 'Motor RPM', value: 3500, unit: 'RPM', max: 8000),
        _MetricGauge(title: 'Ambient Temp', value: 25, unit: '°C', max: 50),
        _MetricGauge(title: 'Cabin Temp', value: 22, unit: '°C', max: 30),
      ],
    );
  }

  /// 2. The historical line charts
  Widget _buildChartsSection() {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(child: _buildLineChart('Battery SoC %')),
          const SizedBox(width: 20),
          Expanded(child: _buildLineChart('Speed (km/h)')),
          const SizedBox(width: 20),
          Expanded(child: _buildLineChart('Power (kW)')),
        ],
      ),
    );
  }

  /// 3. The data tables for sensors
  Widget _buildDataTablesSection() {
    final cellStyle = const TextStyle(color: Colors.white70, fontSize: 14);
    final headerStyle = const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table 1: Tire Pressure
        Text('Tire Pressure', style: headerStyle.copyWith(fontSize: 18)),
        DataTable(
          columns: [
            DataColumn(label: Text('Tire', style: headerStyle)),
            DataColumn(label: Text('Pressure (PSI)', style: headerStyle)),
          ],
          rows: [
            DataRow(
              cells: [
                DataCell(Text('Front Left', style: cellStyle)),
                DataCell(Text('35.2', style: cellStyle)),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('Front Right', style: cellStyle)),
                DataCell(Text('35.1', style: cellStyle)),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('Rear Left', style: cellStyle)),
                DataCell(Text('34.9', style: cellStyle)),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('Rear Right', style: cellStyle)),
                DataCell(Text('35.0', style: cellStyle)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Table 2: Battery Cells
        Text('Battery Cell Temps', style: headerStyle.copyWith(fontSize: 18)),
        DataTable(
          columns: [
            DataColumn(label: Text('Cell Block', style: headerStyle)),
            DataColumn(label: Text('Temp (°C)', style: headerStyle)),
          ],
          rows: [
            DataRow(
              cells: [
                DataCell(Text('Block A (1-8)', style: cellStyle)),
                DataCell(Text('28.5', style: cellStyle)),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('Block B (9-16)', style: cellStyle)),
                DataCell(Text('29.1', style: cellStyle)),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('Block C (17-24)', style: cellStyle)),
                DataCell(Text('29.0', style: cellStyle)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 4. The GPS information panel
  Widget _buildGpsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _GpsInfoRow(label: 'Satellites Locked', value: '18 / 22'),
          _GpsInfoRow(label: 'Latitude', value: '28.4251° N'),
          _GpsInfoRow(label: 'Longitude', value: '77.0435° E'),
          _GpsInfoRow(label: 'Altitude', value: '238 m'),
          _GpsInfoRow(
            label: 'CAN Bus Status',
            value: 'Connected',
            valueColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  /// A helper for the 4 gauges at the top
  Widget _MetricGauge({
    required String title,
    required double value,
    required String unit,
    required double max,
  }) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: max,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.1,
                    cornerStyle: CornerStyle.bothCurve,
                    color: Colors.white12,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: value,
                      width: 0.1,
                      color: Colors.blueAccent,
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            unit,
                            style: const TextStyle(
                              fontSize: 12,
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
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// A helper for the GPS info rows
  Widget _GpsInfoRow({
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// A helper to build a placeholder line chart
  Widget _buildLineChart(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      // Placeholder static data
                      FlSpot(0, 3), FlSpot(1, 1), FlSpot(2, 4), FlSpot(3, 2),
                      FlSpot(4, 5), FlSpot(5, 3), FlSpot(6, 4),
                    ],
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
