// File: lib/screens/category_management_screen.dart
import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final db = DatabaseHelper();
  List<Map<String, dynamic>> categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  void loadCategories() async {
    final data = await db.getCategoriesWithTaskCount();
    if (mounted) {
      setState(() {
        categories = data;
        loading = false;
      });
    }
  }

  // Hộp thoại dùng chung cho cả THÊM MỚI và SỬA
  void _showCategoryDialog({String? id, String? currentName, int? currentColor}) {
    final nameController = TextEditingController(text: currentName ?? "");
    int selectedColor = currentColor ?? Colors.blue.value;

    final List<Color> colorOptions = [
      Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal, Colors.pink, Colors.brown
    ];

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(id == null ? "Tạo danh mục mới" : "Chỉnh sửa danh mục", style: const TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Tên danh mục",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Chọn màu sắc:", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: colorOptions.map((color) {
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedColor = color.value),
                            child: CircleAvatar(
                              backgroundColor: color.withOpacity(0.2),
                              radius: 18,
                              child: CircleAvatar(
                                backgroundColor: color,
                                radius: 14,
                                child: selectedColor == color.value ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () async {
                        if (nameController.text.trim().isNotEmpty) {
                          if (id == null) {
                            await db.insertCategory(nameController.text.trim(), selectedColor);
                          } else {
                            await db.updateCategory(id, nameController.text.trim(), selectedColor);
                          }
                          if (mounted) {
                            Navigator.pop(context);
                            loadCategories();
                          }
                        }
                      },
                      child: Text(id == null ? "Tạo mới" : "Cập nhật", style: const TextStyle(color: Colors.white)),
                    )
                  ],
                );
              }
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Quản lý Danh mục", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
          ? Center(
        child: Text("Chưa có danh mục nào", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final Color catColor = Color(cat['colorCode']);

          return Dismissible(
            key: Key(cat['id'].toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(15)),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (direction) async {
              await db.deleteCategory(cat['id'].toString());
              setState(() => categories.removeAt(index));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa danh mục!")));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: catColor.withOpacity(0.2),
                  child: Icon(Icons.folder, color: catColor),
                ),
                title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Đang có ${cat['taskCount']} công việc chưa xong", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showCategoryDialog(
                      id: cat['id'].toString(),
                      currentName: cat['name'],
                      currentColor: cat['colorCode']
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}