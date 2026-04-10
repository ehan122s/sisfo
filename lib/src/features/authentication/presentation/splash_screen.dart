import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // Navigate to root, the router's redirect logic will handle
      // sending to /login or / (home) based on auth state
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // Light blue background like login page
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with white circular background and shadow
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 50,
                        color: Color(0xFF1976D2), // Blue color like login page
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Main title - Dark color like login page
                    Text(
                      'E-PKL',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212121), // Dark text like login page
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle - Blue accent
                    Text(
                      'SMKN 1 GARUT',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1976D2), // Blue accent
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom developer info
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Column(
                children: [
                  Text(
                    'Dikembang Oleh',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Teknik Elektronika Industri',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1976D2), // Blue color matching login theme
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}