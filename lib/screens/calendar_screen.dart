// File: lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../models/student_models.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<TaskItem> _dayTasks = [];
  Map<String, List<Color>> _taskMarkers = {}; // LƯU DANH SÁCH MÀU CHO TỪNG NGÀY
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeData();
  }

  // Khởi tạo dữ liệu ban đầu
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    // Lấy bản đồ màu sắc cho các ngày
    _taskMarkers = await DatabaseHelper().getTaskMarkers();

    await _loadDataForSelectedDay(_selectedDay!);
  }

  // Tải Công việc cho ngày cụ thể
  Future<void> _loadDataForSelectedDay(DateTime date) async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper().getTasksByDate(date);

    if (mounted) {
      setState(() {
        _dayTasks = data;
        _isLoading = false;
      });
    }
  }

  // TRẢ VỀ DANH SÁCH MÀU ĐỂ VẼ CHẤM
  List<dynamic> _getEventsForDay(DateTime day) {
    String dateStr = DateFormat('yyyy-MM-dd').format(day);
    return _taskMarkers[dateStr] ?? []; // Trả về list Color của ngày đó
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Lịch Cá Nhân", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(_calendarFormat == CalendarFormat.month ? Icons.view_week : Icons.calendar_view_month, color: Colors.blue),
            onPressed: () => setState(() => _calendarFormat = _calendarFormat == CalendarFormat.month ? CalendarFormat.week : CalendarFormat.month),
          )
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay, // Truyền list Color vào đây

            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            calendarStyle: CalendarStyle(
              // Đã xóa markerDecoration cũ đi để dùng Builder mới
              selectedDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
              todayTextStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),

            // --- TÙY CHỈNH VẼ CÁC CHẤM MÀU ĐỘNG TẠI ĐÂY ---
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();

                return Positioned(
                  bottom: 6, // Đẩy lên một chút để không dính viền dưới
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.map((event) {
                      Color color = event as Color;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            // ----------------------------------------------

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadDataForSelectedDay(selectedDay);
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          ),

          const SizedBox(height: 10),

          // DANH SÁCH NHIỆM VỤ
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _dayTasks.isEmpty ? _buildEmptyState() : _buildTaskList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _dayTasks.length,
      itemBuilder: (context, index) {
        final task = _dayTasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            leading: Container(
              width: 5,
              height: 40,
              decoration: BoxDecoration(color: Color(task.colorCode), borderRadius: BorderRadius.circular(5)),
            ),
            title: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? Colors.grey : Colors.black87,
                )
            ),
            subtitle: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(task.time, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            trailing: Transform.scale(
              scale: 1.2,
              child: Checkbox(
                activeColor: Color(task.colorCode),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                value: task.isCompleted,
                onChanged: (v) async {
                  await DatabaseHelper().toggleTask(task.id, task.isCompleted);
                  _loadDataForSelectedDay(_selectedDay!);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.coffee_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("Không có nhiệm vụ nào, nghỉ ngơi thôi!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}