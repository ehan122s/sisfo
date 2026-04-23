import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../data/auth_repository.dart';

const _kBlue900 = Color(0xFF0D47A1);
const _kBlue700 = Color(0xFF1565C0);
const _kBlue500 = Color(0xFF1E88E5);
const _kBlueBg = Color(0xFFF0F5FF);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailC.text.trim();
    final password = _passwordC.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Email dan password harus diisi', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).loginWithEmail(email, password);
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBlueBg,
      body: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kBlue500.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 160,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kBlue300.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kBlue700.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Logo
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_kBlue300, _kBlue900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 36,
                          color: _kBlue700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SIP SMEA',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D1B3E),
                      ),
                    ),
                    Text(
                      'SMKN 1 GARUT',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: _kBlue500,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: _kBlue700.withOpacity(0.1),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang !',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D1B3E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Silahkan login ke akun anda yang sudah terdaftar',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email
                          _buildField(
                            controller: _emailC,
                            hint: 'user@smkn1garut.sch.id',
                            label: 'Email',
                            icon: LucideIcons.mail,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          _buildField(
                            controller: _passwordC,
                            hint: '••••••••',
                            label: 'Password',
                            icon: LucideIcons.lock,
                            isPassword: true,
                          ),

                          const SizedBox(height: 24),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kBlue700,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _kBlue300,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Masuk',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          LucideIcons.arrowRight,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Help
                    Text(
                      'Butuh bantuan? Hubungi admin sekolah',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialBtn(LucideIcons.instagram, Colors.pink),
                        const SizedBox(width: 12),
                        _socialBtn(LucideIcons.messageCircle, Colors.green),
                      ],
                    ),

                    const SizedBox(height: 28),
                    Text(
                      '© 2026 SMKN 1 GARUT',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: isPassword
            ? TextInputType.text
            : TextInputType.emailAddress,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0D1B3E),
        ),
        onSubmitted: (_) {
          if (!isPassword) {
          } else
            _handleLogin();
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 18),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  Widget _socialBtn(IconData icon, Color color) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: _kBlue700.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Icon(icon, color: Colors.grey.shade400, size: 20),
  );
}

const _kBlue300 = Color(0xFF64B5F6);
