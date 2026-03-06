import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/auth_repository.dart';
import '../../authentication/presentation/register_screen.dart';
import '../../../services/biometric_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _hasStoredCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final bioService = ref.read(biometricServiceProvider);
    final available = await bioService.isBiometricAvailable;
    final enabled = await bioService.isBiometricEnabled;

    if (mounted) {
      setState(() {
        _isBiometricAvailable = available;
        _hasStoredCredentials = enabled;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    final bioService = ref.read(biometricServiceProvider);

    // 1. Authenticate
    final authenticated = await bioService.authenticate();
    if (!authenticated) return;

    // 2. Get Credentials
    final credentials = await bioService.getCredentials();
    if (!mounted) return;

    if (credentials == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data login tidak ditemukan. Silakan login manual.'),
          ),
        );
      }
      return;
    }

    // 3. Auto Login
    if (mounted) {
      _emailController.text = credentials['email']!;
      _passwordController.text = credentials['password']!;
      _handleLogin(isBiometric: true);
    }
  }

  Future<void> _handleLogin({bool isBiometric = false}) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .loginWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      debugPrint("Login successful. Waiting for redirect...");

      // Prompt to enable biometric if available and not yet enabled, and manual login
      if (!isBiometric && _isBiometricAvailable && !_hasStoredCredentials) {
        if (mounted) {
          await _showEnableBiometricDialog();
        }
      }
    } catch (e) {
      debugPrint("Login error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showEnableBiometricDialog() async {
    if (!mounted) return;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aktifkan Biometric?"),
        content: const Text(
          "Login lebih cepat berikutnya dengan sidik jari/wajah.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Nanti"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(biometricServiceProvider)
                  .enableBiometric(
                    _emailController.text.trim(),
                    _passwordController.text.trim(),
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Biometric Login Diaktifkan!')),
                );
              }
            },
            child: const Text("Aktifkan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.school,
                size: 80,
                color: Color(0xFF006400),
              ), // Dark Green
              const SizedBox(height: 24),
              Text(
                'Selamat Datang di K-MOB Sagar',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Silakan login untuk melanjutkan',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006400),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'LOGIN',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              // Registration disabled by admin request
              /*
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Belum punya akun? "),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Daftar Sekarang",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              */
              if (_hasStoredCredentials) ...[
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("ATAU", style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: InkWell(
                    onTap: _handleBiometricLogin,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF006400)),
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFF006400).withValues(alpha: 0.1),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.fingerprint,
                            size: 48,
                            color: Color(0xFF006400),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Login dengan Biometric",
                            style: TextStyle(
                              color: Color(0xFF006400),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
