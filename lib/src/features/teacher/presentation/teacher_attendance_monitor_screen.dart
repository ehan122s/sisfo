import 'package:flutter/material.dart';

class TeacherAttendanceMonitorScreen extends StatelessWidget {
  const TeacherAttendanceMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Live Monitoring', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          _buildSearchAndFilter(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: 8,
              itemBuilder: (context, index) => _buildAttendanceTile(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _summaryBox("Hadir", "22", Colors.green),
          const SizedBox(width: 12),
          _summaryBox("Telat", "2", Colors.orange),
          const SizedBox(width: 12),
          _summaryBox("Izin", "1", Colors.blue),
          const SizedBox(width: 12),
          _summaryBox("Alpha", "0", Colors.red),
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 20)),
            Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, size: 20),
                  hintText: "Cari siswa...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildAttendanceTile(int index) {
    bool isLate = index == 1 || index == 4;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isLate ? Colors.orange : Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Budi Santoso", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text("Kelas XII IPA 2 • NIS: 210293", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(isLate ? "07:12" : "06:45", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              Text(isLate ? "TELAT" : "HADIR", 
                style: TextStyle(
                  color: isLate ? Colors.orange : Colors.green, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
