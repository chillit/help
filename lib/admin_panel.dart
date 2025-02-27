import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:help/login_fireinspection.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child("users");
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController roleController = TextEditingController();

  // 📌 Получение списка пользователей
  Stream<DatabaseEvent> fetchUsers() {
    return _database.onValue;
  }

  // 📌 Добавление нового пользователя
  Future<void> addUser() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String role = roleController.text.trim().isEmpty
        ? "instructor"
        : roleController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заполните поля!')),
      );

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Добавление в Realtime Database
      await _database.child(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пользователь добавлен!')),
      );

      emailController.clear();
      passwordController.clear();
      roleController.clear();

      _auth.signOut();
      _auth.signInWithEmailAndPassword(
          email: "admin@gmail.com", password: "admin123");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы успешно вышли из аккаунта')),
      );
      // Перенаправление на страницу входа (замени 'LoginPage()' на свою страницу)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginFire()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выходе: $e')),
      );
    }
  }

  // 📌 Удаление пользователя
  // Future<void> deleteUser(String uid) async {
  //   try {
  //     await _database.child(uid).remove();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Пользователь удален!')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Ошибка удаления: $e')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffee0003),
        title: const Text(
          'Админ-панель',
          style: TextStyle(
            fontSize: 28, // Увеличенный размер шрифта
            fontWeight: FontWeight.bold, // Жирный шрифт
            color: Colors.white,
          )),
        centerTitle: true,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black),
            onPressed: () => signOut(context),
            child: Text("Log Out"),
          ),
          SizedBox(width: 10)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                      controller: nameController,
                      decoration: buildInputDecorator('Имя')),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                      controller: emailController,
                      decoration: buildInputDecorator('Email')),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                      controller: passwordController,
                      decoration: buildInputDecorator('Пароль')),
                  SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  RoleDropdown(),
                  SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                    onPressed: addUser,
                    child: Text('Добавить пользователя'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: fetchUsers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return Center(child: Text("Нет пользователей"));
                  }

                  Map<dynamic, dynamic> users =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  return ListView(
                    children: users.entries.map((entry) {
                      String uid = entry.key;
                      Map<dynamic, dynamic> user = entry.value;
                      return ListTile(
                        title: Text(user['name']),
                        subtitle: Text(
                            '${user["email"]} | Роль: ${user['role'] ?? "instructor"}'),
                        // trailing: IconButton(
                        //   icon: Icon(Icons.delete, color: Colors.red),
                        //   onPressed: () => deleteUser(uid),
                        // ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleDropdown extends StatefulWidget {
  @override
  _RoleDropdownState createState() => _RoleDropdownState();
}

class _RoleDropdownState extends State<RoleDropdown> {
  String selectedRole = 'instructor'; // Начальное значение

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "Выберите роль",
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(
          width: 10,
        ),
        DropdownButton<String>(
          borderRadius: BorderRadius.circular(5),
          value: selectedRole,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                selectedRole = newValue;
              });
            }
          },
          items: [
            DropdownMenuItem(value: 'instructor', child: Text('Инструктор')),
            DropdownMenuItem(value: 'admin', child: Text('Администратор')),
          ],
        ),
      ],
    );
  }
}

InputDecoration buildInputDecorator(String label) => InputDecoration(
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
