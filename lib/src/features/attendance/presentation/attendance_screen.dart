import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

// Import repositories
import '../data/attendance_repository.dart';
import '../../authentication/data/auth_repository.dart';

enum AttendanceMode { checkIn, checkOut }

class AttendanceScreen extends ConsumerStatefulWidget {
  final AttendanceMode mode;
  
  const AttendanceScreen({super.key, required this.mode});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  // State variables
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
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _initData();
    });
  }

  Future<void> _initData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) {
        if (mounted) _showSnack('Sesi habis, silakan login ulang', isError: true);
        return;
      }

      final placement = await ref
          .read(attendanceRepositoryProvider)
          .getStudentPlacement(user.id);

      if (placement != null && mounted) {
        final company = placement['companies'];
        setState(() {
          _placementId = placement['id'];
          _companyName = company['name'] ?? 'Lokasi PKL';
          _radiusMeter = (company['radius_meter'] as num?)?.toDouble() ?? 100.0;
          
          final lat = company['latitude'] as num?;
          final lng = company['longitude'] as num?;
          
          if (lat != null && lng != null) {
            _companyLocation = LatLng(lat.toDouble(), lng.toDouble());
          }
        });
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
      }
      
    } catch (e) {
      debugPrint('❌ Error _initData: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        String errorMsg = 'Gagal memuat data';
        if (e.toString().contains('LateInitializationError')) {
          errorMsg = '⚠️ Error peta. Silakan refresh (F5).';
        } else if (e.toString().contains('Permission')) {
          errorMsg = '⚠️ Izin lokasi ditolak.';
        }
        
        _showSnack(errorMsg, isError: true);
      }
    }
  }

  void _updateAttendanceStatus() {
    if (_currentPosition == null || _companyLocation == null) return;

    try {
      final dist = ref
          .read(attendanceRepositoryProvider)
          .calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            _companyLocation!.latitude,
            _companyLocation!.longitude,
          );

      if (mounted) {
        setState(() {
          _distance = dist;
          _isWithinRange = dist <= _radiusMeter;
        });
      }
    } catch (e) {
      debugPrint('Error distance calc: $e');
    }
  }

  Future<void> _pickSelfie() async {
    if (!_isWithinRange) {
      _showSnack('❌ Di luar radius lokasi!', isError: true);
      return;
    }

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      if (mounted) {
        setState(() {
          _selfieFile = picked;
          _selfieBytes = bytes;
        });
        
        _showSnack('✅ Foto berhasil!');
      }
    } catch (e) {
      debugPrint('Error camera: $e');
      if (mounted) {
        _showSnack('❌ Gagal ambil foto', isError: true);
      }
    }
  }

  Future<void> _handleAction() async {
    if (_placementId == null) {
      _showSnack('⚠️ Belum ada penempatan PKL', isError: true);
      return;
    }
    
    if (_selfieBytes == null) {
      _showSnack('⚠️ Ambil foto selfie dulu!', isError: true);
      return;
    }
    
    if (!_isWithinRange) {
      _showSnack('⚠️ Di luar radius lokasi!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('Not logged in');

      _showSnack('📤 Mengupload...');

      final photoUrl = await ref
          .read(attendanceRepositoryProvider)
          .uploadSelfieBytes(_selfieBytes!, user.id);

      final isCheckIn = widget.mode == AttendanceMode.checkIn;

      _showSnack(isCheckIn ? '🔄 Absen masuk...' : '🔄 Absen pulang...');

      if (isCheckIn) {
        await ref.read(attendanceRepositoryProvider).checkIn(
              studentId: user.id,
              placementId: _placementId!,
              lat: _currentPosition!.latitude,
              long: _currentPosition!.longitude,
              photoUrl: photoUrl,
            );
      } else {
        await ref.read(attendanceRepositoryProvider).checkOut(
              studentId: user.id,
              placementId: _placementId!,
              lat: _currentPosition!.latitude,
              long: _currentPosition!.longitude,
              photoUrl: photoUrl,
            );
      }

      if (mounted) {
        _showSnack(isCheckIn ? '✅ Absen Masuk Berhasil!' : '✅ Absen Pulang Berhasil!');
        ref.invalidate(todaysAttendanceLogProvider);
        
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      debugPrint('Error absen: $e');
      if (mounted) {
        _showSnack('❌ Gagal', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 14)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCheckIn = widget.mode == AttendanceMode.checkIn;
    final userLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2088, 106.8456); // Default Jakarta

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCheckIn ? 'Absen Masuk' : 'Absen Pulang',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isCheckIn ? Colors.blue : Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _initData(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(userLatLng, isCheckIn),
    );
  }

  Widget _buildBody(LatLng userLatLng, bool isCheckIn) {
    if (_isLoading && _currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 20),
            Text('🔍 Mencari lokasi...', style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(flex: 3, child: _buildMapSection(userLatLng)),
        Expanded(flex: 2, child: _buildFormSection(isCheckIn)),
      ],
    );
  }

  /// ✅ MAP SECTION - COMPATIBLE DENGAN FLUTTER_MAP V6.2.1
  Widget _buildMapSection(LatLng userLatLng) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            center: userLatLng,
            zoom: 17.0,
            minZoom: 15.0,
            maxZoom: 19.0,
            interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.sip_smea',
            ),
            
            if (_companyLocation != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _companyLocation!,
                    radius: _radiusMeter,
                    color: _isWithinRange 
                        ? Colors.green.withOpacity(0.3) 
                        : Colors.red.withOpacity(0.3),
                    borderColor: _isWithinRange ? Colors.green : Colors.red,
                    borderStrokeWidth: 3,
                  ),
                ],
              ),
            
            // ✅ MARKER LAYER DENGAN API YANG BENAR UNTUK V6.2.1
            MarkerLayer(markers: _buildMarkers(userLatLng)),
          ],
        ),
        
        // Distance overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isWithinRange ? Icons.check_circle : Icons.cancel,
                  color: _isWithinRange ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Jarak: ${_distance.toStringAsFixed(1)}m',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isWithinRange ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ BUILD MARKERS - MENGGUNAKAN `child` BUKAN `builder` (V6.2.1 API)
  List<Marker> _buildMarkers(LatLng userLatLng) {
    final markers = <Marker>[];
    
    // Marker lokasi PKL
    if (_companyLocation != null) {
      markers.add(Marker(
        point: _companyLocation!,
        width: 120,
        height: 80,
        alignment: Alignment.topCenter, // ✅ v6.2.1: gunakan alignment, bukan anchor
        child: Column(  // ✅ FIX: gunakan `child`, bukan `builder`
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Text(
                _companyName, 
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.location_on, color: Colors.blue, size: 40),
          ],
        ),
      ));
    }
    
    // Marker posisi user
    markers.add(Marker(
      point: userLatLng,
      width: 44,
      height: 44,
      alignment: Alignment.center, // ✅ v6.2.1: alignment
      child: Container(  // ✅ FIX: gunakan `child`, bukan `builder`
        decoration: BoxDecoration(
          color: _isWithinRange ? Colors.green : Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 24),
      ),
    ));
    
    return markers;
  }

  Widget _buildFormSection(bool isCheckIn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: SingleChildScrollView(
        child: Column(
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
    );
  }

  Widget _buildActionButton(bool isCheckIn) {
    final canAbsen = !_isLoading && _isWithinRange && _placementId != null && _selfieBytes != null;
    
    return ElevatedButton.icon(
      onPressed: canAbsen ? _handleAction : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canAbsen ? (isCheckIn ? Colors.green : Colors.orange) : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: _isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(isCheckIn ? Icons.login : Icons.logout),
      label: Text(
        _isLoading ? 'Memproses...' : (isCheckIn ? '✓ Absen Masuk' : '✓ Absen Pulang'),
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ==================== WIDGET PENDUKUNG ====================

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
    Color color;
    IconData icon;
    String title;

    if (!hasPlacement) {
      color = Colors.orange;
      icon = Icons.warning;
      title = 'Belum Ada Penempatan';
    } else if (isWithinRange) {
      color = Colors.green;
      icon = Icons.check_circle;
      title = '✓ Lokasi OK';
    } else {
      color = Colors.red;
      icon = Icons.cancel;
      title = '✕ Di Luar Jangkauan';
    }

    return InkWell(
      onTap: onRefresh,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
                  Text('$companyName (${distance.toStringAsFixed(0)}m)', style: TextStyle(fontSize: 12, color: color.withOpacity(0.6))),
                ],
              ),
            ),
            const Icon(Icons.refresh, size: 18, color: Colors.grey),
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
      onTap: isWithinRange ? onTap : null,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isWithinRange ? Colors.grey[300]! : Colors.grey[200]!),
        ),
        child: selfieBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(fit: StackFit.expand, children: [
                  Image.memory(selfieBytes!, fit: BoxFit.cover),
                  Positioned(top: 8, right: 8,
                    child: GestureDetector(
                      onTap: onTap,
                      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 18)),
                    )),
                ]),
              )
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.camera_alt, size: 44, color: isWithinRange ? Colors.blue : Colors.grey),
                const SizedBox(height: 8),
                Text(isWithinRange ? 'Tap untuk Selfie' : '⛔ Harus dalam radius', style: TextStyle(color: isWithinRange ? Colors.blue : Colors.grey)),
              ]),
      ),
    );
  }
}