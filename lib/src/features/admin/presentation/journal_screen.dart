```dart
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Monitoring Jurnal", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.edit_note_rounded, color: Colors.teal, size: 24),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('journals').stream(primaryKey: ['id']).order('created_at'),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _buildErrorState();
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final journals = snapshot.data!;
                if (journals.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: journals.length,
                  itemBuilder: (context, index) => _buildJournalCard(journals[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
        label: const Text("Filter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _filterChip("Semua", true),
            _filterChip("Perlu Review", false),
            _filterChip("Telah Dinilai", false),
            _filterChip("Hari Ini", false),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? Colors.teal : Colors.black12),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=student')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['student_name'] ?? "Siswa PKL", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(data['company_name'] ?? "PT. Industri Mitra", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              _statusBadge(data['status'] ?? "Pending"),
            ],
          ),
          const SizedBox(height: 20),
          Text(data['title'] ?? "Judul Aktivitas", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            data['content'] ?? "Detail aktivitas hari ini belum diisi secara lengkap oleh siswa.",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey), const SizedBox(width: 5), Text("2 Jam yang lalu", style: TextStyle(color: Colors.grey.shade400, fontSize: 11))]),
              Row(children: [
                TextButton(onPressed: () {}, style: TextButton.styleFrom(foregroundColor: Colors.blueGrey, padding: EdgeInsets.zero, minimumSize: const Size(50, 30)), child: const Text("Preview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const SizedBox(width: 8),
                TextButton(onPressed: () {}, style: TextButton.styleFrom(foregroundColor: Colors.teal, padding: EdgeInsets.zero, minimumSize: const Size(50, 30)), child: const Text("Beri Nilai", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    bool isPending = status == "Pending";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: isPending ? Colors.orange.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), style: TextStyle(color: isPending ? Colors.orange : Colors.green, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildEmptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.edit_note_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text("Belum ada jurnal masuk.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16))]));
  Widget _buildErrorState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300), const SizedBox(height: 16), Text("Gagal memuat data jurnal.", style: TextStyle(color: Colors.red.shade400, fontSize: 16))]));
}
```