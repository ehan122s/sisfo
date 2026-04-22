import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../data/journal_repository.dart';

const _kBlue900 = Color(0xFF0D47A1);
const _kBlue700 = Color(0xFF1565C0);
const _kBlue500 = Color(0xFF1E88E5);
const _kBlue300 = Color(0xFF64B5F6);
const _kBlueBg  = Color(0xFFF0F5FF);

class JournalFormScreen extends ConsumerStatefulWidget {
  const JournalFormScreen({super.key});

  @override
  ConsumerState<JournalFormScreen> createState() => _JournalFormScreenState();
}

class _JournalFormScreenState extends ConsumerState<JournalFormScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _titleC   = TextEditingController();
  final _descC    = TextEditingController();

  XFile?     _pickedFile;
  Uint8List? _pickedBytes;
  bool       _saving = false;

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  // ── Image Picker ────────────────────────────────────────────────────────────
  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source, imageQuality: 80,
        maxWidth: 1200, maxHeight: 1200,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() { _pickedFile = picked; _pickedBytes = bytes; });
    } catch (e) {
      debugPrint('pick error: $e');
    }
  }

  void _showImagePicker() {
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
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Upload Foto Kegiatan',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D1B3E))),
            const SizedBox(height: 20),
            Row(
              children: [
                // Kamera — disabled on web
                Expanded(
                  child: _PickerOption(
                    icon: LucideIcons.camera,
                    label: 'Kamera',
                    enabled: !kIsWeb,
                    onTap: !kIsWeb ? () {
                      Navigator.pop(context);
                      _pick(ImageSource.camera);
                    } : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _PickerOption(
                    icon: LucideIcons.image,
                    label: 'Galeri',
                    enabled: true,
                    onTap: () {
                      Navigator.pop(context);
                      _pick(ImageSource.gallery);
                    },
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

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedBytes == null) {
      _showSnack('Foto kegiatan wajib diupload', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(journalRepositoryProvider);

      // Upload gambar ke Supabase Storage bucket "journal"
      final imageUrl = await repo.uploadEvidenceBytes(_pickedBytes!);

      // Simpan jurnal ke tabel daily_journals
      await repo.submitJournal(
        title: _titleC.text.trim(),
        description: _descC.text.trim(),
        imageUrl: imageUrl,
      );

      if (mounted) {
        _showSnack('Jurnal berhasil disimpan! 🎉');
        await Future.delayed(const Duration(milliseconds: 600));
        Navigator.pop(context, true); // return true → trigger refresh
      }
    } catch (e) {
      if (mounted) _showSnack('Gagal menyimpan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBlueBg,
      appBar: AppBar(
        backgroundColor: _kBlue700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Tulis Jurnal',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo Upload ───────────────────────────────────────────────
              GestureDetector(
                onTap: _showImagePicker,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _pickedBytes != null
                          ? _kBlue500.withOpacity(0.5)
                          : Colors.grey.shade200,
                      width: 2,
                    ),
                    boxShadow: [BoxShadow(
                        color: _kBlue700.withOpacity(0.06),
                        blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: _pickedBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_pickedBytes!, fit: BoxFit.cover),
                              Positioned(
                                top: 10, right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.edit2,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _kBlue500.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.image,
                                  size: 32, color: _kBlue500),
                            ),
                            const SizedBox(height: 12),
                            Text('Tap untuk upload foto kegiatan',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: _kBlue500,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('JPG, PNG — maks 5MB',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.grey.shade400)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Form Card ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                      color: _kBlue700.withOpacity(0.06),
                      blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detail Kegiatan',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D1B3E))),
                    const SizedBox(height: 18),

                    // Judul
                    _buildLabel('Judul Kegiatan'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleC,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDeco(
                          hint: 'Contoh: Membuat laporan harian',
                          icon: LucideIcons.fileText),
                    ),

                    const SizedBox(height: 16),

                    // Deskripsi
                    _buildLabel('Deskripsi Kegiatan'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descC,
                      maxLines: 5,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Deskripsi wajib diisi' : null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDeco(
                          hint: 'Ceritakan apa yang kamu kerjakan hari ini...',
                          icon: LucideIcons.clipboard),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, size: 16, color: _kBlue700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Jurnal akan direview oleh guru pembimbing sebelum disetujui.',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _kBlue300,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.save, size: 18),
                            const SizedBox(width: 10),
                            Text('Simpan Jurnal',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
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

  Widget _buildLabel(String text) => Text(text,
      style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, fontSize: 13,
          color: const Color(0xFF374151)));

  InputDecoration _inputDeco({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: _kBlue500, width: 1.5)),
        errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Colors.red)),
        focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Colors.red, width: 1.5)),
      );
}

// ─── Picker Option Widget ─────────────────────────────────────────────────────
class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  const _PickerOption({
    required this.icon, required this.label,
    required this.enabled, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: _kBlue500.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(icon, size: 28, color: _kBlue700),
                const SizedBox(height: 8),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: const Color(0xFF0D1B3E))),
                if (!enabled)
                  Text('(Mobile only)',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ),
      );
}