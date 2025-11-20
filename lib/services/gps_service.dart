import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:ev_smart_screen/services/platform_service.dart';
import 'package:ev_smart_screen/services/logger_service.dart';

/// Immutable GPS coordinate snapshot
class GPSCoordinate {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed; // m/s
  final double? heading; // degrees
  final double accuracy; // meters
  final DateTime timestamp;
  final String source; // gps | ip | mock

  const GPSCoordinate({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.heading,
    required this.accuracy,
    required this.timestamp,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lon': longitude,
        'alt': altitude,
        'speed': speed,
        'heading': heading,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
        'source': source,
      };
}

/// GPS Service implementing real, IP fallback and mock modes
class GPSService {
  static final GPSService _instance = GPSService._internal();
  static GPSService get instance => _instance;

  GPSService._internal();

  final StreamController<GPSCoordinate> _controller =
      StreamController<GPSCoordinate>.broadcast();
  Stream<GPSCoordinate> get locationStream => _controller.stream;

  GPSCoordinate? _last;
  GPSCoordinate? get lastKnown => _last;

  StreamSubscription<Position>? _positionSub;
  Timer? _ipTimer;
  Timer? _mockTimer;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      AppLogger.warning('GPS already initialized');
      return;
    }

    final platform = PlatformService.instance;

    if (platform.shouldUseMockGPS) {
      AppLogger.info('GPS: Starting MOCK mode');
      _startMock();
      _initialized = true;
      return;
    }

    // Attempt real location first
    final success = await _startReal();
    if (!success) {
      AppLogger.warning('GPS: Real location unavailable, using IP fallback');
      await _startIpFallback();
    }
    _initialized = true;
  }

  Future<bool> _startReal() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Location permission denied');
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permission permanently denied');
        return false;
      }

      // Initial position
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
        _emit(_coordFromPosition(pos, source: 'gps'));
        AppLogger.info(
            'GPS: Initial position (${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})');
      } catch (e) {
        AppLogger.warning('GPS: Failed initial position', error: e);
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        _emit(_coordFromPosition(pos, source: pos.isMocked ? 'mock' : 'gps'));
      }, onError: (e) {
        AppLogger.error('GPS stream error', error: e);
      });

      AppLogger.info('GPS: Real tracking active');
      return true;
    } catch (e) {
      AppLogger.error('GPS: Real init failed', error: e);
      return false;
    }
  }

  GPSCoordinate _coordFromPosition(Position p, {required String source}) {
    return GPSCoordinate(
      latitude: p.latitude,
      longitude: p.longitude,
      altitude: p.altitude,
      speed: p.speed == 0 ? null : p.speed,
      heading: p.heading == 0 ? null : p.heading,
      accuracy: p.accuracy,
      // Position.timestamp is non-null in current geolocator versions; keep direct use
      timestamp: p.timestamp,
      source: source,
    );
  }

  Future<void> _startIpFallback() async {
    await _fetchIpLocation();
    _ipTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _fetchIpLocation();
    });
  }

  Future<void> _fetchIpLocation() async {
    try {
      final resp = await http
          .get(Uri.parse('http://ip-api.com/json/'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['status'] == 'success') {
          _emit(GPSCoordinate(
            latitude: (data['lat'] as num).toDouble(),
            longitude: (data['lon'] as num).toDouble(),
            altitude: null,
            speed: null,
            heading: null,
            accuracy: 5000, // city-level
            timestamp: DateTime.now(),
            source: 'ip',
          ));
          AppLogger.info('GPS: IP location ${data['city']}, ${data['country']}');
        }
      }
    } catch (e) {
      AppLogger.error('IP geolocation failed', error: e);
    }
  }

  void _startMock() {
    // Chandigarh demo route
    double lat = 30.7333;
    double lon = 76.7794;
    double heading = 0.0;
    const double speedMs = 8.33; // ~30 km/h
    final rand = Random();

    _emit(GPSCoordinate(
      latitude: lat,
      longitude: lon,
      altitude: 300,
      speed: speedMs,
      heading: heading,
      accuracy: 10,
      timestamp: DateTime.now(),
      source: 'mock',
    ));

    _mockTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final distanceKm = (speedMs * 2) / 1000;
      lat += distanceKm * cos(heading * pi / 180) / 111.0;
      lon += distanceKm * sin(heading * pi / 180) /
          (111.0 * cos(lat * pi / 180));
      if (rand.nextDouble() < 0.15) {
        heading = (heading + rand.nextDouble() * 90 - 45) % 360;
      }
      _emit(GPSCoordinate(
        latitude: lat,
        longitude: lon,
        altitude: 300 + rand.nextDouble() * 5,
        speed: speedMs + rand.nextDouble() * 1.5 - 0.75,
        heading: heading,
        accuracy: 10,
        timestamp: DateTime.now(),
        source: 'mock',
      ));
    });
  }

  void _emit(GPSCoordinate coord) {
    _last = coord;
    if (!_controller.isClosed) {
      _controller.add(coord);
    }
  }

  void dispose() {
    _positionSub?.cancel();
    _ipTimer?.cancel();
    _mockTimer?.cancel();
    _controller.close();
    AppLogger.info('GPS: Service disposed');
  }
}
