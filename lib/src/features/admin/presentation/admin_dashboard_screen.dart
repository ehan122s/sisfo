import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/admin_repository.dart';
import 'student_management_screen.dart'; // Import Student Screen
import 'dudi_management_screen.dart'; // Import DUDI Screen
import 'attendance_report_screen.dart'; // Import Report Screen
import 'student_journal_report_screen.dart'; // Import Journal Screen

// State provider removed in favor of local state

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
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
          // Sidebar
          NavigationRail(
            extended: true,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Siswa'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.business),
                label: Text('DUDI'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.access_time),
                label: Text('Kehadiran'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment),
                label: Text('Laporan Siswa'),
              ),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (val) {
              setState(() {
                _selectedIndex = val;
              });
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                // 0: Dashboard Overview
                const _DashboardOverview(),
                // 1: Student Management
                const StudentManagementScreen(),
                // 2: DUDI Management
                const DudiManagementScreen(),
                // 3. Laporan Kehadiran
                const AttendanceReportScreen(),
                // 4. Laporan Jurnal Siswa
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
          Row(
            children: [
              const Icon(Icons.dashboard, size: 32, color: Colors.blueGrey),
              const SizedBox(width: 12),
              const Text(
                "Dashboard Overview",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data Siswa
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Data Siswa",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, _) {
                      final count = ref.watch(totalStudentsProvider);
                      return _StatCard(
                        title: "Total Siswa",
                        value: count.when(
                          data: (data) => data.toString(),
                          loading: () => "...",
                          error: (e, _) => "-",
                        ),
                        icon: Icons.people,
                        color: Colors.blue,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Lower Section: Analytics Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Detailed Attendance Status
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Status Kehadiran Detail",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _AttendanceStatusGrid(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right: Top DUDI
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Top 5 DUDI (Jumlah Siswa)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _TopDudiList(),
                    const SizedBox(height: 32),
                    const Text(
                      "Sebaran Lokasi",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _LocationDistributionList(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right: Location Distribution
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sebaran Lokasi",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _LocationDistributionList(),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Map Section
          Row(
            children: [
              const Icon(Icons.map, color: Colors.redAccent),
              const SizedBox(width: 8),
              const Text(
                "Live Monitoring Peserta PKL",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 450,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,
            child: Consumer(
              builder: (context, ref, child) {
                final locationsAsync = ref.watch(
                  todayAttendanceLocationsProvider,
                );

                return locationsAsync.when(
                  data: (locations) {
                    if (locations.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Belum ada data lokasi absensi hari ini.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final markers = locations.map((loc) {
                      // Safely cast numbers
                      final lat = (loc['lat'] as num?)?.toDouble() ?? 0.0;
                      final lng = (loc['lng'] as num?)?.toDouble() ?? 0.0;
                      final name = loc['name'] ?? 'Siswa';
                      final status = loc['status'] ?? '-';
                      final color = loc['color'] ?? 'red';

                      double hue =
                          BitmapDescriptor.hueRed; // Default Red (Belum Hadir)
                      if (color == 'green') {
                        hue = BitmapDescriptor.hueGreen;
                      }

                      return Marker(
                        markerId: MarkerId(loc['id'].toString()),
                        position: LatLng(lat, lng),
                        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
                        infoWindow: InfoWindow(
                          title: name,
                          snippet: status == 'Hadir'
                              ? 'Hadir: ${loc['time']}'
                              : 'Belum Hadir (Lokasi: ${loc['company_name']})',
                        ),
                      );
                    }).toSet();

                    // Center map on the first student
                    final firstLoc = locations.first;
                    final initialTarget = LatLng(
                      (firstLoc['lat'] as num).toDouble(),
                      (firstLoc['lng'] as num).toDouble(),
                    );

                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initialTarget,
                        zoom: 13, // Zoom out a bit to see context
                      ),
                      markers: markers,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Gagal memuat peta: $e")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color.withValues(alpha: 0.8), size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
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
      data: (stats) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatusItem(
              label: "Hadir",
              count: stats['Hadir'] ?? 0,
              color: Colors.green,
              icon: Icons.check_circle,
            ),
            _StatusItem(
              label: "Terlambat",
              count: stats['Terlambat'] ?? 0,
              color: Colors.orange,
              icon: Icons.access_time_filled,
            ),
            _StatusItem(
              label: "Belum Hadir",
              count: stats['Belum Hadir'] ?? 0,
              color: Colors.red,
              icon: Icons.cancel,
            ),
            _StatusItem(
              label: "Izin",
              count: stats['Izin'] ?? 0,
              color: Colors.blue,
              icon: Icons.assignment_ind,
            ),
            _StatusItem(
              label: "Sakit",
              count: stats['Sakit'] ?? 0,
              color: Colors.purple,
              icon: Icons.local_hospital,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text("Error: $e"),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusItem({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: dudiAsync.when(
        data: (dudis) {
          if (dudis.isEmpty) return const Text("Belum ada data DUDI.");

          return Column(
            children: dudis.map((d) {
              final name = d['name'];
              final count = d['count'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      child: Text(
                        name[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value:
                                1.0, // Relative to what? Just full for now or we can verify against total
                            color: Colors.blue[300],
                            backgroundColor: Colors.grey[100],
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "$count Siswa",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text("Error: $e"),
      ),
    );
  }
}

class _LocationDistributionList extends ConsumerWidget {
  const _LocationDistributionList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(studentLocationDistributionProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: locationAsync.when(
        data: (locations) {
          if (locations.isEmpty) return const Text("Belum ada data lokasi.");

          return Column(
            children: locations.map((d) {
              final name = d['name'];
              final count = d['count'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_city,
                      color: Colors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$count",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text("Error: $e"),
      ),
    );
  }
}
