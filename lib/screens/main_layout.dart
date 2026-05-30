// File: lib/screens/main_layout.dart
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'plan_list_screen.dart';
import 'report_screen.dart';
import 'add_task_screen.dart';
import 'brain_dump_screen.dart';

class MainLayout extends StatefulWidget {
  final String fullName; // Thêm biến nhận tên

  const MainLayout({super.key, required this.fullName}); // Yêu cầu truyền tên

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // SỬ DỤNG CHÌA KHÓA ĐỘNG CHO TẤT CẢ CÁC TAB
      // Việc này ép Flutter làm mới giao diện mỗi khi chuyển Tab
      // ========================================================
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Home
          DashboardScreen(
              key: ValueKey('home_$_currentIndex'),
              fullName: widget.fullName
          ),

          // Tab 1: Calendar
          CalendarScreen(
              key: ValueKey('calendar_$_currentIndex')
          ),

          // Tab 2: Học kỳ
          PlanListScreen(
              key: ValueKey('plan_$_currentIndex')
          ),

          // Tab 3: Graph (Báo cáo)
          ReportScreen(
              key: ValueKey('report_$_currentIndex')
          ),
        ],
      ),

      // Nút Nổi ở giữa (FAB)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.purpleAccent,
        elevation: 4,
        onPressed: () async {
          // Khi bấm nút Add (+) sẽ mở màn hình thêm việc
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
          // Ép giao diện làm mới sau khi thêm công việc xong
          setState(() {});
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),

      // Thanh điều hướng bên dưới
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: const Color(0xFF1E1E1E),
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // Nhóm bên trái
              _buildTabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: "Home", index: 0),
              _buildTabItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_month, label: "Calendar", index: 1),

              const SizedBox(width: 48), // Khoảng trống cho nút FAB nổi ở giữa

              // Nhóm bên phải
              _buildTabItem(icon: Icons.folder_special_outlined, activeIcon: Icons.folder_special, label: "Học kỳ", index: 2),
              _buildTabItem(icon: Icons.pie_chart_outline, activeIcon: Icons.pie_chart, label: "Graph", index: 3),
            ],
          ),
        ),
      ),
    );
  }

  // Widget con để vẽ từng nút Tab
  Widget _buildTabItem({required IconData icon, required IconData activeIcon, required String label, required int index}) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? Colors.amber[200] : Colors.grey[500],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.amber[200] : Colors.grey[500],
            ),
          ),
          // Đường gạch dưới nhỏ khi được chọn
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 20,
              color: Colors.amber[200],
            )
        ],
      ),
    );
  }
}