import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(FireCheckApp());
}

class FireCheckApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FireCheckScreen(),
    );
  }
}

class FireCheckScreen extends StatefulWidget {
  @override
  _FireCheckScreenState createState() => _FireCheckScreenState();
}

class _FireCheckScreenState extends State<FireCheckScreen> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(51.1694, 71.4491); // Казахстан

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _showFireCheckSheet(String address) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) {
            return FireCheckSheet(
              address: address,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Домашний пожарный контроль')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 12.0,
            ),
            markers: {
              Marker(
                markerId: MarkerId('home1'),
                position: LatLng(51.1605, 71.4704),
                infoWindow: InfoWindow(
                  title: 'Жилой дом',
                  onTap: () => _showFireCheckSheet('ул. Абая, 12'),
                ),
              )
            },
          ),
        ],
      ),
    );
  }
}

class FireCheckSheet extends StatefulWidget {
  final String address;
  final ScrollController scrollController;

  FireCheckSheet({required this.address, required this.scrollController});

  @override
  _FireCheckSheetState createState() => _FireCheckSheetState();
}

class _FireCheckSheetState extends State<FireCheckSheet> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  int appartment = 0;
  int adults = 0;
  int children = 0;
  int seniors = 0;
  List<String> selectedCategories = [];
  bool hasExtinguisher = false;
  bool exitsClear = false;
  bool smokeDetectorsWork = false;
  bool gasSafe = false;

  final List<String> citizenCategories = [
    'Малоимущие',
    'Многодетные',
    'Инвалиды',
    'Пенсионеры',
    'Работающие'
  ];

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.address;
  }

  void _submitReport() {
    final report = {
      'Адрес': _addressController.text,
      'ФИО': _nameController.text,
      'Инструктирующий': _instructorController.text,
      'Дата проверки': selectedDate.toString().split(' ')[0],
      'Взрослые': adults,
      'Дети': children,
      'Пенсионеры': seniors,
      'Категории граждан': selectedCategories,
      'Есть огнетушитель': hasExtinguisher,
      'Нет загромождённых выходов': exitsClear,
      'Дымовые извещатели работают': smokeDetectorsWork,
      'Газовое оборудование в порядке': gasSafe,
      'Дополнительные замечания': _remarksController.text,
    };
    print(report);
  }

  InputDecoration _buildInputDecorator(String label) => InputDecoration(
        filled: true,
        fillColor: Color.fromRGBO(46, 46, 93, 0.04),
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Futura',
          fontWeight: FontWeight.normal,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: 'Futura',
          fontWeight: FontWeight.normal,
          color: Colors.brown,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.black,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
      );

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(label),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () =>
                  setState(() => onChanged((value > 0) ? value - 1 : 0)),
            ),
            SizedBox(
              width: 70,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: value.toString()),
                decoration: _buildInputDecorator(""),
                onChanged: (val) =>
                    setState(() => onChanged(int.tryParse(val) ?? 0)),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => setState(() => onChanged(value + 1)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Text(
            "Проверочный лист",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 10,
          ),
          TextField(
            controller: _addressController,
            decoration: _buildInputDecorator('Адрес'),
          ),
          SizedBox(
            height: 10,
          ),
          _buildCounter("Квартира", appartment, (val) => appartment = val),
          TextField(
            controller: _nameController,
            decoration: _buildInputDecorator('ФИО инструктируемого'),
          ),
          SizedBox(
            height: 10,
          ),
          TextField(
            controller: _instructorController,
            decoration: _buildInputDecorator('ФИО инструктора'),
          ),
          SizedBox(
            height: 10,
          ),
          ListTile(
            title:
                Text('Дата проверки: ${selectedDate.toString().split(' ')[0]}'),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null && pickedDate != selectedDate) {
                setState(() {
                  selectedDate = pickedDate;
                });
              }
            },
          ),
          Text(
            'Состав семьи',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCounter('Взрослые', adults, (val) => adults = val),
              _buildCounter('Дети', children, (val) => children = val),
              _buildCounter('Пенсионеры', seniors, (val) => seniors = val),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Wrap(
            children: citizenCategories.map((category) {
              return ChoiceChip(
                label: Text(category),
                selected: selectedCategories.contains(category),
                onSelected: (selected) {
                  setState(() {
                    selected
                        ? selectedCategories.add(category)
                        : selectedCategories.remove(category);
                  });
                },
              );
            }).toList(),
          ),
          ListTile(
            title: Text('Есть огнетушитель'),
            trailing: Checkbox(
              value: hasExtinguisher,
              onChanged: (bool? value) {
                setState(() {
                  hasExtinguisher = value ?? false;
                });
              },
            ),
          ),
          ListTile(
            title: Text('Нет загромождённых выходов'),
            trailing: Checkbox(
              value: exitsClear,
              onChanged: (bool? value) {
                setState(() {
                  exitsClear = value ?? false;
                });
              },
            ),
          ),
          ListTile(
            title: Text('Дымовые извещатели работают'),
            trailing: Checkbox(
              value: smokeDetectorsWork,
              onChanged: (bool? value) {
                setState(() {
                  smokeDetectorsWork = value ?? false;
                });
              },
            ),
          ),
          ListTile(
            title: Text('Газовое оборудование в порядке'),
            trailing: Checkbox(
              value: gasSafe,
              onChanged: (bool? value) {
                setState(() {
                  gasSafe = value ?? false;
                });
              },
            ),
          ),
          TextField(
              controller: _remarksController,
              decoration: _buildInputDecorator('Дополнительные замечания')),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            height: 50,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _submitReport,
                child: Text('Сохранить отчёт'),
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}
