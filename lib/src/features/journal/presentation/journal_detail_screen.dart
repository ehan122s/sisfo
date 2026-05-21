import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kBlue900 = Color(0xFF0D47A1);
const _kBlue700 = Color(0xFF1565C0);
const _kBlue500 = Color(0xFF1E88E5);
const _kBlue300 = Color(0xFF64B5F6);
const _kBlueBg = Color(0xFFF0F5FF);

class JournalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> journal;
  const JournalDetailScreen({super.key, required this.journal});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  bool _isDeleting = false;

  Future<void> _deleteJournal() async {
    // Tampilkan dialog konfirmasi
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteConfirmationDialog(),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isDeleting = true);

    try {
      final supabase = Supabase.instance.client;
      final int journalId = widget.journal['id'];

      await supabase
          .from('daily_journals')
          .delete()
          .eq('id', journalId);

      if (!mounted) return;

      // Tampilkan snackbar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                'Jurnal berhasil dihapus',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      // Kembali ke halaman sebelumnya dan kirim sinyal refresh
      Navigator.pop(context, true); // true = jurnal dihapus, perlu refresh list
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gagal menghapus: ${e.message}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terjadi kesalahan. Coba lagi.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isApproved = widget.journal['is_approved'] == true;
    final DateTime date =
        DateTime.parse(widget.journal['created_at']).toLocal();
    final String title = widget.journal['activities'] ??
        widget.journal['activity_title'] ??
        'Tanpa Judul';
    final String desc =
        widget.journal['challenges'] ?? widget.journal['description'] ?? '-';
    final String? imgUrl = widget.journal['evidence_url'];
    final String dateStr =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    final String timeStr = DateFormat('HH:mm', 'id_ID').format(date);

    return Scaffold(
      backgroundColor: _kBlueBg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero AppBar ────────────────────────────────────────────
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
                // Tombol hapus di AppBar (pojok kanan atas)
                actions: [
                  GestureDetector(
                    onTap: _isDeleting ? null : _deleteJournal,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.trash2,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Hapus',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

              // ── Content ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusBadge(approved: isApproved),
                      const SizedBox(height: 14),

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

                      Wrap(
                        spacing: 10,
                        children: [
                          _InfoChip(
                              icon: LucideIcons.calendar, label: dateStr),
                          _InfoChip(
                            icon: LucideIcons.clock,
                            label: 'Dikirim $timeStr',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

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
                                  isApproved
                                      ? 'Disetujui'
                                      : 'Menunggu Persetujuan',
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

                      const SizedBox(height: 20),

                      // ── Tombol Hapus (bawah, merah besar) ─────────────
                      _DeleteButton(
                        isDeleting: _isDeleting,
                        onDelete: _deleteJournal,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Loading overlay saat proses hapus
          if (_isDeleting)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.red,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Menghapus jurnal...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Tombol Hapus Bawah ───────────────────────────────────────────────────────
class _DeleteButton extends StatelessWidget {
  final bool isDeleting;
  final VoidCallback onDelete;

  const _DeleteButton({
    required this.isDeleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isDeleting ? null : onDelete,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          disabledBackgroundColor: Colors.red.shade200,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: isDeleting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(LucideIcons.trash2, size: 18),
        label: Text(
          isDeleting ? 'Menghapus...' : 'Hapus Jurnal Ini',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─── Dialog Konfirmasi Hapus ──────────────────────────────────────────────────
class _DeleteConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.trash2,
              color: Colors.red.shade600,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hapus Jurnal?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D1B3E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jurnal yang dihapus tidak dapat dikembalikan. Apakah kamu yakin ingin menghapus jurnal ini?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Ya, Hapus',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Helpers (sama seperti sebelumnya) ───────────────────────────────────────
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
          color:
              approved ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              approved ? LucideIcons.checkCircle : LucideIcons.clock,
              size: 13,
              color:
                  approved ? const Color(0xFF2E7D32) : Colors.orange.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              approved ? 'Disetujui' : 'Menunggu Review',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: approved
                    ? const Color(0xFF2E7D32)
                    : Colors.orange.shade700,
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