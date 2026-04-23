```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'siswa_screen.dart';
import 'journal_screen.dart';
import 'analytic_screen.dart';
import 'dudi_screen.dart';
import 'setting_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentViewIndex = 0;
  final SupabaseClient supabase = Supabase.instance.client;

  void _changePage(int index) {
    setState(() => _currentViewIndex = index);
  }

  late final List<Widget> _views = [
    _HomeOverview(onNavigate: _changePage),
    const SiswaScreen(),
    const JournalScreen(),
    const AnalyticScreen(),
    const DudiScreen(),
    const SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _views[_currentViewIndex],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildMainActionFAB(),
      bottomNavigationBar: _buildEliteBottomNav(),
    );
  }

  Widget _buildEliteBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.grid_view_rounded, "Home"),
            _navItem(1, Icons.group_rounded, "Siswa"),
            _navItem(2, Icons.auto_awesome_motion_rounded, "Journal"),
            _navItem(3, Icons.bar_chart_rounded, "Analitik"),
            _navItem(4, Icons.business_rounded, "DUDI"),
            _navItem(5, Icons.settings_rounded, "Settings"),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isActive = _currentViewIndex == index;
    return GestureDetector(
      onTap: () => _changePage(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : const Color(0xFF94A3B8), size: 22),
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
          ],
        ),
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
}

class _HomeOverview extends StatelessWidget {
  final Function(int) onNavigate;
  const _HomeOverview({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildPremiumHeader(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 35),
                _buildAnalyticsTeaser(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(24, 70, 24, 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(45)),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 15))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)), child: const CircleAvatar(radius: 28, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=admin'))),
                      const SizedBox(width: 16),
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Halo, Administrator', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text('Senin, 21 April 2024', style: TextStyle(color: Colors.white70, fontSize: 12))]),
                    ],
                  ),
                  _buildNotificationBadge(),
                ],
              ),
              const SizedBox(height: 30),
              _buildQuickActionCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCards() {
    return Row(children: [_quickCard("Siswa Aktif", "854", Icons.person_pin_rounded), const SizedBox(width: 12), _quickCard("Total Mitra", "42", Icons.apartment_rounded)]);
  }

  Widget _quickCard(String title, String value, IconData icon) {
    return Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text(title, style: TextStyle(color: Colors.white60, fontSize: 10))])])));
  }

  Widget _buildNotificationBadge() {
    return Stack(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.notifications_none_rounded, color: Colors.white)), Positioned(right: 8, top: 8, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.blue.shade800, width: 2))))]);
  }

  Widget _buildSectionTitle(String title) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))), Text("Lihat Semua", style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold))]);
  }

  Widget _buildStatsGrid() {
    return Row(children: [_statCard("Absensi", "98%", Icons.fact_check_rounded, Colors.blue), const SizedBox(width: 16), _statCard("Izin", "12", Icons.mail_outline_rounded, Colors.orange)]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)), const SizedBox(height: 16), Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600))])));
  }

  Widget _buildFullMenuGrid() {
    final menus = [{'label': 'Siswa', 'icon': Icons.groups_rounded, 'color': Colors.blue, 'idx': 1}, {'label': 'Jurnal', 'icon': Icons.edit_note_rounded, 'color': Colors.teal, 'idx': 2}, {'label': 'Analitik', 'icon': Icons.bar_chart_rounded, 'color': Colors.purple, 'idx': 3}, {'label': 'Mitra DUDI', 'icon': Icons.business_rounded, 'color': Colors.indigo, 'idx': 4}, {'label': 'Absensi', 'icon': Icons.location_on_rounded, 'color': Colors.red, 'idx': 0}, {'label': 'Sertifikat', 'icon': Icons.workspace_premium_rounded, 'color': Colors.amber, 'idx': 0}, {'label': 'Dokumen', 'icon': Icons.folder_copy_rounded, 'color': Colors.cyan, 'idx': 0}, {'label': 'Setting', 'icon': Icons.settings_rounded, 'color': Colors.grey, 'idx': 5}];
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 20, crossAxisSpacing: 10, childAspectRatio: 0.85), itemCount: menus.length, itemBuilder: (context, index) => InkWell(onTap: () => onNavigate(menus[index]['idx']), child: Column(children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]), Icon(menus[index]['icon'], color: menus[index]['color'])), const SizedBox(height: 10), Text(menus[index]['label'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)), textAlign: TextAlign.center)])));
  }

  Widget _buildRecentActivityList() {
    return Column(children: List.generate(3, (index) => _activityItem(index)));
  }

  Widget _activityItem(int i) {
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Row(children: [CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.bolt_rounded, color: Colors.blue, size: 18)), const SizedBox(width: 16), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Update Proyek Siswa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text("Budi telah mengirimkan progres UI Design", style: TextStyle(color: Colors.grey, fontSize: 11))])), Text("2m ago", style: TextStyle(fontSize: 10, color: Colors.grey.shade400))]));
  }

  Widget _buildAnalyticsTeaser() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(28), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF334155)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 15))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Data Intelligence", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Icon(Icons.insights_rounded, color: Colors.blue.shade300)]), const SizedBox(height: 24), Row(children: [_simpleStat("1.2k", "Records"), const SizedBox(width: 32), _simpleStat("98%", "Uptime")]), const SizedBox(height: 24), SizedBox(width: double.infinity, child: TextButton(onPressed: () {}, style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("View Full Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))]));
  }

  Widget _simpleStat(String val, String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)), Text(label, style: TextStyle(color: Colors.blue.shade200, fontSize: 12, fontWeight: FontWeight.w600))]);
  }
}
```