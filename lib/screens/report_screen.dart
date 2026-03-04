// File: lib/screens/report_screen.dart
import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  int _totalTasks = 0;
  int _completedTasks = 0;
  List<Map<String, dynamic>> _categoryStats = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    try {
      final stats = await DatabaseHelper().getTaskStatistics();
      if (mounted) {
        setState(() {
          _totalTasks = stats['total'];
          _completedTasks = stats['completed'];
          _categoryStats = List<Map<String, dynamic>>.from(stats['categories']);
          _isLoading = false; // Tắt loading khi thành công
        });
      }
    } catch (e) {
      print("❌ LỖI LOAD REPORT: $e");
      if (mounted) {
        setState(() => _isLoading = false); // Tắt loading kể cả khi lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Có lỗi xảy ra khi tải dữ liệu!"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tính phần trăm tổng quan
    double overallProgress = _totalTasks == 0 ? 0 : _completedTasks / _totalTasks;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Báo cáo Thống kê", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TỔNG QUAN (VÒNG TRÒN)
            const Text("Tổng quan công việc", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: overallProgress,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[200],
                          color: Colors.blue,
                        ),
                        Center(
                          child: Text(
                            "${(overallProgress * 100).toInt()}%",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow("Tổng số:", _totalTasks.toString(), Colors.black),
                        const SizedBox(height: 10),
                        _buildStatRow("Đã xong:", _completedTasks.toString(), Colors.green),
                        const SizedBox(height: 10),
                        _buildStatRow("Còn lại:", (_totalTasks - _completedTasks).toString(), Colors.orange),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 35),

            // 2. THỐNG KÊ THEO DANH MỤC
            const Text("Tiến độ theo danh mục", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            _categoryStats.isEmpty
                ? const Center(child: Text("Chưa có dữ liệu danh mục", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categoryStats.length,
              itemBuilder: (context, index) {
                final cat = _categoryStats[index];
                final name = cat['name'];
                final color = Color(cat['colorCode']);
                final int total = cat['totalTasks'];
                final int completed = cat['completedTasks'];
                final double progress = total == 0 ? 0 : completed / total;

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                          Text("$completed/$total", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: color.withOpacity(0.2),
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: valueColor)),
      ],
    );
  }
}