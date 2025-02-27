import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  LatLng? _selectedLocation;
  Marker? _selectedMarker;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('locations');
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  Map<MarkerId, Marker> _markers = {}; // To store the markers from the database
  Uint8List? fileBytes;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations(); // Load saved locations when the screen is initialized
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  // Load saved locations from Firebase
  void _loadSavedLocations() {
    _databaseRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _markers.clear();
          data.forEach((key, value) {
            final latitude = value['latitude'] as double;
            final longitude = value['longitude'] as double;
            final imageUrl = value['photo'] as String?;

            final markerId = MarkerId(key);
            final marker = Marker(
              markerId: markerId,
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(title: 'Saved Location'),
              onTap: () => _showImageBottomSheet(imageUrl),
            );
            _markers[markerId] = marker;
          });
        });
      }
    });
  }

  // Add marker on map tap
  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _selectedMarker = Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
      );
    });
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 150,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () => _takePhoto(),
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Save Location Without Photo'),
              onTap: () {
                Navigator.pop(context);
                _saveLocationToDatabase();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      Navigator.pop(context);
      _saveLocationToDatabase();
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photo taken!')),
      );
    }
  }

  Future<void> _saveLocationToDatabase() async {
    if (_selectedLocation != null) {
      String? imageUrl;

      // Upload the image to Firebase Storage if a photo was taken
      if (_imageFile != null) {
        try {
          // Create a reference to Firebase Storage
          final ref = FirebaseStorage.instance
              .ref('locations/${DateTime.now().millisecondsSinceEpoch}/image');

          // Upload the image file to Firebase Storage
          final uploadTask = await ref.putFile(_imageFile!);

          // Get the download URL of the uploaded image
          imageUrl = await uploadTask.ref.getDownloadURL();
        } catch (e) {
          print('Failed to upload image: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image!')),
          );
          return; // Exit the function if the image upload failed
        }
      }

      // Save the location data (including image URL) to Firebase Realtime Database
      final newLocationRef = _databaseRef.push();
      await newLocationRef.set({
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'photo': imageUrl, // Store the image URL or null if no photo was taken
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved to database!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first!')),
      );
    }
  }

  // Show bottom sheet with image
  void _showImageBottomSheet(String? imageUrl) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Image', style: TextStyle(fontSize: 18)),
              ),
              Expanded(
                child: imageUrl != null
                    ? FutureBuilder(
                  future: _loadImage(imageUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text('Failed to load image!'),
                      );
                    } else {
                      return Image.network(
                        imageUrl,
                        width: MediaQuery.of(context).size.width, // Full screen width
                        fit: BoxFit.cover,
                      );
                    }
                  },
                )
                    : const Center(
                  child: Text('No image available for this location!'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadImage(String imageUrl) async {
    // Simulate loading image from the network
    await Future.delayed(const Duration(seconds: 2)); // Simulate delay for loading
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        onMapCreated: (controller) => _googleMapController = controller,
        markers: _markers.values.toSet(), // Display saved markers from Firebase
        onTap: _onMapTapped,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.black,
            onPressed: () {
              _googleMapController.animateCamera(
                CameraUpdate.newCameraPosition(_initialCameraPosition),
              );
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _showBottomSheet,
            child: const Icon(Icons.save),
          ),
        ],
      ),
    );
  }
}

