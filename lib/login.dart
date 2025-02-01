import 'dart:io';
import 'package:help/chat/chat.dart';
import 'package:help/path.dart';
import 'package:help/prize.dart';
import 'package:help/registration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

import 'info.dart';
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
enum UserRole { viewer, participant, anonymous }

const Map<UserRole, String> roleNames = {
  UserRole.viewer: 'Viewer',
  UserRole.participant: 'Participant',
  UserRole.anonymous: 'Anonymous',
};
class _MyHomePageState extends State<MyHomePage> {
  UserRole _selectedRole = UserRole.viewer;



  TextEditingController emailcontroller = TextEditingController();

  TextEditingController passwordcontroller = TextEditingController();
  void signUserIn(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailcontroller.text, password: passwordcontroller.text);

      Navigator.push(context, MaterialPageRoute(builder: (context) => CharityRunsPage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'Проверьте, пожалуйста, проверьте правильно ли вы ввели данные!'))
      );
      print(e.code);
      String errorMessage;

    }
  }
  void signAnonim(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: "anonim@gmail.com", password: "anonim123");

      Navigator.push(
        context, MaterialPageRoute(builder: (context) => CharityRunsPage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'Проверьте, пожалуйста, проверьте правильно ли вы ввели данные!'))
      );
      print(e.code);
      String errorMessage;
    }
  }
  @override
  void initState() {
    super.initState();
  }
  final List<UserRole> roles = [
    UserRole.participant,
    UserRole.viewer,
    UserRole.anonymous,
  ];


  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    super.dispose();
    emailcontroller.dispose();
    passwordcontroller.dispose();
  }

  bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: true,
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key:_formKey,
              child: Column(
                children: [
                  SizedBox(
                    height: 40,
                  ),
                  Row(
                    children: [
                      if (isDesktop(context))
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width:
                                MediaQuery.of(context).size.shortestSide / 2,
                                height:
                                MediaQuery.of(context).size.shortestSide / 2,
                                child: Container(
                                  width: 300,
                                  height: 230,
                                  decoration: BoxDecoration(color: Colors.white),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(67.0),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10,),
                              Text(
                                'Welcome NIS 2025 Marathon',
                                style: TextStyle(fontFamily: "Futura"),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            if (!isDesktop(context))
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width:
                                    MediaQuery.of(context).size.shortestSide /
                                        2,
                                    height:
                                    MediaQuery.of(context).size.shortestSide /
                                        2,
                                    child: Container(

                                      width: 300,
                                      height: 230,
                                      decoration:
                                      BoxDecoration(color: Colors.white,),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(67.0),
                                        child: Image.asset(

                                          'assets/logo.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10,),

                                  Text(
                                    'Добро пожаловать на КупимВместе,\nсистему покупки товаров',
                                    style: TextStyle(fontFamily: 'Futura'),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Введите почту:',
                                    style: TextStyle(
                                      fontFamily: 'Futura',
                                      fontSize: 20,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Padding(
                                  padding:
                                  EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                                  child: Container(
                                    width: 450,
                                    height: 50,
                                    child: TextFormField(
                                      controller: emailcontroller,
                                      textCapitalization: TextCapitalization.none,
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor:
                                        Color.fromRGBO(46, 46, 93, 0.04),
                                        labelText: 'Электронная почта',
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
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Futura',
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Введите эл почту';
                                        } else if (!value.contains('@')) {
                                          return 'Введите правильную эл почту';
                                        }
                                        return null; // means input is correct
                                      },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Введите пароль:',
                                    style: TextStyle(
                                      fontFamily: 'Futura',
                                      fontSize: 20,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Padding(
                                  padding:
                                  EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                                  child: Container(
                                    width: 450,
                                    height: 50,
                                    child: TextFormField(
                                      controller: passwordcontroller,
                                      textCapitalization: TextCapitalization.none,
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor:
                                        Color.fromRGBO(46, 46, 93, 0.04),
                                        labelText: 'Пароль',
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
                                            width: 1,
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
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Futura',
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      keyboardType: TextInputType.visiblePassword,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Ввведите пароль';
                                        } else if (value.length < 6) {
                                          return 'Пароль должен быть минимум 6 символов в длину';
                                        }
                                        return null; // means input is correct
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                              EdgeInsetsDirectional.fromSTEB(0, 50, 0, 0),
                              child: SizedBox(
                                height: 50,
                                width: 300,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) { // <-- Add this line

                                      signUserIn(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Войти в аккаунт',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w100,
                                          fontFamily: 'Futura',
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16,),
                            GestureDetector(
                              child: Text(
                                'Войти анонимно',
                                style: TextStyle(color: Colors.blue),
                              ),
                              onTap: () {
                                signAnonim(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MyHomePage()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[700],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [

                                Flexible(
                                  child: Text(
                                    'Если у вас нет аккаунта',
                                    softWrap: true,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                                GestureDetector(
                                  child: Text(
                                    ' зарегестритруйтесь.',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => Registration()),
                                    );

                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}