import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _notifEnabled = true;
  bool _biometricEnabled = false;
  Map<String, dynamic>? _profile;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loadingProfile = false);
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select(
            'full_name, role, avatar_url, status, is_verified, phone_number, class_name, nisn',
          )
          .eq('id', userId)
          .single();
      setState(() {
        _profile = data;
        _loadingProfile = false;
      });
    } catch (e) {
      setState(() => _loadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Pengaturan",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildUserProfile(user),
                const SizedBox(height: 32),
                _sectionTitle("Informasi Akun"),
                _buildInfoCard(),
                const SizedBox(height: 32),
                _sectionTitle("Preferensi"),
                _buildSwitchTile(
                  "Push Notifications",
                  "Notifikasi untuk jurnal & presensi baru",
                  _notifEnabled,
                  (v) => setState(() => _notifEnabled = v),
                ),
                _buildSwitchTile(
                  "Biometric Access",
                  "Masuk menggunakan FaceID / TouchID",
                  _biometricEnabled,
                  (v) => setState(() => _biometricEnabled = v),
                ),
                const SizedBox(height: 32),
                _sectionTitle("Keamanan & Dukungan"),
                _buildActionTile(
                  Icons.lock_outline_rounded,
                  "Ganti Password",
                  () async {
                    final email = user?.email;
                    if (email != null) {
                      await supabase.auth.resetPasswordForEmail(email);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Link reset password dikirim ke email kamu",
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                _buildActionTile(
                  Icons.help_center_outlined,
                  "Bantuan & Dokumentasi",
                  () {},
                ),
                _buildActionTile(
                  Icons.info_outline_rounded,
                  "Versi Aplikasi e-PKL v1.0.0",
                  () {},
                ),
                const SizedBox(height: 40),
                _buildLogoutButton(context),
              ],
            ),
    );
  }

  Widget _buildUserProfile(User? user) {
    final String fullName = _profile?['full_name'] ?? user?.email ?? 'Pengguna';
    final String role = _profile?['role'] ?? 'user';
    final String? avatarUrl = _profile?['avatar_url'];
    final bool isVerified = _profile?['is_verified'] ?? false;
    final bool isActive = (_profile?['status'] ?? 'active') == 'active';

    final roleLabel =
        {
          'admin': 'Administrator',
          'teacher': 'Guru Pembimbing',
          'student': 'Siswa PKL',
        }[role] ??
        role;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade400, width: 2),
                ),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _avatarInitialWidget(fullName),
                        ),
                      )
                    : _avatarInitialWidget(fullName),
              ),
              if (isVerified)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0F172A),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 18),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '-',
                  style: TextStyle(
                    color: Colors.blue.shade200,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        roleLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive
                              ? Colors.green.shade300
                              : Colors.red.shade300,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarInitialWidget(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 22,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final role = _profile?['role'] ?? '';
    final isStudent = role == 'student';

    final items = <Map<String, dynamic>>[
      {
        'icon': Icons.phone_outlined,
        'label': 'No. HP',
        'value': _profile?['phone_number'] ?? '-',
      },
      if (isStudent) ...[
        {
          'icon': Icons.class_outlined,
          'label': 'Kelas',
          'value': _profile?['class_name'] ?? '-',
        },
        {
          'icon': Icons.badge_outlined,
          'label': 'NISN',
          'value': _profile?['nisn'] ?? '-',
        },
      ],
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: 18,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Text(
                  item['label'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  item['value'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 14),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String sub,
    bool val,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          sub,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        value: val,
        onChanged: onChanged,
        activeColor: Colors.blue,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF1E293B), size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Keluar",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: const Text(
                "Apakah kamu yakin ingin keluar dari akun ini?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    "Keluar",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await supabase.auth.signOut();
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          "Keluar",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red.shade200),
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
