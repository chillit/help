import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
class FireCheckSheet extends StatefulWidget {
  final String lat;
  final String lon;
  final String address;
  final ScrollController scrollController;

  FireCheckSheet({required this.address, required this.scrollController,required this.lon,required this.lat});

  @override
  _FireCheckSheetState createState() => _FireCheckSheetState();
}

class _FireCheckSheetState extends State<FireCheckSheet> {
  Future<void> saveHouseData({
    required bool checked,
    required String address,
    required String date,
    required String familyComposition,
    required String category,
    required String instructedName,
    required String instructorName,
    required Map<String, bool> safetyRequirements,
    required String advices,
    required int level,
    required String description,
  }) async {
    // Получаем ссылку на базу данных по пути /houses
    final DatabaseReference housesRef = FirebaseDatabase.instance.ref('houses');

    // Генерируем уникальный ключ для нового дома (например, house_1, house_2 и т.д.)
    final DatabaseReference newHouseRef = housesRef.push();

    // Создаем данные для сохранения
    final Map<String, dynamic> houseData = {
      "latitude":widget.lat,
      "longitude":widget.lon,
      'checked': checked,
      'address': address,
      'date': date,
      'familyComposition': familyComposition,
      'category': category,
      'instructedName': instructedName,
      'instructorName': instructorName,
      'safetyRequirements': safetyRequirements,
      "advices":advices,
      "level":level,
      "description":description
    };

    // Сохраняем данные в Realtime Database
    await newHouseRef.set(houseData);
  }

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  int level = 0;
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
  Future<String> translateText(String text, String targetLanguage) async {
    final url = Uri.https(
      'translation.googleapis.com',
      '/language/translate/v2',
      {
        'q': text,
        'target': targetLanguage,
        'key': 'AIzaSyCALbmExO2XPNvUpslYMEezXlE7hBJ1Tq4',
      },
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['translations'][0]['translatedText'];
    } else {
      throw Exception('Failed to translate: ${response.statusCode}');
    }
  }
  Future<String> sendMessage() async {
    try {
      final prompt = "Provide a very short safety fire tips (3-4 sentences) for this house in English, and also include a pollution level rating from 1 to 5 (integer). The response must be a valid JSON object with keys \"tips\" for the safety advice and \"pollutionLevel\" for the pollution level. Do not include any extra text before or after the JSON. House data: amount of adults:${adults}, amount of children:${children}, amount of seniors:${seniors}, hasExtinguisher:${hasExtinguisher}, smokeDetectorsWork:${smokeDetectorsWork}, gas sources as safe:${gasSafe}, brief remarks:${_remarksController.text}, categories:${selectedCategories}. Include advice on fire safety, electrical safety, and general maintenance. Answer must be in English, starting immediately with the JSON output.";
      print(prompt);

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer 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', // Замените на валидный ключ
        },
        body: jsonEncode({
          "model": "gpt-4",
          "messages": [
            {
              "role": "user",
              "content": prompt
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messageContent = data['choices'][0]['message']['content'];

        // Разбираем JSON-ответ
        final parsedResponse = json.decode(messageContent);
        final safetyTips = parsedResponse['tips'] as String;
        level = int.parse(parsedResponse['pollutionLevel'].toString());

        print("Safety Tips: $safetyTips");
        print("Pollution Level (int): $level");

        // Переводим советы на русский, если необходимо
        final russianDescription = await translateText(safetyTips, 'ru');
        return russianDescription;
      } else {
        print('Failed to get response: ${response.statusCode}');
        print('Response body: ${response.body}');
        return "";
      }
    } catch (error) {
      print("Error in making API call: $error");
      return "";
    }
  }


  void _submitReport() async {
    final String date = selectedDate.toString().split(' ')[0];

    final Map<String, bool> safetyRequirements = {
      'Есть огнетушитель': hasExtinguisher,
      'Дымовые извещатели работают': smokeDetectorsWork,
      'Газовое оборудование в порядке': gasSafe,
    };
    String advices = await sendMessage();
    await saveHouseData(
      checked: true, // Можно сделать выбором в UI
      address: _addressController.text,
      date: date,
      familyComposition: 'Взрослые: $adults, Дети: $children, Пенсионеры: $seniors',
      category: selectedCategories.join(', '),
      instructedName: _nameController.text,
      instructorName: _instructorController.text,
      safetyRequirements: safetyRequirements,
      advices: advices,
      level:level,
      description: _remarksController.text
    );

    // Опционально: Очистить поля после отправки
    setState(() {
      _nameController.clear();
      _instructorController.clear();
      _remarksController.clear();
      adults = 0;
      children = 0;
      seniors = 0;
      selectedCategories.clear();
      hasExtinguisher = false;
      smokeDetectorsWork = false;
      gasSafe = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Отчёт сохранён в Firebase!')),
    );
  }
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
        Text(label, style: _textStyle(fontSize: 18)),
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

  TextStyle _textStyle({double fontSize = 18, Color? color}) => TextStyle(
    fontSize: fontSize,
    color: color ?? Colors.blueGrey[800],
  );

  Widget _buildSectionTitle(String title) => Padding(
    padding: EdgeInsets.only(bottom: 20),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.blueGrey[800],
      ),
    ),
  );

  Widget _buildCheckboxTile(String title, bool value) => ListTile(
    title: Text(title, style: _textStyle(fontSize: 18)),
    trailing: Checkbox(
      value: value,
      onChanged: (v) => setState(() => value = v ?? false),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: ListView(
        controller: widget.scrollController,
        children: [
          // Заголовок
          Padding(
            padding: EdgeInsets.only(bottom: 25),
            child: Text(
              "Проверочный лист",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Секция адреса
          _buildSectionTitle('Основная информация'),
          TextField(
            controller: _addressController,
            style: _textStyle(),
            decoration: _buildInputDecorator('Адрес'),
          ),
          SizedBox(height: 20),
          _buildCounter("Квартира", appartment, (val) => appartment = val),
          SizedBox(height: 30),
          Divider(height: 40, thickness: 1.5),

          // Секция ФИО
          _buildSectionTitle('Персональные данные'),
          TextField(
            controller: _nameController,
            style: _textStyle(),
            decoration: _buildInputDecorator('ФИО инструктируемого'),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _instructorController,
            style: _textStyle(),
            decoration: _buildInputDecorator('ФИО инструктора'),
          ),
          SizedBox(height: 30),
          Divider(height: 40, thickness: 1.5),

          // Секция даты
          _buildSectionTitle('Дата проверки'),
          ListTile(
            title: Text(
              'Дата: ${selectedDate.toString().split(' ')[0]}',
              style: _textStyle(fontSize: 18),
            ),
            trailing: Icon(Icons.calendar_today, size: 28),
            contentPadding: EdgeInsets.zero,
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
          SizedBox(height: 30),
          Divider(height: 40, thickness: 1.5),

          // Секция состава семьи
          _buildSectionTitle('Состав семьи'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCounter('Взрослые', adults, (val) => adults = val),
              _buildCounter('Дети', children, (val) => children = val),
              _buildCounter('Пенсионеры', seniors, (val) => seniors = val),
            ],
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: citizenCategories.map((category) {
              return ChoiceChip(
                label: Text(category, style: _textStyle()),
                selected: selectedCategories.contains(category),
                onSelected: (selected) => setState(() {
                  selected
                      ? selectedCategories.add(category)
                      : selectedCategories.remove(category);
                }),
              );
            }).toList(),
          ),
          SizedBox(height: 30),
          Divider(height: 40, thickness: 1.5),

          // Секция безопасности
          _buildSectionTitle('Безопасность'),
          _buildCheckboxTile('Есть огнетушитель', hasExtinguisher),
          _buildCheckboxTile('Дымовые извещатели работают', smokeDetectorsWork),
          _buildCheckboxTile('Газовое оборудование в порядке', gasSafe),
          SizedBox(height: 30),
          Divider(height: 40, thickness: 1.5),

          // Завершающая секция
          _buildSectionTitle('Дополнительно'),
          TextField(
            controller: _remarksController,
            style: _textStyle(),
            decoration: _buildInputDecorator('Замечания'),
            maxLines: 4,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: _submitReport,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 55),
              padding: EdgeInsets.symmetric(vertical: 16),
              textStyle: TextStyle(fontSize: 20),
            ),
            child: Text('Сохранить отчёт'),
          ),
        ],
      ),
    );
  }
}