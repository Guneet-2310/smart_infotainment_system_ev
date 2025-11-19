// lib/views/stats_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the new chart package
import 'package:syncfusion_flutter_gauges/gauges.dart'; // Import the gauge package
import 'package:ev_smart_screen/services/backend_service.dart'; // Backend service
import 'package:ev_smart_screen/services/chart_data_service.dart'; // Chart data service
import 'package:ev_smart_screen/services/analytics_service.dart'; // Analytics service

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  // Backend service
  final BackendService _backend = BackendService();
  Map<String, dynamic> _telemetry = {}; // Real-time data from backend

  // Chart data service for historical data
  final ChartDataService _chartData = ChartDataService();

  // Analytics service
  final AnalyticsService _analytics = AnalyticsService();

  // Loading and connection state
  bool _isLoading = true;
  bool _isConnected = false;
  String _connectionStatus = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _connectToBackend();
  }

  @override
  void dispose() {
    _backend.dispose();
    super.dispose();
  }

  /// Connect to backend and listen for telemetry data
  Future<void> _connectToBackend() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Connecting to backend...';
    });

    await _backend.connect();

    // Listen for telemetry updates
    _backend.telemetryStream.listen(
      (data) {
        setState(() {
          _telemetry = data;
          _isLoading = false;
          _isConnected = true;
          _connectionStatus = 'Connected';
          // Add data point to charts and analytics
          _chartData.addDataPoint(data);
          _analytics.addDataPoint(data);
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _isConnected = false;
          _connectionStatus = 'Connection failed';
        });
      },
    );

    // Check connection status periodically
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final backendConnected = _backend.isConnected;
      if (_isConnected != backendConnected) {
        setState(() {
          _isConnected = backendConnected;
          _connectionStatus = backendConnected ? 'Connected' : 'Disconnected';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This makes the whole view scrollable in case content overflows
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics & Stats'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _connectionStatus,
                  style: TextStyle(
                    color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text(
                    'Connecting to backend...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
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

                  // --- 3. Analytics & Performance ---
                  _buildSectionTitle('Analytics & Performance'),
                  _buildAnalyticsSection(),

                  const Divider(color: Colors.white24, height: 40),

                  // --- 4. Data Tables & GPS ---
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
    // Get real-time data from backend
    final voltage = _telemetry['battery_voltage']?.toDouble() ?? 0;
    final rpm = _telemetry['motor_rpm']?.toDouble() ?? 0;
    final ambientTemp = _telemetry['ambient_temp']?.toDouble() ?? 0;
    final cabinTemp = _telemetry['cabin_temp']?.toDouble() ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _MetricGauge(
          title: 'Battery Voltage',
          value: voltage,
          unit: 'V',
          max: 500,
        ),
        _MetricGauge(title: 'Motor RPM', value: rpm, unit: 'RPM', max: 8000),
        _MetricGauge(
          title: 'Ambient Temp',
          value: ambientTemp,
          unit: '°C',
          max: 50,
        ),
        _MetricGauge(
          title: 'Cabin Temp',
          value: cabinTemp,
          unit: '°C',
          max: 30,
        ),
      ],
    );
  }

  /// 2. The historical line charts
  Widget _buildChartsSection() {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(child: _buildBatteryChart()),
          const SizedBox(width: 20),
          Expanded(child: _buildSpeedChart()),
          const SizedBox(width: 20),
          Expanded(child: _buildPowerChart()),
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
        // Table 1: Tire Pressure (LIVE DATA)
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
                DataCell(
                  Text(
                    (_telemetry['tire_pressure']?['front_left']
                            ?.toStringAsFixed(1) ??
                        '0.0'),
                    style: cellStyle,
                  ),
                ),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('Front Right', style: cellStyle)),
                DataCell(
                  Text(
                    (_telemetry['tire_pressure']?['front_right']
                            ?.toStringAsFixed(1) ??
                        '0.0'),
                    style: cellStyle,
                  ),
                ),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('Rear Left', style: cellStyle)),
                DataCell(
                  Text(
                    (_telemetry['tire_pressure']?['rear_left']?.toStringAsFixed(
                          1,
                        ) ??
                        '0.0'),
                    style: cellStyle,
                  ),
                ),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('Rear Right', style: cellStyle)),
                DataCell(
                  Text(
                    (_telemetry['tire_pressure']?['rear_right']
                            ?.toStringAsFixed(1) ??
                        '0.0'),
                    style: cellStyle,
                  ),
                ),
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
                DataCell(
                  Text(
                    (_telemetry['battery_cells']?['block_a']?.toStringAsFixed(
                          1,
                        ) ??
                        '0.0'),
                    style: cellStyle,
                  ),
                ),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('Block B (9-16)', style: cellStyle)),
                DataCell(
                  Text(
                    (_telemetry['battery_cells']?['block_b']?.toStringAsFixed(
                          1,
                        ) ??
                        '0.0'),
                    style: cellStyle,
                  ),
                ),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('Block C (17-24)', style: cellStyle)),
                DataCell(
                  Text(
                    (_telemetry['battery_cells']?['block_c']?.toStringAsFixed(
                          1,
                        ) ??
                        '0.0'),
                    style: cellStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 4. The GPS information panel
  Widget _buildGpsSection() {
    // Get real-time GPS data from backend
    final gps = _telemetry['gps'] ?? {};
    final satellites = gps['satellites']?.toString() ?? '0';
    final latitude = gps['latitude']?.toStringAsFixed(4) ?? '0.0000';
    final longitude = gps['longitude']?.toStringAsFixed(4) ?? '0.0000';
    final altitude = gps['altitude']?.toStringAsFixed(1) ?? '0.0';
    final canBusConnected = _telemetry['connectivity']?['can_bus'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _GpsInfoRow(label: 'Satellites Locked', value: '$satellites / 22'),
          _GpsInfoRow(label: 'Latitude', value: '$latitude° N'),
          _GpsInfoRow(label: 'Longitude', value: '$longitude° E'),
          _GpsInfoRow(label: 'Altitude', value: '$altitude m'),
          _GpsInfoRow(
            label: 'CAN Bus Status',
            value: canBusConnected ? 'Connected' : 'Disconnected',
            valueColor: canBusConnected ? Colors.greenAccent : Colors.redAccent,
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

  /// Battery SoC Chart (LIVE DATA)
  Widget _buildBatteryChart() {
    final data = _chartData.batteryData;
    return _buildRealTimeChart(
      'Battery SoC %',
      data,
      Colors.greenAccent,
      0,
      100,
    );
  }

  /// Speed Chart (LIVE DATA)
  Widget _buildSpeedChart() {
    final data = _chartData.speedData;
    return _buildRealTimeChart('Speed (km/h)', data, Colors.blueAccent, 0, 120);
  }

  /// Power Chart (LIVE DATA)
  Widget _buildPowerChart() {
    final data = _chartData.powerData;
    return _buildRealTimeChart('Power (kW)', data, Colors.orangeAccent, 0, 100);
  }

  /// Helper method to build a real-time line chart
  Widget _buildRealTimeChart(
    String title,
    List<ChartDataPoint> data,
    Color color,
    double minY,
    double maxY,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 4),
        // Show current value
        Text(
          data.isNotEmpty ? data.last.y.toStringAsFixed(1) : '0.0',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: data.isEmpty
                ? const Center(
                    child: Text(
                      'Collecting data...',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: data
                              .map((point) => FlSpot(point.x, point.y))
                              .toList(),
                          isCurved: true,
                          color: color,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withOpacity(0.2),
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

  /// Build analytics section with performance metrics
  Widget _buildAnalyticsSection() {
    final batterySoc = _telemetry['battery_soc']?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Eco-driving score (large display)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    _analytics.ecoDrivingScore.toStringAsFixed(0),
                    style: TextStyle(
                      color: _getScoreColor(_analytics.ecoDrivingScore),
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Eco Score',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    'Rating: ${_analytics.efficiencyRating}',
                    style: TextStyle(
                      color: _getScoreColor(_analytics.ecoDrivingScore),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Metrics grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAnalyticsMetric(
                'Energy',
                '${_analytics.energyConsumption.toStringAsFixed(1)} kWh/100km',
                Icons.battery_charging_full,
                Colors.greenAccent,
              ),
              _buildAnalyticsMetric(
                'Avg Speed',
                '${_analytics.averageSpeed.toStringAsFixed(0)} km/h',
                Icons.speed,
                Colors.blueAccent,
              ),
              _buildAnalyticsMetric(
                'Regen',
                '${_analytics.regenEfficiency.toStringAsFixed(0)}%',
                Icons.autorenew,
                Colors.purpleAccent,
              ),
              _buildAnalyticsMetric(
                'Range',
                '${_analytics.getRangePrediction(batterySoc).toStringAsFixed(0)} km',
                Icons.route,
                Colors.orangeAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trip statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTripStat(
                'Distance',
                '${_analytics.totalDistance.toStringAsFixed(1)} km',
              ),
              _buildTripStat(
                'Energy Used',
                '${_analytics.totalEnergyUsed.toStringAsFixed(2)} kWh',
              ),
              _buildTripStat(
                'Trip Time',
                _formatDuration(_analytics.tripDuration),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _analytics.resetTrip();
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset Trip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build analytics metric widget
  Widget _buildAnalyticsMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  /// Build trip statistic widget
  Widget _buildTripStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  /// Get color based on score
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 60) return Colors.blueAccent;
    if (score >= 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  /// Format duration
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
