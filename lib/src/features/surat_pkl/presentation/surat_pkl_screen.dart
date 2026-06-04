import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/surat_pkl_repository.dart';

class SuratPklScreen extends ConsumerWidget {
  const SuratPklScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca data surat dari FutureProvider yang tersambung ke Supabase Anda
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
        // Menggunakan Gradasi Linear agar warnanya sama persis dengan tema card utama aplikasi Anda
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
              
              // Ekstraksi data dari Map Supabase secara aman
              final String judul = (surat['judul'] ?? 'Tanpa Judul').toString();
              final String tipe = (surat['tipe'] ?? 'Umum').toString();
              final String status = (surat['status'] ?? 'Diproses').toString();

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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    // AKSI DIKLIK: Membuka bottom sheet interaktif sesuai status surat
                    onTap: () => _showDetailSurat(context, surat),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFFE3F2FD), // Biru muda transparan
                            child: Icon(Icons.description, color: Color(0xFF1565C0)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  judul,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Jenis: $tipe',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(status),
                        ],
                      ),
                    ),
                  ),
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
        onPressed: () => _showFormFormulirBaru(context),
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
        textColor = const Color(0xFF2E7D32); // Hijau pekat
        break;
      case 'ditolak':
        backgroundColor = const Color(0xFFFFEBEE); // Merah soft
        textColor = const Color(0xFFC62828); // Merah pekat
        break;
      case 'diproses':
      default:
        backgroundColor = const Color(0xFFFFF3E0); // Orange/Kuning soft
        textColor = const Color(0xFFE65100); // Orange pekat
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

  /// Membuka Detail Surat sesuai dengan statusnya
  void _showDetailSurat(BuildContext context, Map<String, dynamic> surat) {
    final String status = (surat['status'] ?? 'Diproses').toString().toLowerCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Garis pemegang modal atas
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(surat['status'] ?? 'Diproses'),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        if (status == 'disetujui') ...[
                          _buildPratontonSuratResmi(surat),
                        ] else ...[
                          _buildTrackingTimeline(surat),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tombol di bagian bawah modal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(status == 'disetujui' 
                              ? 'Menyiapkan proses pencetakan dokumen PDF...' 
                              : 'Menghubungkan ke layanan bantuan fakultas...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        status == 'disetujui' ? 'Cetak / Unduh PDF' : 'Hubungi Admin Fakultas',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Pratonton Surat Resmi UMB (Jika Disetujui)
  Widget _buildPratontonSuratResmi(Map<String, dynamic> surat) {
    final String nomor = (surat['nomor_surat'] ?? 'B/412/FT/TI/UNIV/V/2026').toString();
    final String instansi = (surat['instansi_tujuan'] ?? 'PT. Krakatau Steel (Persero)').toString();
    final String nama = (surat['nama_mahasiswa'] ?? 'Ahmad Dhani').toString();
    final String nim = (surat['nim'] ?? '220411082').toString();
    final String prodi = (surat['prodi'] ?? 'Teknik Informatika').toString();
    final String tujuan = (surat['tujuan_penelitian'] ?? 'Sistem Manajemen Berbasis Web').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kop Surat Universitas
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'UMB',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'UNIVERSITAS MERCU BUANA',
                      style: TextStyle(
                        fontWeight: FontWeight.w900, // Diperbaiki dari FontWeight.black menjadi FontWeight.w900
                        fontSize: 11, 
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      'FAKULTAS TEKNIK - TEKNIK INFORMATIKA',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    Text(
                      'Jl. Raya Meruya Selatan No.1, Jakarta Barat 11650',
                      style: TextStyle(fontSize: 7, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 1.5, color: Colors.black87),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Diperbaiki dari .between ke .spaceBetween
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nomor: $nomor', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  const Text('Hal: Permohonan Pengantar PKL', style: TextStyle(fontSize: 10)),
                ],
              ),
              const Text('03 Juni 2026', style: TextStyle(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Kepada Yth.\n$instansi\ndi tempat', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            'Dengan hormat, sehubungan dengan kurikulum akademik mahasiswa Program Studi Teknik Informatika Universitas Mercu Buana, kami sampaikan permohonan kerja praktik untuk:',
            style: TextStyle(fontSize: 10, height: 1.4),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildRowDetailSurat('Nama', nama),
                _buildRowDetailSurat('NIM', nim),
                _buildRowDetailSurat('Prodi', prodi),
                _buildRowDetailSurat('Topik', tujuan),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Demikian permohonan ini kami sampaikan. Atas bantuan dan kerja sama Bapak/Ibu pimpinan instansi terkait, kami mengucapkan terima kasih.',
            style: TextStyle(fontSize: 10, height: 1.4),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 20),
          // Blok TTE digital
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    color: Colors.black87,
                    child: const Icon(Icons.qr_code_2, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('TTE VERIFIED', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                        Text('Dekan FT UMB', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowDetailSurat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))),
          const Text(': ', style: TextStyle(fontSize: 9)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  /// Lini Masa / Tracking Timeline (Jika Diproses)
  Widget _buildTrackingTimeline(Map<String, dynamic> surat) {
    final String judul = (surat['judul'] ?? 'Tanpa Judul').toString();
    final String instansi = (surat['instansi_tujuan'] ?? 'PT. Krakatau Steel (Persero)').toString();
    final String tipe = (surat['tipe'] ?? 'Umum').toString();
    final String tujuan = (surat['tujuan_penelitian'] ?? 'Sistem Informasi Manajemen').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Text('Instansi: $instansi', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text('Kategori: $tipe', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text('Fokus Riset: $tujuan', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Pelacakan Dokumen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        _buildTimelineStep('Diajukan', 'Pengajuan berhasil dikirim oleh Mahasiswa.', true, true),
        _buildTimelineStep('Verifikasi Fakultas', 'Sedang diperiksa oleh Admin/Koordinator Program Studi.', false, true),
        _buildTimelineStep('Tanda Tangan Pimpinan', 'Menunggu persetujuan & tanda tangan elektronik Dekan.', false, false),
        _buildTimelineStep('Selesai', 'Surat resmi diterbitkan & siap diunduh.', false, false, isLast: true),
      ],
    );
  }

  Widget _buildTimelineStep(String title, String desc, bool isCompleted, bool isActive, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.blue : (isActive ? Colors.orange : Colors.grey.shade300),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.radio_button_checked,
                size: 12,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 35,
                color: isCompleted ? Colors.blue : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 12,
                  color: isActive ? Colors.black87 : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 12),
            ],
          ),
        )
      ],
    );
  }

  /// 4. Formulir Pengajuan Baru (Bottom Sheet)
  void _showFormFormulirBaru(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Center(
                  child: Text(
                    'Pengajuan Surat Baru',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Jenis Surat PKL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: 'Surat Pengantar Magang Industri',
                  items: const [
                    DropdownMenuItem(value: 'Surat Pengantar Magang Industri', child: Text('Surat Pengantar Magang')),
                    DropdownMenuItem(value: 'Surat Permohonan Izin Penelitian', child: Text('Surat Izin Penelitian')),
                  ],
                  onChanged: (v) {},
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Nama Instansi / Perusahaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Contoh: PT. Pertamina (Persero)',
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Fokus Riset / Judul Penelitian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Contoh: Pengembangan UI/UX sistem pendaftaran',
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Permohonan berhasil diajukan ke sistem!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Kirim Pengajuan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}