import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

const _kBlue900 = Color(0xFF0D47A1);
const _kBlue700 = Color(0xFF1565C0);
const _kBlue500 = Color(0xFF1E88E5);
const _kBlue300 = Color(0xFF64B5F6);
const _kBlueBg = Color(0xFFF0F5FF);

class JournalDetailScreen extends StatelessWidget {
  final Map<String, dynamic> journal;
  const JournalDetailScreen({super.key, required this.journal});

  @override
  Widget build(BuildContext context) {
    final bool isApproved = journal['is_approved'] == true;
    final DateTime date = DateTime.parse(journal['created_at']).toLocal();
    final String title =
        journal['activities'] ?? journal['activity_title'] ?? 'Tanpa Judul';
    final String desc = journal['challenges'] ?? journal['description'] ?? '-';
    final String? imgUrl = journal['evidence_url'];
    final String dateStr = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(date);
    final String timeStr = DateFormat('HH:mm', 'id_ID').format(date);

    return Scaffold(
      backgroundColor: _kBlueBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero AppBar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: imgUrl != null ? 280 : 160,
            pinned: true,
            backgroundColor: _kBlue700,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: imgUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _GradientBg(),
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : _GradientBg(),
                        ),
                        // gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                _kBlue900.withOpacity(0.85),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _GradientBg(),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  _StatusBadge(approved: isApproved),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D1B3E),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Date + Time chips
                  Wrap(
                    spacing: 10,
                    children: [
                      _InfoChip(icon: LucideIcons.calendar, label: dateStr),
                      _InfoChip(
                        icon: LucideIcons.clock,
                        label: 'Dikirim $timeStr',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description card
                  _SectionCard(
                    title: 'Deskripsi Kegiatan',
                    icon: LucideIcons.fileText,
                    child: Text(
                      desc,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF374151),
                        height: 1.7,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status info card
                  _SectionCard(
                    title: 'Status Review',
                    icon: LucideIcons.checkSquare,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isApproved
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFF3E0),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isApproved
                                ? LucideIcons.checkCircle
                                : LucideIcons.clock,
                            color: isApproved
                                ? const Color(0xFF2E7D32)
                                : Colors.orange.shade700,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isApproved ? 'Disetujui' : 'Menunggu Persetujuan',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isApproved
                                    ? const Color(0xFF2E7D32)
                                    : Colors.orange.shade800,
                              ),
                            ),
                            Text(
                              isApproved
                                  ? 'Jurnal telah disetujui guru pembimbing'
                                  : 'Menunggu review dari guru pembimbing',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Foto bukti (jika ada, tampilkan di bawah juga)
                  if (imgUrl != null) ...[
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Foto Kegiatan',
                      icon: LucideIcons.image,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          imgUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: _kBlue500.withOpacity(0.08),
                            child: const Icon(
                              LucideIcons.image,
                              color: _kBlue300,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _GradientBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [_kBlue700, _kBlue900],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(
        LucideIcons.bookOpen,
        size: 64,
        color: Colors.white.withOpacity(0.2),
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final bool approved;
  const _StatusBadge({required this.approved});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: approved ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          approved ? LucideIcons.checkCircle : LucideIcons.clock,
          size: 13,
          color: approved ? const Color(0xFF2E7D32) : Colors.orange.shade700,
        ),
        const SizedBox(width: 6),
        Text(
          approved ? 'Disetujui' : 'Menunggu Review',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: approved ? const Color(0xFF2E7D32) : Colors.orange.shade700,
          ),
        ),
      ],
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: _kBlue700.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _kBlue500),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _kBlue500.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _kBlue700, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: const Color(0xFF0D1B3E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}
