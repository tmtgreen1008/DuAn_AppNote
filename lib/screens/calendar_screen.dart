// File: lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/student_models.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // TabBar cho 7 ngày (Thứ 2 -> Chủ Nhật)
  final List<String> _days = ["Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "CN"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Thời Khóa Biểu CNTT"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Cho phép trượt ngang nếu màn hình nhỏ
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: _days.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(7, (index) {
          // index 0 là Thứ 2 (dayOfWeek = 2 trong database)
          return ScheduleList(dayOfWeek: index + 2);
        }),
      ),
    );
  }
}

// Widget con: Danh sách môn học của 1 ngày cụ thể
class ScheduleList extends StatefulWidget {
  final int dayOfWeek;
  const ScheduleList({super.key, required this.dayOfWeek});

  @override
  State<ScheduleList> createState() => _ScheduleListState();
}

class _ScheduleListState extends State<ScheduleList> {
  List<ScheduleItem> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- [PHẦN QUAN TRỌNG ĐÃ SỬA] ---
  // Thêm try-catch để không bao giờ bị treo loading
  void _loadData() async {
    try {
      // Gọi hàm lấy lịch từ DatabaseHelper
      final data = await DatabaseHelper().getScheduleByDay(widget.dayOfWeek);

      if(mounted) {
        setState(() {
          items = data;
          loading = false; // Tắt loading khi thành công
        });
      }
    } catch (e) {
      print("❌ Lỗi tải lịch (Ngày ${widget.dayOfWeek}): $e");
      // Nếu có lỗi, vẫn phải tắt loading để màn hình hiện lên
      if(mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }
  // --------------------------------

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    // Nếu ngày đó không có lịch
    if (items.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.weekend, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 10),
        Text("Ngày nghỉ! Không có lịch học.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
      ],
    ));

    // Nếu có lịch
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            // Đường viền màu bên trái để phân biệt môn
            border: Border(left: BorderSide(color: Color(item.colorCode), width: 6)),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                // Cột 1: Thời gian
                Column(
                  children: [
                    Text(item.startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(height: 20, width: 2, color: Colors.grey[200], margin: const EdgeInsets.symmetric(vertical: 2)),
                    Text(item.endTime, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
                const SizedBox(width: 20),

                // Cột 2: Thông tin chi tiết
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.subjectName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.blue[400]),
                          const SizedBox(width: 4),
                          Text(item.room, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 15),
                          Icon(Icons.person, size: 14, color: Colors.orange[400]),
                          const SizedBox(width: 4),
                          Text(item.teacher, style: const TextStyle(fontSize: 13)),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}