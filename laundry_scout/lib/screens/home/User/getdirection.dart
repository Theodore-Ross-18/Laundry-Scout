import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_route_service/open_route_service.dart';

class GetDirectionScreen extends StatefulWidget {
  final double destinationLatitude;
  final double destinationLongitude;
  final String businessName;

  const GetDirectionScreen({
    super.key,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.businessName,
  });

  @override
  State<GetDirectionScreen> createState() => _GetDirectionScreenState();
}

class _GetDirectionScreenState extends State<GetDirectionScreen> {
  LatLng? _currentLocation;
  String _distance = 'Calculating...';
  bool _isLoading = true;
  String _errorMessage = '';
  List<LatLng> _routePoints = [];
  String _openRouteServiceApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImRhZDU5OTdjOGJmMDQ4Nzg4YjMyZDhjM2EzNTUzODkwIiwiaCI6Im11cm11cjY0In0=';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = 'Location services are disabled. Please enable them.';
        _isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Location permissions are denied.';
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'Location permissions are permanently denied, we cannot request permissions.';
        _isLoading = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      await _getRoute(); 
      _isLoading = false;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get current location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getRoute() async {
    if (_currentLocation == null) return;

    final OpenRouteService client = OpenRouteService(apiKey: _openRouteServiceApiKey);

    try {
      final List<ORSCoordinate> routeCoordinates = await client.directionsRouteCoordsGet(
        startCoordinate: ORSCoordinate(latitude: _currentLocation!.latitude, longitude: _currentLocation!.longitude),
        endCoordinate: ORSCoordinate(latitude: widget.destinationLatitude, longitude: widget.destinationLongitude),
      );

      List<LatLng> points = routeCoordinates.map((coordinate) => LatLng(coordinate.latitude, coordinate.longitude)).toList();

      double totalDistance = 0.0;
      for (int i = 0; i < points.length - 1; i++) {
        totalDistance += Geolocator.distanceBetween(
          points[i].latitude,
          points[i].longitude,
          points[i + 1].latitude,
          points[i + 1].longitude,
        );
      }

      setState(() {
        _routePoints = points;
        _distance = '${(totalDistance / 1000).toStringAsFixed(2)} km';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get route: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Directions to ${widget.businessName}'),
        backgroundColor: const Color(0xFF6F5ADC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentLocation ?? LatLng(widget.destinationLatitude, widget.destinationLongitude),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_currentLocation != null)
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: _currentLocation!,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 40.0,
                            ),
                          ),
                        Marker(
                          width: 80.0,
                          height: 80.0,
                          point: LatLng(widget.destinationLatitude, widget.destinationLongitude),
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40.0,
                          ),
                        ),
                      ],
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: Color(0xFF5A35E3),
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                  ],
                ),
      bottomNavigationBar: _currentLocation != null && _routePoints.isNotEmpty
          ? BottomAppBar(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Distance: $_distance',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6F5ADC)),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : null,
    );
  }
}