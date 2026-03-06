import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_config.dart';
import '../../authentication/data/auth_repository.dart';

class TeacherRepository {
  final SupabaseClient _supabase = supabase;

  // 1. Get Managed Students
  Future<List<Map<String, dynamic>>> getManagedStudents(
    String teacherId,
  ) async {
    // We want profiles of students whose placement.company is assigned to this teacher
    // Path: profiles -> placements -> companies -> supervisor_assignments

    // OPTIMIZED: Use SQL View managed_students_view
    // This view joins profiles, placements, companies, and supervisor_assignments.
    final response = await _supabase
        .from('managed_students_view')
        .select()
        .eq('teacher_id', teacherId)
        .order('full_name');

    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Get Pending Journals (for Approval)
  Future<List<Map<String, dynamic>>> getPendingJournals(
    String teacherId,
  ) async {
    // Similar deep filter logic
    final response = await _supabase
        .from('daily_journals')
        .select('''
          *,
          profiles!inner(full_name, avatar_url),
          placements!inner(
            companies!inner(
              supervisor_assignments!inner(teacher_id)
            )
          )
        ''')
        .eq('placements.companies.supervisor_assignments.teacher_id', teacherId)
        .eq('is_approved', false)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // 3. Approve/Reject Journal
  Future<void> updateJournalStatus(
    int journalId,
    bool isApproved, {
    String? notes,
  }) async {
    await _supabase
        .from('daily_journals')
        .update({
          'is_approved': isApproved,
          // 'notes': notes // If we had a notes column
        })
        .eq('id', journalId);
  }

  // 4. Get Managed Students Attendance (Today)
  Future<List<Map<String, dynamic>>> getManagedStudentsAttendance(
    String teacherId,
  ) async {
    final students = await getManagedStudents(teacherId);
    if (students.isEmpty) return [];

    // FIX: View uses 'student_id', not 'id'
    final studentIds = students.map((s) => s['student_id']).toList();
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Fetch logs for these students for today/recent
    final logsResponse = await _supabase
        .from('attendance_logs')
        .select()
        .inFilter('student_id', studentIds)
        .gte('created_at', '$today 00:00:00')
        .order('created_at', ascending: false);

    final logs = List<Map<String, dynamic>>.from(logsResponse);

    // Merge
    return students.map((student) {
      // Find log for this student
      // FIX: Use 'student_id'
      final log = logs.firstWhere(
        (l) => l['student_id'] == student['student_id'],
        orElse: () => <String, dynamic>{}, // Empty map if not found
      );

      String status = 'Belum Hadir';
      if (log.isNotEmpty) {
        status = log['status'] ?? 'Hadir';
      }

      return {
        ...student,
        'attendance_log': log.isNotEmpty ? log : null,
        'attendance_status': status,
      };
    }).toList();
  }

  // 5. Get Dashboard Stats
  Future<Map<String, int>> getTeacherStats(String teacherId) async {
    // 1. Total Students
    final students = await getManagedStudents(teacherId);
    final totalStudents = students.length;

    // 2. Pending Journals
    final journals = await getPendingJournals(teacherId);
    final pendingJournals = journals.length;

    // 3. Present Today
    final attendanceList = await getManagedStudentsAttendance(teacherId);
    final presentCount = attendanceList
        .where((s) => s['attendance_status'] == 'Hadir')
        .length;

    return {
      'total_students': totalStudents,
      'pending_journals': pendingJournals,
      'present_today': presentCount,
    };
  }

  // 6. Get Attendance Report for Export (Current Month)
  Future<List<Map<String, dynamic>>> getAttendanceReportForExport(
    String teacherId, {
    int? month,
    int? year,
  }) async {
    final students = await getManagedStudents(teacherId);
    if (students.isEmpty) return [];

    final studentIds = students.map((s) => s['student_id']).toList();
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;

    // Start and End of month
    final startOfMonth = DateTime(y, m, 1).toIso8601String();
    final endOfMonth = DateTime(
      y,
      m + 1,
      0,
    ).toIso8601String(); // Last day of month

    final logsResponse = await _supabase
        .from('attendance_logs')
        .select()
        .inFilter('student_id', studentIds)
        .gte('created_at', startOfMonth)
        .lte('created_at', '$endOfMonth 23:59:59')
        .order('created_at', ascending: false);

    final logs = List<Map<String, dynamic>>.from(logsResponse);

    // Flatten data for Excel: One row per log, enriched with student info
    List<Map<String, dynamic>> flattenedData = [];

    for (var log in logs) {
      final student = students.firstWhere(
        (s) => s['student_id'] == log['student_id'],
        orElse: () => <String, dynamic>{},
      );

      if (student.isNotEmpty) {
        flattenedData.add({
          ...student,
          ...log, // log overrides student keys if collision, but keys are distinct enough
        });
      }
    }

    return flattenedData;
  }

  // 7. Get Student Attendance by Month
  Future<List<Map<String, dynamic>>> getStudentAttendanceByMonth(
    String studentId,
    int month,
    int year,
  ) async {
    final startOfMonth = DateTime(
      year,
      month,
      1,
    ).toIso8601String().split('T')[0];
    final endOfMonth = DateTime(
      year,
      month + 1,
      0,
    ).toIso8601String().split('T')[0];

    final response = await _supabase
        .from('attendance_logs')
        .select()
        .eq('student_id', studentId)
        .gte('created_at', '$startOfMonth 00:00:00')
        .lte('created_at', '$endOfMonth 23:59:59')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 8. Get Student Journals by Month
  Future<List<Map<String, dynamic>>> getStudentJournalsByMonth(
    String studentId,
    int month,
    int year,
  ) async {
    final startOfMonth = DateTime(
      year,
      month,
      1,
    ).toIso8601String().split('T')[0];
    final endOfMonth = DateTime(
      year,
      month + 1,
      0,
    ).toIso8601String().split('T')[0];

    final response = await _supabase
        .from('daily_journals')
        .select()
        .eq('student_id', studentId)
        .gte('created_at', '$startOfMonth 00:00:00')
        .lte('created_at', '$endOfMonth 23:59:59')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository();
});

final managedStudentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (user == null) return [];
      return ref.watch(teacherRepositoryProvider).getManagedStudents(user.id);
    });

final pendingJournalsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (user == null) return [];
      return ref.watch(teacherRepositoryProvider).getPendingJournals(user.id);
    });

final managedAttendanceProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (user == null) return [];
      return ref
          .watch(teacherRepositoryProvider)
          .getManagedStudentsAttendance(user.id);
    });

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    return {'total_students': 0, 'pending_journals': 0, 'present_today': 0};
  }
  return ref.watch(teacherRepositoryProvider).getTeacherStats(user.id);
});
