import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/supabase_config.dart';
import '../../authentication/data/auth_repository.dart';
import '../../../common_widgets/custom_network_image.dart';

// =====================
// 🎨 WARNA BARU (SESUI LOGIN)
// =====================
class ProfileColors {
  static const navy = Color(0xFF0F172A); // utama (button login)
  static const softNavy = Color(0xFF1E293B);

  static const lightGrey = Color(0xFFF1F5F9); // background
  static const cardGrey = Color(0xFFF8FAFC); // card

  static const darkGrey = Color(0xFF334155); // text
  static const white = Colors.white;
}

// =====================
// 📦 PROVIDER
// =====================
final profileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) throw Exception('No user');

  final data = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return data;
});

// =====================
// 🧑‍💻 SCREEN
// =====================
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: ProfileColors.lightGrey,
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: ProfileColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: ProfileColors.navy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit3,
                color: ProfileColors.white),
            onPressed: () {},
          )
        ],
      ),

      // =====================
      // BODY
      // =====================
      body: SingleChildScrollView(
        child: Column(
          children: [
            // =====================
            // HEADER (NAVY BACKGROUND)
            // =====================
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    color: ProfileColors.navy,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  child: _buildProfileImage(profileAsync),
                ),
              ],
            ),

            const SizedBox(height: 80),

            // =====================
            // INFO USER
            // =====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: profileAsync.when(
                data: (data) => Column(
                  children: [
                    Text(
                      data['full_name'] ?? 'Siswa Magang',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ProfileColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "NISN: ${data['nisn'] ?? '-'}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: ProfileColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Badge Kelas
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: ProfileColors.navy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        data['class_name'] ?? 'Kelas -',
                        style: const TextStyle(
                          color: ProfileColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () =>
                    const CircularProgressIndicator(),
                error: (e, _) =>
                    const Text('Gagal memuat detail'),
              ),
            ),

            const SizedBox(height: 32),

            // =====================
            // CARD MENU
            // =====================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PENGATURAN AKUN",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ProfileColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildActionTile(
                    icon: LucideIcons.settings,
                    title: "Pengaturan Aplikasi",
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),

                  _buildActionTile(
                    icon: LucideIcons.shieldCheck,
                    title: "Keamanan & Privasi",
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),

                  _buildActionTile(
                    icon: LucideIcons.helpCircle,
                    title: "Pusat Bantuan",
                    onTap: () {},
                  ),

                  const SizedBox(height: 40),

                  // =====================
                  // LOGOUT BUTTON
                  // =====================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(authRepositoryProvider)
                            .signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      icon: const Icon(
                        LucideIcons.logOut,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'LOGOUT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ProfileColors.navy,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================
  // PROFILE IMAGE
  // =====================
  Widget _buildProfileImage(
      AsyncValue<Map<String, dynamic>> profileAsync) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: ProfileColors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: profileAsync.when(
        data: (data) => data['avatar_url'] != null
            ? CustomNetworkImage(
                imageUrl: data['avatar_url'],
                width: 100,
                height: 100,
                isCircle: true,
              )
            : const CircleAvatar(
                radius: 50,
                backgroundColor:
                    ProfileColors.cardGrey,
                child: Icon(
                  LucideIcons.user,
                  size: 50,
                  color: ProfileColors.navy,
                ),
              ),
        loading: () => const CircleAvatar(
          radius: 50,
          child: CircularProgressIndicator(),
        ),
        error: (_, __) => const CircleAvatar(
          radius: 50,
          child: Icon(LucideIcons.user),
        ),
      ),
    );
  }

  // =====================
  // MENU TILE
  // =====================
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ProfileColors.cardGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
                horizontal: 20, vertical: 6),
        leading: Icon(icon,
            color: ProfileColors.softNavy, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: ProfileColors.darkGrey,
        ),
        onTap: onTap,
      ),
    );
  }
}