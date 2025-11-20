import 'package:ev_smart_screen/services/logger_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Routing service using OpenStreetMap APIs
/// - Nominatim for geocoding (address → coordinates)
/// - OSRM for routing (A → B with turn-by-turn)
class RoutingService {
  // API endpoints
  static const String nominatimUrl = 'https://nominatim.openstreetmap.org';
  static const String osrmUrl = 'https://router.project-osrm.org';

  /// Search for a place and get coordinates (Geocoding)
  /// Uses Nominatim API - free and open source
  /// Biased towards India region for relevant results
  Future<List<SearchResult>> searchPlace(String query) async {
    if (query.isEmpty) return [];

    try {
      // Prioritize India in search
      final searchQuery = query;
      
      // Viewbox for North India (Delhi-NCR, Rajasthan, Haryana region)
      // This covers Bhiwadi, Gurgaon, Delhi, etc.
      // Format: left(west),top(north),right(east),bottom(south)
      final url = Uri.parse(
        '$nominatimUrl/search?q=${Uri.encodeComponent(searchQuery)}&format=json&limit=10&addressdetails=1&countrycodes=in&viewbox=75.0,30.0,78.5,26.0&bounded=0',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'EV-Smart-Screen/1.0 (guneet.chawla.22cse@bmu.edu.in)',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => SearchResult.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error searching place', error: e);
      return [];
    }
  }

  /// Get route from current location to destination
  /// Uses OSRM API - free routing service
  Future<RouteResult?> getRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        '$osrmUrl/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          return RouteResult.fromJson(data['routes'][0]);
        } else {
          throw Exception('No route found');
        }
      } else {
        throw Exception('Failed to get route: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error getting route', error: e);
      return null;
    }
  }

  /// Get reverse geocoding (coordinates → address)
  Future<String?> reverseGeocode(LatLng location) async {
    try {
      final url = Uri.parse(
        '$nominatimUrl/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'EV-Smart-Screen/1.0 (guneet.chawla.22cse@bmu.edu.in)',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'];
      }
    } catch (e) {
      AppLogger.error('Error reverse geocoding', error: e);
    }
    return null;
  }
}

/// Search result from geocoding
class SearchResult {
  final String displayName;
  final LatLng location;
  final String type;
  final Map<String, dynamic> address;

  SearchResult({
    required this.displayName,
    required this.location,
    required this.type,
    required this.address,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      displayName: json['display_name'] ?? '',
      location: LatLng(double.parse(json['lat']), double.parse(json['lon'])),
      type: json['type'] ?? '',
      address: json['address'] ?? {},
    );
  }
}

/// Route result with turn-by-turn directions
class RouteResult {
  final List<LatLng> routePoints;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;

  RouteResult({
    required this.routePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    // Parse route geometry
    final geometry = json['geometry']['coordinates'] as List;
    final routePoints = geometry.map((coord) {
      return LatLng(coord[1].toDouble(), coord[0].toDouble());
    }).toList();

    // Parse steps
    final legs = json['legs'] as List;
    final List<RouteStep> steps = [];

    for (var leg in legs) {
      final legSteps = leg['steps'] as List;
      for (var step in legSteps) {
        steps.add(RouteStep.fromJson(step));
      }
    }

    return RouteResult(
      routePoints: routePoints,
      distanceMeters: json['distance'].toDouble(),
      durationSeconds: json['duration'].toDouble(),
      steps: steps,
    );
  }

  /// Get formatted distance (e.g., "5.2 km" or "850 m")
  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
  }

  /// Get formatted duration (e.g., "15 min" or "1h 30m")
  String get formattedDuration {
    final minutes = (durationSeconds / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    } else {
      return '$minutes min';
    }
  }
}

/// Individual step in route
class RouteStep {
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final String maneuver;

  RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuver,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final maneuverData = json['maneuver'];
    String instruction = '';

    // Build instruction from maneuver type
    final type = maneuverData['type'] ?? '';
    final modifier = maneuverData['modifier'] ?? '';

    if (type == 'depart') {
      instruction = 'Head $modifier';
    } else if (type == 'arrive') {
      instruction = 'Arrive at destination';
    } else if (type == 'turn') {
      instruction = 'Turn $modifier';
    } else if (type == 'merge') {
      instruction = 'Merge $modifier';
    } else if (type == 'roundabout') {
      instruction = 'Take roundabout';
    } else {
      instruction = 'Continue $modifier';
    }

    // Add street name if available
    if (json['name'] != null && json['name'] != '') {
      instruction += ' onto ${json['name']}';
    }

    return RouteStep(
      instruction: instruction,
      distanceMeters: json['distance'].toDouble(),
      durationSeconds: json['duration'].toDouble(),
      maneuver: type,
    );
  }

  /// Get formatted distance
  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
  }
}
