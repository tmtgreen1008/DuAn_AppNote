// File: lib/screens/category_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/student_models.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final int colorCode;

  const CategoryDetailScreen({super.key, required this.categoryId, required this.categoryName, required this.colorCode});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  List<TaskItem> tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    // Gọi hàm lấy công việc theo ID danh mục
    final data = await DatabaseHelper().getTasksByCategory(widget.categoryId);
    setState(() {
      tasks = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Color(widget.colorCode),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
          ? const Center(child: Text("Chưa có đầu việc nào trong mục này!"))
          : ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(widget.colorCode).withOpacity(0.2),
                child: Icon(Icons.list, color: Color(widget.colorCode)),
              ),
              title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: task.subjectName != null ? Text("Môn: ${task.subjectName}") : null,
            ),
          );
        },
      ),
    );
  }
}