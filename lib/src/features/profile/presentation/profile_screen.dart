import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/supabase_config.dart';
import '../../authentication/data/auth_repository.dart';
import '../../../common_widgets/custom_network_image.dart';

// Simple Provider to fetch profile data
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
      appBar: AppBar(title: const Text('Profil Saya'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: profileAsync.when(
                data: (data) => Column(
                  children: [
                    if (data['avatar_url'] != null)
                      CustomNetworkImage(
                        imageUrl: data['avatar_url'],
                        width: 100,
                        height: 100,
                        isCircle: true,
                      )
                    else
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(
                          LucideIcons.user,
                          size: 50,
                          color: Color(0xFF006400),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      data['full_name'] ?? 'Siswa Magang',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['nisn'] ?? 'NISN Tidak Diketahui',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006400).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data['class_name'] ?? 'Kelas -',
                        style: const TextStyle(
                          color: Color(0xFF006400),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    const Center(child: Text('Gagal memuat profil')),
              ),
            ),

            const SizedBox(height: 32),

            // Settings / Actions
            _buildActionTile(
              icon: LucideIcons.settings,
              title: "Pengaturan",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Menu Pengaturan belum tersedia"),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              icon: LucideIcons.helpCircle,
              title: "Bantuan",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bantuan belum tersedia")),
                );
              },
            ),

            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(LucideIcons.logOut),
                label: const Text('Keluar Aplikasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.black87, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(LucideIcons.chevronRight, size: 16),
        onTap: onTap,
      ),
    );
  }
}
