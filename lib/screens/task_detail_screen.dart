// File: lib/screens/task_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId; // ID của instance (ti...)

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? taskData;
  List<Map<String, dynamic>> subtasks = [];
  bool loading = true;
  final _subtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final db = DatabaseHelper();
    final t = await db.getTaskDetail(widget.taskId);
    final s = await db.getSubtasks(widget.taskId);

    if (mounted) {
      setState(() {
        taskData = t;
        subtasks = List.from(s);
        loading = false;
      });
    }
  }

  void _addSubtask() async {
    if (_subtaskController.text.isEmpty) return;
    await DatabaseHelper().addSubtask(widget.taskId, _subtaskController.text);
    _subtaskController.clear();
    loadData();
  }

  void _toggleSubtask(String id, bool val) async {
    await DatabaseHelper().toggleSubtask(id, val);
    loadData();
  }

  void _deleteSubtask(String id) async {
    await DatabaseHelper().deleteSubtask(id);
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (taskData == null || taskData!.isEmpty) return const Scaffold(body: Center(child: Text("Không tìm thấy công việc")));

    int colorCode = taskData!['colorCode'] ?? 0xFF2196F3;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chi tiết công việc", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, true), // Trả về true để reload Dashboard
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER (DANH MỤC & NGÀY)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(colorCode).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    taskData!['categoryName'] ?? 'General',
                    style: TextStyle(color: Color(colorCode), fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 5),
                Text(taskData!['date'] ?? '', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 20),

            // 2. TIÊU ĐỀ
            Text(
              taskData!['title'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 3. MÔ TẢ (DESCRIPTION)
            const Text("Mô tả", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                (taskData!['description'] != null && taskData!['description'].toString().isNotEmpty)
                    ? taskData!['description']
                    : "Chưa có mô tả chi tiết.",
                style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 30),

            // 4. SUBTASKS (CÔNG VIỆC PHỤ)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Công việc phụ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text("${subtasks.where((e) => e['isCompleted'] == 1).length}/${subtasks.length}", style: TextStyle(color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 10),

            // List Subtasks
            ...subtasks.map((st) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8)
              ),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Color(colorCode),
                title: Text(
                  st['title'],
                  style: TextStyle(
                    decoration: st['isCompleted'] == 1 ? TextDecoration.lineThrough : null,
                    color: st['isCompleted'] == 1 ? Colors.grey : Colors.black,
                  ),
                ),
                value: st['isCompleted'] == 1,
                onChanged: (val) => _toggleSubtask(st['id'], val!),
                secondary: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () => _deleteSubtask(st['id']),
                ),
              ),
            )),

            // Ô nhập Subtask mới
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add, color: Colors.grey),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    decoration: const InputDecoration(
                      hintText: "Thêm công việc phụ...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                IconButton(icon: Icon(Icons.send, color: Color(colorCode)), onPressed: _addSubtask)
              ],
            )
          ],
        ),
      ),
    );
  }
}