import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_config.dart';
import '../../authentication/data/auth_repository.dart';

const _kBlue900 = Color(0xFF0D47A1);
const _kBlue700 = Color(0xFF1565C0);
const _kBlue500 = Color(0xFF1E88E5);
const _kBlue300 = Color(0xFF64B5F6);
const _kBlueBg = Color(0xFFF0F5FF);
const _kNavy = Color(0xFF0F172A);

final profileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) throw Exception('No user');
  return await supabase.from('profiles').select().eq('id', user.id).single();
});

final _journalCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) return 0;
  final res = await supabase
      .from('daily_journals')
      .select('id')
      .eq('student_id', user.id);
  return (res as List).length;
});

final _attendanceCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) return 0;
  final res = await supabase
      .from('attendance_logs')
      .select('id')
      .eq('student_id', user.id);
  return (res as List).length;
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
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picked = await ImagePicker().pickImage(
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
      await supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      final avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      await supabase
          .from('profiles')
          .update({'avatar_url': avatarUrl})
          .eq('id', user.id);
      ref.invalidate(profileProvider);
      _showSnack('Foto profil berhasil diperbarui!', isSuccess: true);
    } catch (e) {
      _showSnack('Gagal upload foto: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? LucideIcons.checkCircle : LucideIcons.xCircle,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? Colors.green.shade600
            : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showEditNameDialog(String currentName) {
    final ctrl = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    bool saving = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModalHandle(),
                  const SizedBox(height: 8),
                  Text(
                    'Ubah Nama',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nama akan diperbarui di seluruh aplikasi',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama tidak boleh kosong'
                        : null,
                    decoration: _inputDeco('Nama lengkap', LucideIcons.user),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setS(() => saving = true);
                              try {
                                final user = ref
                                    .read(authRepositoryProvider)
                                    .currentUser;
                                await supabase
                                    .from('profiles')
                                    .update({'full_name': ctrl.text.trim()})
                                    .eq('id', user!.id);
                                ref.invalidate(profileProvider);
                                if (mounted) {
                                  Navigator.pop(context);
                                  _showSnack(
                                    'Nama berhasil diperbarui!',
                                    isSuccess: true,
                                  );
                                }
                              } catch (e) {
                                _showSnack('Gagal: $e');
                              } finally {
                                setS(() => saving = false);
                              }
                            },
                      style: _btnStyle(),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Simpan',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false, showNew = false, showConfirm = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModalHandle(),
                  const SizedBox(height: 8),
                  Text(
                    'Ubah Password',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gunakan password yang kuat minimal 6 karakter',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: !showNew,
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Password tidak boleh kosong';
                      if (v.length < 6) return 'Minimal 6 karakter';
                      return null;
                    },
                    decoration: _inputDeco('Password baru', LucideIcons.lock)
                        .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              showNew ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () => setS(() => showNew = !showNew),
                          ),
                        ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: !showConfirm,
                    validator: (v) =>
                        v != newPassCtrl.text ? 'Password tidak cocok' : null,
                    decoration:
                        _inputDeco(
                          'Konfirmasi password',
                          LucideIcons.lock,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              showConfirm
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () =>
                                setS(() => showConfirm = !showConfirm),
                          ),
                        ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setS(() => saving = true);
                              try {
                                await supabase.auth.updateUser(
                                  UserAttributes(password: newPassCtrl.text),
                                );
                                if (mounted) {
                                  Navigator.pop(context);
                                  _showSnack(
                                    'Password berhasil diubah!',
                                    isSuccess: true,
                                  );
                                }
                              } catch (e) {
                                _showSnack('Gagal: $e');
                              } finally {
                                setS(() => saving = false);
                              }
                            },
                      style: _btnStyle(),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Simpan Password',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    final faqs = [
      (
        'Bagaimana cara absen masuk?',
        'Buka halaman Home, tap tombol "Absen Masuk", lalu izinkan akses lokasi dan ambil foto selfie.',
      ),
      (
        'Kenapa absen saya tidak terekam?',
        'Pastikan GPS aktif dan kamu berada dalam radius lokasi PKL. Cek koneksi internet kamu.',
      ),
      (
        'Kapan jurnal harus diisi?',
        'Jurnal harus diisi setiap hari kerja sebelum atau setelah absen pulang.',
      ),
      (
        'Bagaimana cara mengganti foto profil?',
        'Di halaman Profil, tap ikon kamera di foto profil kamu, lalu pilih foto dari galeri.',
      ),
      (
        'Siapa yang bisa dihubungi jika ada masalah?',
        'Hubungi guru pembimbing PKL kamu atau admin sekolah.',
      ),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          margin: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    _ModalHandle(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _kBlue500.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.helpCircle,
                            color: _kBlue700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Pusat Bantuan',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _kNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  itemCount: faqs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _FaqTile(question: faqs[i].$1, answer: faqs[i].$2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModalHandle(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.logOut,
                color: Colors.red.shade600,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Keluar Aplikasi?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamu akan keluar dari akun ini.\nPastikan jurnal hari ini sudah diisi.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ref.read(authRepositoryProvider).signOut();
                      if (mounted) context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Keluar',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final journalCountAsync = ref.watch(_journalCountProvider);
    final attendCountAsync = ref.watch(_attendanceCountProvider);

    return Scaffold(
      backgroundColor: _kBlueBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: _kBlue700,
              automaticallyImplyLeading: false,
              elevation: 0,
              title: const Text(''),
              flexibleSpace: FlexibleSpaceBar(
                background: _HeroHeader(
                  profileAsync: profileAsync,
                  isUploading: _isUploading,
                  onTapAvatar: _pickAndUploadAvatar,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: journalCountAsync.when(
                            data: (n) => _StatCard(
                              icon: LucideIcons.bookOpen,
                              label: 'Total Jurnal',
                              value: '$n',
                              color: _kBlue700,
                            ),
                            loading: () => _StatCardSkeleton(),
                            error: (_, __) => _StatCard(
                              icon: LucideIcons.bookOpen,
                              label: 'Total Jurnal',
                              value: '-',
                              color: _kBlue700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: attendCountAsync.when(
                            data: (n) => _StatCard(
                              icon: LucideIcons.calendarCheck,
                              label: 'Kehadiran',
                              value: '$n',
                              color: const Color(0xFF0891B2),
                            ),
                            loading: () => _StatCardSkeleton(),
                            error: (_, __) => _StatCard(
                              icon: LucideIcons.calendarCheck,
                              label: 'Kehadiran',
                              value: '-',
                              color: const Color(0xFF0891B2),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _SectionLabel('PENGATURAN AKUN'),
                    const SizedBox(height: 12),
                    _MenuCard(
                      children: [
                        profileAsync.when(
                          data: (d) => _MenuTile(
                            icon: LucideIcons.userCircle2,
                            iconBg: _kBlue500.withOpacity(0.1),
                            iconColor: _kBlue700,
                            title: 'Ubah Nama',
                            subtitle: d['full_name'] ?? '-',
                            onTap: () =>
                                _showEditNameDialog(d['full_name'] ?? ''),
                          ),
                          loading: () => const SizedBox(height: 56),
                          error: (_, __) => const SizedBox(),
                        ),
                        _divider(),
                        _MenuTile(
                          icon: LucideIcons.lock,
                          iconBg: const Color(0xFFEDE7F6),
                          iconColor: const Color(0xFF7C3AED),
                          title: 'Ubah Password',
                          subtitle: 'Ganti password akun kamu',
                          onTap: _showChangePasswordDialog,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    _SectionLabel('LAINNYA'),
                    const SizedBox(height: 12),
                    _MenuCard(
                      children: [
                        _MenuTile(
                          icon: LucideIcons.helpCircle,
                          iconBg: const Color(0xFFE0F2F1),
                          iconColor: const Color(0xFF0D9488),
                          title: 'Pusat Bantuan',
                          subtitle: 'FAQ & panduan penggunaan',
                          onTap: _showHelpDialog,
                        ),
                        _divider(),
                        _MenuTile(
                          icon: LucideIcons.info,
                          iconBg: const Color(0xFFFFF8E1),
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Tentang Aplikasi',
                          subtitle: 'E-PKL v1.0.0 • SIP SMEA',
                          onTap: () => _showSnack(
                            'E-PKL v1.0.0 — Sistem Informasi PKL SMEA',
                            isSuccess: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showLogoutDialog,
                        icon: const Icon(LucideIcons.logOut, size: 18),
                        label: Text(
                          'Keluar Aplikasi',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF0F0),
                          foregroundColor: Colors.red.shade700,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.red.shade100,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '© 2026 SMKN 1 GARUT',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, indent: 60, color: Colors.grey.shade100);

  ButtonStyle _btnStyle() => ElevatedButton.styleFrom(
    backgroundColor: _kBlue700,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
    prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
    filled: true,
    fillColor: const Color(0xFFF8FAFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: _kBlue500, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Colors.red),
    ),
  );
}

class _HeroHeader extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>> profileAsync;
  final bool isUploading;
  final VoidCallback onTapAvatar;
  const _HeroHeader({
    required this.profileAsync,
    required this.isUploading,
    required this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kBlue900, _kBlue700, _kBlue500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: isUploading ? null : onTapAvatar,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.white, _kBlue300],
                            ),
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: isUploading
                                  ? Container(
                                      color: const Color(0xFF1976D2),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : profileAsync.when(
                                      data: (d) => d['avatar_url'] != null
                                          ? Image.network(
                                              '${d['avatar_url']}?t=${DateTime.now().millisecondsSinceEpoch}',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _DefaultAvatar(
                                                    name: d['full_name'] ?? 'S',
                                                  ),
                                            )
                                          : _DefaultAvatar(
                                              name: d['full_name'] ?? 'S',
                                            ),
                                      loading: () => Container(
                                        color: const Color(0xFF1976D2),
                                      ),
                                      error: (_, __) =>
                                          _DefaultAvatar(name: 'S'),
                                    ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _kBlue500,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: profileAsync.when(
                      data: (d) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            d['full_name'] ?? 'Siswa Magang',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'NISN: ${d['nisn'] ?? '-'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              d['class_name'] ?? '-',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                      error: (_, __) => Text(
                        'Gagal memuat',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
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
}

class _DefaultAvatar extends StatelessWidget {
  final String name;
  const _DefaultAvatar({required this.name});
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF1976D2),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _kNavy,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StatCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 72,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _kBlue700,
      letterSpacing: 1.5,
    ),
  );
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: _kBlue700.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(children: children),
    ),
  );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 19),
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
                      fontSize: 14,
                      color: _kNavy,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    ),
  );
}

class _FaqTile extends StatefulWidget {
  final String question, answer;
  const _FaqTile({required this.question, required this.answer});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _open = !_open),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _open ? _kBlue500.withOpacity(0.04) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _open ? _kBlue300.withOpacity(0.4) : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _kNavy,
                  ),
                ),
              ),
              Icon(
                _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          if (_open) ...[
            const SizedBox(height: 10),
            Text(
              widget.answer,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ModalHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
