import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html; // Web-specific import for file handling
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker_web/image_picker_web.dart'; // Web-specific image picker
import 'package:http/http.dart' as http;

import 'check_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(54.86667, 69.15),
    zoom: 11.5,
  );
  bool _isBottomSheetOpen = false;
  bool _mapInteractionEnabled = true;
  late GoogleMapController _googleMapController;
  LatLng? _selectedLocation;
  Marker? _selectedMarker;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('houses');
  html.File? _imageFile;
  Uint8List? fileBytes;
  Map<MarkerId, Marker> _markers = {};
  Map<CircleId, Circle> _circles = {}; // Store circles for pollution areas
  double _minPollutionLevel = 0;
  double _maxPollutionLevel = 5;
  List<List<String>> setsOfCategories = [
    ['littering', 'e-waste', 'plastic'],
    ['agro', 'water pollution']
  ];
  Set<String> _selectedCategories = {};  // Набор выбранных категорий
  User? currentUser; // Current authenticated user
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Add a variable to store the address
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    // Get the current user
    setState(() {
      currentUser = _auth.currentUser;
    });
  }

  Widget _buildCategoryChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: setsOfCategories.map((set) => Wrap(
        spacing: 8.0, // Горизонтальное расстояние между чипами
        runSpacing: 16.0, // Вертикальное расстояние между строками чипов
        children: set.map((category) => FilterChip(
          label: Text(category),
          selected: _selectedCategories.contains(category),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                _selectedCategories.add(category);
              } else {
                _selectedCategories.remove(category);
              }
              _loadSavedLocations();  // Обновляем маркеры при изменении фильтра
            });
          },
        )).toList(),
      )).toList(),
    );
  }

  Widget _buildResetButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedCategories.clear();  // Сбрасываем выбранные категории
            _loadSavedLocations();  // Обновляем маркеры
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Сбросить фильтры',
              style: TextStyle(
                fontWeight: FontWeight.w100,
                fontFamily: 'Futura',
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterControls() {
    return Column(
      children: [
        const Text('Фильтр по уровню загрязнения'),
        RangeSlider(
          values: RangeValues(_minPollutionLevel, _maxPollutionLevel),
          min: 0,
          max: 5,
          divisions: 5,
          labels: RangeLabels('$_minPollutionLevel', '$_maxPollutionLevel'),
          onChangeStart: (value) {
            setState(() {
              _mapInteractionEnabled = false;  // Отключаем взаимодействие с картой
            });
          },
          onChanged: (values) {
            setState(() {
              _minPollutionLevel = values.start;
              _maxPollutionLevel = values.end;
            });
            _loadSavedLocations();
          },
          onChangeEnd: (value) {
            setState(() {
              _mapInteractionEnabled = true;  // Включаем взаимодействие с картой
            });
          },
        ),
        _buildCategoryChips(),  // Фильтр с чипами
        SizedBox(height: 20),
        _buildResetButton(), // Добавляем фильтр по категориям
      ],
    );
  }

  // Add a new method to get address from coordinates using Google Maps Geocoding API
  Future<String?> getAddressFromLatLng(LatLng latLng) async {
    final apiKey = 'AIzaSyC2g8JTTTO8Du_nVVjFiK2zMNrt9J20yYE'; // Replace with your Google Maps API key
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // Get the first result which is typically the most accurate
          final addressComponents = data['results'][0]['address_components'];

          // Extract street name and house number
          String? streetName;
          String? streetNumber;

          for (var component in addressComponents) {
            List<String> types = List<String>.from(component['types']);

            if (types.contains('route')) {
              streetName = component['long_name'];
            }

            if (types.contains('street_number')) {
              streetNumber = component['long_name'];
            }
          }

          // Form the address
          if (streetName != null) {
            if (streetNumber != null) {
              return '$streetName, $streetNumber';
            } else {
              return streetName;
            }
          } else {
            // Return full formatted address if street components are not found
            return data['results'][0]['formatted_address'];
          }
        } else {
          print('Geocoding error: ${data['status']}');
          return null;
        }
      } else {
        print('Failed to get address: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error in geocoding: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  void _loadSavedLocations() {
    _databaseRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _markers.clear();
          _circles.clear();
          data.forEach((key, value) {
            final latitude = double.parse(value['latitude']);
            final longitude = double.parse(value['longitude']);
            final tip = value['advices'] as String?;
            final category = value['category'] as String?;
            final address = value['address'] as String?;
            final pollutionRating = value["level"] as int;
            final familyComposition = value["familyComposition"] as String?;
            final date = value["date"] as String?;
            final checker = value["instructorName"] as String?;
            final description = value["description"] as String?;


            if ((_selectedCategories.isEmpty || _selectedCategories.contains(category)) && (pollutionRating>=_minPollutionLevel && pollutionRating<=_maxPollutionLevel)) {
              final markerId = MarkerId(key);
              final marker = Marker(
                markerId: markerId,
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(
                  title: address ?? 'Сохраненное место', // Show address as the title if available
                  onTap: () {
                    _showImageBottomSheet(key, category!, address,tip,familyComposition,date,checker,description); // Pass address to the bottom sheet
                  },
                ),
                onTap: () => _showImageBottomSheet(key, category!,address,tip, familyComposition, date,checker,description),
              );
              _markers[markerId] = marker;

              if(pollutionRating != null) {
                final circleId = CircleId(key);

                // Create a color gradient from yellow to red (pollutionRating 1 = yellow, pollutionRating 5 = red)
                Color circleColor;
                if (pollutionRating == 1) {
                  circleColor = Colors.green;
                } else if (pollutionRating == 2) {
                  circleColor = Colors.yellow; // Between yellow and orange
                } else if (pollutionRating == 3) {
                  circleColor = Colors.orange; // Orange for pollutionRating 3
                } else if (pollutionRating == 4) {
                  circleColor = Color.lerp(Colors.orange, Colors.red, 0.5)!; // Between orange and red
                } else {
                  circleColor = Colors.red; // Pollution rating 5 = red
                }

                final circleRadius = 300.0; // Example radius, adjust as needed

                final circle = Circle(
                  circleId: circleId,
                  center: LatLng(latitude, longitude),
                  radius: circleRadius, // Radius in meters
                  strokeColor: circleColor.withOpacity(0.8),
                  fillColor: circleColor.withOpacity(0.3),
                  strokeWidth: 2,
                );
                _circles[circleId] = circle;
              }
            }
          });
        });
      }
    });
  }

  // Modify this method to get the address when tapping on the map
  void _onMapTapped(LatLng position) async {
    if (_isBottomSheetOpen) {
      return; // Не добавлять маркеры, если BottomSheet открыт
    }

    setState(() {
      _selectedLocation = position;
      _selectedAddress = "Loading address..."; // Показываем сообщение о загрузке

      // Добавляем или обновляем маркер с сообщением о загрузке
      final markerId = MarkerId('selected_location');
      _selectedMarker = Marker(
        markerId: markerId,
        position: position,
        infoWindow: InfoWindow(
          title: 'Выбранное место',
          snippet: 'Загрузка адреса...',
        ),
      );

      _markers[markerId] = _selectedMarker!;
    });

    // Получаем адрес и обновляем маркер
    final address = await getAddressFromLatLng(position);

    setState(() {
      _selectedAddress = address ?? "Адрес не найден";

      // Обновляем маркер с адресом
      final markerId = MarkerId('selected_location');
      _selectedMarker = Marker(
        markerId: markerId,
        position: position,
        infoWindow: InfoWindow(
          title: 'Выбранное место',
          snippet: _selectedAddress,
        ),
      );

      _markers[markerId] = _selectedMarker!;
    });
  }

  void _showBottomSheet() {
    final TextEditingController _descriptionController = TextEditingController();

    setState(() {
      _isBottomSheetOpen = true; // Устанавливаем флаг в true при открытии BottomSheet
    });

    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) {
          return FireCheckSheet(
            lat: _selectedLocation!.latitude.toString(),
            lon: _selectedLocation!.longitude.toString(),
            address: _selectedAddress ?? "",
            scrollController: scrollController,
          );
        },
      ),
    ).whenComplete(() {
      setState(() {
        _isBottomSheetOpen = false; // Устанавливаем флаг в false при закрытии BottomSheet
      });
    });
  }
  String location = "";



  String _encodeLocationKey(double latitude, double longitude) {
    return '${latitude.toString().replaceAll('.', '-')}_${longitude.toString().replaceAll('.', '-')}';
  }

  void _showImageBottomSheet(String location, String category, String? address, String? safetyAdvice, String? family, String? date, String? checker, String? description) {
    late OverlayEntry overlayEntry;
    bool isTipVisible = false; // Состояние видимости полного текста tip
    String truncatedAdvice = safetyAdvice != null && safetyAdvice.length > 50 ? '${safetyAdvice.substring(0, 50)}...' : safetyAdvice ?? '';
    String truncateddescription = description != null && description.length > 50 ? '${description.substring(0, 50)}...' : description ?? '';

    overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Positioned(
          right: 20,
          bottom: 20,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              height: 400,
              width: 600,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (address != null)
                      Text(
                        'Адрес: $address',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    if (category.isNotEmpty)
                      Text(
                        'Категория: $category',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    if (family != null)
                      Text(
                        'Семья: $family',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    if (date != null)
                      Text(
                        'Дата: $date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    if (checker != null)
                      Text(
                        'Инспектор: $checker',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    if (safetyAdvice != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Советы по безопасности: $truncatedAdvice',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Советы по безопасности"),
                                  content: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          Text(
                                            safetyAdvice,
                                            style: TextStyle(fontSize: 18),
                                            textAlign: TextAlign.left,
                                          ),
                                        ],
                                      )
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("Закрыть"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text("Показать полностью"),
                          ),
                        ],
                      ),
                    if (safetyAdvice != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Описание от Инструктора: $truncateddescription',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Описание от Инструктора"),
                                  content: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          Text(
                                            description!,
                                            style: TextStyle(fontSize: 18),
                                            textAlign: TextAlign.left,
                                          ),
                                        ],
                                      )
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("Закрыть"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text("Показать полностью"),
                          ),
                        ],
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            location = _encodeLocationKey(
                              _selectedLocation!.latitude,
                              _selectedLocation!.longitude,
                            );
                          },
                          child: Text("Сохранить"),
                        ),
                        SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            overlayEntry.remove();
                          },
                          child: Text("Закрыть"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(overlayEntry);

    Future.delayed(Duration(seconds: 7)).then((value) {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      onDrawerChanged: (isOpened) {
        setState(() {
          _isBottomSheetOpen = isOpened;
        });
      },
      appBar: AppBar(
        backgroundColor: Color(0xffee0003),
        title: const Text('Map Screen'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black,
            ),
            onPressed: () {},
            child: Text("Map view"),
          ),
          SizedBox(width: 10),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black,
            ),
            onPressed: () {
              if (_selectedLocation != null) {
                _showBottomSheet(); // Add a marker with an image
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please select a location on the map.')),
                );
              }
            },
            child: Text("Add mark"),
          ),
          SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xffee0003),
              ),
              child: Text(
                'Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            _buildFilterControls(),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_selectedAddress != null)
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.white,
              width: double.infinity,
              child: Text(
                'Выбранный адрес: $_selectedAddress',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: GoogleMap(
              gestureRecognizers: _mapInteractionEnabled && !_isBottomSheetOpen
                  ? <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer()),
              }
                  : <Factory<OneSequenceGestureRecognizer>>{},
              initialCameraPosition: _initialCameraPosition,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (controller) => _googleMapController = controller,
              markers: _markers.values.toSet(),
              circles: _circles.values.toSet(),
              onTap: _onMapTapped,
              scrollGesturesEnabled: _mapInteractionEnabled && !_isBottomSheetOpen,
              zoomGesturesEnabled: _mapInteractionEnabled && !_isBottomSheetOpen,
              rotateGesturesEnabled: _mapInteractionEnabled && !_isBottomSheetOpen,
              tiltGesturesEnabled: _mapInteractionEnabled && !_isBottomSheetOpen,
            ),
          ),
        ],
      ),
    );
  }
}

class FiltersWidget extends StatefulWidget {
  @override
  _FiltersWidgetState createState() => _FiltersWidgetState();
}

class _FiltersWidgetState extends State<FiltersWidget> {
  bool filterPlastic = false;
  bool filterGlass = false;
  bool filterMetal = false;
  bool filterPaper = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
          CheckboxListTile(
            title: Text('Plastic'),
            value: filterPlastic,
            onChanged: (value) {
              setState(() {
                filterPlastic = value!;
              });
            },
          ),
          CheckboxListTile(
            title: Text('Glass'),
            value: filterGlass,
            onChanged: (value) {
              setState(() {
                filterGlass = value!;
              });
            },
          ),
          CheckboxListTile(
            title: Text('Metal'),
            value: filterMetal,
            onChanged: (value) {
              setState(() {
                filterMetal = value!;
              });
            },
          ),
          CheckboxListTile(
            title: Text('Paper'),
            value: filterPaper,
            onChanged: (value) {
              setState(() {
                filterPaper = value!;
              });
            },
          ),
        ],
      ),
    );
  }
}