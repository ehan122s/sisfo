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
              stream: supabase
                  .from('profiles')
                  .stream(primaryKey: ['id'])
                  .eq('role', 'student')
                  .order('full_name', ascending: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat data: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: Color(0xFFCBD5E1),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada data siswa',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  );
                }

                final students = snapshot.data!.where((s) {
                  final name = (s['full_name'] ?? '').toString().toLowerCase();
                  final nisn = (s['nisn'] ?? '').toString().toLowerCase();
                  final className = (s['class_name'] ?? '')
                      .toString()
                      .toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  return name.contains(query) ||
                      nisn.contains(query) ||
                      className.contains(query);
                }).toList();

                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ditemukan: "$_searchQuery"',
                          style: const TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  );
                }

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
          const Text(
            "Student Directory",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          // Menampilkan jumlah siswa secara real-time via StreamBuilder terpisah
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('profiles')
                .stream(primaryKey: ['id'])
                .eq('role', 'student'),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Text(
                '$count siswa terdaftar',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: "Cari nama, NISN, atau kelas...",
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF0F172A),
              ),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentCard(Map<String, dynamic> data) {
    final String fullName = data['full_name'] ?? 'Unknown';
    final String className = data['class_name'] ?? 'Belum ada kelas';
    final String nisn = data['nisn'] ?? '-';
    final String status = data['status'] ?? 'active';
    final String? avatarUrl = data['avatar_url'];
    final bool isVerified = data['is_verified'] ?? false;

    final bool isActive = status == 'active';

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
        leading: Stack(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            fullName.isNotEmpty
                                ? fullName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
            ),
            // Badge verifikasi
            if (isVerified)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Badge status aktif/nonaktif
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              className,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              'NISN: $nisn',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Color(0xFF0F172A),
          ),
        ),
        onTap: () {
          // TODO: navigasi ke halaman detail siswa
          // Navigator.push(context, MaterialPageRoute(builder: (_) => SiswaDetailScreen(student: data)));
        },
      ),
    );
  }
}
