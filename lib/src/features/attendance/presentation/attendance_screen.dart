import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/attendance_repository.dart';
import '../data/attendance_timer_provider.dart';
import '../../authentication/data/auth_repository.dart';
import '../../../core/services/anti_fake_gps_service.dart';

enum AttendanceMode { checkIn, checkOut }

class AttendanceScreen extends ConsumerStatefulWidget {
  final AttendanceMode mode;
  const AttendanceScreen({super.key, required this.mode});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
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

  // Anti Fake GPS
  final AntiFakeGpsService _antiFakeGps = AntiFakeGpsService();
  FakeGpsDetectionResult? _detectionResult;
  bool _fakeGpsBlocked = false;
  List<String> _fakeGpsWarnings = [];
  FakeGpsRisk _fakeGpsRisk = FakeGpsRisk.none;
  StreamSubscription<Position>? _positionMonitor;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _initData();
    });
  }

  @override
  void dispose() {
    _positionMonitor?.cancel();
    _antiFakeGps.dispose();
    super.dispose();
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

      final placement = await ref.read(attendanceRepositoryProvider).getStudentPlacement(user.id);
      if (placement != null && mounted) {
        final company = placement['companies'];
        setState(() {
          _placementId = placement['id'];
          _companyName = company['name'] ?? 'Lokasi PKL';
          _radiusMeter = (company['radius_meter'] as num?)?.toDouble() ?? 100.0;
          final lat = company['latitude'] as num?;
          final lng = company['longitude'] as num?;
          if (lat != null && lng != null) _companyLocation = LatLng(lat.toDouble(), lng.toDouble());
        });
      }

      final position = await ref.read(attendanceRepositoryProvider).getCurrentLocation();
      if (mounted) {
        setState(() { _currentPosition = position; _isLoading = false; });
        _updateAttendanceStatus();
        await _runFakeGpsCheck(position);
        _startRealTimeMonitoring();
      }
    } catch (e) {
      debugPrint('❌ Error _initData: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMsg = 'Gagal memuat data';
        if (e.toString().contains('LateInitializationError')) errorMsg = '⚠️ Error peta. Silakan refresh.';
        else if (e.toString().contains('Permission')) errorMsg = '⚠️ Izin lokasi ditolak.';
        _showSnack(errorMsg, isError: true);
      }
    }
  }

  Future<void> _runFakeGpsCheck(Position position) async {
    try {
      final result = await _antiFakeGps.performDeepCheck(position);
      if (mounted) {
        setState(() { _detectionResult = result; _fakeGpsRisk = result.risk; _fakeGpsWarnings = result.warnings; _fakeGpsBlocked = result.isBlocked; });
        if (result.isBlocked) _showFakeGpsDialog(result);
        else if (result.warnings.isNotEmpty) _showSnack('⚠️ ${result.warnings.first}', isError: result.risk == FakeGpsRisk.medium);
      }
    } catch (e) { debugPrint('🔴 Fake GPS check error: $e'); }
  }

  void _startRealTimeMonitoring() {
    _positionMonitor?.cancel();
    _positionMonitor = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      if (!mounted) return;
      final result = _antiFakeGps.performQuickCheck(position);
      setState(() { _currentPosition = position; });
      _updateAttendanceStatus();
      if (result.isBlocked && !_fakeGpsBlocked) {
        setState(() { _fakeGpsBlocked = true; _fakeGpsRisk = result.risk; _fakeGpsWarnings = result.warnings; _detectionResult = result; });
        _showFakeGpsDialog(result);
        _positionMonitor?.cancel();
      }
    }, onError: (error) => debugPrint('🔴 Monitor error: $error'));
  }

  Future<bool> _verifyBeforeSubmit() async {
    if (_fakeGpsBlocked) return false;
    setState(() => _isVerifying = true);
    _showSnack('🔍 Memverifikasi lokasi...');
    try {
      final result = await _antiFakeGps.performMultiSampleVerification(sampleCount: 3, interval: const Duration(seconds: 2));
      if (mounted) {
        setState(() { _detectionResult = result; _fakeGpsRisk = result.risk; _fakeGpsWarnings = result.warnings; _fakeGpsBlocked = result.isBlocked; _isVerifying = false; });
        if (result.isBlocked) { _showFakeGpsDialog(result); return false; }
        return true;
      }
    } catch (e) {
      if (mounted) setState(() => _isVerifying = false);
    }
    return false;
  }

  void _showFakeGpsDialog(FakeGpsDetectionResult result) {
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => _FakeGpsWarningDialog(
      result: result,
      onRetry: () { Navigator.pop(ctx); _resetFakeGpsState(); _initData(); },
      onExit: () { Navigator.pop(ctx); Navigator.pop(context); },
    ));
  }

  void _resetFakeGpsState() {
    setState(() { _fakeGpsBlocked = false; _fakeGpsWarnings = []; _fakeGpsRisk = FakeGpsRisk.none; _detectionResult = null; });
  }

  void _updateAttendanceStatus() {
    if (_currentPosition == null || _companyLocation == null) return;
    try {
      final dist = ref.read(attendanceRepositoryProvider).calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, _companyLocation!.latitude, _companyLocation!.longitude);
      if (mounted) setState(() { _distance = dist; _isWithinRange = dist <= _radiusMeter; });
    } catch (e) { debugPrint('Error distance calc: $e'); }
  }

  Future<void> _pickSelfie() async {
    if (_fakeGpsBlocked) { _showSnack('⛔ Lokasi palsu terdeteksi!', isError: true); return; }
    if (!_isWithinRange) { _showSnack('❌ Di luar radius lokasi!', isError: true); return; }
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front, imageQuality: 50, maxWidth: 800, maxHeight: 800);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (mounted) { setState(() { _selfieFile = picked; _selfieBytes = bytes; }); _showSnack('✅ Foto berhasil!'); }
    } catch (e) {
      if (mounted) _showSnack('❌ Gagal ambil foto', isError: true);
    }
  }

  Future<void> _handleAction() async {
    if (_fakeGpsBlocked) { _showSnack('⛔ Lokasi palsu terdeteksi!', isError: true); return; }
    if (_placementId == null) { _showSnack('⚠️ Belum ada penempatan PKL', isError: true); return; }
    if (_selfieBytes == null) { _showSnack('⚠️ Ambil foto selfie dulu!', isError: true); return; }
    if (!_isWithinRange) { _showSnack('⚠️ Di luar radius lokasi!', isError: true); return; }

    final isVerified = await _verifyBeforeSubmit();
    if (!isVerified) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('Not logged in');
      _showSnack('📤 Mengupload...');

      final photoUrl = await ref.read(attendanceRepositoryProvider).uploadSelfieBytes(_selfieBytes!, user.id);
      final isCheckIn = widget.mode == AttendanceMode.checkIn;
      _showSnack(isCheckIn ? '🔄 Absen masuk...' : '🔄 Absen pulang...');

      if (isCheckIn) {
        await ref.read(attendanceRepositoryProvider).checkIn(studentId: user.id, placementId: _placementId!, lat: _currentPosition!.latitude, long: _currentPosition!.longitude, photoUrl: photoUrl);
        // ✅ START TIMER saat check-in berhasil
        ref.read(attendanceTimerProvider.notifier).start(DateTime.now());
      } else {
        await ref.read(attendanceRepositoryProvider).checkOut(studentId: user.id, placementId: _placementId!, lat: _currentPosition!.latitude, long: _currentPosition!.longitude, photoUrl: photoUrl);
        // ✅ STOP TIMER saat check-out berhasil
        ref.read(attendanceTimerProvider.notifier).stop();
      }

      if (mounted) {
        _showSnack(isCheckIn ? '✅ Absen Masuk Berhasil!' : '✅ Absen Pulang Berhasil!');
        ref.invalidate(todaysAttendanceLogProvider);
        Future.delayed(const Duration(seconds: 1), () { if (mounted) Navigator.pop(context, true); });
      }
    } catch (e) {
      debugPrint('Error absen: $e');
      if (mounted) _showSnack('❌ Gagal', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 14)),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isCheckIn = widget.mode == AttendanceMode.checkIn;
    final userLatLng = _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : const LatLng(-6.2088, 106.8456);

    return Scaffold(
      appBar: AppBar(
        title: Text(isCheckIn ? 'Absen Masuk' : 'Absen Pulang', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isCheckIn ? Colors.blue : Colors.orange,
        foregroundColor: Colors.white, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _isLoading ? null : () => _initData(), tooltip: 'Refresh')],
      ),
      body: _buildBody(userLatLng, isCheckIn),
    );
  }

  Widget _buildBody(LatLng userLatLng, bool isCheckIn) {
    if (_isLoading && _currentPosition == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(color: Colors.blue), const SizedBox(height: 20),
        Text('🔍 Mencari lokasi...', style: GoogleFonts.poppins(color: Colors.grey)),
      ]));
    }
    return Column(children: [
      if (_fakeGpsBlocked) _buildFakeGpsBanner(),
      if (_isVerifying) _buildVerifyingBanner(),
      Expanded(flex: 3, child: _buildMapSection(userLatLng)),
      Expanded(flex: 2, child: _buildFormSection(isCheckIn)),
    ]);
  }

  Widget _buildFakeGpsBanner() {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.red.shade700, boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8)]),
      child: Row(children: [
        const Icon(Icons.gpp_bad, color: Colors.white, size: 24), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('⛔ FAKE GPS TERDETEKSI!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
          if (_fakeGpsWarnings.isNotEmpty) Text(_fakeGpsWarnings.first, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ])),
        TextButton(onPressed: () { if (_detectionResult != null) _showFakeGpsDialog(_detectionResult!); }, style: TextButton.styleFrom(foregroundColor: Colors.white), child: const Text('Detail', style: TextStyle(fontSize: 12))),
      ]),
    );
  }

  Widget _buildVerifyingBanner() {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.blue.shade700, boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8)]),
      child: Row(children: [
        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), const SizedBox(width: 12),
        Text('🔍 Memverifikasi lokasi (3 sample)...', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildMapSection(LatLng userLatLng) {
    return Stack(children: [
      FlutterMap(options: MapOptions(center: userLatLng, zoom: 17.0, minZoom: 15.0, maxZoom: 19.0, interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate), children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', subdomains: ['a', 'b', 'c'], userAgentPackageName: 'com.example.sip_smea'),
        if (_companyLocation != null) CircleLayer(circles: [CircleMarker(point: _companyLocation!, radius: _radiusMeter, color: _isWithinRange ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3), borderColor: _fakeGpsBlocked ? Colors.purple : (_isWithinRange ? Colors.green : Colors.red), borderStrokeWidth: 3)]),
        MarkerLayer(markers: _buildMarkers(userLatLng)),
      ]),
      Positioned(top: 16, left: 16, right: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_fakeGpsBlocked ? Icons.gpp_bad : (_isWithinRange ? Icons.check_circle : Icons.cancel), color: _fakeGpsBlocked ? Colors.purple : (_isWithinRange ? Colors.green : Colors.red)),
          const SizedBox(width: 8),
          Text(_fakeGpsBlocked ? '⛔ FAKE GPS!' : 'Jarak: ${_distance.toStringAsFixed(1)}m', style: TextStyle(fontWeight: FontWeight.bold, color: _fakeGpsBlocked ? Colors.purple : (_isWithinRange ? Colors.green : Colors.red))),
        ]),
      )),
    ]);
  }

  List<Marker> _buildMarkers(LatLng userLatLng) {
    final markers = <Marker>[];
    if (_companyLocation != null) markers.add(Marker(point: _companyLocation!, width: 120, height: 80, alignment: Alignment.topCenter, child: Column(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]), child: Text(_companyName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)), const Icon(Icons.location_on, color: Colors.blue, size: 40)])));
    markers.add(Marker(point: userLatLng, width: 44, height: 44, alignment: Alignment.center, child: Container(decoration: BoxDecoration(color: _fakeGpsBlocked ? Colors.purple : (_isWithinRange ? Colors.green : Colors.red), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: _fakeGpsBlocked ? [BoxShadow(color: Colors.purple.withOpacity(0.5), blurRadius: 10)] : null), child: Icon(_fakeGpsBlocked ? Icons.gpp_bad : Icons.person, color: Colors.white, size: 24))));
    return markers;
  }

  Widget _buildFormSection(bool isCheckIn) {
    return Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
      child: SingleChildScrollView(child: Column(children: [
        _StatusCard(isWithinRange: _isWithinRange, hasPlacement: _placementId != null, companyName: _companyName, distance: _distance, onRefresh: _initData, fakeGpsBlocked: _fakeGpsBlocked, fakeGpsRisk: _fakeGpsRisk, fakeGpsWarnings: _fakeGpsWarnings),
        const SizedBox(height: 16),
        _SelfieSection(selfieBytes: _selfieBytes, onTap: _pickSelfie, isWithinRange: _isWithinRange, fakeGpsBlocked: _fakeGpsBlocked),
        const SizedBox(height: 16),
        _buildActionButton(isCheckIn),
      ])),
    );
  }

  Widget _buildActionButton(bool isCheckIn) {
    final canAbsen = !_isLoading && !_isVerifying && !_fakeGpsBlocked && _isWithinRange && _placementId != null && _selfieBytes != null;
    Color btnColor = _fakeGpsBlocked ? Colors.purple.shade300 : _isVerifying ? Colors.blue.shade300 : canAbsen ? (isCheckIn ? Colors.green : Colors.orange) : Colors.grey;

    return ElevatedButton.icon(
      onPressed: canAbsen ? _handleAction : null,
      style: ElevatedButton.styleFrom(backgroundColor: btnColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      icon: _isLoading || _isVerifying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(_fakeGpsBlocked ? Icons.gpp_bad : (isCheckIn ? Icons.login : Icons.logout)),
      label: Text(_isVerifying ? 'Memverifikasi lokasi...' : _fakeGpsBlocked ? '⛔ Lokasi Palsu Terdeteksi' : _isLoading ? 'Memproses...' : (isCheckIn ? '✓ Absen Masuk' : '✓ Absen Pulang'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
    );
  }
}

// ==================== FAKE GPS DIALOG ====================

class _FakeGpsWarningDialog extends StatelessWidget {
  final FakeGpsDetectionResult result;
  final VoidCallback onRetry;
  final VoidCallback onExit;
  const _FakeGpsWarningDialog({required this.result, required this.onRetry, required this.onExit});

  Color _getRiskColor() {
    switch (result.risk) { case FakeGpsRisk.low: return Colors.orange; case FakeGpsRisk.medium: return Colors.deepOrange; case FakeGpsRisk.high: return Colors.red; case FakeGpsRisk.critical: return Colors.red.shade900; case FakeGpsRisk.none: return Colors.green; }
  }
  IconData _getRiskIcon() {
    switch (result.risk) { case FakeGpsRisk.low: return Icons.warning_amber; case FakeGpsRisk.medium: return Icons.warning; case FakeGpsRisk.high: return Icons.gpp_maybe; case FakeGpsRisk.critical: return Icons.gpp_bad; case FakeGpsRisk.none: return Icons.verified_user; }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor();
    return Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(_getRiskIcon(), color: color, size: 40)),
      const SizedBox(height: 16),
      Text(result.risk == FakeGpsRisk.critical ? '🚨 FAKE GPS TERDETEKSI!' : '⚠️ Lokasi Mencurigakan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: color), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))), child: Text('Level: ${result.riskLabel}', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12))),
      const SizedBox(height: 16),
      Container(constraints: const BoxConstraints(maxHeight: 200), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: result.warnings.map((w) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• ', style: TextStyle(fontSize: 14)), Expanded(child: Text(w, style: const TextStyle(fontSize: 13)))]))).toList()))),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Column(children: [Text('Untuk melanjutkan absensi:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)), const SizedBox(height: 4), Text('1. Tutup aplikasi fake GPS\n2. Nonaktifkan Developer Options\n3. Klik "Coba Lagi"', style: TextStyle(fontSize: 11, color: Colors.grey.shade700))])),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: onExit, style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Kembali'))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(onPressed: onRetry, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Coba Lagi'))),
      ]),
    ])));
  }
}

// ==================== STATUS CARD ====================

class _StatusCard extends StatelessWidget {
  final bool isWithinRange; final bool hasPlacement; final String companyName; final double distance; final VoidCallback onRefresh;
  final bool fakeGpsBlocked; final FakeGpsRisk fakeGpsRisk; final List<String> fakeGpsWarnings;
  const _StatusCard({required this.isWithinRange, required this.hasPlacement, required this.companyName, required this.distance, required this.onRefresh, this.fakeGpsBlocked = false, this.fakeGpsRisk = FakeGpsRisk.none, this.fakeGpsWarnings = const []});

  @override
  Widget build(BuildContext context) {
    Color color; IconData icon; String title; String subtitle;
    if (fakeGpsBlocked) { color = Colors.purple; icon = Icons.gpp_bad; title = '⛔ Fake GPS Terdeteksi!'; subtitle = fakeGpsWarnings.isNotEmpty ? fakeGpsWarnings.first : 'Nonaktifkan fake GPS untuk melanjutkan'; }
    else if (!hasPlacement) { color = Colors.orange; icon = Icons.warning; title = 'Belum Ada Penempatan'; subtitle = companyName; }
    else if (isWithinRange) { color = Colors.green; icon = Icons.check_circle; title = '✓ Lokasi OK'; subtitle = '$companyName (${distance.toStringAsFixed(0)}m)'; }
    else { color = Colors.red; icon = Icons.cancel; title = '✕ Di Luar Jangkauan'; subtitle = '$companyName (${distance.toStringAsFixed(0)}m)'; }

    List<Widget> extraWarnings = [];
    if (!fakeGpsBlocked && fakeGpsRisk == FakeGpsRisk.low && fakeGpsWarnings.isNotEmpty) {
      extraWarnings.add(Padding(padding: const EdgeInsets.only(top: 6), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withOpacity(0.3))), child: Row(children: [const Icon(Icons.info_outline, size: 14, color: Colors.orange), const SizedBox(width: 4), Expanded(child: Text(fakeGpsWarnings.first, style: const TextStyle(fontSize: 10, color: Colors.orange), maxLines: 1, overflow: TextOverflow.ellipsis))]))));
    }

    return InkWell(onTap: onRefresh, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color, size: 28), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color.withOpacity(0.8))), Text(subtitle, style: TextStyle(fontSize: 12, color: color.withOpacity(0.6)))])), const Icon(Icons.refresh, size: 18, color: Colors.grey)]),
      ...extraWarnings,
    ])));
  }
}

// ==================== SELFIE SECTION ====================

class _SelfieSection extends StatelessWidget {
  final Uint8List? selfieBytes; final VoidCallback onTap; final bool isWithinRange; final bool fakeGpsBlocked;
  const _SelfieSection({this.selfieBytes, required this.onTap, required this.isWithinRange, this.fakeGpsBlocked = false});

  @override
  Widget build(BuildContext context) {
    final canTap = isWithinRange && !fakeGpsBlocked;
    String hint; IconData hintIcon; Color hintColor;
    if (fakeGpsBlocked) { hint = '⛔ Fake GPS aktif!'; hintIcon = Icons.gpp_bad; hintColor = Colors.purple; }
    else if (!isWithinRange) { hint = '⛔ Harus dalam radius'; hintIcon = Icons.camera_alt; hintColor = Colors.grey; }
    else { hint = 'Tap untuk Selfie'; hintIcon = Icons.camera_alt; hintColor = Colors.blue; }

    return GestureDetector(onTap: canTap ? onTap : null, child: Container(height: 150, decoration: BoxDecoration(color: fakeGpsBlocked ? Colors.purple.withOpacity(0.05) : Colors.grey[100], borderRadius: BorderRadius.circular(16), border: Border.all(color: fakeGpsBlocked ? Colors.purple.withOpacity(0.3) : (isWithinRange ? Colors.grey[300]! : Colors.grey[200]!))),
      child: selfieBytes != null
        ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Stack(fit: StackFit.expand, children: [Image.memory(selfieBytes!, fit: BoxFit.cover), Positioned(top: 8, right: 8, child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 18))))]))
        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(hintIcon, size: 44, color: hintColor), const SizedBox(height: 8), Text(hint, style: TextStyle(color: hintColor))]),
    ));
  }
}