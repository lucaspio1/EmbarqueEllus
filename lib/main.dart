import 'package:flutter/material.dart';
import 'package:embarque_app/screens/main_menu_screen.dart';
import 'package:embarque_app/screens/embarque_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:embarque_app/services/data_service.dart';

// SUBSTITUA ESTA STRING PELA URL DA SUA API DO APPS SCRIPT
const String apiUrl = "https://script.google.com/macros/s/AKfycbz0uVSIKzbCL5iB4paKj9ZtpPhYRyi3McCO_iHNhe3JSF5KeEhB294fydB5uwhh8mgAQg/exec";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App ELLUS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainMenuScreen(), // A home agora é sempre o menu principal
    );
  }
}