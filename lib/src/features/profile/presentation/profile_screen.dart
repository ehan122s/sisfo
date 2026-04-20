import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // TAMBAH INI
import '../../../services/supabase_config.dart';
import '../../authentication/data/auth_repository.dart';

const kPrimaryNavy = Color(0xFF0F172A);
const kAccentBlue = Color(0xFFD1E9FF);
const kPrimaryBlue = Color(0xFF1976D2);
const kDarkBlue = Color(0xFF0D47A1);

final profileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) throw Exception('No user');

  final data = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();
  return data;
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('No user');

      final bytes = await picked.readAsBytes();
      final fileExt = picked.name.split('.').last;
      final fileName = '${user.id}/avatar.$fileExt';

      // Upload ke Supabase Storage
      await supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true), // FIX: pakai const
          );

      // Ambil public URL
      final avatarUrl =
          supabase.storage.from('avatars').getPublicUrl(fileName);

      // Update kolom avatar_url di tabel profiles
      await supabase
          .from('profiles')
          .update({'avatar_url': avatarUrl}).eq('id', user.id);

      // Refresh provider
      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Foto profil berhasil diperbarui!',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal upload foto: $e',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3F2FD), Color(0xFFF8FBFF)],
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header biru
                    _buildHeader(),

                    // Profile Card
                    Transform.translate(
                      offset: const Offset(0, -40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: profileAsync.when(
                          data: (data) => _buildProfileCard(data),
                          loading: () => _buildLoadingCard(),
                          error: (e, _) => _buildErrorCard(),
                        ),
                      ),
                    ),

                    // Menu items
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildMenuCard(),
                            const SizedBox(height: 16),
                            _buildLogoutButton(),
                            const SizedBox(height: 20),
                            Text(
                              '© 2026 SMKN 1 GARUT',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kDarkBlue, kPrimaryBlue, Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil Saya',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Kelola informasi akunmu',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> data) {
    final avatarUrl = data['avatar_url'] as String?;
    final name = data['full_name'] ?? 'Siswa Magang';
    final nisn = data['nisn'] ?? '-';
    final className = data['class_name'] ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar dengan tombol upload
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kPrimaryBlue.withOpacity(0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryBlue.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _isUploading
                      ? Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: kPrimaryBlue,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : avatarUrl != null
                          ? Image.network(
                              // tambahkan cache buster biar langsung update
                              '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _defaultAvatar(name),
                            )
                          : _defaultAvatar(name),
                ),
              ),

              // Tombol kamera
              GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadAvatar,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isUploading ? Colors.grey : kPrimaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isUploading
                        ? Icons.hourglass_top_rounded
                        : Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Nama
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimaryNavy,
            ),
          ),

          const SizedBox(height: 4),

          // NISN
          Text(
            'NISN: $nisn',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),

          const SizedBox(height: 12),

          // Badge kelas
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kDarkBlue, kPrimaryBlue],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              className,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info upload
          if (!_isUploading)
            Text(
              'Ketuk ikon kamera untuk ganti foto',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kPrimaryBlue.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Mengupload foto...',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: kPrimaryBlue,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(String name) {
    return Container(
      color: kAccentBlue,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: kDarkBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: kPrimaryBlue),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(
            'Gagal memuat profil',
            style: GoogleFonts.poppins(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile(
            icon: LucideIcons.settings,
            title: 'Pengaturan Akun',
            subtitle: 'Ubah password & data diri',
            onTap: () {},
            isFirst: true,
          ),
          Divider(height: 1, color: Colors.grey[100]),
          _buildMenuTile(
            icon: LucideIcons.helpCircle,
            title: 'Pusat Bantuan',
            subtitle: 'FAQ & kontak admin',
            onTap: () {},
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kPrimaryBlue, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: kPrimaryNavy,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await ref.read(authRepositoryProvider).signOut();
          if (context.mounted) context.go('/login');
        },
        icon: const Icon(LucideIcons.logOut, size: 18),
        label: Text(
          'KELUAR APLIKASI',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}