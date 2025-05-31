import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Tetap import ini
import 'splash_screen.dart'; // Tetap import SplashScreen Anda

void main() async { // <<< UBAH INI MENJADI ASYNC
  // Pastikan inisialisasi Flutter Binding selesai sebelum memanggil fungsi async
  WidgetsFlutterBinding.ensureInitialized();
  
  // Panggil initializeDateFormatting() di sini
  // 'id' adalah kode locale untuk Bahasa Indonesia
  await initializeDateFormatting('id', null); // <<< PENTING: Panggil ini!

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(), // Pastikan ini const jika SplashScreen tidak berubah
      debugShowCheckedModeBanner: false,
    );
  }
}