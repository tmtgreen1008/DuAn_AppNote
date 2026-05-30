// File: lib/screens/dashboard_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_helper.dart';
import '../models/student_models.dart';
import 'category_detail_screen.dart';
import 'task_detail_screen.dart';
import 'category_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String fullName;

  const DashboardScreen({super.key, required this.fullName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final db = DatabaseHelper();
  List<TaskItem> tasks = [];
  List<Map<String, dynamic>> categories = [];
  bool loading = true;

  // ==========================================
  // [MỚI] BIẾN LƯU TRỮ PROFILE CÁ NHÂN
  // ==========================================
  late String _currentName;
  String? _avatarPath; // Đường dẫn ảnh đại diện trên máy
  bool _isNotificationEnabled = true; // Trạng thái thông báo

  String _selectedFilter = 'Hôm nay';
  final List<String> _filters = ['Tất cả', 'Hôm nay', 'Sắp tới', 'Đã trễ', 'Đã xong'];

  @override
  void initState() {
    super.initState();
    _currentName = widget.fullName;
    _loadUserProfile(); // Tải dữ liệu cá nhân ngay khi mở app
    loadData();
  }

  // [MỚI] Tải dữ liệu từ SharedPreferences
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentName = prefs.getString('userName') ?? widget.fullName;
      _avatarPath = prefs.getString('avatarPath');
      _isNotificationEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  void loadData() async {
    try {
      await db.database;
      final t = await db.getAllTasks();
      final c = await db.getCategoriesWithTaskCount();
      t.sort((a, b) => a.time.compareTo(b.time));
      if (mounted) setState(() { tasks = t; categories = c; loading = false; });
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  List<TaskItem> get _filteredTasks {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    return tasks.where((task) {
      DateTime taskDate;
      try { taskDate = DateFormat('yyyy-MM-dd').parse(task.date); } catch (e) { taskDate = today; }
      DateTime tDateOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
      if (_selectedFilter == 'Đã xong') return task.isCompleted;
      if (task.isCompleted) return false;
      if (_selectedFilter == 'Tất cả') return true;
      if (_selectedFilter == 'Hôm nay') return tDateOnly.isAtSameMomentAs(today);
      if (_selectedFilter == 'Sắp tới') return tDateOnly.isAfter(today);
      if (_selectedFilter == 'Đã trễ') return tDateOnly.isBefore(today);
      return true;
    }).toList();
  }

  Map<String, int> _getFilterStats() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    int total = 0; int completed = 0;
    for (var task in tasks) {
      DateTime tDate;
      try { tDate = DateFormat('yyyy-MM-dd').parse(task.date); } catch (e) { tDate = today; }
      DateTime tDateOnly = DateTime(tDate.year, tDate.month, tDate.day);
      bool isMatchDate = false;
      if (_selectedFilter == 'Tất cả' || _selectedFilter == 'Đã xong') isMatchDate = true;
      else if (_selectedFilter == 'Hôm nay') isMatchDate = tDateOnly.isAtSameMomentAs(today);
      else if (_selectedFilter == 'Sắp tới') isMatchDate = tDateOnly.isAfter(today);
      else if (_selectedFilter == 'Đã trễ') isMatchDate = tDateOnly.isBefore(today);
      if (isMatchDate) { total++; if (task.isCompleted) completed++; }
    }
    return {'total': total, 'completed': completed};
  }

  // ==========================================
  // [CẬP NHẬT] HỘP THOẠI QUẢN LÝ PROFILE
  // ==========================================
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _currentName);
    String? tempAvatarPath = _avatarPath;
    bool tempNotif = _isNotificationEnabled;

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text("Thiết lập cá nhân", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Khu vực đổi Ảnh đại diện
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.purple[100],
                            backgroundImage: tempAvatarPath != null ? FileImage(File(tempAvatarPath!)) : null,
                            child: tempAvatarPath == null
                                ? Text(
                                nameController.text.isNotEmpty ? nameController.text[0].toUpperCase() : 'U',
                                style: TextStyle(fontSize: 35, color: Colors.purple[800], fontWeight: FontWeight.bold)
                            )
                                : null,
                          ),
                          GestureDetector(
                            onTap: () async {
                              try {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                if (image != null) {
                                  setDialogState(() => tempAvatarPath = image.path);
                                }
                              } catch (e) {
                                print("❌ Lỗi mở thư viện ảnh: $e");
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không thể mở thư viện ảnh!"), backgroundColor: Colors.red));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2)
                              ),
                              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 25),

                      // 2. Khu vực đổi Tên
                      TextField(
                        controller: nameController,
                        onChanged: (val) {
                          // Gọi setDialogState để cái chữ cái ở Avatar thay đổi ngay lập tức khi gõ
                          setDialogState(() {});
                        },
                        decoration: InputDecoration(
                          labelText: "Tên hiển thị",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 3. Khu vực Cài đặt thông báo
                      Container(
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                        child: SwitchListTile(
                          title: const Text("Thông báo nhắc nhở", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          activeColor: Colors.blue,
                          value: tempNotif,
                          onChanged: (bool value) {
                            setDialogState(() => tempNotif = value);
                          },
                        ),
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
                        // Kiểm tra nếu để trống tên
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tên hiển thị không được để trống!"), backgroundColor: Colors.orange));
                          return;
                        }

                        try {
                          // Lưu vĩnh viễn vào SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('userName', nameController.text.trim());
                          await prefs.setBool('notifications', tempNotif);
                          if (tempAvatarPath != null) {
                            await prefs.setString('avatarPath', tempAvatarPath!);
                          }

                          // Cập nhật lại giao diện chính (Sẽ làm chữ Xin chào đổi ngay lập tức)
                          setState(() {
                            _currentName = nameController.text.trim();
                            _isNotificationEnabled = tempNotif;
                            _avatarPath = tempAvatarPath;
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu thiết lập thành công!"), backgroundColor: Colors.green));
                          }
                        } catch (e) {
                          print("❌ Lỗi lưu dữ liệu: $e");
                        }
                      },
                      child: const Text("Lưu", style: TextStyle(color: Colors.white)),
                    )
                  ],
                );
              }
          );
        }
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    int selectedColor = Colors.blue.value;
    final List<Color> colorOptions = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal];

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text("Tạo danh mục mới", style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên danh mục", hintText: "VD: Học Tiếng Anh", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))), const SizedBox(height: 20), const Text("Chọn màu sắc:", style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 10),
                      Wrap(spacing: 10, children: colorOptions.map((color) => GestureDetector(onTap: () => setDialogState(() => selectedColor = color.value), child: CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 18, child: CircleAvatar(backgroundColor: color, radius: 14, child: selectedColor == color.value ? const Icon(Icons.check, size: 16, color: Colors.white) : null)))).toList())
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () async { if (nameController.text.trim().isNotEmpty) { await db.insertCategory(nameController.text.trim(), selectedColor); if (mounted) { Navigator.pop(context); loadData(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm danh mục mới!"))); } } }, child: const Text("Tạo mới", style: TextStyle(color: Colors.white)))
                  ],
                );
              }
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayTasks = _filteredTasks;
    final stats = _getFilterStats();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Xin chào, $_currentName! 👋", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const Text("Quản lý công việc cá nhân", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: _showEditProfileDialog,
              child: CircleAvatar(
                backgroundColor: Colors.purple[100],
                backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null, // Hiện ảnh nếu có
                child: _avatarPath == null
                    ? Text(_currentName.isNotEmpty ? _currentName[0].toUpperCase() : 'U', style: TextStyle(color: Colors.purple[800], fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: () async => loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryManagementScreen())); loadData(); },
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("🗂️ Danh mục", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Row(children: [Text("Quản lý", style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)), const SizedBox(width: 4), Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[500])])]),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 55,
                child: ListView(
                  scrollDirection: Axis.horizontal, clipBehavior: Clip.none,
                  children: [
                    ...categories.map((cat) {
                      Color catColor = Color(cat['colorCode']);
                      return Container(
                        margin: const EdgeInsets.only(right: 15, top: 6),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryDetailScreen(categoryId: cat['id'].toString(), categoryName: cat['name'], colorCode: cat['colorCode']))).then((_) => loadData()); },
                              child: Container(padding: const EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.center, decoration: BoxDecoration(color: catColor.withOpacity(0.08), borderRadius: BorderRadius.circular(30), border: Border.all(color: catColor.withOpacity(0.5), width: 1)), child: Text(cat['name'], style: TextStyle(color: catColor, fontWeight: FontWeight.w700, fontSize: 13))),
                            ),
                            if (cat['taskCount'] > 0)
                              Positioned(top: -6, right: -6, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), constraints: const BoxConstraints(minWidth: 22, minHeight: 22), child: Center(child: Text('${cat['taskCount']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))),
                          ],
                        ),
                      );
                    }),
                    Container(margin: const EdgeInsets.only(top: 6), child: GestureDetector(onTap: _showAddCategoryDialog, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.center, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)), child: Row(children: [Icon(Icons.add, size: 16, color: Colors.grey[700]), const SizedBox(width: 4), Text("Thêm", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 13))]))))
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("📝 Danh sách nhiệm vụ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)), child: Text("${stats['completed']}/${stats['total']} Xong", style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.bold)))]),
              const SizedBox(height: 15),
              SizedBox(height: 38, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _filters.length, itemBuilder: (context, index) { bool isSelected = _selectedFilter == _filters[index]; return GestureDetector(onTap: () => setState(() => _selectedFilter = _filters[index]), child: Container(margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 18), alignment: Alignment.center, decoration: BoxDecoration(color: isSelected ? (_filters[index] == 'Đã xong' ? Colors.green : Colors.blue) : Colors.grey[200], borderRadius: BorderRadius.circular(20)), child: Text(_filters[index], style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 13)))); })),
              const SizedBox(height: 20),
              displayTasks.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Column(children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: Icon(_selectedFilter == 'Đã xong' ? Icons.check_circle_outline : Icons.done_all, size: 50, color: Colors.green.withOpacity(0.8))), const SizedBox(height: 15), Text(_selectedFilter == 'Đã trễ' ? "Thật xuất sắc!" : _selectedFilter == 'Đã xong' ? "Chưa có thành tựu nào" : "Trống trải quá!", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 5), Text(_selectedFilter == 'Đã trễ' ? "Bạn không có deadline nào bị trễ." : _selectedFilter == 'Đã xong' ? "Hãy hoàn thành một vài việc nhé." : "Không có công việc nào trong mục này.", style: TextStyle(color: Colors.grey[500], fontSize: 14))])) )
                  : ListView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: displayTasks.length,
                itemBuilder: (ctx, i) {
                  final task = displayTasks[i];
                  return Dismissible(
                    key: Key(task.id), direction: DismissDirection.endToStart,
                    background: Container(margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(20)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 25), child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28)),
                    onDismissed: (direction) async { await db.deleteTask(task.id); setState(() => tasks.removeWhere((t) => t.id == task.id)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa công việc!"))); loadData(); },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: task.isCompleted ? Colors.grey.shade50 : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: task.isCompleted ? Colors.grey.shade200 : Colors.transparent, width: 1), boxShadow: task.isCompleted ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, spreadRadius: 0, offset: const Offset(0, 8))]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: task.isCompleted ? Colors.grey.shade300 : Color(task.colorCode), width: 6))),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(taskId: task.id))); loadData(); },
                            title: Text(task.title, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null, color: task.isCompleted ? Colors.grey.shade500 : Colors.black87, fontWeight: FontWeight.w700, fontSize: 16)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(children: [Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Text(task.time, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)), const SizedBox(width: 12), if (task.subjectName != null) Expanded(child: Text(task.subjectName!, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.blue[600], fontWeight: FontWeight.w600)))]),
                                if (task.location != null && task.location!.isNotEmpty) ...[const SizedBox(height: 6), Row(children: [Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Expanded(child: Text(task.location!, style: TextStyle(color: Colors.grey[600], fontSize: 12), overflow: TextOverflow.ellipsis))])],
                                if (task.dueDate != null && task.dueDate!.isNotEmpty) ...[const SizedBox(height: 6), Row(children: [Icon(Icons.flag_rounded, size: 14, color: Colors.red[400]), const SizedBox(width: 4), Text("Hạn chót: ${task.dueDate}", style: TextStyle(color: Colors.red[500], fontSize: 12, fontWeight: FontWeight.bold))])],
                                if (task.totalSubtasks > 0) ...[const SizedBox(height: 12), Row(children: [Icon(Icons.account_tree_outlined, size: 14, color: Colors.blue[400]), const SizedBox(width: 4), Text("${task.completedSubtasks}/${task.totalSubtasks} tiến độ", style: TextStyle(fontSize: 12, color: Colors.blue[600], fontWeight: FontWeight.bold)), const SizedBox(width: 8), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: task.totalSubtasks > 0 ? task.completedSubtasks / task.totalSubtasks : 0, minHeight: 4, backgroundColor: Colors.blue[100], valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!)))), const SizedBox(width: 10)])],
                              ],
                            ),
                            trailing: Transform.scale(scale: 1.2, child: Checkbox(activeColor: Color(task.colorCode), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), side: BorderSide(color: Colors.grey.shade400, width: 1.5), value: task.isCompleted, onChanged: (v) async { await db.toggleTask(task.id, task.isCompleted); loadData(); })),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}