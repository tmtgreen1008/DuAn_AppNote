import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_helper.dart';
import '../models/student_models.dart';
import 'schedule_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Cấu hình hiển thị
  CalendarFormat _calendarFormat = CalendarFormat.month; // Để mặc định là tháng cho bạn dễ nhìn tổng quan
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Dữ liệu hiển thị
  List<ScheduleItem> _daySchedules = [];
  List<ScheduleItem> _allSchedulesTemplate = []; // Dùng để vẽ dấu chấm (Markers)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeData();
  }

  // Hàm khởi tạo dữ liệu ban đầu
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    // Lấy tất cả lịch của học kỳ hiện tại để vẽ dấu chấm (Markers)
    // Thay vì truyền cứng 'p2', ta tìm Plan dựa trên ngày hiện tại
    final currentPlan = await DatabaseHelper().getPlanByDate(DateTime.now());
    String planId = currentPlan != null ? currentPlan['id'] : 'p2';

    final allData = await DatabaseHelper().getScheduleByDay(-1, planId);

    setState(() {
      _allSchedulesTemplate = allData;
    });

    // Sau khi có template, tải dữ liệu chi tiết cho ngày đang chọn
    await _loadDataForSelectedDay(_selectedDay!);
  }

  // Hàm tải lịch học cho một ngày cụ thể
  Future<void> _loadDataForSelectedDay(DateTime date) async {
    setState(() => _isLoading = true);

    final plan = await DatabaseHelper().getPlanByDate(date);

    if (plan != null) {
      // Logic chuyển đổi thứ: Flutter (1:Mon -> 7:Sun) sang DB (2:T2 -> 8:CN)
      int dbDay = date.weekday == 7 ? 8 : date.weekday + 1;

      final data = await DatabaseHelper().getScheduleByDay(dbDay, plan['id']);
      setState(() {
        _daySchedules = data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _daySchedules = [];
        _isLoading = false;
      });
    }
  }

  // Hàm trả về "Sự kiện" cho mỗi ô ngày trên lịch tháng
  List<dynamic> _getEventsForDay(DateTime day) {
    // Chuyển ngày thành Thứ (2-8)
    int dbDay = day.weekday == 7 ? 8 : day.weekday + 1;

    // Trả về danh sách các môn học lặp lại vào thứ này
    return _allSchedulesTemplate.where((s) => s.dayOfWeek == dbDay).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Lịch Học Tập", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
          // BỘ LỊCH CÓ EVENT LOADER
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay, // Đây là dòng quan trọng để hiện dấu chấm

            // Giao diện lịch
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle), // Màu dấu chấm
              selectedDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
              todayTextStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),

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

          // DANH SÁCH MÔN HỌC
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _daySchedules.isEmpty ? _buildEmptyState() : _buildScheduleList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _daySchedules.length,
      itemBuilder: (context, index) {
        final item = _daySchedules[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(width: 5, height: 40, color: Color(item.colorCode)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("${item.startTime} - ${item.endTime} | Phòng: ${item.room}", style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
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
          const Text("Không có lịch học, nghỉ ngơi thôi!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}