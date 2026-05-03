import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import file detail agar bisa pindah halaman
import '../../journal/presentation/journal_detail_screen.dart'; 

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Journal Reviews", 
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Menggunakan stream agar UI otomatis berubah saat database di-update
        stream: supabase
            .from('daily_journals')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator.adaptive());
          
          final journals = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            itemCount: journals.length,
            itemBuilder: (context, i) => _journalItem(context, journals[i]),
          );
        },
      ),
    );
  }

  Widget _journalItem(BuildContext context, Map<String, dynamic> data) {
    final supabase = Supabase.instance.client;
    
    // MENGGUNAKAN IS_APPROVED (BOOLEAN)
    final bool isApproved = data['is_approved'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18, 
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.person, size: 18, color: Color(0xFF64748B))
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Student ID: ${data['student_id'].toString().length > 5 ? data['student_id'].toString().substring(0, 5) : data['student_id']}", 
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)
                    ),
                    Text(data['date'] ?? "-", style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  ],
                ),
              ),
              _statusChip(isApproved),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            data['activities'] ?? "No Title", 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))
          ),
          const SizedBox(height: 8),
          Text(
            data['challenges'] ?? "No details provided.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JournalDetailScreen(journal: data),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Preview", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              
              // TOMBOL ACTION: BISA APPROVE DAN BISA CANCEL (TOGGLE)
              GestureDetector(
                onTap: () async {
                  // Toggle status: jika true jadi false, jika false jadi true
                  await supabase
                      .from('daily_journals')
                      .update({'is_approved': !isApproved})
                      .eq('id', data['id']);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isApproved ? Colors.green : const Color(0xFF0F172A), 
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isApproved ? Icons.done_all_rounded : Icons.check_rounded, 
                    color: Colors.white
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _statusChip(bool isApproved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.shade50 : Colors.orange.shade50, 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Text(
        isApproved ? "APPROVED" : "PENDING", 
        style: TextStyle(
          color: isApproved ? Colors.green : Colors.orange.shade700, 
          fontWeight: FontWeight.w900, 
          fontSize: 10
        )
      ),
    );
  }
}