import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DudiScreen extends StatefulWidget {
  const DudiScreen({super.key});

  @override
  State<DudiScreen> createState() => _DudiScreenState();
}

class _DudiScreenState extends State<DudiScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text("Mitra Industri"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('companies').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: data.length,
            itemBuilder: (context, index) => _buildCard(data[index]),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: const Icon(Icons.business, color: Colors.blue),
        title: Text(data['company_name'] ?? "Perusahaan"),
        subtitle: Text(data['sector'] ?? "Sektor Industri"),
      ),
    );
  }
}