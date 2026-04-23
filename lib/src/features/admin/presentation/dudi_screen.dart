import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DudiScreen extends StatelessWidget {
  const DudiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Industrial Partners", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Partner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('companies').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator.adaptive());
          final data = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: data.length,
            itemBuilder: (context, index) => _partnerCard(data[index]),
          );
        },
      ),
    );
  }

  Widget _partnerCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.business_rounded, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? "Enterprise Corp", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(data['address'] ?? "Metropolitan Area", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_right_rounded, color: Colors.grey))
        ],
      ),
    );
  }
}