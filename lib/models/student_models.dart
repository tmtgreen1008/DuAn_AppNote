// File: lib/models/student_models.dart
class TaskItem {
  final String id;
  final String title;
  final String date;
  final bool isCompleted;
  final String? subjectName;
  final int colorCode;
  final String time;

  TaskItem({
    required this.id,
    required this.title,
    required this.date,
    required this.isCompleted,
    this.subjectName,
    required this.colorCode,
    required this.time,
  });

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'],
      title: map['title'],
      date: map['date'],
      isCompleted: map['isCompleted'] == 1,
      subjectName: map['subjectName'],
      colorCode: map['subjectColor'] ?? map['categoryColor'] ?? 0xFF9E9E9E,
      time: map['remindAt'] ?? '08:00',
    );
  }
}

class Score {
  final String subjectName;
  final double scoreValue;
  final String type;

  Score({required this.subjectName, required this.scoreValue, required this.type});
}
class ScheduleItem {
  final String id;
  final String subjectName;
  final String room;
  final String teacher;
  final String startTime;
  final String endTime;
  final int dayOfWeek; // 2 = Thứ 2, 3 = Thứ 3... 8 = Chủ Nhật
  final int colorCode;

  ScheduleItem({
    required this.id,
    required this.subjectName,
    required this.room,
    required this.teacher,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    required this.colorCode,
  });

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'],
      subjectName: map['subjectName'],
      room: map['room'],
      teacher: map['teacher'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      dayOfWeek: map['dayOfWeek'],
      colorCode: map['colorCode'],
    );
  }
}