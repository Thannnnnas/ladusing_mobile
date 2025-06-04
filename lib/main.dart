import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'splash_screen.dart'; 

void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}