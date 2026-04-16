// lib/screens/brain_dump_screen.dart
import 'package:flutter/material.dart';
import 'auto_schedule_service.dart';

class BrainDumpScreen extends StatefulWidget {
  const BrainDumpScreen({super.key});

  @override
  State<BrainDumpScreen> createState() => _BrainDumpScreenState();
}

class _BrainDumpScreenState extends State<BrainDumpScreen> {
  final _noteController = TextEditingController();
  bool _isProcessing = false;

  void _handleAutoSchedule() async {
    if (_noteController.text.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    // Tách các dòng text thành list
    List<String> titles = _noteController.text
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    // Gọi AI Service để tự tìm giờ rảnh và xếp lịch cho ngày hôm nay
    await AutoScheduleService().smartSchedule(titles, DateTime.now());

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã tự động xếp ${titles.length} việc vào giờ rảnh!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ghi chú nhanh (Brain Dump)", style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _noteController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 16, height: 1.5),
                decoration: const InputDecoration(
                  hintText: "Nhập hoặc dán danh sách việc tại đây...\nVí dụ:\n- Mua sách\n- Gửi email\n- Review code...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleAutoSchedule,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                icon: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_fix_high, color: Colors.white),
                label: const Text("Tự động xếp lịch thông minh", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }

}