  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
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

    // Navigasi ke halaman tertentu dari Dashboard Overview
    void _changePage(int index) {
      setState(() => _currentViewIndex = index);
    }

    late final List<Widget> _views = [
      _HomeOverview(onNavigate: _changePage),
      const SiswaScreen(),
      const JournalScreen(),
      const DudiManagementScreen(),
      const SettingScreen(),
    ];

    @override
    Widget build(BuildContext context) {
      // Dark status bar untuk kesan premium
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _views[_currentViewIndex],
        ),
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
              _navItem(0, Icons.grid_view_rounded, "Overview"),
              _navItem(1, Icons.group_rounded, "Students"),
              _navItem(2, Icons.auto_awesome_motion_rounded, "Journal"),
              _navItem(3, Icons.business_rounded, "DUDI"),
              _navItem(4, Icons.face_retouching_natural_rounded, "Profile"),
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
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
            ],
          ),
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
          _buildHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 32),
                  _buildQuickAccess(),
                  const SizedBox(height: 40),
                  _buildAnalyticsTeaser(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildHeader() {
      return SliverAppBar(
        expandedHeight: 140,
        collapsedHeight: 80,
        pinned: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        flexibleSpace: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          title: const Text(
            "Nexus Admin",
            style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A)),
                onPressed: () {},
              ),
            ),
          )
        ],
      );
    }

    Widget _buildWelcomeSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Management Console", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text("Welcome back,\nSuper Administrator", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.2)),
        ],
      );
    }

    Widget _buildQuickAccess() {
      final tools = [
        {'label': 'Siswa', 'icon': Icons.people_alt_rounded, 'color': Colors.blue, 'idx': 1},
        {'label': 'Jurnal', 'icon': Icons.description_rounded, 'color': Colors.indigo, 'idx': 2},
        {'label': 'DUDI', 'icon': Icons.business_rounded, 'color': Colors.amber.shade700, 'idx': 3},
        {'label': 'Export', 'icon': Icons.ios_share_rounded, 'color': Colors.teal, 'idx': 0},
      ];

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: tools.length,
        itemBuilder: (context, i) => InkWell(
          onTap: () => onNavigate(tools[i]['idx'] as int),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: (tools[i]['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(tools[i]['icon'] as IconData, color: tools[i]['color'] as Color, size: 24),
                ),
                Text(tools[i]['label'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildAnalyticsTeaser() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF334155)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 15))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Data Intelligence", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.insights_rounded, color: Colors.blue.shade300),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _simpleStat("1.2k", "Records"),
                const SizedBox(width: 32),
                _simpleStat("98%", "Uptime"),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text("View Full Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      );
    }

    Widget _simpleStat(String val, String label) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: Colors.blue.shade200, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );
    }
  }