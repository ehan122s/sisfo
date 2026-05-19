import 'package:flutter/material.dart';

class TeacherRiwayatScreen extends StatelessWidget {
  const TeacherRiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTimelineDate("HARI INI"),
          _buildTimelineItem(
            time: "07:45",
            title: "Absensi Selesai",
            desc: "24 Siswa XII IPA 1 telah berhasil diverifikasi.",
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          _buildTimelineItem(
            time: "08:30",
            title: "Jurnal Mengajar Diperbarui",
            desc: "Materi 'Logaritma' telah ditambahkan ke sistem.",
            icon: Icons.edit_note_rounded,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          _buildTimelineDate("KEMARIN"),
          _buildTimelineItem(
            time: "14:20",
            title: "Input Nilai Harian",
            desc: "Nilai Tugas 1 Bahasa Indonesia sudah masuk.",
            icon: Icons.assignment_turned_in,
            color: Colors.orange,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDate(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(text, style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 11)),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: color.withOpacity(0.2),
              )
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
              const SizedBox(height: 24),
            ],
          ),
        )
      ],
    );
  }
}