import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // State variables
  bool _notifEnabled = true;
  bool _biometricEnabled = false;
  bool _darkModeEnabled = false;
  bool _loadingProfile = true;
  bool _savingChanges = false;
  Map<String, dynamic>? _profile;
  
  // Controllers untuk edit profil
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _classController;
  late TextEditingController _nisnController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _classController = TextEditingController();
    _nisnController = TextEditingController();
    _loadSettings();
    _fetchProfile();
    _checkBiometricSupport();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _classController.dispose();
    _nisnController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  // LOAD SETTINGS DARI LOCAL STORAGE
  // ════════════════════════════════════════════════════════════════

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _notifEnabled = prefs.getBool('notif_enabled') ?? true;
        _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
        _darkModeEnabled = prefs.getBool('dark_mode') ?? false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      }
      
      debugPrint('Saved setting: $key = $value');
    } catch (e) {
      debugPrint('Error saving setting $key: $e');
      _showSnackBar('Gagal menyimpan pengaturan', isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // BIOMETRIC AUTHENTICATION - ✅ FIXED (Basic Version)
  // ════════════════════════════════════════════════════════════════

  Future<void> _checkBiometricSupport() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported && mounted) {
        setState(() => _biometricEnabled = false);
      }
    } catch (e) {
      debugPrint('Biometric check error: $e');
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (!enabled) {
      setState(() => _biometricEnabled = false);
      await _saveSetting('biometric_enabled', false);
      return;
    }

    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      
      if (!isAvailable || !isSupported) {
        _showSnackBar('Perangkat ini tidak mendukung biometrik', isError: true);
        return;
      }

      // ✅ FIXED: Hanya gunakan localizedReason (basic version)
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verifikasi untuk mengaktifkan login biometrik',
      );

      if (authenticated && mounted) {
        setState(() => _biometricEnabled = true);
        await _saveSetting('biometric_enabled', true);
        _showSnackBar('✅ Login biometrik berhasil diaktifkan!');
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric error: ${e.message}');
      setState(() => _biometricEnabled = false);
      _showSnackBar('Gagal mengaktifkan biometrik: ${e.message}', isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // FETCH & UPDATE PROFILE
  // ════════════════════════════════════════════════════════════════

  Future<void> _fetchProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select('''
            full_name, role, avatar_url, status, is_verified, 
            phone_number, class_name, nisn
          ''')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _profile = data;
          _loadingProfile = false;
          
          // Set controllers
          _nameController.text = data['full_name'] ?? '';
          _phoneController.text = data['phone_number'] ?? '';
          _classController.text = data['class_name'] ?? '';
          _nisnController.text = data['nisn'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Fetch profile error: $e');
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _updateProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Nama wajib diisi!', isError: true);
      return;
    }

    setState(() => _savingChanges = true);

    try {
      final updateData = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
      };

      // Student-specific fields
      final role = _profile?['role'];
      if (role == 'student') {
        updateData['class_name'] = _classController.text.trim();
        updateData['nisn'] = _nisnController.text.trim();
      }

      await supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);

      if (mounted) {
        _showSnackBar('✅ Profil berhasil diperbarui!');
        Navigator.pop(context);
        _fetchProfile();
      }
    } on PostgrestException catch (e) {
      _showSnackBar('Error: ${e.message}', isError: true);
    } catch (e) {
      _showSnackBar('Gagal memperbarui profil: $e', isError: true);
    } finally {
      if (mounted) setState(() => _savingChanges = false);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CHANGE PASSWORD
  // ════════════════════════════════════════════════════════════════

  Future<void> _resetPassword() async {
    final user = supabase.auth.currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      _showSnackBar('Email tidak ditemukan', isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Link reset password akan dikirim ke:\n\n$email',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Kirim Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await supabase.auth.resetPasswordForEmail(email);
      
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('✅ Link reset password telah dikirim ke $email');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Gagal mengirim link: $e', isError: true);
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // DARK MODE TOGGLE
  // ════════════════════════════════════════════════════════════════

  void _toggleDarkMode(bool enabled) async {
    setState(() => _darkModeEnabled = enabled);
    await _saveSetting('dark_mode', enabled);
    _showSnackBar(enabled ? '🌙 Mode gelap diaktifkan' : '☀️ Mode terang diaktifkan');
  }

  // ════════════════════════════════════════════════════════════════
  // HELP & ABOUT
  // ════════════════════════════════════════════════════════════════

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.help_center_rounded, size: 60, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Bantuan & Dokumentasi',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _helpItem(Icons.person_search, 'Cara Penggunaan', 
                'Pelajari cara menggunakan aplikasi e-PKL'),
            _helpItem(Icons.book, 'Panduan Siswa', 
                'Panduan lengkap untuk siswa PKL'),
            _helpItem(Icons.school, 'Panduan Guru', 
                'Panduan untuk guru pembimbing'),
            _helpItem(Icons.admin_panel_settings, 'Panduan Admin', 
                'Panduan administrasi sistem'),
            _helpItem(Icons.contact_support, 'Hubungi Support', 
                'support@epkl-school.id'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Tutup'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpItem(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.1),
        child: Icon(icon, color: Colors.blue.shade700, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        _showSnackBar('Membuka $title...');
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'e-PKL',
      applicationVersion: 'v1.0.0 (Build 2024.01)',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue, Colors.blue.shade700]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.school_rounded, color: Colors.white, size: 35),
      ),
      children: [
        const SizedBox(height: 12),
        const Text(
          'Aplikasi e-PKL adalah sistem informasi untuk mengelola kegiatan Praktik Kerja Lapangan (PKL) secara digital.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Divider(),
        _aboutRow('Dikembangkan oleh', 'Tim IT Sekolah'),
        _aboutRow('Framework', 'Flutter + Supabase'),
        _aboutRow('Lisensi', 'MIT License 2024'),
        _aboutRow('Server', 'Supabase Cloud'),
      ],
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // EDIT PROFILE DIALOG
  // ════════════════════════════════════════════════════════════════

  void _showEditProfileDialog() {
    _nameController.text = _profile?['full_name'] ?? '';
    _phoneController.text = _profile?['phone_number'] ?? '';
    _classController.text = _profile?['class_name'] ?? '';
    _nisnController.text = _profile?['nisn'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Profil',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(),
              
              const SizedBox(height: 16),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap *',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'No. HP',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      
                      if (_profile?['role'] == 'student') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _classController,
                          decoration: InputDecoration(
                            labelText: 'Kelas',
                            prefixIcon: const Icon(Icons.school_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nisnController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'NISN',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _savingChanges ? null : _updateProfile,
                  icon: _savingChanges 
                      ? const SizedBox(
                          width: 18, 
                          height: 18, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _savingChanges ? 'Menyimpan...' : 'Simpan Perubahan',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LOGOUT
  // ════════════════════════════════════════════════════════════════

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade700),
            const SizedBox(width: 12),
            const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun ini?\n\n'
          'Anda perlu login kembali untuk mengakses aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await supabase.auth.signOut();
      
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar('Gagal logout: $e', isError: true);
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SNACKBAR HELPER
  // ════════════════════════════════════════════════════════════════

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD UI
  // ════════════════════════════════════════════════════════════════

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
        actions: [
          IconButton(
            onPressed: _showEditProfileDialog,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profil',
          ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator.adaptive())
          : RefreshIndicator(
              onRefresh: _fetchProfile,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildUserProfile(user),
                  
                  const SizedBox(height: 32),
                  
                  _sectionTitle("Informasi Akun"),
                  _buildInfoCard(),
                  
                  _buildActionTile(
                    Icons.edit_note_rounded,
                    "Edit Profil",
                    _showEditProfileDialog,
                    trailingText: 'Ubah data diri',
                  ),
                  
                  const SizedBox(height: 32),
                  
                  _sectionTitle("Preferensi"),
                  
                  _buildSwitchTile(
                    Icons.notifications_active_rounded,
                    "Push Notifications",
                    "Notifikasi untuk jurnal & presensi baru",
                    _notifEnabled,
                    (v) async {
                      setState(() => _notifEnabled = v);
                      await _saveSetting('notif_enabled', v);
                      if (v) {
                        _showSnackBar('🔔 Notifikasi diaktifkan');
                      } else {
                        _showSnackBar('🔕 Notifikasi dinonaktifkan');
                      }
                    },
                  ),
                  
                  _buildSwitchTile(
                    Icons.fingerprint_rounded,
                    "Login Biometrik",
                    "Masuk menggunakan FaceID / TouchID",
                    _biometricEnabled,
                    _toggleBiometric,
                  ),
                  
                  _buildSwitchTile(
                    Icons.dark_mode_rounded,
                    "Mode Gelap",
                    "Tampilan tema gelap pada aplikasi",
                    _darkModeEnabled,
                    _toggleDarkMode,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  _sectionTitle("Keamanan"),
                  
                  _buildActionTile(
                    Icons.lock_reset_rounded,
                    "Ganti Password",
                    _resetPassword,
                    trailingText: 'Kirim link reset',
                  ),
                  
                  const SizedBox(height: 32),
                  
                  _sectionTitle("Dukungan"),
                  
                  _buildActionTile(
                    Icons.help_center_rounded,
                    "Bantuan & Dokumentasi",
                    _showHelpDialog,
                    trailingText: 'FAQ & Panduan',
                  ),
                  
                  _buildActionTile(
                    Icons.info_outline_rounded,
                    "Tentang Aplikasi",
                    _showAboutDialog,
                    trailingText: 'e-PKL v1.0.0',
                  ),
                  
                  _buildActionTile(
                    Icons.privacy_tip_outlined,
                    "Kebijakan Privasi",
                    () {
                      _showSnackBar('Membuka kebijakan privasi...');
                    },
                    trailingText: 'Baca kebijakan',
                  ),
                  
                  const SizedBox(height: 40),
                  
                  _buildLogoutButton(),
                  
                  const SizedBox(height: 40),
                  
                  Center(
                    child: Text(
                      'e-PKL v1.0.0 • Build 2024.01.15',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGET COMPONENTS
  // ════════════════════════════════════════════════════════════════

  Widget _buildUserProfile(User? user) {
    final String fullName = _profile?['full_name'] ?? user?.email ?? 'Pengguna';
    final String role = _profile?['role'] ?? 'user';
    final String? avatarUrl = _profile?['avatar_url'];
    final bool isVerified = _profile?['is_verified'] ?? false;
    final bool isActive = (_profile?['status'] ?? 'active') == 'active';

    final roleLabel = {
      'admin': 'Administrator',
      'teacher': 'Guru Pembimbing',
      'student': 'Siswa PKL',
    }[role] ?? role;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0F172A), const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade700],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade300, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl!,
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
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0F172A),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 18),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '-',
                  style: TextStyle(
                    color: Colors.blue.shade200,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        roleLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? Icons.check_circle : Icons.cancel,
                            size: 12,
                            color: isActive 
                                ? Colors.green.shade300 
                                : Colors.red.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                              fontSize: 11,
                              color: isActive
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
          fontSize: 26,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final role = _profile?['role'] ?? '';
    final isStudent = role == 'student';

    final items = <Map<String, dynamic>>[
      {
        'icon': Icons.email_outlined,
        'label': 'Email',
        'value': supabase.auth.currentUser?.email ?? '-',
      },
      {
        'icon': Icons.phone_outlined,
        'label': 'No. HP',
        'value': _profile?['phone_number'] ?? 'Belum diisi',
      },
      if (isStudent) ...[
        {
          'icon': Icons.school_outlined,
          'label': 'Kelas',
          'value': _profile?['class_name'] ?? '-',
        },
        {
          'icon': Icons.badge_outlined,
          'label': 'NISN',
          'value': _profile?['nisn'] ?? '-',
        },
      ],
      {
        'icon': Icons.verified_user_outlined,
        'label': 'Status Verifikasi',
        'value': (_profile?['is_verified'] == true) ? 'Terverifikasi' : 'Belum',
      },
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 18,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item['label'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Text(
                    item['value'] as String,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
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
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String sub,
    bool val,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: SwitchListTile(
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: val ? Colors.blue.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, 
            size: 20, 
            color: val ? Colors.blue : Colors.grey,
          ),
        ),
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

  Widget _buildActionTile(
    IconData icon, 
    String title, 
    VoidCallback onTap, {
    String? trailingText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF1E293B), size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: trailingText != null
            ? Text(
                trailingText,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              )
            : null,
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          "Keluar dari Akun",
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.shade200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}