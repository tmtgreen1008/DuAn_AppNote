// File: lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:untitled3/screens/report_screen.dart';
import '../services/database_helper.dart';
import '../models/student_models.dart';
import '../dataa/seed_data.dart'; // Đảm bảo đường dẫn này đúng với thư mục của bạn
import 'calendar_screen.dart';
import 'category_detail_screen.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';
import 'plan_list_screen.dart';
import 'brain_dump_screen.dart'; // [MỚI] Import màn hình Brain Dump

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

      // --- [ĐÃ TÍCH HỢP] SẮP XẾP TASK THEO THỜI GIAN TỪ SÁNG TỚI TỐI ---
      t.sort((a, b) => a.time.compareTo(b.time));

      if (mounted) {
        setState(() {
          tasks = t;
          scores = s;
          loading = false;
        });
      }
    } catch (e) {
      print("❌ Lỗi tải dữ liệu Dashboard: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  // --- HÀM TÍNH TỔNG GPA (Hệ 4.0) ---
  String _calculateGPA() {
    if (scores.isEmpty) return "0.0";
    double total = 0;
    for (var s in scores) {
      double s10 = s.scoreValue;
      if (s10 >= 8.5) {
        total += 4.0;
      } else if (s10 >= 7.0) {
        total += 3.0;
      } else if (s10 >= 5.5) {
        total += 2.0;
      } else if (s10 >= 4.0) {
        total += 1.0;
      }
    }
    return (total / scores.length).toStringAsFixed(2);
  }

  // --- HÀM MỞ BẢNG NHẬP ĐIỂM ---
  void _showAddScoreBottomSheet(BuildContext context) async {
    final subjects = await DatabaseHelper().getSubjectsForActivePlan();

    if (subjects.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chưa có môn học nào trong kỳ này!"), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return _AddScoreForm(
          subjects: subjects,
          onSaved: () => loadData(), // Load lại data sau khi lưu điểm thành công
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      // ==========================================
      // 1. NÚT THÊM VIỆC & BRAIN DUMP (FAB) ĐÃ CẬP NHẬT
      // ==========================================
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // NÚT GHI CHÚ NHANH (MỚI)
          FloatingActionButton(
            heroTag: "dump",
            onPressed: () async {
              final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BrainDumpScreen())
              );
              if (res == true) loadData(); // Load lại lịch nếu có tự động xếp việc
            },
            backgroundColor: Colors.orange,
            mini: true,
            tooltip: "Ghi chú nhanh",
            child: const Icon(Icons.note_alt, color: Colors.white),
          ),
          const SizedBox(height: 10),
          // NÚT THÊM VIỆC CŨ
          FloatingActionButton.extended(
            heroTag: "add",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTaskScreen()),
              );
              if (result == true) loadData();
            },
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Thêm việc", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),

      // 2. APP BAR
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
          // --- NÚT QUẢN LÝ HỌC KỲ ---
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
            child: IconButton(
              icon: const Icon(Icons.folder_special, color: Colors.orange),
              tooltip: "Quản lý Học kỳ",
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlanListScreen()),
                );
                loadData();
              },
            ),
          ),

          // --- NÚT XEM BÁO CÁO THỐNG KÊ ---
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
            child: IconButton(
              icon: const Icon(Icons.bar_chart, color: Colors.green),
              tooltip: "Xem Báo cáo Thống kê",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportScreen()),
                ).then((_) => loadData());
              },
            ),
          ),

          // --- NÚT XEM LỊCH ---
          Container(
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
            child: IconButton(
              icon: const Icon(Icons.calendar_month, color: Colors.blue),
              tooltip: "Xem Thời Khóa Biểu",
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarScreen()),
                );
                loadData();
              },
            ),
          )
        ],
      ),

      // 3. BODY
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. DANH MỤC
              const Text("🗂️ Danh mục (Ấn để xem)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: SeedData.categories.map((cat) {
                    return GestureDetector(
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
                        ).then((_) => loadData());
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

              // B. BẢNG ĐIỂM
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text("📊 Kết quả học tập", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue, size: 24),
                        onPressed: () => _showAddScoreBottomSheet(context),
                        tooltip: "Nhập điểm mới",
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(10)),
                    child: Text(
                        "GPA: ${_calculateGPA()}",
                        style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 13)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 130,
                child: scores.isEmpty
                    ? const Center(child: Text("Chưa có điểm số", style: TextStyle(color: Colors.grey)))
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
                      Text(scores[i].subjectName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("${scores[i].scoreValue}", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 4),
                      Text(scores[i].type, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.orange)),
                    ]),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // C. DANH SÁCH CÔNG VIỆC
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
                itemBuilder: (ctx, i) {
                  final task = tasks[i];
                  return Dismissible(
                    key: Key(task.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    onDismissed: (direction) async {
                      await db.deleteTask(task.id);
                      setState(() {
                        tasks.removeAt(i);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa công việc!")));
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(left: BorderSide(color: Color(task.colorCode), width: 4)),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)],
                      ),
                      child: ListTile(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailScreen(taskId: task.id),
                            ),
                          );
                          loadData();
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                        title: Text(task.title,
                            style: TextStyle(
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: task.isCompleted ? Colors.grey : Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        subtitle: Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(task.time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(width: 10),
                            if (task.subjectName != null)
                              Expanded(child: Text(task.subjectName!, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.blue[400]))),
                          ],
                        ),
                        trailing: Transform.scale(
                          scale: 1.1,
                          child: Checkbox(
                              activeColor: Color(task.colorCode),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              value: task.isCompleted,
                              onChanged: (v) async {
                                await db.toggleTask(task.id, task.isCompleted);
                                loadData();
                              }),
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

// ==========================================
// WIDGET FORM NHẬP ĐIỂM BÊN DƯỚI (BOTTOM SHEET)
// ==========================================
class _AddScoreForm extends StatefulWidget {
  final List<Map<String, dynamic>> subjects;
  final VoidCallback onSaved;

  const _AddScoreForm({required this.subjects, required this.onSaved});

  @override
  State<_AddScoreForm> createState() => _AddScoreFormState();
}

class _AddScoreFormState extends State<_AddScoreForm> {
  String? _selectedSubjectId;
  String _selectedType = 'Cuối kỳ';
  final _scoreController = TextEditingController();

  final List<String> _scoreTypes = ['Chuyên cần', 'Giữa kỳ', 'Thực hành', 'Cuối kỳ', 'Đồ án'];

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) {
      _selectedSubjectId = widget.subjects.first['id'] as String;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Nhập kết quả học tập", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 20),

          // Chọn môn học
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: "Môn học", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            value: _selectedSubjectId,
            items: widget.subjects.map((sub) => DropdownMenuItem<String>(
              value: sub['id'] as String,
              child: Text(sub['name'] as String),
            )).toList(),
            onChanged: (val) => setState(() => _selectedSubjectId = val),
          ),
          const SizedBox(height: 15),

          // Chọn loại điểm
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: "Loại điểm", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            value: _selectedType,
            items: _scoreTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (val) => setState(() => _selectedType = val!),
          ),
          const SizedBox(height: 15),

          // Nhập số điểm
          TextField(
            controller: _scoreController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Số điểm (Hệ 10)",
              hintText: "Ví dụ: 8.5",
              prefixIcon: const Icon(Icons.score),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 25),

          // Nút Lưu
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                double? score = double.tryParse(_scoreController.text.replaceAll(',', '.'));
                if (score != null && score >= 0 && score <= 10 && _selectedSubjectId != null) {
                  await DatabaseHelper().insertOrUpdateScore(_selectedSubjectId!, _selectedType, score);
                  if (context.mounted) {
                    Navigator.pop(context);
                    widget.onSaved(); // Load lại Dashboard
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu điểm thành công!"), backgroundColor: Colors.green));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập điểm hợp lệ (0-10)"), backgroundColor: Colors.red));
                }
              },
              child: const Text("Lưu điểm", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}