import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/surat_pkl_repository.dart';

class SuratPklScreen extends ConsumerWidget {
  const SuratPklScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca data surat dari FutureProvider yang tersambung ke Supabase
    final daftarSuratAsync = ref.watch(daftarSuratProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA), // Background soft agar card terlihat kontras
      appBar: AppBar(
        title: const Text(
          'Surat PKL',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 0,
        // Menggunakan Gradasi Linear agar warnanya sama persis dengan tema card utama aplikasi kamu
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1565C0), // Biru tua (sisi kiri)
                Color(0xFF1976D2), // Biru medium
                Color(0xFF0288D1), // Biru terang/cyan (sisi kanan)
              ],
            ),
          ),
        ),
      ),
      body: daftarSuratAsync.when(
        // 1. Kondisi ketika data berhasil diambil dari Supabase
        data: (daftarSurat) {
          if (daftarSurat.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat pengajuan surat.',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: daftarSurat.length,
            itemBuilder: (context, index) {
              final surat = daftarSurat[index];
              
              // Ekstraksi data dari Map Supabase
              final String judul = surat['judul'] ?? 'Tanpa Judul';
              final String tipe = surat['tipe'] ?? 'Umum';
              final String status = surat['status'] ?? 'Diproses';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16), // Radius melengkung tebal sesuai tema aplikasi
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE3F2FD), // Biru muda transparan untuk background ikon
                    child: const Icon(Icons.description, color: Color(0xFF1565C0)),
                  ),
                  title: Text(
                    judul,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Jenis: $tipe',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  trailing: _buildStatusBadge(status),
                ),
              );
            },
          );
        },
        // 2. Kondisi ketika terjadi error jaringan / database
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Terjadi kesalahan: $err',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // 3. Kondisi saat loading mengambil data
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
          ),
        ),
      ),
      // Tombol mengambang untuk mengajukan surat baru
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fitur formulir pengajuan surat baru sedang disiapkan!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        backgroundColor: const Color(0xFF1565C0), // Menyamakan warna FAB dengan tema utama
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Widget Helper untuk membuat Badge Status berwarna (Disetujui, Diproses, Ditolak)
  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'disetujui':
        backgroundColor = const Color(0xE8E5F5E3); // Hijau soft
        textColor = Colors.green[700]!;
        break;
      case 'ditolak':
        backgroundColor = const Color(0xFFFFEBEE); // Merah soft
        textColor = Colors.red[700]!;
        break;
      case 'diproses':
      default:
        backgroundColor = const Color(0xFFFFF3E0); // Orange/Kuning soft
        textColor = Colors.orange[700]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}