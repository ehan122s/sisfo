import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text("Jurnal Siswa"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('journals').stream(primaryKey: ['id']).order('created_at'),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error memuat data jurnal"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final journals = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: journals.length,
            itemBuilder: (context, index) => _buildJournalCard(journals[index]),
          );
        },
      ),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['student_name'] ?? "Siswa", style: const TextStyle(fontWeight: FontWeight.bold)),
              _statusBadge(data['status'] ?? "Pending"),
            ],
          ),
          const SizedBox(height: 12),
          Text(data['title'] ?? "Aktivitas Harian", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(data['content'] ?? "Detail laporan...", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () {}, child: const Text("Tinjau")),
          )
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}