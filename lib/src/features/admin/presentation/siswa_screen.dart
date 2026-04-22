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
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('profiles').stream(primaryKey: ['id']).eq('role', 'student'),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Terjadi kesalahan data"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final filtered = snapshot.data!.where((s) {
                  return (s['full_name'] ?? "").toString().toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildSiswaCard(filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 20),
      child: const Text("Data Siswa", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: "Cari siswa...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSiswaCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: CircleAvatar(child: Text(data['full_name']?[0] ?? "S")),
        title: Text(data['full_name'] ?? "Nama Siswa"),
        subtitle: Text(data['class_name'] ?? "Kelas"),
      ),
    );
  }
}