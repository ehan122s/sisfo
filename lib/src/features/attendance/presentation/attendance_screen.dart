import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../data/attendance_repository.dart';
import '../../authentication/data/auth_repository.dart';
import '../../../services/image_compression_service.dart';
import '../../journal/data/journal_repository.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _kBlue900 = Color(0xFF0D47A1);
const _kBlue700 = Color(0xFF1565C0);
const _kBlue500 = Color(0xFF1E88E5);

enum AttendanceMode { checkIn, checkOut }

class AttendanceScreen extends ConsumerStatefulWidget {
  final AttendanceMode mode;
  const AttendanceScreen({super.key, required this.mode});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isWithinRange = false;
  double _distance = 0.0;

  LatLng? _companyLocation;
  double _radiusMeter = 100;
  String _companyName = 'Lokasi PKL';
  int? _placementId; // ← TAMBAHAN: simpan placement id

  // Selfie preview
  XFile? _selfieFile;
  Uint8List? _selfieBytes;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      final placement = await ref
          .read(attendanceRepositoryProvider)
          .getStudentPlacement(user.id);

      if (placement != null) {
        _placementId = placement['id'] as int; // ← TAMBAHAN: ambil id
        final company = placement['companies'];
        _companyName = company['name'];
        _radiusMeter = (company['radius_meter'] as num).toDouble();
        _companyLocation = LatLng(
          (company['latitude'] as num).toDouble(),
          (company['longitude'] as num).toDouble(),
        );
      }

      final position = await ref
          .read(attendanceRepositoryProvider)
          .getCurrentLocation();

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        _updateStatus();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateStatus() {
    if (_currentPosition == null || _companyLocation == null) return;
<<<<<<< HEAD
    final dist = ref
=======

    final distance = ref
>>>>>>> fitur-coba
        .read(attendanceRepositoryProvider)
        .calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _companyLocation!.latitude,
          _companyLocation!.longitude,
        );
    setState(() {
      _distance = dist;
      _isWithinRange = dist <= _radiusMeter;
    });
<<<<<<< HEAD
=======

>>>>>>> fitur-coba
    _mapController.move(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      16.0,
    );
  }

  // ── Selfie picker (Web-safe) ─────────────────────────────────────────────────
  Future<void> _pickSelfie() async {
    // Cek radius dulu sebelum boleh selfie
    if (!_isWithinRange) {
      _showSnack(
        _companyLocation == null
            ? 'Belum ada penempatan PKL. Hubungi admin.'
            : 'Kamu di luar radius PKL (${_distance.toStringAsFixed(0)}m). Mendekat dulu!',
        isError: true,
      );
      return;
    }

    // Di web: pakai galeri. Di mobile: kamera depan
    final source = kIsWeb ? ImageSource.gallery : ImageSource.camera;

    final picked = await ImagePicker().pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 60,
      maxWidth: 800,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _selfieFile = picked;
      _selfieBytes = bytes;
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────────
  Future<void> _handleAction() async {
    if (_selfieBytes == null) {
      _showSnack('Ambil foto selfie dulu!', isError: true);
      return;
    }

    // ← TAMBAHAN: cek placementId tersedia
    if (_placementId == null) {
      _showSnack('Belum ada penempatan PKL. Hubungi admin.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      String photoUrl;
<<<<<<< HEAD

      // Upload bytes — works on both Web & Mobile
      final connectivity = await Connectivity().checkConnectivity();
      if (!kIsWeb && connectivity.contains(ConnectivityResult.none)) {
        // Offline mobile: simpan path lokal
        photoUrl = _selfieFile!.path;
=======
      final List<ConnectivityResult> connectivityResult = await Connectivity()
          .checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        photoUrl = imageFile.path;
>>>>>>> fitur-coba
      } else {
        photoUrl = await ref
            .read(attendanceRepositoryProvider)
            .uploadSelfieBytes(_selfieBytes!, user.id);
      }

      String successMessage = '';
      if (widget.mode == AttendanceMode.checkIn) {
        successMessage = await ref
            .read(attendanceRepositoryProvider)
            .checkIn(
              studentId: user.id,
              placementId: _placementId!, // ← TAMBAHAN
              lat: _currentPosition!.latitude,
              long: _currentPosition!.longitude,
              photoUrl: photoUrl,
            );
      } else {
        await ref
            .read(attendanceRepositoryProvider)
            .checkOut(
              studentId: user.id,
              placementId: _placementId!, // ← TAMBAHAN
              lat: _currentPosition!.latitude,
              long: _currentPosition!.longitude,
              photoUrl: photoUrl,
            );
        successMessage = 'Absen Pulang Berhasil! 🏠';
      }

      if (mounted) {
<<<<<<< HEAD
        _showSnack(successMessage, isError: false);
=======
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
>>>>>>> fitur-coba
        ref.invalidate(todaysAttendanceLogProvider);
        ref.invalidate(todaysJournalStatusProvider);
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
<<<<<<< HEAD
        if (e is OfflineException) {
          _showSnack(
            'Tidak ada internet. Data disimpan lokal.',
            isError: false,
            isWarning: true,
          );
        } else {
          _showSnack('Gagal: $e', isError: true);
        }
=======
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
>>>>>>> fitur-coba
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: isError
            ? Colors.red.shade600
            : isWarning
            ? Colors.orange.shade700
            : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final isCheckIn = widget.mode == AttendanceMode.checkIn;
    final accentColor = isCheckIn
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
=======
>>>>>>> fitur-coba
    final userLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(0, 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FF),
      appBar: AppBar(
<<<<<<< HEAD
        backgroundColor: _kBlue700,
=======
        title: Text(
          widget.mode == AttendanceMode.checkIn
              ? 'Absen Masuk'
              : 'Absen Pulang',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
>>>>>>> fitur-coba
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isCheckIn ? 'Absen Masuk' : 'Absen Pulang',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
<<<<<<< HEAD
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _kBlue700))
=======
      body: _currentPosition == null
          ? Center(
              child: CircularProgressIndicator(color: Colors.blue.shade700),
            )
>>>>>>> fitur-coba
          : Column(
              children: [
                // ── Map ────────────────────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
<<<<<<< HEAD
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: userLatLng,
                          initialZoom: 16,
=======
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.smkn1garut.sip',
                      ),
                      if (_companyLocation != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _companyLocation!,
                              radius: _radiusMeter,
                              useRadiusInMeter: true,
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderColor: Colors.blue.shade700,
                              borderStrokeWidth: 2,
                            ),
                          ],
>>>>>>> fitur-coba
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.smkn1garut.sip',
                          ),
                          if (_companyLocation != null)
<<<<<<< HEAD
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _companyLocation!,
                                  radius: _radiusMeter,
                                  useRadiusInMeter: true,
                                  color: _kBlue500.withOpacity(0.15),
                                  borderColor: _kBlue700,
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              if (_companyLocation != null)
                                Marker(
                                  point: _companyLocation!,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: _kBlue700,
                                    size: 36,
                                  ),
                                ),
                              Marker(
                                point: userLatLng,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
=======
                            Marker(
                              point: _companyLocation!,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.blue,
                                size: 40,
                              ),
                            ),
                          Marker(
                            point: userLatLng,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.red,
                              size: 40,
                            ),
>>>>>>> fitur-coba
                          ),
                        ],
                      ),
                      // Refresh location button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: _initData,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              LucideIcons.refreshCcw,
                              size: 18,
                              color: _kBlue700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
<<<<<<< HEAD

                // ── Bottom Panel ───────────────────────────────────────────
=======
>>>>>>> fitur-coba
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
<<<<<<< HEAD
                        color: Colors.black12,
=======
                        color: Colors.black.withValues(alpha: 0.1),
>>>>>>> fitur-coba
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status card
                      _StatusCard(
                        isWithinRange: _isWithinRange,
                        hasPlacement: _companyLocation != null,
                        companyName: _companyName,
                        distance: _distance,
                      ),
                      const SizedBox(height: 16),

                      // Selfie preview / pick button
                      _SelfieSection(
                        selfieBytes: _selfieBytes,
                        onTap: _pickSelfie,
                        isWeb: kIsWeb,
                        isWithinRange: _isWithinRange,
                      ),
                      const SizedBox(height: 16),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (_isWithinRange &&
                                  !_isSubmitting &&
                                  _selfieBytes != null)
                              ? _handleAction
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade200,
                            disabledForegroundColor: Colors.grey.shade400,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isCheckIn
                                          ? LucideIcons.logIn
                                          : LucideIcons.logOut,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      isCheckIn
                                          ? 'Absen Masuk Sekarang'
                                          : 'Absen Pulang Sekarang',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Status Card ──────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final bool isWithinRange, hasPlacement;
  final String companyName;
  final double distance;

  const _StatusCard({
    required this.isWithinRange,
    required this.hasPlacement,
    required this.companyName,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = !hasPlacement
        ? Colors.orange.shade50
        : isWithinRange
        ? Colors.green.shade50
        : Colors.red.shade50;
    final Color border = !hasPlacement
        ? Colors.orange.shade200
        : isWithinRange
        ? Colors.green.shade200
        : Colors.red.shade200;
    final Color iconColor = !hasPlacement
        ? Colors.orange.shade700
        : isWithinRange
        ? Colors.green.shade700
        : Colors.red.shade700;
    final IconData icon = !hasPlacement
        ? LucideIcons.alertCircle
        : isWithinRange
        ? LucideIcons.checkCircle
        : LucideIcons.mapPin;
    final String title = !hasPlacement
        ? 'Belum Ada Penempatan'
        : isWithinRange
        ? 'Lokasi Terverifikasi ✓'
        : 'Di Luar Jangkauan';
    final String sub = !hasPlacement
        ? 'Hubungi admin untuk penempatan PKL'
        : '$companyName · ${distance.toStringAsFixed(0)}m';

<<<<<<< HEAD
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: iconColor,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: iconColor.withOpacity(0.8),
                  ),
                ),
              ],
=======
  Widget _buildStatusCard() {
    return InkWell(
      onTap: () {
        setState(() => _isLoading = true);
        _initData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Memperbarui lokasi dan data...")),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isWithinRange
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isWithinRange
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.red.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isWithinRange
                  ? Icons.check_circle_rounded
                  : Icons.location_off_rounded,
              color: _isWithinRange ? Colors.green : Colors.red,
              size: 28,
>>>>>>> fitur-coba
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _companyLocation == null
                        ? "Belum ada Penempatan (Klik untuk cek)"
                        : (_isWithinRange
                              ? "Lokasi Terverifikasi"
                              : "Diluar Jangkauan"),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _isWithinRange
                          ? Colors.green[800]
                          : Colors.red[800],
                    ),
                  ),
                  if (_companyLocation != null)
                    Text(
                      "$_companyName (${_distance.toStringAsFixed(0)}m)",
                      style: GoogleFonts.poppins(
                        color: Colors.blue.shade900,
                        fontSize: 13,
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

<<<<<<< HEAD
// ─── Selfie Section ───────────────────────────────────────────────────────────
class _SelfieSection extends StatelessWidget {
  final Uint8List? selfieBytes;
  final VoidCallback onTap;
  final bool isWeb;
  final bool isWithinRange;

  const _SelfieSection({
    required this.selfieBytes,
    required this.onTap,
    required this.isWeb,
    required this.isWithinRange,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: selfieBytes != null
              ? Colors.transparent
              : (!isWithinRange
                    ? Colors.grey.shade50
                    : const Color(0xFFF0F5FF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selfieBytes != null
                ? _kBlue500.withOpacity(0.4)
                : (!isWithinRange
                      ? Colors.grey.shade200
                      : const Color(0xFFBBDEFB)),
            width: 2,
          ),
        ),
        child: selfieBytes != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      selfieBytes!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.refreshCcw,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ganti',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !isWithinRange
                          ? Colors.grey.shade100
                          : _kBlue500.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      !isWithinRange
                          ? LucideIcons.mapPinOff
                          : (isWeb ? LucideIcons.image : LucideIcons.camera),
                      color: !isWithinRange ? Colors.grey.shade400 : _kBlue700,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !isWithinRange
                            ? 'Tidak Dalam Radius'
                            : (isWeb ? 'Pilih Foto Selfie' : 'Ambil Selfie'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: !isWithinRange
                              ? Colors.grey.shade400
                              : _kBlue700,
                        ),
                      ),
                      Text(
                        !isWithinRange
                            ? 'Masuk radius PKL untuk bisa selfie'
                            : (isWeb
                                  ? 'Pilih dari galeri (kamera tidak\ntersedia di browser)'
                                  : 'Tap untuk buka kamera depan'),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
=======
  Widget _buildActionButton() {
    return ElevatedButton.icon(
      onPressed: !_isLoading ? _handleAction : null,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.camera_alt_rounded),
      label: Text(
        _isLoading
            ? 'Memproses...'
            : (widget.mode == AttendanceMode.checkIn
                  ? 'Ambil Selfie & Masuk'
                  : 'Ambil Selfie & Pulang'),
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.mode == AttendanceMode.checkIn
            ? const Color(0xFF4CAF50)
            : const Color(0xFFEF5350),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        disabledBackgroundColor: Colors.grey[300],
>>>>>>> fitur-coba
      ),
    );
  }
}