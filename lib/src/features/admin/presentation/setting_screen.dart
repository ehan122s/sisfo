import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:go_router/go_router.dart';

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
  bool _isBiometricSupported = false; // ✅ Track biometric support
  String _biometricType = ''; // ✅ Type of biometric available

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
    _checkBiometricSupport(); // ✅ Check on init
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
  // ✅ BIOMETRIC AUTHENTICATION - FULL VERSION WITH DEVICE CHECK
  // ════════════════════════════════════════════════════════════════

  /// Cek apakah device mendukung biometrik dan dapatkan jenisnya
  Future<void> _checkBiometricSupport() async {
    try {
      debugPrint('🔍 Checking biometric support...');

      // 1. Cek apakah hardware mendukung biometrik
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      debugPrint('📱 Device supported: $isDeviceSupported');

      if (!isDeviceSupported) {
        debugPrint('❌ Device does NOT support biometric');
        if (mounted) {
          setState(() {
            _isBiometricSupported = false;
            _biometricType = '';
            _biometricEnabled = false;
          });
          await _saveSetting('biometric_enabled', false);
        }
        return;
      }

      // 2. Cek apakah biometrik tersedia (sudah di-setup oleh user)
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      debugPrint('🔐 Can check biometrics: $canCheckBiometrics');

      if (!canCheckBiometrics) {
        debugPrint('⚠️ Biometrics not enrolled/setup yet');
        if (mounted) {
          setState(() {
            _isBiometricSupported = true; // Device support, but not enrolled
            _biometricType = 'not_enrolled';
            _biometricEnabled = false;
          });
          await _saveSetting('biometric_enabled', false);
        }
        return;
      }

      // 3. Dapatkan list jenis biometrik yang tersedia
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      debugPrint('🧬 Available biometrics: $availableBiometrics');

      String biometricTypeName = '';

      if (availableBiometrics.contains(BiometricType.face)) {
        biometricTypeName = 'Face ID / Face Unlock';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        biometricTypeName = 'Fingerprint / Sidik Jari';
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        biometricTypeName = 'Iris Scanner';
      } else if (availableBiometrics.isNotEmpty) {
        biometricTypeName = 'Biometrik';
      }

      debugPrint('✅ Biometric type detected: $biometricTypeName');

      if (mounted) {
        setState(() {
          _isBiometricSupported = true;
          _biometricType = biometricTypeName;
          // Jika sebelumnya enabled tapi sekarang tidak available, disable
          if (_biometricEnabled && biometricTypeName.isEmpty) {
            _biometricEnabled = false;
            _saveSetting('biometric_enabled', false);
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking biometric support: $e');
      if (mounted) {
        setState(() {
          _isBiometricSupported = false;
          _biometricType = '';
          _biometricEnabled = false;
        });
      }
    }
  }

  /// Toggle biometric on/off
  Future<void> _toggleBiometric(bool enabled) async {
    // Jika menonaktifkan
    if (!enabled) {
      setState(() => _biometricEnabled = false);
      await _saveSetting('biometric_enabled', false);
      _showSnackBar('🔒 Login biometrik dinonaktifkan');
      return;
    }

    // ─── CEK KEMBALI SUPPORT SEBELUM AKTIFKAN ───

    // Refresh check terlebih dahulu
    await _checkBiometricSupport();

    if (!_isBiometricSupported) {
      _showNotSupportedDialog();
      return;
    }

    if (_biometricType == 'not_enrolled') {
      _showNotEnrolledDialog();
      return;
    }

    // Tampilkan dialog konfirmasi
    final confirmAuth = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.fingerprint, color: Colors.blue.shade700, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Aktifkan Biometrik',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Untuk mengaktifkan login biometrik, silakan verifikasi identitas Anda.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Metode: $_biometricType',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            // ✅ FIXED: verified_rounded (bukan verify_rounded)
            icon: const Icon(Icons.verified_rounded, size: 18),
            label: const Text('Verifikasi Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmAuth != true) return;

    // Tampilkan scanning dialog
    _showScanningDialog();

    try {
      // Jalankan autentikasi
      final authenticated = await _localAuth.authenticate(
        localizedReason:
            'Verifikasi untuk mengaktifkan login biometrik di e-PKL',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow fallback ke PIN/Pattern jika perlu
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );

      // Tutup scanning dialog
      if (mounted) Navigator.pop(context);

      if (authenticated && mounted) {
        setState(() => _biometricEnabled = true);
        await _saveSetting('biometric_enabled', true);

        _showSnackBar('✅ Login biometrik berhasil diaktifkan!');

        // Success dialog
        _showSuccessDialog();
      }
    } on PlatformException catch (e) {
      // Tutup scanning dialog
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}

        setState(() => _biometricEnabled = false);
        _handleBiometricError(e);
      }
    } catch (e) {
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
        setState(() => _biometricEnabled = false);
        _showSnackBar('❌ Gagal: ${e.toString()}', isError: true);
      }
    }
  }

  /// Handle biometric errors dengan pesan yang jelas
  void _handleBiometricError(PlatformException e) {
    String title = 'Gagal Autentikasi';
    String message;
    IconData icon = Icons.error_outline;

    switch (e.code) {
      case 'NotAvailable':
        title = 'Tidak Tersedia';
        message = 'Biometrik tidak tersedia di perangkat ini saat ini.';
        icon = Icons.device_unknown;
        break;
      case 'NotEnrolled':
        title = 'Belum Terdaftar';
        message =
            'Anda belum mendaftarkan sidik jari/wajah.\n\n'
            'Silakan buka Pengaturan → Keamanan/Password & Biometrik → '
            'Tambahkan Finger/Face ID.';
        icon = Icons.person_add_disabled;
        break;
      case 'LockedOut':
        title = 'Terlalu Banyak Percobaan';
        message =
            'Terlalu banyak percobaan gagal.\n\nSilakan coba lagi dalam 30 detik, '
            'atau gunakan PIN/Password perangkat Anda.';
        icon = Icons.lock_clock;
        break;
      case 'PermanentlyLockedOut':
        title = 'Biometrik Terkunci';
        message =
            'Biometrik terkunci karena terlalu banyak percobaan.\n\n'
            'Gunakan PIN/Password perangkat Anda untuk membuka kunci, '
            'lalu coba lagi.';
        icon = Icons.lock;
        break;
      case 'PasscodeNotSet':
        title = 'PIN Belum Diatur';
        message =
            'Anda harus mengatur lock screen (PIN/Pattern/Password) '
            'terlebih dahulu sebelum menggunakan biometrik.\n\n'
            'Buka Pengaturan → Keamanan → Lock Screen.';
        icon = Icons.password;
        break;
      case 'Canceled':
      case 'UserCancel':
        return; // User cancel, tidak perlu show error
      default:
        message = e.message ?? 'Terjadi kesalahan saat autentikasi biometrik.';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: Colors.orange.shade700, size: 26),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  /// Dialog ketika device tidak support biometrik
  void _showNotSupportedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.devices_other, color: Colors.grey.shade600, size: 26),
            const SizedBox(width: 12),
            const Text(
              'Tidak Didukung',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maaf, perangkat Anda tidak mendukung autentikasi biometrik.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '💡 Tips:\n'
                '• Pastikan HP memiliki sensor fingerprint atau camera depan untuk Face Unlock\n'
                '• Beberapa HP lawas mungkin tidak support fitur ini\n'
                '• Gunakan login biasa (email/password) sebagai alternatif',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  /// Dialog ketika biometrik belum didaftarkan/di-setup
  void _showNotEnrolledDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            // ✅ FIXED: fingerprint_outlined (bukan fingerprint_off)
            Icon(
              Icons.fingerprint_outlined,
              color: Colors.orange.shade700,
              size: 26,
            ),
            const SizedBox(width: 12),
            const Text(
              'Belum Setup Biometrik',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Perangkat Anda mendukung biometrik, tetapi belum ada sidik jari atau wajah yang terdaftar.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildSetupGuide(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Nanti Saja',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openDeviceSettings();
            },
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Buka Pengaturan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget panduan setup biometrik berdasarkan platform
  Widget _buildSetupGuide() {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.orange.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Cara Setup ${isAndroid ? '(Android)' : '(iOS)'}:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._getSetupSteps(isAndroid).map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getSetupSteps(bool isAndroid) {
    if (isAndroid) {
      return [
        'Buka Pengaturan (Settings)',
        'Pilih "Keamanan" atau "Password & Keamanan"',
        'Pilih "Fingerprint" atau "Sidik Jari"',
        'Ikuti instruksi untuk mendaftarkan sidik jari',
        'Untuk Face Unlock: Pilih "Face Recognition"',
      ];
    } else {
      return [
        'Buka Settings (Pengaturan)',
        'Scroll ke bawah, pilih "Face ID & Passcode"',
        'Masukkan passcode iPhone Anda',
        'Aktifkan "Face ID" atau pilih "Add a Fingerprint"',
        'Ikuti instruksi untuk menyelesaikan setup',
      ];
    }
  }

  /// Buka pengaturan device (untuk setup biometrik)
  Future<void> _openDeviceSettings() async {
    try {
      _showSnackBar('📱 Silakan buka Pengaturan HP secara manual...');
    } catch (e) {
      debugPrint('Cannot open settings: $e');
    }
  }

  /// Dialog saat sedang scanning
  void _showScanningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade700,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          size: 45,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Memindai Biometrik...',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _biometricType.isNotEmpty
                      ? 'Silakan gunakan $_biometricType'
                      : 'Tempelkan jari pada sensor atau gunakan FaceID',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.blue.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dialog sukses setelah aktivasi
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: null,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 35,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Berhasil! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Login biometrik telah aktif menggunakan $_biometricType.\n\n'
              'Sekarang Anda bisa login lebih cepat dan aman!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
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

      await supabase.from('profiles').update(updateData).eq('id', userId);

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
            const Text(
              'Reset Password',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
    _showSnackBar(
      enabled ? '🌙 Mode gelap diaktifkan' : '☀️ Mode terang diaktifkan',
    );
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
            _helpItem(
              Icons.person_search,
              'Cara Penggunaan',
              'Pelajari cara menggunakan aplikasi e-PKL',
            ),
            _helpItem(
              Icons.book,
              'Panduan Siswa',
              'Panduan lengkap untuk siswa PKL',
            ),
            _helpItem(
              Icons.school,
              'Panduan Guru',
              'Panduan untuk guru pembimbing',
            ),
            _helpItem(
              Icons.admin_panel_settings,
              'Panduan Admin',
              'Panduan administrasi sistem',
            ),
            _helpItem(
              Icons.contact_support,
              'Hubungi Support',
              'support@epkl-school.id',
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Tutup'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'No. HP',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      if (_profile?['role'] == 'student') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _classController,
                          decoration: InputDecoration(
                            labelText: 'Kelas',
                            prefixIcon: const Icon(Icons.school_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nisnController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'NISN',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _savingChanges ? 'Menyimpan...' : 'Simpan Perubahan',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
        Navigator.of(context).pop(); // tutup loading dialog
        context.go('/login');
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
  // BUILD UI - ✅ UPDATED BIOMETRIC TILE
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

                  // ✅ IMPROVED: Biometric tile with support info
                  _buildBiometricSwitchTile(),

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

  /// ✅ NEW: Special widget for biometric switch with status info
  Widget _buildBiometricSwitchTile() {
    // Determine status and subtitle based on support
    String subtitle;
    bool isEnabled = _biometricEnabled;
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    if (!_isBiometricSupported) {
      subtitle = '❌ Perangkat tidak mendukung biometrik';
      statusColor = Colors.red.shade300;
      statusIcon = Icons.block;
      isEnabled = false; // Force disabled
    } else if (_biometricType == 'not_enrolled') {
      subtitle = '⚠️ Belum setup biometrik di HP Anda';
      statusColor = Colors.orange.shade400;
      statusIcon = Icons.warning_amber_rounded;
      isEnabled = false; // Force disabled until enrolled
    } else if (_biometricType.isNotEmpty) {
      subtitle = '$_biometricType • ${isEnabled ? 'Aktif' : 'Nonaktif'}';
      statusColor = isEnabled ? Colors.green : Colors.blue;
      statusIcon = isEnabled ? Icons.check_circle : Icons.fingerprint;
    } else {
      subtitle = 'Memeriksa dukungan...';
      statusColor = Colors.grey;
      statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: !_isBiometricSupported
              ? Colors.red.shade200
              : _biometricType == 'not_enrolled'
              ? Colors.orange.shade200
              : Colors.grey.shade100,
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(statusIcon, size: 20, color: statusColor),
        ),
        title: Text(
          "Login Biometrik",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: !_isBiometricSupported
                ? Colors.red.shade400
                : _biometricType == 'not_enrolled'
                ? Colors.orange.shade500
                : Colors.grey,
          ),
        ),
        value: isEnabled,
        onChanged: !_isBiometricSupported || _biometricType == 'not_enrolled'
            ? null // Disable switch if not supported or not enrolled
            : (v) => _toggleBiometric(v),
        activeColor: Colors.blue,
        inactiveThumbColor: Colors.grey.shade300,
        inactiveTrackColor: Colors.grey.shade200,
        contentPadding: EdgeInsets.zero,
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
          child: Icon(icon, size: 20, color: val ? Colors.blue : Colors.grey),
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
          child: const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Color(0xFF94A3B8),
          ),
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
