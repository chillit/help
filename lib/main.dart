import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:help/admin_panel.dart';
import 'package:help/check_bottom_sheet.dart';
import 'package:help/login_fireinspection.dart';
import 'package:help/path.dart';
import 'package:help/registration.dart';
import 'package:help/role_redirector.dart';
import 'info.dart';
import 'list.dart';
import 'login.dart';
import 'chat/chat.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    print("ffffffffffffffffffffffffffffffqqqqqqqq");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: "Helvetica",
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MapScreen(),
    );
  }
}
