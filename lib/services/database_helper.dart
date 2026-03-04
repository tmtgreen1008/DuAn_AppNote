// File: lib/services/database_helper.dart
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../dataa/seed_data.dart';
import '../models/student_models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // [QUAN TRỌNG] Đổi tên DB thành v300 để tạo bảng mới có cột description và bảng subtasks
    String path = join(await getDatabasesPath(), 'student_planner_v303.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createPhysicalDB,
    );
  }

  Future<void> _createPhysicalDB(Database db, int version) async {
    await db.execute('CREATE TABLE users (id TEXT PRIMARY KEY, username TEXT, password TEXT, fullName TEXT)');
    await db.execute('CREATE TABLE user_settings (userId TEXT PRIMARY KEY, themeMode TEXT, language TEXT)');
    await db.execute('CREATE TABLE plans (id TEXT PRIMARY KEY, title TEXT, startDate TEXT, endDate TEXT, status TEXT)');
    await db.execute('CREATE TABLE categories (id TEXT PRIMARY KEY, name TEXT, colorCode INTEGER)');
    await db.execute('CREATE TABLE cycles (id TEXT PRIMARY KEY, cycleName TEXT, frequencyType TEXT, daysOfWeek TEXT)');

    await db.execute('''
      CREATE TABLE subjects (
        id TEXT PRIMARY KEY, planId TEXT, name TEXT, teacherName TEXT, credit INTEGER, colorCode INTEGER,
        FOREIGN KEY (planId) REFERENCES plans(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE scores (
        id TEXT PRIMARY KEY, subjectId TEXT, type TEXT, scoreValue REAL,
        FOREIGN KEY (subjectId) REFERENCES subjects(id)
      )
    ''');

    // [CẬP NHẬT] Thêm cột description vào bảng tasks_definition
    await db.execute('''
      CREATE TABLE tasks_definition (
        id TEXT PRIMARY KEY, planId TEXT, categoryId TEXT, cycleId TEXT, subjectId TEXT, title TEXT, 
        description TEXT, priority INTEGER,
        FOREIGN KEY (subjectId) REFERENCES subjects(id),
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');

    await db.execute('CREATE TABLE daily_plans (date TEXT PRIMARY KEY, userId TEXT, dailyNote TEXT)');
    await db.execute('''
      CREATE TABLE task_instances (
        id TEXT PRIMARY KEY, taskDefId TEXT, date TEXT, isCompleted INTEGER,
        FOREIGN KEY (taskDefId) REFERENCES tasks_definition(id),
        FOREIGN KEY (date) REFERENCES daily_plans(date)
      )
    ''');

    await db.execute('CREATE TABLE notifications (id TEXT PRIMARY KEY, instanceId TEXT, remindAt TEXT)');

    // [MỚI] Tạo bảng Subtasks
    await db.execute('CREATE TABLE subtasks (id TEXT PRIMARY KEY, instanceId TEXT, title TEXT, isCompleted INTEGER)');
    await db.execute('''
      CREATE TABLE timetable (
        id TEXT PRIMARY KEY, 
        planId TEXT,  -- Cột mới để phân biệt học kỳ
        subjectName TEXT, room TEXT, teacher TEXT, startTime TEXT, endTime TEXT, dayOfWeek INTEGER, colorCode INTEGER
      )
    ''');
    await _seedFullData(db);
  }

  Future<void> _seedFullData(Database db) async {
    final batch = db.batch();
    batch.insert('users', SeedData.user);
    for (var i in SeedData.plans) batch.insert('plans', i);
    for (var i in SeedData.categories) batch.insert('categories', i);
    for (var i in SeedData.cycles) batch.insert('cycles', i);
    for (var i in SeedData.subjects) batch.insert('subjects', i);
    for (var i in SeedData.scores) batch.insert('scores', i);
    for (var i in SeedData.taskDefs) batch.insert('tasks_definition', i);
    batch.insert('daily_plans', {'date': SeedData.today, 'userId': 'u01', 'dailyNote': 'Demo App'});
    for (var i in SeedData.instancesToday) batch.insert('task_instances', i);
    for (var i in SeedData.notifications) batch.insert('notifications', i);
    for (var i in SeedData.timetable) batch.insert('timetable', i);

    // [MỚI] Nạp subtask mẫu
    for (var i in SeedData.subtasks) batch.insert('subtasks', i);

    await batch.commit(noResult: true);
  }

  // --- CÁC HÀM GET CŨ (GIỮ NGUYÊN) ---
  Future<List<Score>> getScores() async {
    final db = await database;
    final res = await db.rawQuery('SELECT sc.scoreValue, sc.type, s.name FROM scores sc JOIN subjects s ON sc.subjectId = s.id');
    return res.map((e) => Score(subjectName: e['name'] as String, scoreValue: e['scoreValue'] as double, type: e['type'] as String)).toList();
  }

  Future<List<ScheduleItem>> getScheduleByDay(int dayOfWeek, String planId) async {
    final db = await database;
    final List<Map<String, dynamic>> res;

    if (dayOfWeek == -1) {
      // Lấy tất cả các môn trong học kỳ đó
      res = await db.query('timetable', where: 'planId = ?', whereArgs: [planId]);
    } else {
      // Lấy theo thứ cụ thể
      res = await db.query('timetable',
          where: 'dayOfWeek = ? AND planId = ?',
          whereArgs: [dayOfWeek, planId]);
    }
    return res.map((e) => ScheduleItem.fromMap(e)).toList();
  }

  // [MỚI] Hàm lấy danh sách các Học kỳ
  Future<List<Map<String, dynamic>>> getAllPlans() async {
    final db = await database;
    return await db.query('plans', orderBy: 'startDate DESC'); // Mới nhất lên đầu
  }

  Future<List<TaskItem>> getTasksForToday() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT ti.id, ti.date, ti.isCompleted, td.title, s.name as subjectName, 
             s.colorCode as subjectColor, c.colorCode as categoryColor, n.remindAt
      FROM task_instances ti
      JOIN tasks_definition td ON ti.taskDefId = td.id
      LEFT JOIN subjects s ON td.subjectId = s.id
      JOIN categories c ON td.categoryId = c.id
      LEFT JOIN notifications n ON n.instanceId = ti.id
    ''');
    return res.map((e) {
      var map = Map<String, dynamic>.from(e);
      map['colorCode'] = e['subjectColor'] ?? e['categoryColor'];
      return TaskItem.fromMap(map);
    }).toList();
  }

  Future<List<TaskItem>> getTasksByCategory(String categoryId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT td.id as id, td.title, c.colorCode, s.name as subjectName
      FROM tasks_definition td
      JOIN categories c ON td.categoryId = c.id
      LEFT JOIN subjects s ON td.subjectId = s.id
      WHERE td.categoryId = ?
    ''', [categoryId]);

    return res.map((e) => TaskItem(
      id: e['id'] as String, title: e['title'] as String, date: 'Danh sách tổng', isCompleted: false,
      colorCode: e['colorCode'] as int, time: '', subjectName: e['subjectName'] as String?,
    )).toList();
  }

  Future<void> toggleTask(String id, bool status) async {
    final db = await database;
    await db.update('task_instances', {'isCompleted': status ? 0 : 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('task_instances', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addTask(String title, String date, String time, String categoryId) async {
    final db = await database;
    String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('tasks_definition', {
      'id': 'td_$uniqueId', 'planId': 'p1', 'categoryId': categoryId, 'subjectId': null, 'title': title, 'priority': 1,
      'description': '' // Mặc định rỗng
    });
    await db.insert('task_instances', {'id': 'ti_$uniqueId', 'taskDefId': 'td_$uniqueId', 'date': date, 'isCompleted': 0});
    await db.insert('notifications', {'id': 'n_$uniqueId', 'instanceId': 'ti_$uniqueId', 'remindAt': time});
  }

  // --- [MỚI] CÁC HÀM XỬ LÝ CHI TIẾT & SUBTASK ---

  // 1. Lấy chi tiết Task (kèm Description)
  Future<Map<String, dynamic>> getTaskDetail(String instanceId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT ti.id, td.title, td.description, c.name as categoryName, c.colorCode, ti.date, n.remindAt
      FROM task_instances ti
      JOIN tasks_definition td ON ti.taskDefId = td.id
      JOIN categories c ON td.categoryId = c.id
      LEFT JOIN notifications n ON n.instanceId = ti.id
      WHERE ti.id = ?
    ''', [instanceId]);
    return res.isNotEmpty ? res.first : {};
  }

  // 2. Lấy danh sách Subtasks
  Future<List<Map<String, dynamic>>> getSubtasks(String instanceId) async {
    final db = await database;
    return await db.query('subtasks', where: 'instanceId = ?', whereArgs: [instanceId]);
  }

  // 3. Thêm Subtask
  Future<void> addSubtask(String instanceId, String title) async {
    final db = await database;
    String id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('subtasks', {
      'id': id, 'instanceId': instanceId, 'title': title, 'isCompleted': 0
    });
  }

  // 4. Toggle Subtask
  Future<void> toggleSubtask(String id, bool val) async {
    final db = await database;
    await db.update('subtasks', {'isCompleted': val ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  // 5. Xóa Subtask
  Future<void> deleteSubtask(String id) async {
    final db = await database;
    await db.delete('subtasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getPlanByDate(DateTime date) async {
    final db = await database;
    String dateStr = DateFormat('yyyy-MM-dd').format(date);

    final res = await db.rawQuery('''
      SELECT * FROM plans 
      WHERE date(startDate) <= date(?) AND date(endDate) >= date(?)
      LIMIT 1
    ''', [dateStr, dateStr]);

    if (res.isNotEmpty) return res.first;
    return null;
  }

  // 2. Hàm gọi (Nơi có thể bạn đang bị lỗi)
  Future<List<ScheduleItem>> getClassesForDate(DateTime date) async {
    // B1: Tìm học kỳ
    final plan = await getPlanByDate(date);

    if (plan == null) {
      return [];
    }

    // B2: Tính thứ
    int flutterWeekday = date.weekday;
    int dbDayOfWeek = flutterWeekday == 7 ? 8 : flutterWeekday + 1;

    // B3: Gọi hàm (SỬA LỖI TẠI ĐÂY)
    // Cũ (Sai): return await getScheduleByDay(dbDayOfWeek);
    // Mới (Đúng): Truyền thêm plan['id'] vào
    return await getScheduleByDay(dbDayOfWeek, plan['id']);
  }
  Future<int> deleteSchedule(String id) async {
    final db = await database;
    return await db.delete(
        'timetable',
        where: 'id = ?',
        whereArgs: [id]
    );
  }
  Future<bool> registerUser(String username, String password, String fullName) async {
    final db = await database;

    // Kiểm tra xem username đã tồn tại chưa
    final check = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (check.isNotEmpty) return false; // Tên đăng nhập đã bị trùng

    // Thêm user mới vào DB
    await db.insert('users', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(), // Tạo ID ngẫu nhiên
      'username': username,
      'password': password,
      'fullName': fullName,
    });
    return true; // Đăng ký thành công
  }

  // 2. Đăng nhập
  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final db = await database;

    // Tìm user có đúng username và password
    final res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (res.isNotEmpty) return res.first; // Trả về thông tin user
    return null; // Sai tài khoản hoặc mật khẩu
  }
  // Thêm điểm mới hoặc cập nhật nếu đã tồn tại
  Future<void> insertOrUpdateScore(String subjectId, String type, double value) async {
    final db = await database;
    // Kiểm tra xem loại điểm này của môn này đã có chưa
    final existing = await db.query('scores',
        where: 'subjectId = ? AND type = ?',
        whereArgs: [subjectId, type]);

    if (existing.isNotEmpty) {
      await db.update('scores', {'scoreValue': value},
          where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      await db.insert('scores', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'subjectId': subjectId,
        'type': type,
        'scoreValue': value,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getSubjectsForActivePlan() async {
    final db = await database;

    // Tìm học kỳ hiện tại
    String today = DateTime.now().toIso8601String().split('T')[0];
    final planRes = await db.rawQuery('''
      SELECT * FROM plans 
      WHERE date(startDate) <= date(?) AND date(endDate) >= date(?)
      LIMIT 1
    ''', [today, today]);

    if (planRes.isEmpty) return [];

    String planId = planRes.first['id'] as String;

    // Lấy các môn học thuộc học kỳ này
    return await db.query('subjects', where: 'planId = ?', whereArgs: [planId]);
  }
  Future<Map<String, dynamic>> getTaskStatistics() async {
    try {
      final db = await database;

      // 1. Tổng quan toàn bộ công việc
      final totalRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM task_instances');
      int total = (totalRes.isNotEmpty ? totalRes.first['cnt'] as int? : 0) ?? 0;

      final compRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM task_instances WHERE isCompleted = 1');
      int completed = (compRes.isNotEmpty ? compRes.first['cnt'] as int? : 0) ?? 0;

      // 2. Thống kê chi tiết theo từng danh mục
      // [QUAN TRỌNG] Đã sửa đúng tên bảng thành 'tasks_definition'
      final catStats = await db.rawQuery('''
        SELECT c.name, c.colorCode, COUNT(ti.id) as totalTasks,
               IFNULL(SUM(CASE WHEN ti.isCompleted = 1 THEN 1 ELSE 0 END), 0) as completedTasks
        FROM categories c
        LEFT JOIN tasks_definition td ON c.id = td.categoryId 
        LEFT JOIN task_instances ti ON td.id = ti.taskDefId
        GROUP BY c.id
        HAVING totalTasks > 0
        ORDER BY totalTasks DESC
      ''');

      return {
        'total': total,
        'completed': completed,
        'categories': catStats,
      };
    } catch (e) {
      print("❌ LỖI TRUY VẤN THỐNG KÊ: $e");
      return {
        'total': 0,
        'completed': 0,
        'categories': [],
      };
    }
  }
}