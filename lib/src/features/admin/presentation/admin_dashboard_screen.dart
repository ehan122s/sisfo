import 'package:flutter/material.dart';
import 'siswa_screen.dart';
import 'journal_screen.dart';
import 'analytic_screen.dart';
import 'dudi_screen.dart';
import 'setting_screen.dart';
import 'journal_screen.dart'; // File baru yang kita buat di bawah
import 'analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentViewIndex = 0;

  void _changePage(int index) {
    setState(() => _currentViewIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildCurrentView(),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentViewIndex) {
      case 0: return _buildHomeOverview();
      case 1: return const SiswaScreen();
      case 2: return const JournalScreen();
      case 3: return const AnalyticScreen();
      case 4: return const DudiScreen();
      case 5: return const SettingScreen();
      default: return _buildHomeOverview();
    }
  }

  Widget _buildHomeOverview() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Layanan Utama", null),
                const SizedBox(height: 16),
                _buildMenuGrid(),
                const SizedBox(height: 32),
                _buildSectionTitle("Ikhtisar Statistik", () => _changePage(3)),
                const SizedBox(height: 16),
                _buildStatsGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Selamat Datang,", style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text("Administrator", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback? onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        if (onTap != null)
          TextButton(onPressed: onTap, child: const Text("Lihat Semua")),
      ],
    );
  }

  Widget _buildMenuGrid() {
    final menus = [
      {'label': 'Siswa', 'icon': Icons.people_alt_rounded, 'color': Colors.blue, 'idx': 1},
      {'label': 'Jurnal', 'icon': Icons.assignment_rounded, 'color': Colors.teal, 'idx': 2},
      {'label': 'Analitik', 'icon': Icons.insights_rounded, 'color': Colors.purple, 'idx': 3},
      {'label': 'Mitra', 'icon': Icons.handshake_rounded, 'color': Colors.orange, 'idx': 4},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) => InkWell(
        onTap: () => _changePage(menus[index]['idx'] as int),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Icon(menus[index]['icon'] as IconData, color: menus[index]['color'] as Color),
            ),
            const SizedBox(height: 8),
            Text(menus[index]['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _statCard("98%", "Absensi", Icons.check_circle_outline, Colors.green),
        const SizedBox(width: 16),
        _statCard("12", "Laporan", Icons.pending_actions_rounded, Colors.orange),
      ],
    );
  }

  Widget _statCard(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentViewIndex > 3 ? 3 : _currentViewIndex,
      onTap: (idx) => _changePage(idx == 3 ? 5 : idx),
      selectedItemColor: Colors.blue.shade900,
      unselectedItemColor: Colors.blueGrey.shade400, // Perbaikan: Colors.slate tidak ada di Flutter
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Beranda"),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Siswa"),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: "Jurnal"),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "Setting"),
      ],
    );
  }
}
