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

  // Quản lý ngày tháng
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Dữ liệu
  List<Map<String, dynamic>> _dayClasses = [];
  List<TaskItem> _dayTasks = [];

  // Dùng để vẽ chấm màu
  Map<String, List<Color>> _taskMarkers = {};
  List<Map<String, dynamic>> _allClasses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Tải dữ liệu toàn cục để vẽ các chấm màu cho lịch
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    final dbHelper = DatabaseHelper();
    _taskMarkers = await dbHelper.getTaskMarkers(); // Lấy màu Task

    final db = await dbHelper.database;
    _allClasses = await db.query('timetable'); // Lấy màu Môn học

    await _loadDataForDay(_selectedDay);
  }

  // Tải chi tiết Lịch học + Task cho ngày đang chọn
  Future<void> _loadDataForDay(DateTime date) async {
    setState(() => _isLoading = true);

    // Gọi 2 hàm đã viết trong DatabaseHelper
    final classes = await DatabaseHelper().getClassesForSpecificDay(date);
    final tasks = await DatabaseHelper().getTasksByDate(date);

    if (mounted) {
      setState(() {
        _dayClasses = classes;
        _dayTasks = tasks;
        _isLoading = false;
      });
    }
  }

  // Hàm tính toán chấm màu: Kết hợp cả màu Task và màu Môn học
  List<dynamic> _getEventsForDay(DateTime day) {
    String dateStr = DateFormat('yyyy-MM-dd').format(day);
    List<Color> markers = [];

    // 1. Màu của Công việc (Tasks)
    if (_taskMarkers.containsKey(dateStr)) {
      markers.addAll(_taskMarkers[dateStr]!);
    }

    // 2. Màu của Môn học (Classes)
    int targetWeekday = day.weekday == 7 ? 8 : day.weekday + 1;
    for (var c in _allClasses) {
      bool hasClass = false;
      if (c['dayOfWeek'] == 0) { // Lịch đột xuất
        if (c['specificDate'] == dateStr) hasClass = true;
      } else { // Lịch lặp
        if (c['dayOfWeek'] == targetWeekday) {
          if (c['fromDate'] != null && c['toDate'] != null) {
            DateTime from = DateTime.parse(c['fromDate']);
            DateTime to = DateTime.parse(c['toDate']);
            from = DateTime(from.year, from.month, from.day);
            to = DateTime(to.year, to.month, to.day);
            DateTime target = DateTime(day.year, day.month, day.day);
            if (!target.isBefore(from) && !target.isAfter(to)) {
              hasClass = true;
            }
          } else {
            hasClass = true;
          }
        }
      }

      if (hasClass) {
        Color color = Color(c['colorCode'] as int);
        if (!markers.contains(color)) markers.add(color);
      }
    }

    return markers.take(4).toList(); // Lịch nhỏ nên chỉ vẽ tối đa 4 chấm/ngày
  }

  // Chức năng: Nhảy nhanh về ngày hôm nay
  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
    _loadDataForDay(_selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Lịch Tổng Hợp", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          // NÚT "HÔM NAY" GÓC TRÊN CÙNG
          TextButton.icon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today, color: Colors.blue, size: 18),
            label: const Text("Hôm nay", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: Icon(_calendarFormat == CalendarFormat.month ? Icons.view_week : Icons.calendar_view_month, color: Colors.blue),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month ? CalendarFormat.week : CalendarFormat.month;
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          // =================== GIAO DIỆN LỊCH ===================
          Container(
            color: Colors.white,
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Tháng',
                CalendarFormat.week: 'Tuần',
              },
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,

              // TÙY CHỈNH STYLE: LÀM NỔI BẬT NGÀY "HÔM NAY"
              calendarStyle: CalendarStyle(
                // Ngày hôm nay: Nền xanh nhạt, viền xanh đậm
                todayDecoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 2)
                ),
                todayTextStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                // Ngày đang được bấm chọn: Nền xanh kín
                selectedDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              ),

              // VẼ CHẤM MÀU
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox();
                  return Positioned(
                    bottom: 6,
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

              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _loadDataForDay(selectedDay);
                }
              },
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            ),
          ),
          const SizedBox(height: 10),

          // =================== DANH SÁCH BÊN DƯỚI LỊCH ===================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_dayClasses.isEmpty && _dayTasks.isEmpty)
                ? _buildEmptyState()
                : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // --- KHU VỰC 1: LỊCH HỌC TRÊN TRƯỜNG ---
                if (_dayClasses.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.school, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text("LỊCH TRÊN TRƯỜNG", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._dayClasses.map((c) => _buildClassCard(c)),
                  const SizedBox(height: 25), // Khoảng cách giữa 2 khu vực
                ],

                // --- KHU VỰC 2: NHIỆM VỤ CÁ NHÂN ---
                if (_dayTasks.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.task_alt, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text("NHIỆM VỤ CÁ NHÂN", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._dayTasks.map((t) => _buildTaskCard(t)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET VẼ THẺ LỊCH HỌC ---
  Widget _buildClassCard(Map<String, dynamic> item) {
    bool isSpecial = item['dayOfWeek'] == 0;
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

  // --- WIDGET VẼ THẺ NHIỆM VỤ ---
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
            // Tick hoàn thành -> Cập nhật Database -> Load lại màn hình
            await DatabaseHelper().toggleTask(task.id, task.isCompleted);
            _initializeData();
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

  // --- MÀN HÌNH TRỐNG KHI KHÔNG CÓ VIỆC ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("Tuyệt vời!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 5),
          Text("Ngày này bạn không có lịch trình nào.", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}