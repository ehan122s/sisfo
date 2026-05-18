import 'package:flutter/material.dart';
import 'teacher_attendance_monitor_screen.dart';
import 'teacher_journal_screen.dart';
import 'teacher_datasiswa_screen.dart';
import 'teacher_riwayat_screen.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Dashboard Guru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, Guru!', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _menuCard(context, 'Monitoring Absensi', Icons.location_on_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherAttendanceMonitorScreen()));
                }),
                _menuCard(context, 'Laporan Jurnal', Icons.book_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherJournalScreen()));
                }),
                _menuCard(context, 'Data Siswa', Icons.badge_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherDataSiswaScreen()));
                }),
                _menuCard(context, 'Riwayat Aktivitas', Icons.history_edu_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherRiwayatScreen()));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.indigo),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}