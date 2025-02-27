import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class House {
  final String id; // Уникальный идентификатор дома
  final bool checked;
  final String address;
  final String date;
  final String familyComposition;
  final String category;
  final String instructedName;
  final String instructorName;
  final Map<String, bool> safetyRequirements;

  House({
    required this.id,
    required this.checked,
    required this.address,
    required this.date,
    required this.familyComposition,
    required this.category,
    required this.instructedName,
    required this.instructorName,
    required this.safetyRequirements,
  });

  factory House.fromMap(String id, Map<String, dynamic> data) {
    return House(
      id: id,
      checked: data['checked'] ?? false,
      address: data['address'] ?? 'Не указан',
      date: data['date'] ?? 'Не указана',
      familyComposition: data['familyComposition'] ?? 'Не указан',
      category: data['category'] ?? 'Не указана',
      instructedName: data['instructedName'] ?? 'Не указано',
      instructorName: data['instructorName'] ?? 'Не указано',
      safetyRequirements: Map<String, bool>.from(data['safetyRequirements'] ?? {}),
    );
  }
}

// Экран со списком домов
class HouseListScreen extends StatefulWidget {
  @override
  _HouseListScreenState createState() => _HouseListScreenState();
}

class _HouseListScreenState extends State<HouseListScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child('houses');
  List<House> houses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  void _loadHouses() {
    _databaseRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        // Приводим данные к типу Map<String, dynamic>
        final Map<dynamic, dynamic> housesMap = data as Map<dynamic, dynamic>;
        setState(() {
          houses = housesMap.entries.map((entry) {
            // Приводим entry.value к Map<String, dynamic>
            final houseData = entry.value as Map<dynamic, dynamic>;
            return House.fromMap(entry.key.toString(), houseData.cast<String, dynamic>());
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }, onError: (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        backgroundColor: Color(0xffee0003),
        elevation: 10, // Тень для AppBar
        title: const Text(
          'Map Screen',
          style: TextStyle(
            fontSize: 28, // Увеличенный размер шрифта
            fontWeight: FontWeight.bold, // Жирный шрифт
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Закруглённые углы
              ),
            ),
            onPressed: () {},
            child: Text(
              "Map view",
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : houses.isEmpty
          ? Center(
        child: Text(
          'Дома не найдены',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16), // Отступы для ListView
        itemCount: houses.length,
        itemBuilder: (context, index) {
          final house = houses[index];
          return Card(
            elevation: 4, // Тень для Card
            margin: EdgeInsets.symmetric(vertical: 8), // Отступы между Card
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Закруглённые углы
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16), // Внутренние отступы
              title: Text(
                house.address,
                style: TextStyle(
                  fontSize: 20, // Увеличенный размер шрифта
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Дата посещения: ${house.date}',
                style: TextStyle(fontSize: 16),
              ),
              trailing: house.checked
                  ? Icon(Icons.check_circle, color: Colors.green, size: 32)
                  : Icon(Icons.cancel, color: Colors.red, size: 32),
              onTap: () {
                // Переход на экран с деталями дома
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HouseDetailsScreen(house: house),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// Экран с деталями дома
class HouseDetailsScreen extends StatelessWidget {
  final House house;

  HouseDetailsScreen({required this.house});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffee0003),
        elevation: 10, // Тень для AppBar
        title: Text(
          'Детали дома',
          style: TextStyle(
            fontSize: 28, // Увеличенный размер шрифта
            fontWeight: FontWeight.bold, // Жирный шрифт
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Карточка с основными данными
              Card(
                elevation: 4, // Тень
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Закруглённые углы
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Основная информация',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildDetailRow('Адрес', house.address),
                      _buildDetailRow('Дата посещения', house.date),
                      _buildDetailRow('Состав семьи', house.familyComposition),
                      _buildDetailRow('Категория граждан', house.category),
                      _buildDetailRow('Ф.И.О. инструктируемого', house.instructedName),
                      _buildDetailRow('Ф.И.О. должностного лица', house.instructorName),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Карточка с требованиями пожарной безопасности
              Card(
                elevation: 4, // Тень
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Закруглённые углы
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Требования пожарной безопасности',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 10),
                      ...house.safetyRequirements.entries.map((entry) {
                        return CheckboxListTile(
                          title: Text(
                            entry.key,
                            style: TextStyle(fontSize: 18),
                          ),
                          value: entry.value,
                          onChanged: null, // Чекбоксы только для просмотра
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Вспомогательный метод для создания строки с деталями
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}