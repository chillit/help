import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(37.7739872, -122.431297),
    zoom: 11.5,
  );
  late GoogleMapController _googleMapController;
  Map<MarkerId, Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final List<LatLng> marathonRoute = [
    const LatLng(37.773972, -122.431297),
    const LatLng(37.774900, -122.419415),
    const LatLng(37.781500, -122.410050),
    const LatLng(37.793200, -122.397800),
    const LatLng(37.802900, -122.405700),
    const LatLng(37.808000, -122.417900),
    const LatLng(37.801400, -122.433700),
  ];

  @override
  void initState() {
    super.initState();
    _createPolyline();
  }

  void _createPolyline() {
    _polylines.add(Polyline(
      polylineId: const PolylineId('marathonRoute'),
      points: marathonRoute,
      color: Colors.blue,
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    ));
  }

  Future<void> _loadMarkers() async {
    final BitmapDescriptor startIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(90, 90)),
      'assets/start.png',
    );

    final BitmapDescriptor finishIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(90, 90)),
      'assets/finish.png',
    );

    final BitmapDescriptor runnerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(32, 32)),
      'assets/mikey.png',
    );

    setState(() {
      _markers[const MarkerId('start')] = Marker(
        markerId: const MarkerId('start'),
        position: marathonRoute.first,
        icon: startIcon,
        infoWindow: const InfoWindow(title: 'Start Line'),
      );

      _markers[const MarkerId('finish')] = Marker(
        markerId: const MarkerId('finish'),
        position: marathonRoute.last,
        icon: finishIcon,
        infoWindow: const InfoWindow(title: 'Finish Line'),
      );

      _markers[const MarkerId('runner')] = Marker(
        markerId: const MarkerId('runner'),
        position: marathonRoute[1],
        icon: runnerIcon,
        infoWindow: const InfoWindow(title: 'runner'),
      );
    });
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        title: Text(
          '🏆 Marathon Prize',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Add share functionality here
            },
          ),
        ],
      ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                ),
                child: Text(
                  'Leaderboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              _buildLeaderboardEntry('John Doe', 5.4, Icons.directions_run),
              _buildLeaderboardEntry('Jane Smith', 8.2, Icons.directions_run),
              _buildLeaderboardEntry('Alex Brown', 12.3, Icons.directions_run),
            ],
          ),
        ),
    body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        onMapCreated: (controller) async {
          _googleMapController = controller;
          await _loadMarkers();
        },
        markers: _markers.values.toSet(),
        polylines: _polylines,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () => _googleMapController.animateCamera(
              CameraUpdate.newCameraPosition(_initialCameraPosition),
            ),
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: Colors.blue,
            onPressed: _zoomToRoute,
            child: const Icon(Icons.zoom_out_map),
          ),
        ],
      ),
    );
  }

  void _zoomToRoute() {
    final bounds = _calculateBounds(marathonRoute);
    _googleMapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    for (final point in points) {
      minLat = (minLat == null || point.latitude < minLat) ? point.latitude : minLat;
      maxLat = (maxLat == null || point.latitude > maxLat) ? point.latitude : maxLat;
      minLng = (minLng == null || point.longitude < minLng) ? point.longitude : minLng;
      maxLng = (maxLng == null || point.longitude > maxLng) ? point.longitude : maxLng;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }
}
Widget _buildLeaderboardEntry(String name, double kilometers, IconData icon) {
  return ListTile(
    leading: Icon(icon, color: Colors.deepPurple),
    title: Text(
      name,
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    subtitle: Text('$kilometers km', style: TextStyle(color: Colors.grey)),
    trailing: Icon(Icons.star_border, color: Colors.deepPurple), // Optional: Star icon for rankings
    onTap: () {
      // Add functionality if needed, for example, navigate to their profile or stats
    },
  );
}