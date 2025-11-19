import 'dart:collection';

/// Analytics service for calculating efficiency metrics and performance scores
class AnalyticsService {
  // Historical data for calculations
  final Queue<AnalyticsDataPoint> _dataPoints = Queue<AnalyticsDataPoint>();
  static const int maxDataPoints = 300; // 5 minutes of data

  // Trip statistics
  double _totalDistance = 0.0; // km
  double _totalEnergyUsed = 0.0; // kWh
  DateTime? _tripStartTime;

  /// Add new telemetry data point
  void addDataPoint(Map<String, dynamic> telemetry) {
    final timestamp = DateTime.now();

    // Extract values
    final speed = telemetry['speed']?.toDouble() ?? 0.0;
    final power = telemetry['power_kw']?.toDouble() ?? 0.0;
    final batterySoc = telemetry['battery_soc']?.toDouble() ?? 0.0;

    // Create data point
    final dataPoint = AnalyticsDataPoint(
      timestamp: timestamp,
      speed: speed,
      power: power,
      batterySoc: batterySoc,
    );

    _dataPoints.add(dataPoint);

    // Remove old data points
    if (_dataPoints.length > maxDataPoints) {
      _dataPoints.removeFirst();
    }

    // Update trip statistics
    _tripStartTime ??= timestamp;

    // Calculate distance (speed * time interval)
    if (_dataPoints.length > 1) {
      final lastPoint = _dataPoints.elementAt(_dataPoints.length - 2);
      final timeInterval =
          timestamp.difference(lastPoint.timestamp).inSeconds / 3600.0; // hours
      _totalDistance += speed * timeInterval;
    }

    // Calculate energy used (power * time interval)
    if (_dataPoints.length > 1) {
      final lastPoint = _dataPoints.elementAt(_dataPoints.length - 2);
      final timeInterval =
          timestamp.difference(lastPoint.timestamp).inSeconds / 3600.0; // hours
      _totalEnergyUsed += power * timeInterval;
    }
  }

  /// Get energy consumption (kWh/100km)
  double get energyConsumption {
    if (_totalDistance < 0.1) return 0.0;
    return (_totalEnergyUsed / _totalDistance) * 100.0;
  }

  /// Get average speed (km/h)
  double get averageSpeed {
    if (_dataPoints.isEmpty) return 0.0;
    final sum = _dataPoints.fold<double>(
      0.0,
      (sum, point) => sum + point.speed,
    );
    return sum / _dataPoints.length;
  }

  /// Get eco-driving score (0-100)
  double get ecoDrivingScore {
    if (_dataPoints.isEmpty) return 0.0;

    double score = 100.0;

    // Penalty for high speeds (>80 km/h)
    final avgSpeed = averageSpeed;
    if (avgSpeed > 80) {
      score -= (avgSpeed - 80) * 0.5;
    }

    // Penalty for high energy consumption (>20 kWh/100km)
    final consumption = energyConsumption;
    if (consumption > 20) {
      score -= (consumption - 20) * 2.0;
    }

    // Penalty for aggressive acceleration/deceleration
    int aggressiveEvents = 0;
    for (int i = 1; i < _dataPoints.length; i++) {
      final current = _dataPoints.elementAt(i);
      final previous = _dataPoints.elementAt(i - 1);
      final speedChange = (current.speed - previous.speed).abs();

      if (speedChange > 10) {
        // Speed changed by more than 10 km/h in 1 second
        aggressiveEvents++;
      }
    }
    score -= aggressiveEvents * 0.5;

    // Clamp score between 0 and 100
    return score.clamp(0.0, 100.0);
  }

  /// Get efficiency rating (A+ to F)
  String get efficiencyRating {
    final score = ecoDrivingScore;
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    if (score >= 40) return 'E';
    return 'F';
  }

  /// Get trip duration
  Duration get tripDuration {
    if (_tripStartTime == null) return Duration.zero;
    return DateTime.now().difference(_tripStartTime!);
  }

  /// Get total distance traveled (km)
  double get totalDistance => _totalDistance;

  /// Get total energy used (kWh)
  double get totalEnergyUsed => _totalEnergyUsed;

  /// Get regenerative braking efficiency (%)
  double get regenEfficiency {
    if (_dataPoints.isEmpty) return 0.0;

    // Count negative power events (regenerative braking)
    int regenEvents = 0;
    double totalRegenPower = 0.0;

    for (var point in _dataPoints) {
      if (point.power < 0) {
        regenEvents++;
        totalRegenPower += point.power.abs();
      }
    }

    if (regenEvents == 0) return 0.0;

    // Calculate efficiency as percentage of total energy
    final avgRegenPower = totalRegenPower / regenEvents;
    return (avgRegenPower / 50.0 * 100.0).clamp(
      0.0,
      100.0,
    ); // Assume max 50kW regen
  }

  /// Get range prediction based on current driving (km)
  double getRangePrediction(double currentBatterySoc) {
    if (energyConsumption < 0.1) return 0.0;

    // Assume 75 kWh battery capacity (typical for EVs)
    const batteryCapacity = 75.0;
    final remainingEnergy = batteryCapacity * (currentBatterySoc / 100.0);

    // Calculate range based on current consumption
    return (remainingEnergy / energyConsumption) * 100.0;
  }

  /// Reset trip statistics
  void resetTrip() {
    _totalDistance = 0.0;
    _totalEnergyUsed = 0.0;
    _tripStartTime = null;
    _dataPoints.clear();
  }

  /// Clear all data
  void clearData() {
    _dataPoints.clear();
  }
}

/// Analytics data point
class AnalyticsDataPoint {
  final DateTime timestamp;
  final double speed;
  final double power;
  final double batterySoc;

  AnalyticsDataPoint({
    required this.timestamp,
    required this.speed,
    required this.power,
    required this.batterySoc,
  });
}
