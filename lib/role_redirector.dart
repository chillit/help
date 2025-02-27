import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:help/admin_panel.dart';
import 'package:help/login_fireinspection.dart';
import 'package:help/path.dart';

class RoleRedirector extends StatefulWidget {
  @override
  _RoleRedirectorState createState() => _RoleRedirectorState();
}

class _RoleRedirectorState extends State<RoleRedirector> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('users');

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _checkUserRole());
  }

  void _checkUserRole() async {
    User? user = _auth.currentUser;
    print(user);
    if (user == null) {
      print("not logged");
      // Если не вошел в систему → переход на страницу входа
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginFire()));
      return;
    }

    // Запрос роли пользователя из Realtime Database
    DatabaseEvent event = await _database.orderByChild("email").equalTo(user.email).once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value != null && snapshot.value is Map) {
      Map<dynamic, dynamic> usersMap = snapshot.value as Map<dynamic, dynamic>;

      String? role;
      usersMap.forEach((key, value) {
        if (value["email"] == user.email) {
          role = value["role"];
        }
      });
      print(role);

      // Перенаправление в зависимости от роли
      if (role == "admin") {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminPanel()));
      } else if (role == "instructor") {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MapScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginFire()));
      }
    } else {
      // Если роли нет → отправляем на страницу входа
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginFire()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()), // Ожидание загрузки роли
    );
  }
}
