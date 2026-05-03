import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kBlue900 = Color(0xFF0D47A1);
const _kBlue700 = Color(0xFF1565C0);
const _kBlue500 = Color(0xFF1E88E5);
const _kBlueBg = Color(0xFFF0F5FF);

class JournalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> journal;
  const JournalDetailScreen({super.key, required this.journal});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  late Map<String, dynamic> journalData;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    journalData = Map<String, dynamic>.from(widget.journal);
  }

  // Fungsi Update Status ke Supabase
  Future<void> _updateStatus() async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    // Ambil nilai boolean is_approved saat ini
    final bool currentApproved = journalData['is_approved'] == true;
    final bool nextStatus = !currentApproved;

    try {
      await Supabase.instance.client
          .from('daily_journals') // Sesuai screenshot kamu
          .update({'is_approved': nextStatus}) // Sesuai screenshot kamu
          .eq('id', journalData['id']);

      setState(() {
        journalData['is_approved'] = nextStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextStatus ? 'Jurnal disetujui' : 'Status dipending'),
            backgroundColor: nextStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logika tampilan berdasarkan kolom is_approved
    final bool isApproved = journalData['is_approved'] == true;

    // Parsing Tanggal
    DateTime date;
    try {
      date = journalData['created_at'] != null 
          ? DateTime.parse(journalData['created_at']).toLocal() 
          : DateTime.now();
    } catch (e) {
      date = DateTime.now();
    }

    final String title = journalData['activities'] ?? 'Tanpa Judul';
    final String desc = journalData['description'] ?? journalData['challenges'] ?? '-';
    final String? imgUrl = journalData['evidence_url'];
    final String dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);

    return Scaffold(
      backgroundColor: _kBlueBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: imgUrl != null ? 280 : 160,
            pinned: true,
            backgroundColor: _kBlue700,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: imgUrl != null
                  ? Image.network(imgUrl, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [_kBlue700, _kBlue900]),
                      ),
                      child: Icon(LucideIcons.bookOpen, size: 64, color: Colors.white.withOpacity(0.2)),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOMBOL STATUS (Bisa Diklik)
                  GestureDetector(
                    onTap: _updateStatus,
                    child: _StatusBadge(approved: isApproved, isLoading: _isUpdating),
                  ),
                  
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: _kBlue900),
                  ),
                  const SizedBox(height: 8),
                  Text(dateStr, style: GoogleFonts.poppins(color: Colors.grey.shade600)),

                  const SizedBox(height: 24),
                  _SectionCard(
                    title: 'Isi Kegiatan',
                    icon: LucideIcons.fileText,
                    child: Text(desc, style: GoogleFonts.poppins(height: 1.6, color: Colors.black87)),
                  ),

                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Info Review',
                    icon: LucideIcons.shieldCheck,
                    child: Row(
                      children: [
                        Icon(
                          isApproved ? LucideIcons.checkCircle : LucideIcons.clock,
                          color: isApproved ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isApproved ? 'Telah diverifikasi oleh Admin' : 'Menunggu verifikasi admin',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: isApproved ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
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

class _StatusBadge extends StatelessWidget {
  final bool approved;
  final bool isLoading;
  const _StatusBadge({required this.approved, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: approved ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: approved ? Colors.green : Colors.orange, width: 1.5),
      ),
      child: isLoading 
        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(approved ? LucideIcons.checkCircle : LucideIcons.clock, 
                   size: 16, color: approved ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              Text(
                approved ? 'APPROVED' : 'PENDING',
                style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: approved ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _kBlue700),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}