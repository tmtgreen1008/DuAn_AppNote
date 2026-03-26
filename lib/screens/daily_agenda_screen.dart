import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../models/student_models.dart';

class DailyAgendaScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DailyAgendaScreen({super.key, required this.selectedDate});

  @override
  State<DailyAgendaScreen> createState() => _DailyAgendaScreenState();
}

class _DailyAgendaScreenState extends State<DailyAgendaScreen> {
  List<Map<String, dynamic>> _classes = [];
  List<TaskItem> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    setState(() => _isLoading = true);

    // Tải song song cả Lịch học và Nhiệm vụ của ngày hôm đó
    final classes = await DatabaseHelper().getClassesForSpecificDay(widget.selectedDate);
    final tasks = await DatabaseHelper().getTasksByDate(widget.selectedDate);

    if (mounted) {
      setState(() {
        _classes = classes;
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayDate = DateFormat('dd/MM/yyyy').format(widget.selectedDate);
    String weekday = widget.selectedDate.weekday == 7 ? "Chủ Nhật" : "Thứ ${widget.selectedDate.weekday + 1}";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Lịch trình trong ngày", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            Text("$weekday, $displayDate", style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_classes.isEmpty && _tasks.isEmpty)
          ? _buildEmptyState()
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_classes.isNotEmpty) ...[
            const Text("🎓 LỊCH TRÊN TRƯỜNG", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            ..._classes.map((c) => _buildClassCard(c)),
            const SizedBox(height: 25),
          ],

          if (_tasks.isNotEmpty) ...[
            const Text("📝 NHIỆM VỤ CÁ NHÂN", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            ..._tasks.map((t) => _buildTaskCard(t)),
          ]
        ],
      ),
    );
  }

  // --- GIAO DIỆN THẺ LỊCH HỌC ---
  Widget _buildClassCard(Map<String, dynamic> item) {
    bool isSpecial = item['dayOfWeek'] == 0; // Lịch thi/học bù
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: Color(item['colorCode'] as int), width: 6)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        title: Row(
          children: [
            Expanded(child: Text(item['subjectName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            if (isSpecial)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                child: const Text("Đột xuất", style: TextStyle(color: Colors.deepOrange, fontSize: 10, fontWeight: FontWeight.bold)),
              )
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(item['room'], style: TextStyle(color: Colors.grey[600])),
              const SizedBox(width: 15),
              Icon(Icons.person, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(child: Text(item['teacher'], style: TextStyle(color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item['startTime'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15)),
            Text(item['endTime'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- GIAO DIỆN THẺ NHIỆM VỤ ---
  Widget _buildTaskCard(TaskItem task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: task.isCompleted ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Checkbox(
          activeColor: Color(task.colorCode),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          value: task.isCompleted,
          onChanged: (v) async {
            await DatabaseHelper().toggleTask(task.id, task.isCompleted);
            _loadDailyData(); // Render lại
          },
        ),
        title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : Colors.black87,
            )
        ),
        subtitle: Row(
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 5),
            Text(task.time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(width: 15),
            CircleAvatar(radius: 4, backgroundColor: Color(task.colorCode)),
          ],
        ),
      ),
    );
  }

  // --- TRẠNG THÁI TRỐNG ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.weekend_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("Tuyệt vời!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 5),
          Text("Ngày này bạn không có lịch trình nào.", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}