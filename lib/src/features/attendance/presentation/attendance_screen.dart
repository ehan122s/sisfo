import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

// Import project kamu (Sesuaikan path ini jika masih ada merah di import)
import '../data/attendance_repository.dart';
import '../../authentication/data/auth_repository.dart';
import '../../journal/data/journal_repository.dart';
import '../../../services/image_compression_service.dart';

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

  void _updateStatus() {
    _updateAttendanceStatus();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      final placement = await ref
          .read(attendanceRepositoryProvider)
          .getStudentPlacement(user.id);

      if (placement != null) {
        _placementId = placement['id'];
        final company = placement['companies'];
        _companyName = company['name'] ?? 'Lokasi PKL';
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
        _updateAttendanceStatus();

        if (_currentPosition != null) {
          _mapController.move(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            16.0,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Gagal memuat data: $e', isError: true);
      }
    }
  }

  void _updateAttendanceStatus() {
    if (_currentPosition == null || _companyLocation == null) return;

    final dist = ref.read(attendanceRepositoryProvider).calculateDistance(
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

    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _selfieFile = picked;
      _selfieBytes = bytes;
    });
  }

  Future<void> _handleAction() async {
    if (_placementId == null || _selfieFile == null) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      // Simulasi upload/proses (Sesuaikan dengan logic repository kamu)
      String successMessage = '';
      final isCheckIn = widget.mode == AttendanceMode.checkIn;

      if (isCheckIn) {
        await ref.read(attendanceRepositoryProvider).checkIn(
              studentId: user.id,
              placementId: _placementId!,
              lat: _currentPosition!.latitude,
              long: _currentPosition!.longitude,
              photoUrl: _selfieFile!.path, // Sesuaikan jika butuh upload dulu
            );
        successMessage = 'Absen Masuk Berhasil!';
      } else {
        await ref.read(attendanceRepositoryProvider).checkOut(
              studentId: user.id,
              placementId: _placementId!,
              lat: _currentPosition!.latitude,
              long: _currentPosition!.longitude,
              photoUrl: _selfieFile!.path,
            );
        successMessage = 'Absen Pulang Berhasil!';
      }

      if (mounted) {
        _showSnack(successMessage, isError: false);
        // Refresh data setelah sukses
        ref.invalidate(todaysAttendanceLogProvider);
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

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
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
      body: _isLoading && _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
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
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      if (_companyLocation != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _companyLocation!,
                              radius: _radiusMeter,
                              useRadiusInMeter: true,
                              color: Colors.blue.withOpacity(0.2),
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
                              child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                            ),
                          Marker(
                            point: userLatLng,
                            child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
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
    final bool canAbsen = !_isLoading &&
        _isWithinRange &&
        _placementId != null &&
        _selfieBytes != null;
    final isCheckIn = widget.mode == AttendanceMode.checkIn;

    return ElevatedButton.icon(
      onPressed: canAbsen ? _handleAction : null,
      icon: _isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
                        : isCheckIn ? 'Absen Masuk' : 'Absen Pulang',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCheckIn ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

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
    return InkWell(
      onTap: onRefresh,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isWithinRange ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isWithinRange ? Colors.green : Colors.red),
        ),
        child: Row(
          children: [
            Icon(isWithinRange ? Icons.check_circle : Icons.location_off, color: isWithinRange ? Colors.green : Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isWithinRange ? 'Lokasi Terverifikasi' : 'Di Luar Jangkauan', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('$companyName (${distance.toStringAsFixed(0)}m)'),
                ],
              ),
            ),
            const Icon(Icons.refresh, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SelfieSection extends StatelessWidget {
  final Uint8List? selfieBytes;
  final VoidCallback onTap;
  final bool isWithinRange;

  const _SelfieSection({this.selfieBytes, required this.onTap, required this.isWithinRange});

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
                child: Image.memory(selfieBytes!, fit: BoxFit.cover, width: double.infinity),
              )
            : const Center(child: Icon(Icons.camera_alt, size: 32, color: Colors.grey)),
      ),
    );
  }
}