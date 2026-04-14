import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/admin_repository.dart';
import 'student_management_screen.dart';
import 'dudi_management_screen.dart';
import 'attendance_report_screen.dart';
import 'student_journal_report_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel K-MOB SMEA'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar / Navigation Rail
          NavigationRail(
            extended: true,
            minExtendedWidth: 200,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('Siswa')),
              NavigationRailDestination(icon: Icon(Icons.business), label: Text('DUDI')),
              NavigationRailDestination(icon: Icon(Icons.access_time), label: Text('Kehadiran')),
              NavigationRailDestination(icon: Icon(Icons.assignment), label: Text('Laporan Siswa')),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (val) => setState(() => _selectedIndex = val),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content Area
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const _DashboardOverview(),
                const StudentManagementScreen(),
                const DudiManagementScreen(),
                const AttendanceReportScreen(),
                const StudentJournalReportScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: const [
              Icon(Icons.dashboard, size: 32, color: Colors.blueGrey),
              SizedBox(width: 12),
              Text(
                "Dashboard Overview",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 1. Total Students Card
          const Text("Data Siswa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Consumer(builder: (context, ref, _) {
            final count = ref.watch(totalStudentsProvider);
            return _StatCard(
              title: "Total Siswa Terdaftar",
              value: count.when(data: (d) => d.toString(), loading: () => "...", error: (e, _) => "-"),
              icon: Icons.people,
              color: Colors.blue,
            );
          }),

          const SizedBox(height: 40),

          // 2. Attendance Stats (Wrap to prevent overflow)
          const Text("Status Kehadiran Hari Ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const _AttendanceStatusGrid(), // Fixed: const removed inside the widget definition if dynamic

          const SizedBox(height: 40),

          // 3. Analytics Section (Top DUDI & Location)
          Wrap(
            spacing: 32,
            runSpacing: 32,
            children: [
              // Top DUDI List
              SizedBox(
                width: 450,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Top 5 DUDI (Jumlah Siswa)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    _TopDudiList(), 
                  ],
                ),
              ),
              // Location Distribution
              SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Sebaran Lokasi (Kecamatan)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    _LocationDistributionList(),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          // 4. Map Section
          Row(
            children: const [
              Icon(Icons.map, color: Colors.redAccent),
              SizedBox(width: 8),
              Text("Live Monitoring Peserta PKL", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const _LiveMapSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _AttendanceStatusGrid extends ConsumerWidget {
  const _AttendanceStatusGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(todayAttendanceStatsProvider);

    return statsAsync.when(
      data: (stats) => Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _StatusItem(label: "Hadir", count: stats['Hadir'] ?? 0, color: Colors.green, icon: Icons.check_circle),
          _StatusItem(label: "Terlambat", count: stats['Terlambat'] ?? 0, color: Colors.orange, icon: Icons.access_time_filled),
          _StatusItem(label: "Belum Hadir", count: stats['Belum Hadir'] ?? 0, color: Colors.red, icon: Icons.cancel),
          _StatusItem(label: "Izin", count: stats['Izin'] ?? 0, color: Colors.blue, icon: Icons.assignment_ind),
          _StatusItem(label: "Sakit", count: stats['Sakit'] ?? 0, color: Colors.purple, icon: Icons.local_hospital),
        ],
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text("Error loading stats: $e"),
    );
  }
}

class _LiveMapSection extends ConsumerWidget {
  const _LiveMapSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(todayAttendanceLocationsProvider);

    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: locationsAsync.when(
        data: (locations) {
          if (locations.isEmpty) return const Center(child: Text("Belum ada data lokasi hari ini."));
          
          final markers = locations.map((loc) {
            final lat = (loc['lat'] as num?)?.toDouble() ?? 0.0;
            final lng = (loc['lng'] as num?)?.toDouble() ?? 0.0;
            return Marker(
              markerId: MarkerId(loc['id'].toString()),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                loc['color'] == 'green' ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed
              ),
              infoWindow: InfoWindow(title: loc['name'], snippet: loc['status']),
            );
          }).toSet();

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng((locations.first['lat'] as num).toDouble(), (locations.first['lng'] as num).toDouble()),
              zoom: 12,
            ),
            markers: markers,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Gagal memuat peta: $e")),
      ),
    );
  }
}

// Reusable Small Widgets
class _StatCard extends StatelessWidget {
  final String title, value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusItem({required this.label, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}

class _TopDudiList extends ConsumerWidget {
  const _TopDudiList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dudiAsync = ref.watch(studentDistributionProvider);
    return dudiAsync.when(
      data: (dudis) => Column(
        children: dudis.map((d) => ListTile(
          leading: const Icon(Icons.business, color: Colors.blue),
          title: Text(d['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          trailing: Text("${d['count']} Siswa"),
        )).toList(),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text("Error: $e"),
    );
  }
}

class _LocationDistributionList extends ConsumerWidget {
  const _LocationDistributionList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(studentLocationDistributionProvider);
    return locationAsync.when(
      data: (locations) => Column(
        children: locations.map((l) => ListTile(
          leading: const Icon(Icons.location_on, color: Colors.teal),
          title: Text(l['name'], style: const TextStyle(fontSize: 14)),
          trailing: Badge(label: Text(l['count'].toString()), backgroundColor: Colors.teal),
        )).toList(),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text("Error: $e"),
    );
  }
}