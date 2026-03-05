// File: lib/screens/plan_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import 'plan_detail_screen.dart';
class PlanListScreen extends StatefulWidget {
  const PlanListScreen({super.key});

  @override
  State<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends State<PlanListScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  void _loadPlans() async {
    final data = await DatabaseHelper().getAllPlans();
    if (mounted) {
      setState(() {
        _plans = data;
        _isLoading = false;
      });
    }
  }

  // Bảng thêm Học kỳ mới
  void _showAddPlanBottomSheet() {
    final titleController = TextEditingController();
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20, right: 20, top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Thêm Học Kỳ Mới", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 20),

                    // Tên học kỳ
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Tên Học kỳ (VD: Học kỳ 2 - 2026)",
                        prefixIcon: const Icon(Icons.school),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Chọn ngày bắt đầu
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                      leading: const Icon(Icons.date_range, color: Colors.blue),
                      title: Text(selectedStartDate == null ? "Chọn ngày bắt đầu" : "Bắt đầu: ${DateFormat('dd/MM/yyyy').format(selectedStartDate!)}"),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030),
                        );
                        if (picked != null) setModalState(() => selectedStartDate = picked);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Chọn ngày kết thúc
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                      leading: const Icon(Icons.event_available, color: Colors.orange),
                      title: Text(selectedEndDate == null ? "Chọn ngày kết thúc" : "Kết thúc: ${DateFormat('dd/MM/yyyy').format(selectedEndDate!)}"),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context, initialDate: selectedStartDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030),
                        );
                        if (picked != null) setModalState(() => selectedEndDate = picked);
                      },
                    ),
                    const SizedBox(height: 25),

                    // Nút Lưu
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (titleController.text.isNotEmpty && selectedStartDate != null && selectedEndDate != null) {
                            if (selectedEndDate!.isBefore(selectedStartDate!)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ngày kết thúc phải sau ngày bắt đầu!"), backgroundColor: Colors.red));
                              return;
                            }
                            await DatabaseHelper().addPlan(
                              titleController.text.trim(),
                              DateFormat('yyyy-MM-dd').format(selectedStartDate!),
                              DateFormat('yyyy-MM-dd').format(selectedEndDate!),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadPlans(); // Tải lại danh sách
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đủ thông tin!"), backgroundColor: Colors.orange));
                          }
                        },
                        child: const Text("Lưu Học Kỳ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Quản lý Học kỳ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlanBottomSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
          ? const Center(child: Text("Chưa có học kỳ nào. Hãy nhấn + để thêm."))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];
          // Format lại ngày để hiển thị đẹp hơn
          String start = DateFormat('dd/MM/yyyy').format(DateTime.parse(plan['startDate']));
          String end = DateFormat('dd/MM/yyyy').format(DateTime.parse(plan['endDate']));
          bool isActive = plan['status'] == 'active';

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isActive ? Colors.blue.withOpacity(0.5) : Colors.transparent, width: 2),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PlanDetailScreen(
                          planId: plan['id'],
                          planTitle: plan['title']
                      )
                  ),
                );
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              title: Text(plan['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text("Từ: $start  đến  $end", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: isActive ? Colors.green[50] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text(
                        isActive ? "Đang diễn ra" : "Đã kết thúc",
                        style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)
                    ),
                  )
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  await DatabaseHelper().deletePlan(plan['id']);
                  _loadPlans();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}