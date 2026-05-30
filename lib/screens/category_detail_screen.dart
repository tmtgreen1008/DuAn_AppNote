// File: lib/screens/category_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/student_models.dart';
import 'task_detail_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final int colorCode;

  const CategoryDetailScreen({super.key, required this.categoryId, required this.categoryName, required this.colorCode});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final db = DatabaseHelper();
  List<TaskItem> tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final data = await db.getTasksByCategory(widget.categoryId);
    // Sắp xếp ưu tiên: Việc chưa làm lên trên, việc làm rồi xuống dưới
    data.sort((a, b) {
      if (a.isCompleted == b.isCompleted) return 0;
      if (a.isCompleted) return 1;
      return -1;
    });

    if (mounted) {
      setState(() {
        tasks = data;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(widget.colorCode),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 15),
            Text("Chưa có nhiệm vụ nào!", style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.bold)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Dismissible(
            key: Key(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(20)),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 25),
              child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
            ),
            onDismissed: (direction) async {
              await db.deleteTask(task.id);
              setState(() => tasks.removeAt(index));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa công việc!")));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: task.isCompleted ? Colors.grey.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: task.isCompleted ? Colors.grey.shade200 : Colors.transparent,
                  width: 1,
                ),
                boxShadow: task.isCompleted
                    ? []
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24, spreadRadius: 0, offset: const Offset(0, 8),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: task.isCompleted ? Colors.grey.shade300 : Color(task.colorCode),
                        width: 6,
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(taskId: task.id)));
                      loadData();
                    },
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? Colors.grey.shade500 : Colors.black87,
                        fontWeight: FontWeight.w700, fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]), const SizedBox(width: 4),
                            Text(task.date, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)), const SizedBox(width: 12),
                            if (task.subjectName != null)
                              Expanded(child: Text(task.subjectName!, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.blue[600], fontWeight: FontWeight.w600))),
                          ],
                        ),
                        if (task.location != null && task.location!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(children: [Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Expanded(child: Text(task.location!, style: TextStyle(color: Colors.grey[600], fontSize: 12), overflow: TextOverflow.ellipsis))]),
                        ],
                        if (task.dueDate != null && task.dueDate!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(children: [Icon(Icons.flag_rounded, size: 14, color: Colors.red[400]), const SizedBox(width: 4), Text("Hạn chót: ${task.dueDate}", style: TextStyle(color: Colors.red[500], fontSize: 12, fontWeight: FontWeight.bold))]),
                        ],
                        if (task.totalSubtasks > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.account_tree_outlined, size: 14, color: Colors.blue[400]), const SizedBox(width: 4),
                              Text("${task.completedSubtasks}/${task.totalSubtasks} tiến độ", style: TextStyle(fontSize: 12, color: Colors.blue[600], fontWeight: FontWeight.bold)), const SizedBox(width: 8),
                              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: task.totalSubtasks > 0 ? task.completedSubtasks / task.totalSubtasks : 0, minHeight: 4, backgroundColor: Colors.blue[100], valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!)))), const SizedBox(width: 10),
                            ],
                          )
                        ],
                      ],
                    ),
                    trailing: Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                          activeColor: Color(task.colorCode),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                          value: task.isCompleted,
                          onChanged: (v) async {
                            await db.toggleTask(task.id, task.isCompleted);
                            loadData(); // Cập nhật lại UI lập tức
                          }),
                    ),
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