import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'siswa_screen.dart';
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
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildCurrentView(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildMainActionFAB(),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentViewIndex) {
      case 0: return _buildHomeOverview();
      case 1: return const SiswaScreen();
      case 2: return const JournalScreen(); // Sekarang sudah terhubung
      case 3: return _placeholderView("Laporan & Analitik", Icons.bar_chart_rounded, Colors.purple);
      case 4: return const DudiScreen(); // Sekarang sudah terhubung
      case 5: return const SettingScreen(); // Sekarang sudah terhubung
      default: return _buildHomeOverview();
    }
  }

  Widget _buildHomeOverview() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                _buildSectionTitle("Ringkasan Eksekutif"),
                const SizedBox(height: 16),
                _buildStatsGrid(),
                const SizedBox(height: 35),
                _buildSectionTitle("Navigasi Cepat"),
                const SizedBox(height: 16),
                _buildFullMenuGrid(),
                const SizedBox(height: 35),
                _buildSectionTitle("Aktivitas Terbaru"),
                const SizedBox(height: 16),
                _buildRecentActivityList(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(45)),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 15))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=admin'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo, Administrator', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Senin, 21 April 2024', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              _buildNotificationBadge(),
            ],
          ),
          const SizedBox(height: 30),
          _buildQuickActionCards(),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards() {
    return Row(
      children: [
        _quickCard("Siswa Aktif", "854", Icons.person_pin_rounded),
        const SizedBox(width: 12),
        _quickCard("Total Mitra", "42", Icons.apartment_rounded),
      ],
    );
  }

  Widget _quickCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(title, style: TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _statCard("Absensi", "98%", Icons.fact_check_rounded, Colors.blue),
        const SizedBox(width: 16),
        _statCard("Izin", "12", Icons.mail_outline_rounded, Colors.orange),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFullMenuGrid() {
    final List<Map<String, dynamic>> menus = [
      {'label': 'Siswa', 'icon': Icons.groups_rounded, 'color': Colors.blue, 'idx': 1},
      {'label': 'Jurnal', 'icon': Icons.edit_note_rounded, 'color': Colors.teal, 'idx': 2},
      {'label': 'Analitik', 'icon': Icons.bar_chart_rounded, 'color': Colors.purple, 'idx': 3},
      {'label': 'Mitra DUDI', 'icon': Icons.business_rounded, 'color': Colors.indigo, 'idx': 4},
      {'label': 'Absensi', 'icon': Icons.location_on_rounded, 'color': Colors.red, 'idx': 0},
      {'label': 'Sertifikat', 'icon': Icons.workspace_premium_rounded, 'color': Colors.amber, 'idx': 0},
      {'label': 'Dokumen', 'icon': Icons.folder_copy_rounded, 'color': Colors.cyan, 'idx': 0},
      {'label': 'Setting', 'icon': Icons.settings_rounded, 'color': Colors.grey, 'idx': 5},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) => InkWell(
        onTap: () => setState(() => _currentViewIndex = menus[index]['idx']),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Icon(menus[index]['icon'], color: menus[index]['color']),
            ),
            const SizedBox(height: 10),
            Text(menus[index]['label'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return Column(children: List.generate(3, (index) => _activityItem(index)));
  }

  Widget _activityItem(int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.bolt_rounded, color: Colors.blue, size: 18)),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Update Proyek Siswa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text("Budi telah mengirimkan progres UI Design", style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text("2m ago", style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        Text("Lihat Semua", style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNotificationBadge() {
    return Stack(
      children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.notifications_none_rounded, color: Colors.white)),
        Positioned(right: 8, top: 8, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.blue.shade800, width: 2)))),
      ],
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(0, Icons.grid_view_rounded),
            _navIcon(1, Icons.people_alt_rounded),
            const SizedBox(width: 50),
            _navIcon(2, Icons.history_edu_rounded),
            _navIcon(5, Icons.settings_rounded),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(int index, IconData icon) {
    bool isSel = _currentViewIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentViewIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSel ? Colors.blue.shade800 : Colors.blueGrey.shade200, size: 26),
          const SizedBox(height: 4),
          if (isSel) Container(width: 5, height: 5, decoration: BoxDecoration(color: Colors.blue.shade800, shape: BoxShape.circle))
        ],
      ),
    );
  }

  Widget _buildMainActionFAB() {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _placeholderView(String title, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: color.withOpacity(0.1)),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => setState(() => _currentViewIndex = 0), style: ElevatedButton.styleFrom(backgroundColor: color, shape: const StadiumBorder()), child: const Text("Kembali ke Beranda", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
