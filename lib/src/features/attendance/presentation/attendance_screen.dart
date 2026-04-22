import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

// Import project kamu
import '../data/attendance_repository.dart';
import '../../authentication/data/auth_repository.dart';
import '../../journal/data/journal_repository.dart';

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
  bool _isWithinRange = false;
  double _distance = 0.0;

  LatLng? _companyLocation;
  double _radiusMeter = 100;
  String _companyName = 'Lokasi PKL';
  int? _placementId;

  XFile? _selfieFile;
  Uint8List? _selfieBytes;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    final placement = await ref
        .read(attendanceRepositoryProvider)
        .getStudentPlacement(user.id);

    if (placement != null) {
      _placementId = placement['id'];
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            16.0,
          );
        }
      });
    }
  }

  void _updateStatus() {
    if (_currentPosition == null || _companyLocation == null) return;

    final dist = ref
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
  }

  Future<void> _pickSelfie() async {
    if (!_isWithinRange) {
      _showSnack('Di luar radius! Tidak bisa absen.', isError: true);
      return;
    }

    final source = kIsWeb ? ImageSource.gallery : ImageSource.camera;

    final picked = await ImagePicker().pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _selfieFile = picked;
      _selfieBytes = bytes;
    });
  }

  Future<void> _handleAction() async {
    if (_placementId == null) {
      _showSnack('Belum ada penempatan PKL. Hubungi admin.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      final photoUrl = await ref
          .read(attendanceRepositoryProvider)
          .uploadSelfieBytes(_selfieBytes!, user.id);

      String successMessage = '';

      if (widget.mode == AttendanceMode.checkIn) {
        successMessage = await ref
            .read(attendanceRepositoryProvider)
            .checkIn(
              studentId: user.id,
              placementId: _placementId!,
              lat: _currentPosition!.latitude,
              long: _currentPosition!.longitude,
              photoUrl: photoUrl,
            );
      } else {
        await ref
            .read(attendanceRepositoryProvider)
            .checkOut(
              studentId: user.id,
              placementId: _placementId!,
              lat: _currentPosition!.latitude,
              long: _currentPosition!.longitude,
              photoUrl: photoUrl,
            );
        successMessage = 'Absen Pulang Berhasil!';
      }

      if (mounted) {
        _showSnack(successMessage, isError: false);
        ref.invalidate(todaysAttendanceLogProvider);
        ref.invalidate(todaysJournalStatusProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Gagal: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Colors.red
            : isWarning
            ? Colors.orange
            : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCheckIn = widget.mode == AttendanceMode.checkIn;
    final userLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCheckIn ? 'Absen Masuk' : 'Absen Pulang',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue.shade700),
                  const SizedBox(height: 12),
                  Text(
                    'Memuat data lokasi...',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: userLatLng,
                      initialZoom: 16,
                    ),
                    children: [
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
                        ),
                      MarkerLayer(
                        markers: [
                          if (_companyLocation != null)
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusCard(
                        isWithinRange: _isWithinRange,
                        hasPlacement: _placementId != null,
                        companyName: _companyName,
                        distance: _distance,
                        onRefresh: _initData,
                      ),
                      const SizedBox(height: 16),
                      _SelfieSection(
                        selfieBytes: _selfieBytes,
                        onTap: _pickSelfie,
                        isWithinRange: _isWithinRange,
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(isCheckIn),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton(bool isCheckIn) {
    final bool canAbsen =
        !_isLoading &&
        _isWithinRange &&
        _placementId != null &&
        _selfieBytes != null;

    return ElevatedButton.icon(
      onPressed: canAbsen ? _handleAction : null,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Icon(isCheckIn ? Icons.login : Icons.logout),
      label: Text(
        _isLoading
            ? 'Memproses...'
            : _placementId == null
            ? 'Belum Ada Penempatan'
            : !_isWithinRange
            ? 'Diluar Jangkauan'
            : _selfieBytes == null
            ? 'Ambil Selfie Dulu'
            : isCheckIn
            ? 'Absen Masuk'
            : 'Absen Pulang',
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCheckIn
            ? const Color(0xFF4CAF50)
            : const Color(0xFFEF5350),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        disabledBackgroundColor: Colors.grey[300],
      ),
    );
  }
}

// ================== STATUS CARD ==================
class _StatusCard extends StatelessWidget {
  final bool isWithinRange;
  final bool hasPlacement;
  final String companyName;
  final double distance;
  final VoidCallback onRefresh;

  const _StatusCard({
    required this.isWithinRange,
    required this.hasPlacement,
    required this.companyName,
    required this.distance,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = !hasPlacement
        ? Colors.orange.withValues(alpha: 0.1)
        : isWithinRange
        ? Colors.green.withValues(alpha: 0.1)
        : Colors.red.withValues(alpha: 0.1);

    final Color border = !hasPlacement
        ? Colors.orange.withValues(alpha: 0.3)
        : isWithinRange
        ? Colors.green.withValues(alpha: 0.3)
        : Colors.red.withValues(alpha: 0.3);

    final Color iconColor = !hasPlacement
        ? Colors.orange
        : isWithinRange
        ? Colors.green
        : Colors.red;

    final IconData icon = !hasPlacement
        ? Icons.warning_amber_rounded
        : isWithinRange
        ? Icons.check_circle_rounded
        : Icons.location_off_rounded;

    final String title = !hasPlacement
        ? 'Belum ada penempatan'
        : isWithinRange
        ? 'Lokasi Terverifikasi'
        : 'Diluar Jangkauan';

    final String sub = !hasPlacement
        ? 'Hubungi admin untuk penempatan'
        : '$companyName · ${distance.toStringAsFixed(0)}m';

    return InkWell(
      onTap: onRefresh,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: iconColor,
                    ),
                  ),
                  Text(
                    sub,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.refresh, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

// ================== SELFIE SECTION ==================
class _SelfieSection extends StatelessWidget {
  final Uint8List? selfieBytes;
  final VoidCallback onTap;
  final bool isWithinRange;

  const _SelfieSection({
    required this.selfieBytes,
    required this.onTap,
    required this.isWithinRange,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: selfieBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(selfieBytes!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isWithinRange
                        ? 'Tap untuk ambil selfie'
                        : 'Masuk radius dulu',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
