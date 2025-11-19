import 'dart:collection';

/// Service to manage historical data for charts
/// Stores last 300 data points (5 minutes at 1 second intervals)
class ChartDataService {
  static const int maxDataPoints = 300; // 5 minutes of data

  // Historical data storage
  final Queue<ChartDataPoint> _batteryData = Queue<ChartDataPoint>();
  final Queue<ChartDataPoint> _speedData = Queue<ChartDataPoint>();
  final Queue<ChartDataPoint> _powerData = Queue<ChartDataPoint>();

  // Current time offset for X-axis
  int _timeOffset = 0;

  /// Add new telemetry data point
  void addDataPoint(Map<String, dynamic> telemetry) {
    final timestamp = _timeOffset++;

    // Extract values with null safety
    final batteryLevel = telemetry['battery_soc']?.toDouble() ?? 0.0;
    final speed = telemetry['speed']?.toDouble() ?? 0.0;
    final power = telemetry['power_kw']?.toDouble() ?? 0.0;

    // Add new data points
    _batteryData.add(ChartDataPoint(timestamp.toDouble(), batteryLevel));
    _speedData.add(ChartDataPoint(timestamp.toDouble(), speed));
    _powerData.add(ChartDataPoint(timestamp.toDouble(), power));

    // Remove old data points if we exceed max
    if (_batteryData.length > maxDataPoints) {
      _batteryData.removeFirst();
    }
    if (_speedData.length > maxDataPoints) {
      _speedData.removeFirst();
    }
    if (_powerData.length > maxDataPoints) {
      _powerData.removeFirst();
    }
  }

  /// Get battery SoC data for chart
  List<ChartDataPoint> get batteryData => _batteryData.toList();

  /// Get speed data for chart
  List<ChartDataPoint> get speedData => _speedData.toList();

  /// Get power data for chart
  List<ChartDataPoint> get powerData => _powerData.toList();

  /// Clear all historical data
  void clearData() {
    _batteryData.clear();
    _speedData.clear();
    _powerData.clear();
    _timeOffset = 0;
  }

  /// Get data count
  int get dataPointCount => _batteryData.length;
}

/// Data point for charts
class ChartDataPoint {
  final double x; // Time (seconds)
  final double y; // Value

  ChartDataPoint(this.x, this.y);
}
