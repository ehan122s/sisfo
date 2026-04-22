import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart'; // Ganti ke Flutter Map
import 'package:latlong2/latlong.dart';      // Library koordinat gratis
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Import project kamu
import '../data/attendance_repository.dart';
import '../../authentication/data/auth_repository.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../services/image_compression_service.dart';
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

  // Dynamic Company Data
  LatLng? _companyLocation;
  double _radiusMeter = 100;
  String _companyName = "Lokasi PKL";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      // 1. Get Placement Data dari Repository kamu
      final placement = await ref
          .read(attendanceRepositoryProvider)
          .getStudentPlacement(user.id);

      if (placement != null) {
        final company = placement['companies'];
        _companyName = company['name'];
        _radiusMeter = (company['radius_meter'] as num).toDouble();
        _companyLocation = LatLng(
          (company['latitude'] as num).toDouble(),
          (company['longitude'] as num).toDouble(),
        );
      }

      // 2. Get Current Location
      final position = await ref
          .read(attendanceRepositoryProvider)
          .getCurrentLocation();

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        _updateAttendanceStatus();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateAttendanceStatus() {
    if (_currentPosition == null || _companyLocation == null) return;

    // Hitung Jarak menggunakan Haversine (lewat repository kamu)
    final distance = ref.read(attendanceRepositoryProvider).calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _companyLocation!.latitude,
          _companyLocation!.longitude,
        );

    setState(() {
      _distance = distance;
      _isWithinRange = distance <= _radiusMeter;
    });

    // Pindahkan kamera peta ke lokasi user
    _mapController.move(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      16.0,
    );
  }

  Future<void> _handleAction() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50,
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      final File originalFile = File(pickedFile.path);
      final File imageFile = await ref
          .read(imageCompressionServiceProvider)
          .compressImage(originalFile);

      String photoUrl;
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult.contains(ConnectivityResult.none)) {
        photoUrl = imageFile.path;
      } else {
        photoUrl = await ref
            .read(attendanceRepositoryProvider)
            .uploadSelfie(imageFile, user.id);
      }

      String successMessage = '';
      if (widget.mode == AttendanceMode.checkIn) {
        successMessage = await ref.read(attendanceRepositoryProvider).checkIn(
              studentId: user.id,
              lat: _currentPosition!.latitude,
              long: _currentPosition!.longitude,
              photoUrl: photoUrl,
            );
      } else {
        await ref.read(attendanceRepositoryProvider).checkOut(
              studentId: user.id,
              lat: _currentPosition!.latitude,
              long: _currentPosition!.longitude,
              photoUrl: photoUrl,
            );
        successMessage = 'Absen Pulang Berhasil!';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
        ref.invalidate(todaysAttendanceLogProvider);
        ref.invalidate(todaysJournalStatusProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String message = 'Gagal: $e';
        Color color = Colors.red;
        if (e is OfflineException) {
          message = 'Tidak ada internet. Data disimpan lokal.';
          color = Colors.orange;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLatLng = _currentPosition != null 
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) 
        : const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == AttendanceMode.checkIn ? 'Absen Masuk' : 'Absen Pulang',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator(color: Colors.blue.shade700))
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
                        userAgentPackageName: 'com.smkn1garut.sip',
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
                // Panel Bawah (Status & Tombol)
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
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 24),
                      _buildActionButton(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isWithinRange ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isWithinRange ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isWithinRange ? Icons.check_circle_rounded : Icons.location_off_rounded,
            color: _isWithinRange ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _companyLocation == null
                      ? "Belum ada Penempatan"
                      : (_isWithinRange ? "Lokasi Terverifikasi" : "Diluar Jangkauan"),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _isWithinRange ? Colors.green[800] : Colors.red[800],
                  ),
                ),
                if (_companyLocation != null)
                  Text(
                    "$_companyName (${_distance.toStringAsFixed(0)}m)",
                    style: GoogleFonts.poppins(color: Colors.blue.shade900, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton.icon(
      onPressed: (_isWithinRange && !_isLoading) ? _handleAction : null,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.camera_alt_rounded),
      label: Text(
        _isLoading ? 'Memproses...' : (widget.mode == AttendanceMode.checkIn ? 'Ambil Selfie & Masuk' : 'Ambil Selfie & Pulang'),
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.mode == AttendanceMode.checkIn ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        disabledBackgroundColor: Colors.grey[300],
      ),
    );
  }
}