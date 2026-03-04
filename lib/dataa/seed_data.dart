// File: lib/data/seed_data.dart
import 'package:intl/intl.dart';

class SeedData {
  // Ngày hôm nay
  static final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // 1. User
// Trong class SeedData
  static final Map<String, dynamic> user = {
    'id': 'u1',
    'username': 'student',
    'password': '123', // <--- THÊM DÒNG NÀY
    'fullName': 'Sinh Viên'
  };
  // 2. Danh mục
  static final List<Map<String, dynamic>> categories = [
    {'id': 'c_school', 'name': 'Trường lớp', 'colorCode': 0xFF2196F3},
    {'id': 'c_work', 'name': 'Freelance', 'colorCode': 0xFFFF9800},
    {'id': 'c_health', 'name': 'Sức khỏe', 'colorCode': 0xFF4CAF50},
    {'id': 'c_social', 'name': 'Xã hội', 'colorCode': 0xFF9C27B0},
    {'id': 'c_exam', 'name': 'Thi cử', 'colorCode': 0xFFF44336},
  ];

  // 3. HỌC KỲ (PLANS)
  static final List<Map<String, dynamic>> plans = [
    {'id': 'p1', 'title': 'Học kỳ 1 (2025)', 'startDate': '2025-08-15', 'endDate': '2025-12-31', 'status': 'completed'},
    // Học kỳ 2 bao trùm toàn bộ năm 2026 (Tháng 1 -> Tháng 6)
    {'id': 'p2', 'title': 'Học kỳ 2 (2026)', 'startDate': '2026-01-15', 'endDate': '2026-06-30', 'status': 'active'},
  ];

  // 4. MÔN HỌC (Đầy đủ cho HK2)
  static final List<Map<String, dynamic>> subjects = [
    {'id': 's_flutter', 'planId': 'p1', 'name': 'Lập trình Flutter', 'teacherName': 'Thầy Dũng', 'credit': 3, 'colorCode': 0xFF2196F3},
    {'id': 's_english', 'planId': 'p1', 'name': 'Tiếng Anh CN', 'teacherName': 'Ms. Sarah', 'credit': 2, 'colorCode': 0xFFFF9800},
    {'id': 's_backend', 'planId': 'p1', 'name': 'NodeJS Backend', 'teacherName': 'Cô Lan', 'credit': 3, 'colorCode': 0xFF009688},
    // Các môn HK2
    {'id': 's_ai', 'planId': 'p2', 'name': 'Trí tuệ nhân tạo', 'teacherName': 'TS. Hùng', 'credit': 3, 'colorCode': 0xFFFF5722},
    {'id': 's_mobile_adv', 'planId': 'p2', 'name': 'Lập trình Mobile NC', 'teacherName': 'Thầy Dũng', 'credit': 3, 'colorCode': 0xFF2196F3},
    {'id': 's_project', 'planId': 'p2', 'name': 'Đồ án Tốt nghiệp', 'teacherName': 'GVHD', 'credit': 10, 'colorCode': 0xFFE91E63},
    {'id': 's_intern', 'planId': 'p2', 'name': 'Thực tập', 'teacherName': 'Mentor', 'credit': 4, 'colorCode': 0xFF4CAF50},
  ];

  // 5. BẢNG ĐIỂM
  static final List<Map<String, dynamic>> scores = [
    {'id': 'sc1', 'subjectId': 's_flutter', 'type': 'Giữa kỳ', 'scoreValue': 9.5},
  ];

  // 6. TASK
  static final List<Map<String, dynamic>> taskDefs = [
    {'id': 'td1', 'planId': 'p1', 'categoryId': 'c_school', 'subjectId': 's_flutter', 'title': 'Làm bài tập UI/UX', 'priority': 3, 'description': 'Hoàn thành UI Login.'},
  ];

  static final List<Map<String, dynamic>> instancesToday = [
    {'id': 'ti1', 'taskDefId': 'td1', 'date': today, 'isCompleted': 0},
  ];

  // 7. LỊCH HỌC (TIMETABLE) - ĐÃ CẬP NHẬT FULL TUẦN CHO HK2
  // Logic: Chỉ cần khai báo 1 tuần mẫu, App sẽ tự hiển thị cho cả tháng 2, 3, 4...
  static final List<Map<String, dynamic>> timetable = [
    // --- HK1 ---
    {'id': 't2_1', 'planId': 'p1', 'subjectName': 'Flutter', 'room': 'Lab 3', 'teacher': 'Thầy Dũng', 'startTime': '07:00', 'endTime': '09:30', 'dayOfWeek': 2, 'colorCode': 0xFF2196F3},

    // --- HK2 (Full tuần để test) ---
    // Thứ 2: AI
    {'id': 'hk2_t2', 'planId': 'p2', 'subjectName': 'Trí tuệ nhân tạo', 'room': 'P.505', 'teacher': 'TS. Hùng', 'startTime': '07:00', 'endTime': '09:30', 'dayOfWeek': 2, 'colorCode': 0xFFFF5722},

    // Thứ 3: Đồ án (Sáng)
    {'id': 'hk2_t3', 'planId': 'p2', 'subjectName': 'Đồ án Tốt nghiệp', 'room': 'Văn phòng', 'teacher': 'GVHD', 'startTime': '08:00', 'endTime': '11:00', 'dayOfWeek': 3, 'colorCode': 0xFFE91E63},

    // Thứ 4: Mobile NC (Chiều)
    {'id': 'hk2_t4', 'planId': 'p2', 'subjectName': 'Lập trình Mobile NC', 'room': 'Lab 2', 'teacher': 'Thầy Dũng', 'startTime': '13:00', 'endTime': '15:30', 'dayOfWeek': 4, 'colorCode': 0xFF2196F3},

    // Thứ 5: Đồ án (Chiều - Lặp lại để test)
    {'id': 'hk2_t5', 'planId': 'p2', 'subjectName': 'Họp nhóm Đồ án', 'room': 'Online Meet', 'teacher': 'GVHD', 'startTime': '14:00', 'endTime': '16:00', 'dayOfWeek': 5, 'colorCode': 0xFFE91E63},

    // Thứ 6: Thực tập (Sáng)
    {'id': 'hk2_t6', 'planId': 'p2', 'subjectName': 'Thực tập', 'room': 'Cty FPT', 'teacher': 'Mentor', 'startTime': '08:00', 'endTime': '11:30', 'dayOfWeek': 6, 'colorCode': 0xFF4CAF50},

    // Thứ 7: Tiếng Anh (Tối)
    {'id': 'hk2_t7', 'planId': 'p2', 'subjectName': 'Tiếng Anh Giao tiếp', 'room': 'Trung tâm', 'teacher': 'Ms. Sarah', 'startTime': '18:00', 'endTime': '20:00', 'dayOfWeek': 7, 'colorCode': 0xFFFF9800},
  ];

  static final List<Map<String, dynamic>> subtasks = [];
  static final List<Map<String, dynamic>> cycles = [];
  static final List<Map<String, dynamic>> notifications = [];
}