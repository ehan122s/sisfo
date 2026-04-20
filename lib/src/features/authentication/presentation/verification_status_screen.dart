import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationStatusScreen extends StatelessWidget {
  final String? status;
  final String? message;

  const VerificationStatusScreen({
    super.key,
    this.status,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ilustrasi / Icon
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.person_search_rounded,
                        size: 80,
                        color: Color(0xFF2563EB),
                      ),
                      Positioned(
                        bottom: 25,
                        right: 25,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.access_time_filled,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              // Teks Status
              Text(
                status ?? 'Akun Sedang Diverifikasi',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message ?? 'Halo! Pendaftaran Anda telah kami terima. Saat ini Admin atau Guru Pembimbing sedang mengecek kecocokan data Anda.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Card Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  children: [
                    _buildInfoItem(Icons.info_outline, 'Estimasi waktu: 1-2 hari kerja'),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildInfoItem(Icons.notifications_active_outlined, 'Kami akan mengirimkan notifikasi jika akun sudah aktif'),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Tombol Kembali
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'KEMBALI KE LOGIN',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Text(
                'Butuh bantuan cepat? Hubungi Admin Sekolah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}