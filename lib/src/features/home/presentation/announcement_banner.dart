import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../data/announcement_repository.dart';
import '../domain/announcement_model.dart';

// ─── Color helpers ────────────────────────────────────────────────────────────
const _kBlue700 = Color(0xFF1565C0);
const _kBlue900 = Color(0xFF0D47A1);

_BannerTheme _themeForTitle(String title) {
  final t = title.toLowerCase();
  if (t.contains('libur') || t.contains('cuti') || t.contains('holiday')) {
    return _BannerTheme(
      gradient: const LinearGradient(
        colors: [Color(0xFF388E3C), Color(0xFF1B5E20)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: LucideIcons.calendarOff,
      shadow: const Color(0xFF388E3C),
    );
  }
  if (t.contains('urgent') || t.contains('penting') || t.contains('darurat')) {
    return _BannerTheme(
      gradient: const LinearGradient(
        colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: LucideIcons.alertTriangle,
      shadow: const Color(0xFFE53935),
    );
  }
  if (t.contains('ujian') || t.contains('ulangan') || t.contains('test')) {
    return _BannerTheme(
      gradient: const LinearGradient(
        colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: LucideIcons.fileText,
      shadow: const Color(0xFF7B1FA2),
    );
  }
  if (t.contains('kegiatan') || t.contains('acara') || t.contains('event')) {
    return _BannerTheme(
      gradient: const LinearGradient(
        colors: [Color(0xFFF57C00), Color(0xFFE65100)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: LucideIcons.calendarDays,
      shadow: const Color(0xFFF57C00),
    );
  }
  // default — biru
  return _BannerTheme(
    gradient: const LinearGradient(
      colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    icon: LucideIcons.megaphone,
    shadow: const Color(0xFF1565C0),
  );
}

class _BannerTheme {
  final LinearGradient gradient;
  final IconData icon;
  final Color shadow;
  const _BannerTheme({
    required this.gradient,
    required this.icon,
    required this.shadow,
  });
}

// ─── Main Banner Widget ───────────────────────────────────────────────────────
class AnnouncementBanner extends ConsumerWidget {
  const AnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(activeAnnouncementsProvider);

    return announcementsAsync.when(
      data: (announcements) {
        if (announcements.isEmpty) return const SizedBox.shrink();
        return _BannerCarousel(announcements: announcements);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<AnnouncementModel> announcements;
  const _BannerCarousel({required this.announcements});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.announcements.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) =>
                _AnnouncementCard(announcement: widget.announcements[i]),
          ),
        ),
        // Dots indicator (only if >1)
        if (widget.announcements.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.announcements.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _current ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _current ? _kBlue700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final theme = _themeForTitle(announcement.title);
    final dateStr = DateFormat(
      'd MMM yyyy',
      'id_ID',
    ).format(announcement.createdAt ?? DateTime.now());

    return GestureDetector(
      onTap: () =>
          context.push('/home/announcements/detail', extra: announcement),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          gradient: theme.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadow.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              right: 40,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(theme.icon, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          dateStr,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      announcement.content,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Tap untuk baca selengkapnya →',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
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
