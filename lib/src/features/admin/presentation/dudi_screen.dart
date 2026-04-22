```dart
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Mitra Industri", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _actionButton(Icons.add_business_rounded),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildQuickStats(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('dudi_partners').stream(primaryKey: ['id']).order('company_name'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final partners = snapshot.data!;
                
                if (partners.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.business_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text("Belum ada mitra", style: TextStyle(color: Colors.grey.shade500, fontSize: 16))]));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: partners.length,
                  itemBuilder: (context, index) => _buildPartnerCard(partners[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Mitra", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _miniSummary("Total", "42", Colors.indigo),
          const SizedBox(width: 12),
          _miniSummary("Aktif", "38", Colors.green),
          const SizedBox(width: 12),
          _miniSummary("Penuh", "4", Colors.red),
        ],
      ),
    );
  }

  Widget _miniSummary(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
            Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            children: [
              Container(height: 50, width: 50, decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.business_rounded, color: Colors.indigo)),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['company_name'] ?? 'PT. Maju Mundur', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(data['sector'] ?? 'Teknologi Informasi', style: const TextStyle(color: Colors.grey, fontSize: 11))])),
              const Icon(Icons.verified_rounded, color: Colors.blue, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_infoRow(Icons.people_outline, "${data['quota'] ?? 0} Kuota"), _infoRow(Icons.location_on_outlined, data['city'] ?? "Jakarta"), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: const Text("Lihat MoU", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)))]),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 5), Text(text, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600))]);
  }

  Widget _actionButton(IconData icon) {
    return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.indigo.shade800, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: Colors.white, size: 20));
  }
}
```