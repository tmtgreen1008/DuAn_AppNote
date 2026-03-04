import 'package:flutter/material.dart';
import '../models/student_models.dart';
import '../services/database_helper.dart';

class ScheduleDetailScreen extends StatelessWidget {
  final ScheduleItem item; // Nhận dữ liệu môn học từ màn hình Lịch

  const ScheduleDetailScreen({super.key, required this.item});

  // Hàm xử lý xóa lịch học
  void _deleteSchedule(BuildContext context) async {
    // 1. Hiện hộp thoại hỏi cho chắc
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa lịch học?"),
        content: Text("Bạn có chắc muốn xóa môn '${item.subjectName}' không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    // 2. Nếu đồng ý xóa
    if (confirm == true) {
      await DatabaseHelper().deleteSchedule(item.id);

      if (context.mounted) {
        // Trả về 'true' để màn hình Lịch biết mà load lại dữ liệu
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa môn học thành công!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy màu chủ đạo của môn học
    Color themeColor = Color(item.colorCode);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chi tiết môn học", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black, onPressed: () => Navigator.pop(context, false)),
        actions: [
          // NÚT XÓA MÔN HỌC
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
            tooltip: "Xóa môn học này",
            onPressed: () => _deleteSchedule(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER: TÊN MÔN HỌC TO ĐẸP
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: themeColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]
                    ),
                    child: Icon(Icons.class_, size: 40, color: themeColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item.subjectName,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: themeColor),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(20)
                    ),
                    child: const Text("Chính thức", style: TextStyle(color: Colors.white, fontSize: 12)),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text("Thông tin chi tiết", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // 2. CÁC DÒNG THÔNG TIN
            _buildInfoTile(Icons.access_time_filled, "Thời gian", "${item.startTime} - ${item.endTime}", Colors.blue),
            _buildInfoTile(Icons.location_on, "Phòng học", item.room, Colors.orange),
            _buildInfoTile(Icons.person, "Giảng viên", item.teacher, Colors.green),

            const SizedBox(height: 40),

            // 3. NÚT QUAY LẠI
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Quay lại", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget con để vẽ từng dòng thông tin
  Widget _buildInfoTile(IconData icon, String title, String value, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }
}