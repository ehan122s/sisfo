import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_config.dart';

class AdminRepository {
  final SupabaseClient _supabase = supabase;

  // 1. Get Total Students
  Future<int> getTotalStudents() async {
    final response = await _supabase
        .from('profiles')
        .select('id')
        .count(CountOption.exact); // Efficient count
    return response.count;
  }

  // 2. Get Today's Attendance Count (Hadir)
  Future<int> getTodayAttendanceCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).toIso8601String();

    final response = await _supabase
        .from('attendance_logs')
        .select('id')
        .eq('status', 'Hadir')
        .gte('created_at', startOfDay)
        .lte('created_at', endOfDay)
        .count(CountOption.exact);

    return response.count;
  }

  // 3. Get Today's Attendance Locations for Map
  Future<List<Map<String, dynamic>>> getTodayAttendanceLocations() async {
    // This is kept for backward compat if needed, or we just replace it.
    // But let's create the smarter one.
    return getLiveMonitoringData();

    // Original implementation commented out/replaced logic below
  }

  // 3b. Smart Live Monitoring (Green = Hadir, Red = Belum)
  Future<List<Map<String, dynamic>>> getLiveMonitoringData() async {
    // 1. Get All Students with Placements
    final students = await getAllStudents();

    // 2. Get Today's Attendance
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).toIso8601String();

    final attendanceLogs = await _supabase
        .from('attendance_logs')
        .select()
        .eq('status', 'Hadir')
        .gte('created_at', startOfDay)
        .lte('created_at', endOfDay);

    // 3. Merge Data
    List<Map<String, dynamic>> mapData = [];

    for (var student in students) {
      // Filter non-active students if we want
      if (student['status'] != 'active') continue;

      final studentId = student['id'];
      final studentName = student['full_name'];

      // Check attendance
      // Check attendance
      final matchingLogs = attendanceLogs.where(
        (log) => log['student_id'] == studentId,
      );
      final attendance = matchingLogs.isNotEmpty ? matchingLogs.first : null;

      if (attendance != null &&
          attendance['check_in_lat'] != null &&
          attendance['check_in_long'] != null) {
        // Case 1: Hadir (Green) -> Use Check-in Location
        mapData.add({
          'id': studentId,
          'name': studentName,
          'lat': attendance['check_in_lat'],
          'lng': attendance['check_in_long'],
          'status': 'Hadir',
          'color': 'green',
          'time': attendance['check_in_time'],
        });
      } else {
        // Case 2: Belum Hadir (Red) -> Use Company Location (Expected)
        if (student['placements'] != null &&
            (student['placements'] as List).isNotEmpty) {
          final placement = (student['placements'] as List).first;
          if (placement['companies'] != null) {
            final company = placement['companies'];
            if (company['latitude'] != null && company['longitude'] != null) {
              mapData.add({
                'id': studentId,
                'name': studentName,
                'lat': company['latitude'],
                'lng': company['longitude'],
                'status': 'Belum Hadir',
                'color': 'red',
                'company_name': company['name'],
              });
            }
          }
        }
      }
    }

    return mapData;
  }

  // --- Student Management (CRUD) ---

  // 4. Get All Students (with Placement Info)
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final response = await _supabase
        .from('profiles')
        .select(
          '*, placements(id, company_id, companies(id, name, latitude, longitude))',
        )
        .order('created_at', ascending: false); // Newest first for verification
    return List<Map<String, dynamic>>.from(response);
  }

  // 4b. Get Paginated Students
  Future<List<Map<String, dynamic>>> getPaginatedStudents({
    int page = 0,
    int pageSize = 10,
  }) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('profiles')
        .select(
          '*, placements(id, company_id, companies(id, name, latitude, longitude))',
        )
        .order('created_at', ascending: false) // Newest first
        .range(start, end);

    return List<Map<String, dynamic>>.from(response);
  }

  // 5. Update Student Profile
  Future<void> updateStudent(String id, Map<String, dynamic> updates) async {
    await _supabase.from('profiles').update(updates).eq('id', id);
  }

  // 5b. Update Student Status (Approve/Reject)
  Future<void> updateStudentStatus(String id, String status) async {
    await _supabase.from('profiles').update({'status': status}).eq('id', id);
  }

  // 6. Delete Student
  Future<void> deleteStudent(String id) async {
    await _supabase.from('profiles').delete().eq('id', id);
  }

  // 6b. Assign Student Placement
  Future<void> assignStudentPlacement(String studentId, int companyId) async {
    // Upsert mechanism: If placement exists for student, update it. Else insert.
    // However, simplest is to check if exists then update or insert.
    // Or just insert new one if we track history.
    // For this MVP, let's assume 1 active placement per student.
    // We will delete existing placement first to keep it simple (or update).

    // Check existing
    final existing = await _supabase
        .from('placements')
        .select()
        .eq('student_id', studentId)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('placements')
          .update({'company_id': companyId})
          .eq('id', existing['id']);
    } else {
      await _supabase.from('placements').insert({
        'student_id': studentId,
        'company_id': companyId,
        'start_date': DateTime.now().toIso8601String(),
      });
    }
  }

  // --- DUDI Management (CRUD) ---

  // 7. Get All Companies
  Future<List<Map<String, dynamic>>> getAllCompanies() async {
    final response = await _supabase
        .from('companies')
        .select()
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // 7b. Get Paginated Companies
  Future<List<Map<String, dynamic>>> getPaginatedCompanies({
    int page = 0,
    int pageSize = 10,
  }) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('companies')
        .select()
        .order('name', ascending: true)
        .range(start, end); // Use range for pagination

    return List<Map<String, dynamic>>.from(response);
  }

  // 8. Add Company
  Future<void> addCompany(Map<String, dynamic> data) async {
    await _supabase.from('companies').insert(data);
  }

  // 9. Update Company
  Future<void> updateCompany(int id, Map<String, dynamic> data) async {
    await _supabase.from('companies').update(data).eq('id', id);
  }

  // --- Attendance Report ---

  // 11. Get Attendance Logs (Rich Data)
  Future<List<Map<String, dynamic>>> getAttendanceLogs({
    DateTime? date,
    String? className,
    String? status, // New parameter
    int page = 0,
    int pageSize = 10,
  }) async {
    // If no date is selected (History Mode), just return the raw logs (paginated)
    if (date == null) {
      final start = page * pageSize;
      final end = start + pageSize - 1;

      final response = await _supabase
          .from('attendance_logs')
          .select('''
            *,
            profiles (
              full_name,
              nisn,
              class_name,
              placements (
                companies (name)
              )
            )
          ''')
          .order('created_at', ascending: false)
          .range(start, end);
      return List<Map<String, dynamic>>.from(response);
    }

    // If Date IS Selected -> We want a Daily Report (All Students: Hadir vs Belum)
    // NOTE: Pagination here is tricky because we merge data in memory.
    // For MVP, we will fetch ALL students (for accurate "Belum Hadir" calculation)
    // and then implement pagination IN MEMORY before returning.
    // This is not efficient for 10k students, but fine for < 500.

    // 1. Get All Students
    final students = await getAllStudents();

    // 2. Get Logs for that Date
    final startOfDay = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();
    final endOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    ).toIso8601String();

    final logsResponse = await _supabase
        .from('attendance_logs')
        .select('''
          *,
          profiles (
            full_name,
            nisn,
            class_name,
            placements (
              companies (name)
            )
          )
        ''')
        .gte('created_at', startOfDay)
        .lte('created_at', endOfDay);

    final logs = List<Map<String, dynamic>>.from(logsResponse);

    // 3. Merge Data
    List<Map<String, dynamic>> combinedReport = [];

    for (var student in students) {
      // Filter non-active students if we want
      // if (student['status'] != 'active') continue;

      // Filter by Class Name if provided
      if (className != null && className.isNotEmpty) {
        if (student['class_name'] != className) continue;
      }

      final studentId = student['id'];

      // Find if this student has a log for today
      final existingLog = logs.firstWhere(
        (log) => log['student_id'] == studentId,
        orElse: () => {},
      );

      String calculatedStatus = 'Belum Hadir';
      Map<String, dynamic> reportEntry = {};

      if (existingLog.isNotEmpty) {
        // Student is Present (or has a log)
        // Check for Late (Terlambat) -> > 08:00
        calculatedStatus = existingLog['status'] ?? 'Hadir';
        final checkInTime = (existingLog['check_in_time'] ?? '').toString();

        if (calculatedStatus == 'Hadir' && checkInTime.isNotEmpty) {
          try {
            final checkInDt = DateTime.parse(checkInTime).toLocal();
            // Create 08:00 threshold for that day
            final threshold = DateTime(
              checkInDt.year,
              checkInDt.month,
              checkInDt.day,
              8,
              0,
            );

            if (checkInDt.isAfter(threshold)) {
              calculatedStatus = 'Terlambat';
            }
          } catch (_) {
            // If parsing fails, ignore (keep as Hadir)
          }
        }

        // Create a copy to modify status
        reportEntry = Map<String, dynamic>.from(existingLog);
        reportEntry['status'] = calculatedStatus;
      } else {
        // Student is Absent -> Create a "Virtual" Log Entry
        reportEntry = {
          'id': 'virtual_$studentId', // distinct ID
          'created_at':
              startOfDay, // Sort at start of day or handled via sorting
          'student_id': studentId,
          'status': 'Belum Hadir',
          'profiles':
              student, // Pass the full student profile including placements
          'check_in_time': '-',
          'check_out_time': '-',
        };
        calculatedStatus = 'Belum Hadir';
      }

      // Filter by Status if provided
      if (status != null && status.isNotEmpty) {
        if (calculatedStatus != status) continue;
      }

      combinedReport.add(reportEntry);
    }

    // 4. Sort: Belum Hadir first, then Terlambat, then Hadir
    combinedReport.sort((a, b) {
      final statusA = a['status'] ?? '';
      final statusB = b['status'] ?? '';

      // Define a custom order for statuses
      int getStatusOrder(String status) {
        switch (status) {
          case 'Belum Hadir':
            return 0;
          case 'Terlambat':
            return 1;
          case 'Hadir':
            return 2;
          default:
            return 3; // For any other status, place it last
        }
      }

      final orderA = getStatusOrder(statusA);
      final orderB = getStatusOrder(statusB);

      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }

      final nameA = (a['profiles']?['full_name'] ?? '')
          .toString()
          .toLowerCase();
      final nameB = (b['profiles']?['full_name'] ?? '')
          .toString()
          .toLowerCase();
      return nameA.compareTo(nameB);
    });

    // 5. Apply In-Memory Pagination
    final start = page * pageSize;
    if (start >= combinedReport.length) return [];

    final end = (start + pageSize) < combinedReport.length
        ? (start + pageSize)
        : combinedReport.length;

    return combinedReport.sublist(start, end);
  }

  // 12. Get Student Distribution by Company (Top 5)
  Future<List<Map<String, dynamic>>> getStudentDistributionByCompany() async {
    final students = await getAllStudents();
    final Map<String, int> companyCounts = {};

    for (var student in students) {
      final placements = student['placements'] as List?;
      if (placements != null && placements.isNotEmpty) {
        final company = placements.first['companies'];
        if (company != null) {
          final name = company['name'] as String;
          companyCounts[name] = (companyCounts[name] ?? 0) + 1;
        }
      } else {
        companyCounts['Belum Ada DUDI'] =
            (companyCounts['Belum Ada DUDI'] ?? 0) + 1;
      }
    }

    final sortedList = companyCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5
    return sortedList
        .take(5)
        .map((e) => {'name': e.key, 'count': e.value})
        .toList();
  }

  // 13. Get Detailed Attendance Stats for Today
  Future<Map<String, int>> getTodayAttendanceStats() async {
    // Reuse the logic from getAttendanceLogs for consistency
    final logs = await getAttendanceLogs(date: DateTime.now());

    final stats = {
      'Hadir': 0,
      'Terlambat': 0,
      'Belum Hadir': 0,
      'Izin': 0,
      'Sakit': 0,
    };

    for (var log in logs) {
      final status = log['status'] as String? ?? 'Belum Hadir';
      if (stats.containsKey(status)) {
        stats[status] = (stats[status] ?? 0) + 1;
      } else {
        // Fallback for unexpected statuses
        stats['Belum Hadir'] = (stats['Belum Hadir'] ?? 0) + 1;
      }
    }
    return stats;
  }

  // 14. Get Student Distribution by City/Regency (From Address)
  Future<List<Map<String, dynamic>>> getStudentDistributionByCity() async {
    final students = await getAllStudents();
    final Map<String, int> cityCounts = {};

    // Improved Regex: Case insensitive, handles "Kab" without dot, matches until comma or number
    final cityRegex = RegExp(
      r'\b(Kota|Kabupaten|Kab\.?)\s+([^,0-9]+)',
      caseSensitive: false,
    );

    for (var student in students) {
      final placements = student['placements'] as List?;
      if (placements != null && placements.isNotEmpty) {
        final company = placements.first['companies'];
        if (company != null) {
          final address = company['address'] as String? ?? '';

          final match = cityRegex.firstMatch(address);
          if (match != null) {
            String city = match.group(0)!.trim();
            // Clean up trailing commas or newlines
            city = city.replaceAll(RegExp(r'[,\.]+$'), '').trim();

            // Normalize casing (Title Case)
            // capitalize first letter of each word
            city = city
                .split(' ')
                .map((word) {
                  if (word.isEmpty) return '';
                  return word[0].toUpperCase() +
                      word.substring(1).toLowerCase();
                })
                .join(' ');

            // Normalize "Kab" to "Kabupaten"
            if (city.toLowerCase().startsWith('kab ') ||
                city.toLowerCase().startsWith('kab. ')) {
              city = city.replaceFirst(
                RegExp(r'Kab\.?\s+', caseSensitive: false),
                'Kabupaten ',
              );
            }

            cityCounts[city] = (cityCounts[city] ?? 0) + 1;
          } else {
            // Fallback: If formatted address (comma separated), maybe try to guess?
            // For now, keep as "Lainnya" but maybe log it if we could.
            cityCounts['Lainnya'] = (cityCounts['Lainnya'] ?? 0) + 1;
          }
        }
      }
    }

    final sortedList = cityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedList.map((e) => {'name': e.key, 'count': e.value}).toList();
  }

  // 10. Delete Company
  Future<void> deleteCompany(int id) async {
    await _supabase.from('companies').delete().eq('id', id);
  }

  // 15. Get Student Attendance History (Specific Student)
  Future<List<Map<String, dynamic>>> getStudentAttendanceHistory(
    String studentId,
  ) async {
    final response = await _supabase
        .from('attendance_logs')
        .select('*')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 16. Get Daily Journals (Activity Logs)
  Future<List<Map<String, dynamic>>> getDailyJournals({
    DateTime? date,
    String? className,
    String? studentId,
    int page = 0,
    int pageSize = 10,
  }) async {
    // Base Select
    // We use PostgrestFilterBuilder explicitly to allow chaining filters
    PostgrestFilterBuilder query = _supabase.from('daily_journals').select('''
      *,
      profiles!inner (
        full_name,
        class_name,
        nisn
      )
    ''');
    // Using !inner on profiles to allow filtering by related table columns if needed,
    // though for className check we might do it simply or via filter.
    // If we want accurate pagination with class filter, we MUST filter in the query.

    // Filter by Date
    if (date != null) {
      final startOfDay = DateTime(
        date.year,
        date.month,
        date.day,
      ).toIso8601String();
      final endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
      ).toIso8601String();
      query = query.gte('created_at', startOfDay).lte('created_at', endOfDay);
    }

    // Filter by Student ID
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    // Filter by Class Name (Joining filter)
    if (className != null && className.isNotEmpty) {
      query = query.eq('profiles.class_name', className);
    }

    // Pagination (Transform)
    final start = page * pageSize;
    final end = start + pageSize - 1;
    final transformQuery = query
        .range(start, end)
        .order('created_at', ascending: false);

    final response = await transformQuery;
    return List<Map<String, dynamic>>.from(response);
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

// Providers for Dashboard Stats
final totalStudentsProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.read(adminRepositoryProvider).getTotalStudents();
});

final todayAttendanceProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.read(adminRepositoryProvider).getTodayAttendanceCount();
});

final todayAttendanceLocationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ref.read(adminRepositoryProvider).getTodayAttendanceLocations();
    });

final studentDistributionProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ref
          .read(adminRepositoryProvider)
          .getStudentDistributionByCompany();
    });

final studentLocationDistributionProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ref.read(adminRepositoryProvider).getStudentDistributionByCity();
    });

final todayAttendanceStatsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
      return ref.read(adminRepositoryProvider).getTodayAttendanceStats();
    });

final allStudentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ref.read(adminRepositoryProvider).getAllStudents();
    });

final allCompaniesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return ref.read(adminRepositoryProvider).getAllCompanies();
    });

final attendanceLogsProvider = FutureProvider.family
    .autoDispose<
      List<Map<String, dynamic>>,
      ({DateTime? date, String? className, String? status, int page})
    >((ref, params) async {
      return ref
          .read(adminRepositoryProvider)
          .getAttendanceLogs(
            date: params.date,
            className: params.className,
            status: params.status,
            page: params.page,
          );
    });

final studentAttendanceHistoryProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, String>((ref, studentId) async {
      return ref
          .read(adminRepositoryProvider)
          .getStudentAttendanceHistory(studentId);
    });

final dailyJournalsProvider = FutureProvider.family
    .autoDispose<
      List<Map<String, dynamic>>,
      ({DateTime? date, String? className, String? studentId, int page})
    >((ref, params) async {
      return ref
          .read(adminRepositoryProvider)
          .getDailyJournals(
            date: params.date,
            className: params.className,
            studentId: params.studentId,
            page: params.page,
          );
    });

final paginatedStudentsProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, int>((ref, page) async {
      return ref.read(adminRepositoryProvider).getPaginatedStudents(page: page);
    });

final paginatedCompaniesProvider = FutureProvider.family
    .autoDispose<List<Map<String, dynamic>>, int>((ref, page) async {
      return ref
          .read(adminRepositoryProvider)
          .getPaginatedCompanies(page: page);
    });
