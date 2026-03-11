// File: lib/screens/plan_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_helper.dart';

class PlanDetailScreen extends StatefulWidget {
  final String planId;
  final String planTitle;

  const PlanDetailScreen({super.key, required this.planId, required this.planTitle});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  bool _isCalendarView = false;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final List<Color> _colors = [
    Colors.red, Colors.blue, Colors.green, Colors.orange,
    Colors.purple, Colors.teal, Colors.pink, Colors.indigo
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { setState(() {}); });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final subs = await dbHelper.getSubjectsByPlan(widget.planId);
    final scheds = await db.query('timetable', where: 'planId = ?', whereArgs: [widget.planId]);

    if (mounted) {
      setState(() {
        _subjects = subs;
        _schedules = scheds;
        _isLoading = false;
      });
    }
  }

  // --- [MỚI] HÀM KIỂM TRA NGÀY CÓ LỊCH HỌC ĐỂ VẼ CHẤM TRÒN ---
  List<dynamic> _getEventsForDay(DateTime day) {
    DateTime target = DateTime(day.year, day.month, day.day);
    List<Color> dotColors = [];

    for (var s in _schedules) {
      bool hasClass = false;

      if (s['dayOfWeek'] == 0) {
        // Lịch 1 ngày
        if (s['specificDate'] == DateFormat('yyyy-MM-dd').format(target)) {
          hasClass = true;
        }
      } else {
        // Lịch lặp
        int targetWeekday = target.weekday == 7 ? 8 : target.weekday + 1;
        if (s['dayOfWeek'] == targetWeekday) {
          if (s['fromDate'] != null && s['toDate'] != null) {
            DateTime from = DateTime.parse(s['fromDate']);
            DateTime to = DateTime.parse(s['toDate']);
            from = DateTime(from.year, from.month, from.day);
            to = DateTime(to.year, to.month, to.day);
            if (!target.isBefore(from) && !target.isAfter(to)) {
              hasClass = true;
            }
          } else {
            hasClass = true;
          }
        }
      }

      if (hasClass) {
        Color c = Color(s['colorCode'] as int);
        if (!dotColors.contains(c) && dotColors.length < 4) { // Tối đa 4 chấm màu
          dotColors.add(c);
        }
      }
    }
    return dotColors;
  }
  // ---------------------------------------------------------

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
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
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
                            if (context.mounted) { Navigator.pop(context); _loadData(); }
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

  void _showAddScheduleBottomSheet() {
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng thêm Môn học trước!"), backgroundColor: Colors.orange));
      return;
    }

    String? selectedSubjectId = _subjects.first['id'] as String;
    bool isRecurring = true;
    int selectedDay = 2;
    DateTime selectedDate = DateTime.now();
    DateTimeRange selectedDateRange = DateTimeRange(start: DateTime.now(), end: DateTime.now().add(const Duration(days: 90)));
    TimeOfDay startTime = const TimeOfDay(hour: 7, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 30);
    final roomController = TextEditingController();

    String formatTime(TimeOfDay t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

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
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => isRecurring = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(color: isRecurring ? Colors.blue : Colors.transparent, borderRadius: BorderRadius.circular(15)),
                                child: Text("Lịch Lặp Hàng Tuần", textAlign: TextAlign.center, style: TextStyle(color: isRecurring ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => isRecurring = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(color: !isRecurring ? Colors.orange : Colors.transparent, borderRadius: BorderRadius.circular(15)),
                                child: Text("1 Ngày Cụ Thể", textAlign: TextAlign.center, style: TextStyle(color: !isRecurring ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Chọn Môn học", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      value: selectedSubjectId,
                      items: _subjects.map((sub) => DropdownMenuItem<String>(
                          value: sub['id'] as String,
                          child: Row(children: [CircleAvatar(backgroundColor: Color(sub['colorCode']), radius: 8), const SizedBox(width: 10), Text(sub['name'])])
                      )).toList(),
                      onChanged: (val) => setModalState(() => selectedSubjectId = val),
                    ),
                    const SizedBox(height: 15),

                    if (isRecurring) ...[
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(labelText: "Học vào Thứ mấy?", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        value: selectedDay,
                        items: [2, 3, 4, 5, 6, 7, 8].map((d) => DropdownMenuItem(value: d, child: Text(d == 8 ? "CN" : "Thứ $d"))).toList(),
                        onChanged: (val) => setModalState(() => selectedDay = val!),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade200)),
                        title: const Text("Thời gian học môn này", style: TextStyle(fontSize: 12, color: Colors.blue)),
                        subtitle: Text("${DateFormat('dd/MM/yyyy').format(selectedDateRange.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange.end)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        trailing: const Icon(Icons.date_range, color: Colors.blue),
                        onTap: () async {
                          final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030), initialDateRange: selectedDateRange);
                          if (picked != null) setModalState(() => selectedDateRange = picked);
                        },
                      ),
                    ] else ...[
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade300)),
                        title: const Text("Chọn ngày", style: TextStyle(fontSize: 12, color: Colors.orange)),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        trailing: const Icon(Icons.calendar_month, color: Colors.orange),
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (picked != null) setModalState(() => selectedDate = picked);
                        },
                      ),
                    ],

                    const SizedBox(height: 15),
                    TextField(controller: roomController, decoration: InputDecoration(labelText: "Phòng học (VD: Lab 3)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 15),

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
                        style: ElevatedButton.styleFrom(backgroundColor: isRecurring ? Colors.blue : Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (selectedSubjectId == null || roomController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập Phòng học!"), backgroundColor: Colors.orange));
                            return;
                          }

                          try {
                            final selectedSubjectMap = _subjects.firstWhere((s) => s['id'] == selectedSubjectId);

                            await DatabaseHelper().addSchedule(
                              widget.planId,
                              selectedSubjectMap['name'],
                              selectedSubjectMap['teacherName'],
                              roomController.text.trim(),
                              formatTime(startTime),
                              formatTime(endTime),
                              isRecurring ? selectedDay : 0,
                              selectedSubjectMap['colorCode'],
                              specificDate: isRecurring ? null : DateFormat('yyyy-MM-dd').format(selectedDate),
                              fromDate: isRecurring ? DateFormat('yyyy-MM-dd').format(selectedDateRange.start) : null,
                              toDate: isRecurring ? DateFormat('yyyy-MM-dd').format(selectedDateRange.end) : null,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lưu lịch thành công!"), backgroundColor: Colors.green));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                      title: const Text("Lỗi Database!"),
                                      content: Text(e.toString()),
                                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đã hiểu"))]
                                  )
                              );
                            }
                          }
                        },
                        child: Text(isRecurring ? "Lưu Lịch Hàng Tuần" : "Lưu Lịch Đột Xuất", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isCalendarView ? "Xem theo Ngày cụ thể" : "Xem theo Mẫu hàng tuần",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              Switch(
                value: _isCalendarView,
                activeColor: Colors.blue,
                onChanged: (val) => setState(() => _isCalendarView = val),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isCalendarView
              ? Column(
            children: [
              Container(
                color: Colors.white,
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,

                  // --- [ĐÃ SỬA TẠI ĐÂY] DỊCH NÚT THÀNH THÁNG/TUẦN VÀ ẨN 2 WEEKS ---
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Tháng',
                    CalendarFormat.week: 'Tuần',
                  },
                  // ---------------------------------------------------------------

                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEventsForDay,

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
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) => setState(() => _calendarFormat = format),
                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                  headerStyle: const HeaderStyle(titleCentered: true),
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: Builder(
                    builder: (context) {
                      DateTime target = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

                      var dailyClasses = _schedules.where((s) {
                        if (s['dayOfWeek'] == 0) {
                          return s['specificDate'] == DateFormat('yyyy-MM-dd').format(target);
                        } else {
                          int targetWeekday = target.weekday == 7 ? 8 : target.weekday + 1;
                          if (s['dayOfWeek'] != targetWeekday) return false;

                          if (s['fromDate'] != null && s['toDate'] != null) {
                            DateTime from = DateTime.parse(s['fromDate']);
                            DateTime to = DateTime.parse(s['toDate']);
                            from = DateTime(from.year, from.month, from.day);
                            to = DateTime(to.year, to.month, to.day);
                            if (target.isBefore(from) || target.isAfter(to)) return false;
                          }
                          return true;
                        }
                      }).toList();

                      dailyClasses.sort((a, b) => (a['startTime'] as String).compareTo(b['startTime'] as String));

                      if (dailyClasses.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.coffee_outlined, size: 50, color: Colors.grey[300]),
                              const SizedBox(height: 10),
                              Text("Ngày này được nghỉ ngơi!", style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 80),
                        itemCount: dailyClasses.length,
                        itemBuilder: (context, index) {
                          var item = dailyClasses[index];
                          String? extra = item['dayOfWeek'] == 0 ? "Lịch đột xuất" : null;
                          return _buildScheduleCard(item, extraInfo: extra);
                        },
                      );
                    }
                ),
              ),
            ],
          )
              : ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 80),
            children: [
              ...List.generate(7, (index) {
                int day = index + 2;
                var dayClasses = _schedules.where((s) => s['dayOfWeek'] == day).toList();
                if (dayClasses.isEmpty) return const SizedBox();
                dayClasses.sort((a, b) => (a['startTime'] as String).compareTo(b['startTime'] as String));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(day == 8 ? "Chủ Nhật" : "Thứ $day", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ),
                    ...dayClasses.map((item) => _buildScheduleCard(item)),
                  ],
                );
              }),

              Builder(builder: (context) {
                var specificClasses = _schedules.where((s) => s['dayOfWeek'] == 0).toList();
                if (specificClasses.isEmpty) return const SizedBox();
                specificClasses.sort((a, b) => (a['specificDate'] as String).compareTo(b['specificDate'] as String));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 25, bottom: 10),
                      child: Text("Lịch Đặc Biệt (Học Bù / Thi)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ),
                    ...specificClasses.map((item) {
                      String displayDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(item['specificDate']));
                      return _buildScheduleCard(item, extraInfo: "Ngày: $displayDate");
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> item, {String? extraInfo}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: Color(item['colorCode'] as int), width: 5)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: ListTile(
        title: Text(item['subjectName'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phòng: ${item['room']}  •  GV: ${item['teacher']}"),
            if (extraInfo != null) Text(extraInfo, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item['startTime'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            Text(item['endTime'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        onLongPress: () async {
          await DatabaseHelper().deleteSchedule(item['id']);
          _loadData();
        },
      ),
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
          _subjects.isEmpty ? const Center(child: Text("Chưa có môn học nào.")) : ListView.builder(
            padding: const EdgeInsets.all(20), itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final sub = _subjects[index];
              return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(
                leading: CircleAvatar(backgroundColor: Color(sub['colorCode'] as int), radius: 15),
                title: Text(sub['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("GV: ${sub['teacherName']}"),
              ),
              );
            },
          ),
          _buildScheduleTab(),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tabController.index == 0 ? _showAddSubjectBottomSheet : _showAddScheduleBottomSheet,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_tabController.index == 0 ? "Thêm Môn" : "Thêm Lịch", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}