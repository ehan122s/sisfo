import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Jangan lupa import ini agar tidak eror
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/attendance_repository.dart';
import '../../authentication/data/auth_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isWithinRange = false;
  double _distance = 0.0;

  // Dynamic Company Data
  LatLng? _companyLocation;
  double _radiusMeter = 100;
  String _companyName = "Lokasi PKL";

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) return;

      // 1. Get Placement Data
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
        _updateMapUI();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateMapUI() {
    if (_currentPosition == null) return;

    final userLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    if (_companyLocation != null) {
      final distance = ref
          .read(attendanceRepositoryProvider)
          .calculateDistance(
            userLatLng.latitude,
            userLatLng.longitude,
            _companyLocation!.latitude,
            _companyLocation!.longitude,
          );
      _distance = distance;
      _isWithinRange = distance <= _radiusMeter;

      _markers = {
        Marker(
          markerId: const MarkerId('company'),
          position: _companyLocation!,
          infoWindow: InfoWindow(title: _companyName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
        Marker(
          markerId: const MarkerId('user'),
          position: userLatLng,
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
      _circles = {
        Circle(
          circleId: const CircleId('radius'),
          center: _companyLocation!,
          radius: _radiusMeter,
          fillColor: Colors.blue.withOpacity(0.15),
          strokeColor: Colors.blue.shade700,
          strokeWidth: 2,
        ),
      };
    } else {
      _markers = {
        Marker(
          markerId: const MarkerId('user'),
          position: userLatLng,
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
      _isWithinRange = false;
    }

    setState(() {});

    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(userLatLng));
    }
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
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult.contains(ConnectivityResult.none)) {
        photoUrl = imageFile.path;
      } else {
        photoUrl = await ref
            .read(attendanceRepositoryProvider)
            .uploadSelfie(imageFile, user.id);
      }

      String successMessage = '';
      if (widget.mode == AttendanceMode.checkIn) {
        successMessage = await ref
            .read(attendanceRepositoryProvider)
            .checkIn(
              studentId: user.id,
              lat: _currentPosition!.latitude,
              long: _currentPosition!.longitude,
              photoUrl: photoUrl,
            );
      } else {
        await ref
            .read(attendanceRepositoryProvider)
            .checkOut(
              studentId: user.id,
              lat: _currentPosition!.latitude,
              long: _currentPosition!.longitude,
              photoUrl: photoUrl,
            );
        successMessage = 'Absen Pulang Berhasil!';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == AttendanceMode.checkIn ? 'Absen Masuk' : 'Absen Pulang',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700, // Header Biru
        foregroundColor: Colors.white,
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator(color: Colors.blue.shade700))
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 16,
                    ),
                    markers: _markers,
                    circles: _circles,
                    myLocationEnabled: true,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _updateMapUI();
                    },
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
                      // Status Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isWithinRange
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isWithinRange
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isWithinRange
                                  ? Icons.check_circle_rounded
                                  : Icons.location_off_rounded,
                              color: _isWithinRange ? Colors.green : Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _companyLocation == null
                                        ? "Belum ada Penempatan"
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
                                        color: Colors.blue.shade900, // Teks detail Biru Gelap
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Action Button
                      ElevatedButton.icon(
                        onPressed: (_isWithinRange && !_isLoading) ? _handleAction : null,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt_rounded),
                        label: Text(
                          _isLoading
                              ? 'Memproses...'
                              : (widget.mode == AttendanceMode.checkIn
                                  ? 'Ambil Selfie & Masuk'
                                  : 'Ambil Selfie & Pulang'),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.mode == AttendanceMode.checkIn
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFEF5350),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey[300],
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