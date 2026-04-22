import 'package:flutter/material.dart';

class AnalyticScreen extends StatelessWidget {
  const AnalyticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Analitik & Laporan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAnalyticCard("Keaktifan Jurnal", "88%", Icons.auto_graph, Colors.teal),
          const SizedBox(height: 16),
          _buildAnalyticCard("Kepatuhan Absensi", "92%", Icons.verified_user, Colors.blue),
          const SizedBox(height: 16),
          _buildAnalyticCard("Mitra Industri", "42 Perusahaan", Icons.business_rounded, Colors.purple),
          const SizedBox(height: 24),
          const Text("Statistik Mingguan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Text("Grafik Visual Placeholder")),
          )
        ],
      ),
    );
  }

  Widget _buildAnalyticCard(String title, String value, IconData icon, Color col) {
    return Container(
      padding: const EdgeInsets.all(24), // Perbaikan: Menghapus teks impor yang nyelip
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: col.withOpacity(0.1), child: Icon(icon, color: col)),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}