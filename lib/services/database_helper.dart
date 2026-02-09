// File: lib/services/database_helper.dart
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
    // ĐỔI TÊN LẦN CUỐI CÙNG Ở ĐÂY:
    String path = join(await getDatabasesPath(), 'student_planner_complete.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        print("⏳ ĐANG KHỞI TẠO DB...");
        await _createPhysicalDB(db, version);
        print("✅ KHỞI TẠO THÀNH CÔNG!");
      },
    );
  }

  Future<void> _createPhysicalDB(Database db, int version) async {
    // 1. Tạo bảng
    await db.execute('CREATE TABLE users (id TEXT PRIMARY KEY, username TEXT, fullName TEXT)');
    await db.execute('CREATE TABLE user_settings (userId TEXT PRIMARY KEY, themeMode TEXT, language TEXT)');
    await db.execute('CREATE TABLE plans (id TEXT PRIMARY KEY, title TEXT, startDate TEXT, endDate TEXT, status TEXT)');
    await db.execute('CREATE TABLE categories (id TEXT PRIMARY KEY, name TEXT, colorCode INTEGER)');

    // [ĐÃ SỬA] Thêm cột daysOfWeek vào đây để khớp với SeedData
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

    await db.execute('''
      CREATE TABLE tasks_definition (
        id TEXT PRIMARY KEY, planId TEXT, categoryId TEXT, cycleId TEXT, subjectId TEXT, title TEXT, priority INTEGER,
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
    await db.execute('CREATE TABLE timetable (id TEXT PRIMARY KEY, subjectName TEXT, room TEXT, teacher TEXT, startTime TEXT, endTime TEXT, dayOfWeek INTEGER, colorCode INTEGER)');

    // 2. Nạp dữ liệu
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

    await batch.commit(noResult: true);
  }

  // CÁC HÀM GET DATA
  // Future<List<TaskItem>> getTasksForToday() async {
  //   final db = await database;
  //   final List<Map<String, dynamic>> result = await db.rawQuery('''
  //     SELECT
  //       ti.id, ti.date, ti.isCompleted,
  //       td.title,
  //       s.name as subjectName, s.colorCode as subjectColor,
  //       c.colorCode as categoryColor,
  //       n.remindAt
  //     FROM task_instances ti
  //     JOIN tasks_definition td ON ti.taskDefId = td.id
  //     LEFT JOIN subjects s ON td.subjectId = s.id
  //     JOIN categories c ON td.categoryId = c.id
  //     LEFT JOIN notifications n ON n.instanceId = ti.id
  //     ORDER BY n.remindAt ASC
  //   ''');
  //
  //   return result.map((row) {
  //     Map<String, dynamic> newRow = Map.from(row);
  //     newRow['colorCode'] = row['subjectColor'] ?? row['categoryColor'];
  //     return TaskItem.fromMap(newRow);
  //   }).toList();
  // }

  Future<List<Score>> getScores() async {
    final db = await database;
    final res = await db.rawQuery('SELECT sc.scoreValue, sc.type, s.name FROM scores sc JOIN subjects s ON sc.subjectId = s.id');
    return res.map((e) => Score(subjectName: e['name'] as String, scoreValue: e['scoreValue'] as double, type: e['type'] as String)).toList();
  }

  Future<void> toggleTask(String id, bool status) async {
    final db = await database;
    await db.update('task_instances', {'isCompleted': status ? 0 : 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ScheduleItem>> getScheduleByDay(int dayOfWeek) async {
    final db = await database;
    final res = await db.query('timetable', where: 'dayOfWeek = ?', whereArgs: [dayOfWeek], orderBy: 'startTime ASC');
    return res.map((e) => ScheduleItem.fromMap(e)).toList();
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

  // [MỚI] Lấy công việc theo Danh Mục
  Future<List<TaskItem>> getTasksByCategory(String categoryId) async {
    final db = await database;
    // Query này tìm tất cả Task Definition thuộc Category đó
    final res = await db.rawQuery('''
      SELECT td.id as id, td.title, c.colorCode, s.name as subjectName
      FROM tasks_definition td
      JOIN categories c ON td.categoryId = c.id
      LEFT JOIN subjects s ON td.subjectId = s.id
      WHERE td.categoryId = ?
    ''', [categoryId]);

    return res.map((e) => TaskItem(
      id: e['id'] as String,
      title: e['title'] as String,
      date: 'Danh sách tổng',
      isCompleted: false,
      colorCode: e['colorCode'] as int,
      time: '',
      subjectName: e['subjectName'] as String?,
    )).toList();
  }
}