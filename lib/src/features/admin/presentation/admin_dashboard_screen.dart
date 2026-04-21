import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/* STRUKTUR PEMBAGIAN TUGAS KELOMPOK (Updated):
  1. main.dart -> Inisialisasi Supabase
  2. admin_dashboard_screen.dart -> File ini (Orchestrator & Home View)
  3. views/siswa_view.dart -> Logic Manajemen Siswa & Profiles
  4. views/journal_view.dart -> Monitoring Jurnal Harian
  5. views/report_view.dart -> Rekapitulasi Laporan & Nilai
  6. views/dudi_view.dart -> Database Mitra & Kerjasama
*/

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
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentView(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildCustomFAB(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentViewIndex) {
      case 0: return _buildHomeView();
      case 1: return _buildSiswaView(); // Real-time Student List
      case 2: return _buildJournalView(); // New: Monitoring Jurnal
      case 3: return _buildReportView(); // New: Student Report
      case 4: return _buildSimplePlaceholder("Daftar Mitra DUDI", Icons.business_rounded);
      case 5: return _buildSimplePlaceholder("Pengaturan Sistem", Icons.settings_suggest_rounded);
      default: return _buildHomeView();
    }
  }

  // --- 1. HOME VIEW (DASHBOARD) ---
  Widget _buildHomeView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnhancedHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildSectionTitle('Statistik Real-time'),
                const SizedBox(height: 16),
                _buildStatsGrid(),
                const SizedBox(height: 32),
                _buildSectionTitle('Menu Administrasi'),
                const SizedBox(height: 16),
                _buildMenuGrid(),
                const SizedBox(height: 32),
                _buildSectionTitle('Aktivitas Jurnal Terbaru'),
                const SizedBox(height: 16),
                _buildRecentJournalList(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. SISWA VIEW (SUPABASE CONNECTED) ---
  Widget _buildSiswaView() {
    return Column(
      children: [
        _buildHeaderMinimal("Database Siswa", Icons.people_outline),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase.from('profiles').stream(primaryKey: ['id']).eq('role', 'student').order('created_at'),
            builder: (context, snapshot) {
              if (snapshot.hasError) return _errorState();
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final data = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: data.length,
                itemBuilder: (context, index) => _buildSiswaCard(data[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 3. JOURNAL VIEW (NEW) ---
  Widget _buildJournalView() {
    return Column(
      children: [
        _buildHeaderMinimal("Monitoring Jurnal", Icons.history_edu_rounded),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            // Asumsi ada tabel 'journals' yang berelasi dengan 'profiles'
            stream: supabase.from('daily_journals').stream(primaryKey: ['id']).order('created_at'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) => _buildJournalCard(snapshot.data![index]),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 4. REPORT VIEW (NEW) ---
  Widget _buildReportView() {
    return Column(
      children: [
        _buildHeaderMinimal("Laporan Mingguan", Icons.assessment_rounded),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.shade900, borderRadius: BorderRadius.circular(25)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text("Total 12 laporan butuh verifikasi hari ini.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        // Implementasi list report di sini...
      ],
    );
  }

  // --- UI REUSABLE COMPONENTS ---

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 2)),
                child: const CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=admin')),
              ),
              const SizedBox(width: 15),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Super Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  Text('Koordinator PKL 2024', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          _buildIconBadge(Icons.notifications_none_rounded, Colors.orange, true),
        ],
      ),
    );
  }

  Widget _buildIconBadge(IconData icon, Color color, bool hasNotification) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: color),
        ),
        if (hasNotification)
          Positioned(
            right: 8, top: 8,
            child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          )
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _statCard('Siswa Aktif', '1,284', Icons.school, Colors.blue)),
        const SizedBox(width: 15),
        Expanded(child: _statCard('Izin Masuk', '24', Icons.mail_rounded, Colors.orange)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final List<Map<String, dynamic>> items = [
      {'label': 'Siswa', 'icon': Icons.groups_rounded, 'color': Colors.blue, 'target': 1},
      {'label': 'Jurnal', 'icon': Icons.history_edu_rounded, 'color': Colors.teal, 'target': 2},
      {'label': 'Report', 'icon': Icons.assessment_rounded, 'color': Colors.purple, 'target': 3},
      {'label': 'Mitra', 'icon': Icons.business_rounded, 'color': Colors.indigo, 'target': 4},
      {'label': 'Absensi', 'icon': Icons.fact_check_rounded, 'color': Colors.orange, 'target': 0},
      {'label': 'Sertifikat', 'icon': Icons.verified_user_rounded, 'color': Colors.green, 'target': 0},
      {'label': 'Map', 'icon': Icons.map_rounded, 'color': Colors.red, 'target': 0},
      {'label': 'Settings', 'icon': Icons.settings_rounded, 'color': Colors.blueGrey, 'target': 5},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 20, crossAxisSpacing: 10, childAspectRatio: 0.8),
      itemCount: items.length,
      itemBuilder: (context, index) => InkWell(
        onTap: () => setState(() => _currentViewIndex = items[index]['target']),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: (items[index]['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(22)),
              child: Icon(items[index]['icon'], color: items[index]['color']),
            ),
            const SizedBox(height: 8),
            Text(items[index]['label'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900));
  }

  Widget _buildRecentJournalList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.edit_note_rounded, color: Colors.teal)),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Budi Santoso", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Membuat desain UI Landing Page...", style: TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text("10m ago", style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMinimal(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(onPressed: () => setState(() => _currentViewIndex = 0), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
          const SizedBox(width: 10),
          Icon(icon, color: Colors.blue, size: 28),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSiswaCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue.shade50, child: Text(data['full_name']?[0] ?? '?', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['full_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(data['class_name'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          _statusBadge(data['status'] ?? 'inactive'),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    bool isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: isActive ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> data) {
    return Card(child: ListTile(title: Text(data['title'] ?? 'No Title')));
  }

  Widget _errorState() => const Center(child: Text("Error loading data."));

  Widget _buildSimplePlaceholder(String title, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 100, color: Colors.blue.withOpacity(0.1)), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), const SizedBox(height: 20), ElevatedButton(onPressed: () => setState(() => _currentViewIndex = 0), child: const Text("Go Home"))]));
  }

  Future<void> _addNewSiswa() async {
    // Untuk demo, tampilkan pesan bahwa fitur belum diimplementasi
    // Karena menambah siswa memerlukan pembuatan user di auth.users terlebih dahulu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur tambah siswa belum diimplementasi. Gunakan dashboard Supabase untuk menambah data.')),
    );
  }

  Widget _buildCustomFAB() {
    return Container(
      height: 64, width: 64,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: FloatingActionButton(
        onPressed: _addNewSiswa,
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _bottomNavItem(int index, IconData icon) {
    bool isSel = _currentViewIndex == index;
    return IconButton(
      onPressed: () => setState(() => _currentViewIndex = index),
      icon: Icon(icon, color: isSel ? const Color(0xFF2563EB) : Colors.blueGrey.shade200, size: 28),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      height: 80,
      notchMargin: 12,
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomNavItem(0, Icons.grid_view_rounded),
          _bottomNavItem(1, Icons.people_outline_rounded),
          const SizedBox(width: 48),
          _bottomNavItem(2, Icons.history_edu_rounded),
          _bottomNavItem(5, Icons.settings_outlined),
        ],
      ),
    );
  }
}