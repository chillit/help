import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('messages'); // Путь в базе данных
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    // Загрузка сообщений из Realtime Database
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _messages.clear();
        data.forEach((key, value) {
          _messages.add(Map<String, String>.from(value as Map));
        });
      });
    }
  }

  Future<void> sendMessage(String message) async {
    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer sk-2ruHUfuexrGGvI3JkS6GBXpPQacBoG7CjgINSwuUZVT3BlbkFJBl8zXKJcR-TTVQg72cf3UNDg_E_YwZLgqefgJfr1UA',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'Вы - ChatGPT, искусственный интеллект.'},
            ..._messages.map((msg) => {'role': msg['role'], 'content': msg['content']}),
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reply = data['choices'][0]['message']['content'];

        // Добавляем сообщение бота
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
        });

        // Сохраняем в Firebase
        await _saveMessageToFirebase('assistant', reply);
      } else {
        throw Exception('Не удалось получить ответ');
      }
    } catch (error) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Ошибка: $error'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    // Сохраняем сообщение пользователя
    await _saveMessageToFirebase('user', message);
  }

  Future<void> _saveMessageToFirebase(String role, String content) async {
    final newMessageRef = _dbRef.push(); // Создаем уникальный ключ для сообщения
    await newMessageRef.set({
      'role': role,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чат с ChatGPT'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message['content']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Введите сообщение...',
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      sendMessage(_controller.text.trim());
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
