// File: lib/screens/plan_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/student_models.dart';

class PlanDetailScreen extends StatefulWidget {
  final String planId;
  final String planTitle;

  const PlanDetailScreen({super.key, required this.planId, required this.planTitle});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

// [MỚI] Thêm SingleTickerProviderStateMixin để quản lý TabController
class _PlanDetailScreenState extends State<PlanDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _subjects = [];
  List<ScheduleItem> _schedules = [];
  bool _isLoading = true;

  final List<Color> _colors = [
    Colors.red, Colors.blue, Colors.green, Colors.orange,
    Colors.purple, Colors.teal, Colors.pink, Colors.indigo
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Lắng nghe thay đổi Tab để cập nhật nút Floating Action Button
    _tabController.addListener(() {
      setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Tải đồng thời cả Môn học và Lịch học
  void _loadData() async {
    final subs = await DatabaseHelper().getSubjectsByPlan(widget.planId);
    final scheds = await DatabaseHelper().getScheduleByDay(-1, widget.planId);
    if (mounted) {
      setState(() {
        _subjects = subs;
        _schedules = scheds;
        _isLoading = false;
      });
    }
  }

  // --- POPUP 1: THÊM MÔN HỌC (Cũ) ---
  void _showAddSubjectBottomSheet() {
    final nameController = TextEditingController();
    final teacherController = TextEditingController();
    Color selectedColor = _colors[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20, right: 20, top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Thêm Môn Học Mới", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên môn học", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 15),
                    TextField(controller: teacherController, decoration: InputDecoration(labelText: "Tên Giảng viên", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 15),
                    const Text("Chọn màu nhận diện:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: _colors.map((color) {
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedColor = color),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: selectedColor == color ? Colors.black : Colors.transparent, width: 3)),
                            child: selectedColor == color ? const Icon(Icons.check, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (nameController.text.isNotEmpty) {
                            await DatabaseHelper().addSubject(widget.planId, nameController.text.trim(), teacherController.text.trim(), selectedColor.value);
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadData();
                            }
                          }
                        },
                        child: const Text("Lưu Môn Học", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  // --- POPUP 2: THÊM LỊCH HỌC [MỚI] ---
  void _showAddScheduleBottomSheet() {
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng thêm Môn học ở tab bên cạnh trước!"), backgroundColor: Colors.orange));
      return;
    }

    Map<String, dynamic>? selectedSubject = _subjects.first;
    int selectedDay = 2; // Mặc định Thứ 2
    TimeOfDay startTime = const TimeOfDay(hour: 7, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 30);
    final roomController = TextEditingController();

    String formatTime(TimeOfDay t) {
      return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Xếp Lịch Học", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 20),

                    // Chọn Môn Học
                    DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: InputDecoration(labelText: "Chọn Môn học", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      value: selectedSubject,
                      items: _subjects.map((sub) => DropdownMenuItem(
                          value: sub,
                          child: Row(children: [
                            CircleAvatar(backgroundColor: Color(sub['colorCode']), radius: 8),
                            const SizedBox(width: 10),
                            Text(sub['name']),
                          ])
                      )).toList(),
                      onChanged: (val) => setModalState(() => selectedSubject = val),
                    ),
                    const SizedBox(height: 15),

                    // Chọn Thứ & Phòng học
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(labelText: "Thứ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            value: selectedDay,
                            items: [2, 3, 4, 5, 6, 7, 8].map((d) => DropdownMenuItem(value: d, child: Text(d == 8 ? "CN" : "Thứ $d"))).toList(),
                            onChanged: (val) => setModalState(() => selectedDay = val!),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: roomController,
                            decoration: InputDecoration(labelText: "Phòng học (VD: Lab 3)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Chọn Giờ
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                            title: const Text("Giờ bắt đầu", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            subtitle: Text(formatTime(startTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: startTime);
                              if (picked != null) setModalState(() => startTime = picked);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                            title: const Text("Giờ kết thúc", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            subtitle: Text(formatTime(endTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: endTime);
                              if (picked != null) setModalState(() => endTime = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (selectedSubject != null && roomController.text.isNotEmpty) {
                            await DatabaseHelper().addSchedule(
                                widget.planId,
                                selectedSubject!['name'],
                                selectedSubject!['teacherName'],
                                roomController.text.trim(),
                                formatTime(startTime),
                                formatTime(endTime),
                                selectedDay,
                                selectedSubject!['colorCode']
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadData();
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập Phòng học!"), backgroundColor: Colors.orange));
                          }
                        },
                        child: const Text("Lưu Lịch Học", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  // --- WIDGET XÂY DỰNG TAB LỊCH TUẦN ---
  Widget _buildScheduleTab() {
    if (_schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text("Chưa có lịch học nào. \nNhấn 'Thêm Lịch' để bắt đầu xếp lịch!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 7, // 7 ngày trong tuần
      itemBuilder: (context, index) {
        int day = index + 2; // Bắt đầu từ Thứ 2 (2) -> Chủ Nhật (8)

        // Lọc các môn học của ngày này
        var dayClasses = _schedules.where((s) => s.dayOfWeek == day).toList();
        if (dayClasses.isEmpty) return const SizedBox(); // Ngày nào trống thì không vẽ ra

        // Sắp xếp theo giờ học
        dayClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(day == 8 ? "Chủ Nhật" : "Thứ $day", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            ...dayClasses.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: Color(item.colorCode), width: 5)),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
              ),
              child: ListTile(
                title: Text(item.subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Phòng: ${item.room}  •  GV: ${item.teacher}"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.startTime, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(item.endTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                onLongPress: () async {
                  // Chức năng xóa môn học khỏi lịch
                  await DatabaseHelper().deleteSchedule(item.id);
                  _loadData();
                },
              ),
            )),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.planTitle, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: "Môn học"),
            Tab(icon: Icon(Icons.calendar_month), text: "Lịch tuần"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // --- TAB 1: DANH SÁCH MÔN HỌC ---
          _subjects.isEmpty
              ? const Center(child: Text("Chưa có môn học nào."))
              : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final sub = _subjects[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Color(sub['colorCode'] as int), radius: 15),
                  title: Text(sub['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("GV: ${sub['teacherName']}"),
                ),
              );
            },
          ),

          // --- TAB 2: LỊCH TUẦN ---
          _buildScheduleTab(),
        ],
      ),

      // Nút Floating Action Button (Tự động đổi tên theo Tab)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tabController.index == 0 ? _showAddSubjectBottomSheet : _showAddScheduleBottomSheet,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
            _tabController.index == 0 ? "Thêm Môn" : "Thêm Lịch",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}