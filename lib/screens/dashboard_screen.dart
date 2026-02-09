// File: lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/student_models.dart';
import '../dataa/seed_data.dart'; // Đã sửa lại đường dẫn đúng (data thay vì dataa)
import 'calendar_screen.dart';
import 'category_detail_screen.dart'; // Import màn hình chi tiết

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final db = DatabaseHelper();
  List<TaskItem> tasks = [];
  List<Score> scores = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    try {
      await db.database;
      final t = await db.getTasksForToday();
      final s = await db.getScores();

      if (mounted) {
        setState(() {
          tasks = t;
          scores = s;
          loading = false;
        });
      }
    } catch (e) {
      print("❌ Lỗi tải dữ liệu: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Xin chào, Student! 👋", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const Text("Dashboard", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
            child: IconButton(
              icon: const Icon(Icons.calendar_month, color: Colors.blue),
              tooltip: "Xem Thời Khóa Biểu",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarScreen()),
                );
              },
            ),
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- A. PHẦN DANH MỤC (ĐÃ CẬP NHẬT SỰ KIỆN BẤM) ---
            const Text("🗂️ Danh mục (Ấn để xem)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            SizedBox(
              height: 45, // Tăng chiều cao một chút cho dễ bấm
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: SeedData.categories.map((cat) {
                  return GestureDetector(
                    // [QUAN TRỌNG] Sự kiện bấm chuyển trang
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryDetailScreen(
                            categoryId: cat['id'],
                            categoryName: cat['name'],
                            colorCode: cat['colorCode'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color(cat['colorCode']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Color(cat['colorCode']), width: 1),
                      ),
                      child: Text(
                        cat['name'],
                        style: TextStyle(color: Color(cat['colorCode']), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 25),

            // --- B. PHẦN BẢNG ĐIỂM ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("📊 Kết quả học tập", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(8)),
                  child: const Text("GPA: 3.8", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 110,
              child: scores.isEmpty
                  ? const Center(child: Text("Chưa có điểm số"))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: scores.length,
                itemBuilder: (ctx, i) => Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 15, bottom: 5),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(scores[i].subjectName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 5),
                    Text("${scores[i].scoreValue}", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue)),
                    Text(scores[i].type, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                  ]),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // --- C. PHẦN DANH SÁCH CÔNG VIỆC ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("📝 Nhiệm vụ hôm nay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${tasks.where((t) => t.isCompleted).length}/${tasks.length} Xong", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            tasks.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Không có công việc nào!")))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (ctx, i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(color: Color(tasks[i].colorCode), width: 4)),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                  title: Text(tasks[i].title,
                      style: TextStyle(
                          decoration: tasks[i].isCompleted ? TextDecoration.lineThrough : null,
                          color: tasks[i].isCompleted ? Colors.grey : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  subtitle: Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(tasks[i].time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 10),
                      if (tasks[i].subjectName != null)
                        Expanded(child: Text(tasks[i].subjectName!, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.blue[400]))),
                    ],
                  ),
                  trailing: Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                        activeColor: Color(tasks[i].colorCode),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        value: tasks[i].isCompleted,
                        onChanged: (v) async {
                          await db.toggleTask(tasks[i].id, tasks[i].isCompleted);
                          loadData();
                        }),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}