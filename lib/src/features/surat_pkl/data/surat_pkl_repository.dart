import 'package:flutter_riverpod/flutter_riverpod.dart';

// Menyiapkan tiruan data pengajuan surat PKL dari database
final daftarSuratProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Menyimulasikan waktu tunggu loading data dari internet/Supabase
  await Future.delayed(const Duration(milliseconds: 800));

  // Mengembalikan list data surat tiruan agar tampilan tidak kosong
  return [
    {
      'judul': 'Surat Pengantar Magang Industri',
      'tipe': 'Instansi Perusahaan',
      'status': 'Diproses',
    },
    {
      'judul': 'Surat Permohonan Izin Penelitian',
      'tipe': 'Umum',
      'status': 'Disetujui',
    },
  ];
});