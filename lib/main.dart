// File: lib/main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // [MỚI] Import màn hình đăng nhập

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Planner',
      theme: ThemeData(
        // Sử dụng ColorScheme để giao diện Material 3 đẹp hơn
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // [QUAN TRỌNG] Đổi màn hình khởi động từ DashboardScreen thành LoginScreen
      home: const LoginScreen(),
    );
  }
}