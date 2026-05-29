// File: lib/screens/add_task_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../dataa/seed_data.dart'; // Để lấy danh sách Category cho Dropdown

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  // Biến cho Ngày thực hiện & Giờ nhắc
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // [MỚI] Biến cho Hạn chót (Có thể null vì là tùy chọn)
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;

  String _selectedCategoryId = SeedData.categories[0]['id'];

  // Hàm chọn Ngày & Giờ thực hiện
  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // [MỚI] Hàm chọn Ngày & Giờ cho Deadline
  void _pickDeadline() async {
    // 1. Chọn ngày trước
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Deadline không thể ở quá khứ
      lastDate: DateTime(2030),
      helpText: 'CHỌN NGÀY NỘP BÀI',
    );

    if (pickedDate != null) {
      if (!mounted) return;
      // 2. Chọn giờ sau khi đã chọn ngày
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDueTime ?? const TimeOfDay(hour: 23, minute: 59), // Gợi ý mặc định là 23:59
        helpText: 'CHỌN GIỜ NỘP BÀI',
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDueDate = pickedDate;
          _selectedDueTime = pickedTime;
        });
      }
    }
  }

  // [MỚI] Hàm xóa Deadline
  void _clearDeadline() {
    setState(() {
      _selectedDueDate = null;
      _selectedDueTime = null;
    });
  }

  // Hàm lưu công việc
  void _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên công việc!")));
      return;
    }

    // Format dữ liệu Ngày giờ thực hiện
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String timeStr = "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

    // Format dữ liệu Deadline (Nếu có chọn)
    String? dueDateData;
    if (_selectedDueDate != null && _selectedDueTime != null) {
      String dueD = DateFormat('dd/MM/yyyy').format(_selectedDueDate!);
      String dueT = "${_selectedDueTime!.hour.toString().padLeft(2, '0')}:${_selectedDueTime!.minute.toString().padLeft(2, '0')}";
      dueDateData = "$dueT - $dueD"; // Format hiển thị: 23:59 - 16/04/2026
    }

    String? locationData = _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null;

    // Lưu vào DB
    await DatabaseHelper().addTask(
      _titleController.text.trim(),
      dateStr,
      timeStr,
      _selectedCategoryId,
      location: locationData,
      dueDate: dueDateData,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm công việc mới!"), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Thêm công việc mới", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ô NHẬP TÊN
            const Text("Tên công việc", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "Ví dụ: Làm slide báo cáo...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(Icons.edit_note, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 20),

            // 2. CHỌN DANH MỤC
            const Text("Danh mục", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategoryId,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  items: SeedData.categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['id'],
                      child: Row(
                        children: [
                          Icon(Icons.circle, color: Color(cat['colorCode']), size: 14),
                          const SizedBox(width: 12),
                          Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. CHỌN NGÀY & GIỜ THỰC HIỆN
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Ngày thực hiện", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                          decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[100]!)
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Giờ nhắc", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                          decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange[100]!)
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 18, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text("${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // 4. Ô NHẬP ĐỊA ĐIỂM
            const Text("Địa điểm (Tùy chọn)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: "Ví dụ: Phòng họp, Thư viện...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: Icon(Icons.location_on, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),

            // 5. [MỚI] CHỌN DEADLINE BẰNG PICKER
            const Text("Hạn chót / Deadline (Tùy chọn)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedDueDate != null ? Colors.red[300]! : Colors.transparent)
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.red[400]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedDueDate != null && _selectedDueTime != null
                            ? "${_selectedDueTime!.hour.toString().padLeft(2, '0')}:${_selectedDueTime!.minute.toString().padLeft(2, '0')} - ${DateFormat('dd/MM/yyyy').format(_selectedDueDate!)}"
                            : "Nhấn để chọn ngày giờ nộp bài...",
                        style: TextStyle(
                            color: _selectedDueDate != null ? Colors.red[700] : Colors.red[300],
                            fontWeight: _selectedDueDate != null ? FontWeight.bold : FontWeight.normal,
                            fontSize: 15
                        ),
                      ),
                    ),
                    if (_selectedDueDate != null)
                      GestureDetector(
                        onTap: _clearDeadline,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.red[100], shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.red, size: 16),
                        ),
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 6. NÚT LƯU
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _saveTask,
                child: const Text("Tạo công việc", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}