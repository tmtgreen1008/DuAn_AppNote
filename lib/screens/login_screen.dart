// File: lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // Import màn hình chính của bạn
import '../services/database_helper.dart'; // Để gọi hàm login
import 'register_screen.dart'; // Để chuyển sang màn hình đăng ký
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Gọi Database kiểm tra tài khoản
        final user = await DatabaseHelper().loginUser(
            _usernameController.text.trim(),
            _passwordController.text.trim()
        );

        if (mounted) {
          setState(() => _isLoading = false); // Tắt loading an toàn

          if (user != null) {
            // Đăng nhập thành công
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Xin chào, ${user['fullName']}!"), backgroundColor: Colors.green),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else {
            // Đăng nhập thất bại (Sai tài khoản/mật khẩu)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sai tên đăng nhập hoặc mật khẩu!"), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        // Bắt lỗi ngầm (ví dụ lỗi cấu trúc Database)
        if (mounted) {
          setState(() => _isLoading = false); // Tắt hiệu ứng quay
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Có lỗi xảy ra: $e"), backgroundColor: Colors.red),
          );
          print("LỖI ĐĂNG NHẬP: $e"); // In ra console để dễ debug
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo hoặc Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school, size: 80, color: Colors.blue),
                  ),
                  const SizedBox(height: 30),

                  // Tiêu đề
                  const Text(
                    "UTC Student Planner",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Đăng nhập để quản lý lịch học và công việc",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 40),

                  // Ô nhập Tài khoản
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: "Tên đăng nhập",
                      hintText: "Nhập 'student'",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? "Vui lòng nhập tên đăng nhập" : null,
                  ),
                  const SizedBox(height: 20),

                  // Ô nhập Mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      hintText: "Nhập '123456'",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? "Vui lòng nhập mật khẩu" : null,
                  ),
                  const SizedBox(height: 10),

                  // Quên mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {}, // Thêm tính năng quên mật khẩu sau
                      child: const Text("Quên mật khẩu?"),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nút Đăng nhập
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Đăng nhập", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Chưa có tài khoản?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text("Đăng ký ngay", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}