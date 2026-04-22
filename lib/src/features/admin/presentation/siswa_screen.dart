import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SiswaScreen extends StatefulWidget {
  const SiswaScreen({super.key});

  @override
  State<SiswaScreen> createState() => _SiswaScreenState();
}

class _SiswaScreenState extends State<SiswaScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildEliteSearchHeader(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('profiles').stream(primaryKey: ['id']).eq('role', 'student'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator.adaptive());
                
                final students = snapshot.data!.where((s) {
                  return (s['full_name'] ?? "").toString().toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  itemCount: students.length,
                  itemBuilder: (context, i) => _studentCard(students[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEliteSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Student Directory", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: "Search records...",
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F172A)),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          height: 52, width: 52,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue, Colors.blue.shade700]), borderRadius: BorderRadius.circular(16)),
          child: Center(child: Text(data['full_name']?[0] ?? "S", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20))),
        ),
        title: Text(data['full_name'] ?? "Unknown Candidate", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(data['class_name'] ?? "Unassigned Class", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0F172A)),
        ),
      ),
    );
  }
}