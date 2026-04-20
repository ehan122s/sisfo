import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Warna latar yang lebih bersih (Slate 50)
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionTitle('Ringkasan Data'),
                  const SizedBox(height: 16),
                  _buildStatsGrid(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Menu Layanan'),
                  const SizedBox(height: 16),
                  _buildMenuGrid(),
                  const SizedBox(height: 32),
                  _buildApprovalCard(),
                  const SizedBox(height: 100), // Ruang ekstra agar tidak tertutup nav
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 68,
        width: 68,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF2563EB),
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 35),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
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
                      border: Border.all(color: Colors.blue.shade100, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Halo, Admin',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Koordinator Wilayah',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B)),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                hintText: 'Cari data siswa atau mitra...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4, // Ukuran kartu lebih proporsional (tidak terlalu panjang ke bawah)
      children: [
        _statCard('Siswa Aktif', '1,284', Icons.school_rounded, Colors.blue),
        _statCard('Mitra DUDI', '84', Icons.business_rounded, Colors.indigo),
        _statCard('Presensi', '94%', Icons.task_alt_rounded, Colors.teal),
        _statCard('Laporan', '12', Icons.description_rounded, Colors.orange),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final List<Map<String, dynamic>> menus = [
      {'label': 'Siswa', 'icon': Icons.people_rounded, 'color': Colors.blue},
      {'label': 'Mitra', 'icon': Icons.handshake_rounded, 'color': Colors.indigo},
      {'label': 'Peta', 'icon': Icons.map_rounded, 'color': Colors.red},
      {'label': 'Monitor', 'icon': Icons.analytics_rounded, 'color': Colors.teal},
      {'label': 'Izin', 'icon': Icons.assignment_ind_rounded, 'color': Colors.amber},
      {'label': 'Nilai', 'icon': Icons.grade_rounded, 'color': Colors.purple},
      {'label': 'Sertif', 'icon': Icons.verified_rounded, 'color': Colors.orange},
      {'label': 'Lainnya', 'icon': Icons.grid_view_rounded, 'color': Colors.blueGrey},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (menus[index]['color'] as Color).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(menus[index]['icon'], color: menus[index]['color'], size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                menus[index]['label'],
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApprovalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'BUTUH PERSETUJUAN',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _approvalItem('Reza Aditya', 'Izin Sakit - PT. Astra'),
          const SizedBox(height: 12),
          _approvalItem('Laila Sari', 'Pengajuan PKL - Telkom'),
        ],
      ),
    );
  }

  Widget _approvalItem(String name, String info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(info, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Text('Detail', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      height: 75,
      color: Colors.white,
      notchMargin: 12,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.grid_view_rounded, 'Home'),
          _navItem(1, Icons.people_alt_rounded, 'Siswa'),
          const SizedBox(width: 60), // Space for FAB
          _navItem(2, Icons.business_center_rounded, 'Mitra'),
          _navItem(3, Icons.settings_rounded, 'Sistem'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}