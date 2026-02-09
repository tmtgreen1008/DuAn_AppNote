// File: lib/data/seed_data.dart
import 'package:intl/intl.dart';

class SeedData {
  // Ngày hôm nay
  static final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // 1. User
  static final Map<String, dynamic> user = {'id': 'u1', 'username': 'student', 'fullName': 'Sinh Viên'};

  // 2. Danh mục (Categories)
  static final List<Map<String, dynamic>> categories = [
    {'id': 'c_school', 'name': 'Trường lớp', 'colorCode': 0xFF2196F3}, // Xanh dương
    {'id': 'c_work', 'name': 'Freelance', 'colorCode': 0xFFFF9800},   // Cam
    {'id': 'c_health', 'name': 'Sức khỏe', 'colorCode': 0xFF4CAF50},  // Xanh lá
    {'id': 'c_social', 'name': 'Xã hội', 'colorCode': 0xFF9C27B0},    // Tím
    {'id': 'c_exam', 'name': 'Thi cử', 'colorCode': 0xFFF44336},      // Đỏ
  ];

  // 3. Môn học
  static final List<Map<String, dynamic>> subjects = [
    {'id': 's_flutter', 'planId': 'p1', 'name': 'Lập trình Flutter', 'teacherName': 'Thầy Dũng', 'credit': 3, 'colorCode': 0xFF2196F3},
    {'id': 's_english', 'planId': 'p1', 'name': 'Tiếng Anh CN', 'teacherName': 'Ms. Sarah', 'credit': 2, 'colorCode': 0xFFFF9800},
    {'id': 's_backend', 'planId': 'p1', 'name': 'NodeJS Backend', 'teacherName': 'Cô Lan', 'credit': 3, 'colorCode': 0xFF009688},
  ];

  // 4. Bảng điểm (Đã thêm dữ liệu)
  static final List<Map<String, dynamic>> scores = [
    {'id': 'sc1', 'subjectId': 's_flutter', 'type': 'Giữa kỳ', 'scoreValue': 9.5},
    {'id': 'sc2', 'subjectId': 's_english', 'type': 'Speaking', 'scoreValue': 8.5},
    {'id': 'sc3', 'subjectId': 's_backend', 'type': 'Đồ án', 'scoreValue': 9.0},
  ];

  // 5. Định nghĩa công việc (Task Definitions)
  static final List<Map<String, dynamic>> taskDefs = [
    // Trường lớp
    {'id': 'td1', 'planId': 'p1', 'categoryId': 'c_school', 'subjectId': 's_flutter', 'title': 'Làm bài tập UI/UX', 'priority': 3},
    {'id': 'td2', 'planId': 'p1', 'categoryId': 'c_school', 'subjectId': 's_backend', 'title': 'Cấu hình Server', 'priority': 2},
    // Freelance
    {'id': 'td3', 'planId': null, 'categoryId': 'c_work', 'subjectId': null, 'title': 'Fix lỗi giao diện Shopee', 'priority': 3},
    {'id': 'td4', 'planId': null, 'categoryId': 'c_work', 'subjectId': null, 'title': 'Gửi báo cáo khách hàng', 'priority': 2},
    // Sức khỏe
    {'id': 'td5', 'planId': null, 'categoryId': 'c_health', 'subjectId': null, 'title': 'Chạy bộ 3km', 'priority': 1},
    // Thi cử
    {'id': 'td6', 'planId': null, 'categoryId': 'c_exam', 'subjectId': 's_english', 'title': 'Ôn từ vựng Unit 5', 'priority': 3},
  ];

  // 6. Công việc CỤ THỂ HÔM NAY (Instances)
  static final List<Map<String, dynamic>> instancesToday = [
    {'id': 'ti1', 'taskDefId': 'td1', 'date': today, 'isCompleted': 0}, // Bài tập UI
    {'id': 'ti3', 'taskDefId': 'td3', 'date': today, 'isCompleted': 0}, // Fix lỗi Shopee
    {'id': 'ti5', 'taskDefId': 'td5', 'date': today, 'isCompleted': 1}, // Chạy bộ (Đã xong)
    {'id': 'ti6', 'taskDefId': 'td6', 'date': today, 'isCompleted': 0}, // Ôn thi
  ];

  // Các bảng phụ để tránh lỗi
  static final List<Map<String, dynamic>> plans = [{'id': 'p1', 'title': 'HK1', 'startDate': '2024-01', 'endDate': '2024-06', 'status': 'active'}];
  static final List<Map<String, dynamic>> cycles = [{'id': 'cy1', 'cycleName': 'Daily', 'frequencyType': 'daily', 'daysOfWeek': null}];
  static final List<Map<String, dynamic>> notifications = [{'id': 'n1', 'instanceId': 'ti1', 'remindAt': '08:00'}];
  static final List<Map<String, dynamic>> timetable = [];
}