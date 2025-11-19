// lib/views/map_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ev_smart_screen/services/backend_service.dart';
import 'package:ev_smart_screen/services/routing_service.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // Backend service
  final BackendService _backend = BackendService();
  Map<String, dynamic> _telemetry = {};

  // Map controller
  final MapController _mapController = MapController();

  // Current vehicle position
  LatLng _vehiclePosition = const LatLng(
    28.4595,
    77.0266,
  ); // Default: Gurgaon, India

  // Route tracking
  final List<LatLng> _routePoints = [];

  // Connection state
  bool _isConnected = false;
  String _connectionStatus = 'Connecting...';

  // Map settings
  bool _followVehicle = true;
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _connectToBackend();
  }

  @override
  void dispose() {
    _backend.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Search for a place using real geocoding API
  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await _routingService.searchPlace(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No results found. Try a different search.'),
            backgroundColor: Colors.orangeAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Select a search result and calculate route
  Future<void> _selectSearchResult(SearchResult result) async {
    setState(() {
      _destination = result.location;
      _searchResults = [];
      _showSearch = false;
      _searchController.clear();
      _followVehicle = false;
      _isSearching = true;
    });

    // Animate to show both vehicle and destination
    final bounds = LatLngBounds(_vehiclePosition, result.location);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );

    // Calculate route
    try {
      final route = await _routingService.getRoute(
        _vehiclePosition,
        result.location,
      );

      if (route != null) {
        setState(() {
          _currentRoute = route;
          _isSearching = false;
          _showDirections = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Route: ${route.formattedDistance}, ETA ${route.formattedDuration}',
            ),
            backgroundColor: Colors.greenAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _isSearching = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find route to destination'),
            backgroundColor: Colors.orangeAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Routing failed: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Clear current route
  void _clearRoute() {
    setState(() {
      _currentRoute = null;
      _destination = null;
      _showDirections = false;
      _routePoints.clear();
    });
  }

  /// Connect to backend and listen for GPS updates
  Future<void> _connectToBackend() async {
    await _backend.connect();

    // Listen for telemetry updates
    _backend.telemetryStream.listen(
      (data) {
        setState(() {
          _telemetry = data;
          _isConnected = true;
          _connectionStatus = 'Connected';

          // Update vehicle position from GPS data
          final gps = data['gps'];
          if (gps != null) {
            final lat = gps['latitude']?.toDouble() ?? 28.4595;
            final lon = gps['longitude']?.toDouble() ?? 77.0266;

            _vehiclePosition = LatLng(lat, lon);

            // Add to route tracking
            if (_routePoints.isEmpty ||
                _routePoints.last.latitude != lat ||
                _routePoints.last.longitude != lon) {
              _routePoints.add(_vehiclePosition);

              // Keep only last 500 points (about 8 minutes at 1 update/sec)
              if (_routePoints.length > 500) {
                _routePoints.removeAt(0);
              }
            }

            // Auto-center map on vehicle if follow mode is enabled
            if (_followVehicle) {
              _mapController.move(_vehiclePosition, _currentZoom);
            }
          }
        });
      },
      onError: (error) {
        setState(() {
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

  // Search controller
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  // Routing service
  final RoutingService _routingService = RoutingService();

  // Search results
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  // Route data
  RouteResult? _currentRoute;
  LatLng? _destination;
  bool _showDirections = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for a place...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  suffixIcon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _showSearch = false;
                              _searchResults = [];
                            });
                          },
                        ),
                ),
                onChanged: (value) {
                  if (value.length > 2) {
                    _searchPlace(value);
                  }
                },
                onSubmitted: (value) {
                  _searchPlace(value);
                },
              )
            : const Text('Navigation & Map'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _showSearch
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showSearch = false;
                    _searchController.clear();
                  });
                },
              )
            : null,
        actions: [
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showSearch = true;
                });
              },
              tooltip: 'Search place',
            ),
          // Connection status
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnected ? Icons.gps_fixed : Icons.gps_off,
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
          // Follow vehicle toggle
          IconButton(
            icon: Icon(
              _followVehicle ? Icons.my_location : Icons.location_searching,
              color: _followVehicle ? Colors.blueAccent : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _followVehicle = !_followVehicle;
                if (_followVehicle) {
                  _mapController.move(_vehiclePosition, _currentZoom);
                }
              });
            },
            tooltip: _followVehicle ? 'Following vehicle' : 'Free navigation',
          ),
          // Clear route
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.orangeAccent),
            onPressed: () {
              setState(() {
                _routePoints.clear();
              });
            },
            tooltip: 'Clear route',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _vehiclePosition,
              initialZoom: _currentZoom,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  // User is manually moving the map
                  setState(() {
                    _followVehicle = false;
                    _currentZoom = position.zoom;
                  });
                }
              },
            ),
            children: [
              // Tile layer (map tiles from OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bmu.ev_smart_screen',
              ),

              // Travel history polyline (light blue)
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 3.0,
                      color: Colors.lightBlueAccent.withOpacity(0.5),
                    ),
                  ],
                ),

              // Calculated route polyline (bright blue)
              if (_currentRoute != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _currentRoute!.routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blueAccent,
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),

              // Markers layer
              MarkerLayer(
                markers: [
                  // Vehicle marker
                  Marker(
                    point: _vehiclePosition,
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.blueAccent,
                        size: 30,
                      ),
                    ),
                  ),
                  // Destination marker
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Search results dropdown
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1B2B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.blueAccent,
                        ),
                        title: Text(
                          result.displayName,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          result.type,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () => _selectSearchResult(result),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Route info panel (top)
          if (_currentRoute != null && !_showSearch)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1B2B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions,
                        color: Colors.blueAccent,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_currentRoute!.formattedDistance} • ${_currentRoute!.formattedDuration}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_currentRoute!.steps.length} steps',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.list, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _showDirections = !_showDirections;
                          });
                        },
                        tooltip: 'Show directions',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _clearRoute,
                        tooltip: 'Clear route',
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Turn-by-turn directions panel
          if (_showDirections && _currentRoute != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              bottom: 100,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1B2B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Turn-by-Turn Directions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showDirections = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _currentRoute!.steps.length,
                          itemBuilder: (context, index) {
                            final step = _currentRoute!.steps[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                step.instruction,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                step.formattedDistance,
                                style: const TextStyle(color: Colors.white54),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Data overlay panel (bottom)
          if (!_showDirections)
            Positioned(bottom: 0, left: 0, right: 0, child: _buildDataPanel()),
        ],
      ),
    );
  }

  /// Build data panel with GPS info and stats
  Widget _buildDataPanel() {
    final gps = _telemetry['gps'] ?? {};
    final speed = _telemetry['speed']?.toDouble() ?? 0.0;
    final heading = gps['heading']?.toDouble() ?? 0.0;
    final altitude = gps['altitude']?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // GPS Data
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDataItem(
                'Speed',
                '${speed.toStringAsFixed(0)} km/h',
                Icons.speed,
                Colors.blueAccent,
              ),
              _buildDataItem(
                'Heading',
                '${heading.toStringAsFixed(0)}°',
                Icons.explore,
                Colors.greenAccent,
              ),
              _buildDataItem(
                'Altitude',
                '${altitude.toStringAsFixed(0)} m',
                Icons.terrain,
                Colors.orangeAccent,
              ),
              _buildDataItem(
                'Route Points',
                '${_routePoints.length}',
                Icons.route,
                Colors.purpleAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Coordinates
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                '${_vehiclePosition.latitude.toStringAsFixed(6)}, ${_vehiclePosition.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual data item
  Widget _buildDataItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
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
}
