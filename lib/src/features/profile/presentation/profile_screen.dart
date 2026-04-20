import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/supabase_config.dart';
import '../../authentication/data/auth_repository.dart';
import '../../../common_widgets/custom_network_image.dart';

// Palette warna berdasarkan login
const kPrimaryNavy = Color(0xFF0F172A); // Warna tombol 'Masuk'
const kAccentBlue = Color(0xFFD1E9FF); // Warna lingkaran background login

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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Background abu sangat muda agar card terlihat menonjol
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: kPrimaryNavy, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kPrimaryNavy),
      ),
      body: Stack(
        children: [
          // Aksen lingkaran biru muda di pojok kiri atas (mirip halaman login)
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: kAccentBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Card dengan styling mirip form login
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      40,
                    ), // Border radius besar sesuai UI login
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: profileAsync.when(
                    data: (data) => Column(
                      children: [
                        // Avatar dengan aksen biru muda
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: kAccentBlue,
                            shape: BoxShape.circle,
                          ),
                          child: data['avatar_url'] != null
                              ? CustomNetworkImage(
                                  imageUrl: data['avatar_url'],
                                  width: 100,
                                  height: 100,
                                  isCircle: true,
                                )
                              : const CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    LucideIcons.user,
                                    size: 50,
                                    color: kPrimaryNavy,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          data['full_name'] ?? 'Siswa Magang',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['nisn'] ?? 'NISN Tidak Diketahui',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Badge Kelas dengan warna Navy
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryNavy,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            data['class_name'] ?? 'Kelas -',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: kPrimaryNavy),
                    ),
                    error: (e, _) =>
                        const Center(child: Text('Gagal memuat profil')),
                  ),
                ),

                const SizedBox(height: 32),

                // Action Tiles
                _buildActionTile(
                  icon: LucideIcons.settings,
                  title: "Pengaturan Akun",
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  icon: LucideIcons.helpCircle,
                  title: "Pusat Bantuan",
                  onTap: () {},
                ),

                const SizedBox(height: 32),

                // Logout Button (Warna Navy agar konsisten dengan tombol 'Masuk')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(LucideIcons.logOut, size: 20),
                    label: const Text(
                      'KELUAR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.all(18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Footer text
                Text(
                  "© 2026 SMKN 1 GARUT",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: kPrimaryNavy, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: kPrimaryNavy,
          ),
        ),
        trailing: const Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
