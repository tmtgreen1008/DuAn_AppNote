// lib/services/auto_schedule_service.dart
import 'package:intl/intl.dart';
import '../models/student_models.dart';
import '../services/database_helper.dart';
class AutoScheduleService {
  final dbHelper = DatabaseHelper();

  // Chuyển "HH:mm" thành phút
  int _tToMin(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  // Chuyển phút thành "HH:mm"
  String _minToT(int m) => "${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}";

  Future<void> smartSchedule(List<String> taskTitles, DateTime date) async {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);

    // 1. Lấy dữ liệu thực tế của ngày hôm đó để tránh trùng lịch
    final classes = await dbHelper.getClassesForSpecificDay(date);
    final existingTasks = await dbHelper.getTasksByDate(date);

    // 2. Định nghĩa khung giờ rảnh (Ví dụ: 07:00 - 22:00)
    int start = _tToMin("07:00");
    int end = _tToMin("22:00");
    int step = 30; // Mỗi công việc nhỏ mặc định 30 phút

    // Đánh dấu các khối 30p đã bận
    Map<int, bool> busySlots = {};
    for (int i = start; i < end; i += step) busySlots[i] = false;

    // Đánh dấu bận từ Lịch học
    for (var c in classes) {
      int s = _tToMin(c['startTime']);
      int e = _tToMin(c['endTime']);
      busySlots.keys.where((k) => k >= s && k < e).forEach((k) => busySlots[k] = true);
    }

    // Đánh dấu bận từ Task đã có
    for (var t in existingTasks) {
      int s = _tToMin(t.time);
      busySlots[s] = true;
    }

    // 3. Lấp đầy các ghi chú mới vào chỗ trống
    int taskIdx = 0;
    for (int time in busySlots.keys) {
      if (!busySlots[time]! && taskIdx < taskTitles.length) {
        // Lưu trực tiếp vào Database
        await dbHelper.insertTask(
          title: taskTitles[taskIdx],
          time: _minToT(time),
          categoryId: 1, // Mặc định danh mục đầu tiên
          date: dateStr,
        );
        taskIdx++;
      }
    }
  }
}