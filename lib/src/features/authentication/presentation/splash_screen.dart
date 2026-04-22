import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go('/');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFBBDEFB),
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.08,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            Container(
                              width: isSmall ? 80 : 110,
                              height: isSmall ? 80 : 110,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1976D2)
                                        .withOpacity(0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.school_rounded,
                                size: isSmall ? 40 : 55,
                                color: const Color(0xFF1976D2),
                              ),
                            ),

                            SizedBox(height: size.height * 0.03),

                            // E-PKL Title
                            Text(
                              'E-PKL',
                              style: GoogleFonts.poppins(
                                fontSize: isSmall ? 30 : 40,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D47A1),
                                letterSpacing: 2,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Subtitle chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'SMKN 1 GARUT',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmall ? 11 : 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),

                            SizedBox(height: size.height * 0.04),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color:
                                        const Color(0xFF1976D2).withOpacity(0.3),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: const Color(0xFF1976D2)
                                        .withOpacity(0.5),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color:
                                        const Color(0xFF1976D2).withOpacity(0.3),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: size.height * 0.03),

                            // Description
                            Text(
                              'Sistem Informasi Praktek\nKerja Lapangan',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: isSmall ? 12 : 14,
                                color: const Color(0xFF1565C0),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom section
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: size.height * 0.05,
                      left: 24,
                      right: 24,
                    ),
                    child: Column(
                      children: [
                        // Loading dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            return AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF1976D2).withOpacity(
                                      ((_controller.value + i * 0.2) % 1.0)
                                          .clamp(0.2, 1.0),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),

                        const SizedBox(height: 20),

                        // Developer card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF1976D2).withOpacity(0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1976D2).withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Dikembangkan Oleh',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kelompok 4',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmall ? 15 : 17,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D47A1),
                                ),
                              ),
                              Text(
                                'XI-PPL 2',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmall ? 12 : 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1976D2),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}