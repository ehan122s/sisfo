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
    final response = await _supabase
        .from('managed_students_view')
        .select()
        .eq('teacher_id', teacherId)
        .order('full_name');
    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Get Student List (untuk dropdown export)
  Future<List<Map<String, dynamic>>> getStudentList(String teacherId) async {
    final response = await _supabase
        .from('managed_students_view')
        .select('student_id, full_name')
        .eq('teacher_id', teacherId)
        .order('full_name');
    return List<Map<String, dynamic>>.from(response);
  }

  // 3. Get Pending Journals
  Future<List<Map<String, dynamic>>> getPendingJournals(
    String teacherId,
  ) async {
    final students = await getManagedStudents(teacherId);
    if (students.isEmpty) return [];
    final studentIds = students.map((s) => s['student_id']).toList();
    final response = await _supabase
        .from('daily_journals')
        .select('*, profiles!inner(full_name, avatar_url)')
        .inFilter('student_id', studentIds)
        .eq('is_approved', false)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // 4. Approve/Reject Journal
  Future<void> updateJournalStatus(
    int journalId,
    bool isApproved, {
    String? notes,
  }) async {
    await _supabase
        .from('daily_journals')
        .update({'is_approved': isApproved})
        .eq('id', journalId);
  }

  // 5. Get Managed Students Attendance by Date
  Future<List<Map<String, dynamic>>> getManagedStudentsAttendance(
    String teacherId, {
    DateTime? date,
  }) async {
    final students = await getManagedStudents(teacherId);
    if (students.isEmpty) return [];

    final studentIds = students.map((s) => s['student_id']).toList();

    final now = date ?? DateTime.now().toLocal();
    final targetDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final logsResponse = await _supabase
        .from('attendance_logs')
        .select()
        .inFilter('student_id', studentIds)
        .eq('date', targetDate)
        .order('created_at', ascending: false);

    final logs = List<Map<String, dynamic>>.from(logsResponse);

    return students.map((student) {
      final log = logs.firstWhere(
        (l) => l['student_id'] == student['student_id'],
        orElse: () => <String, dynamic>{},
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

  // 6. Get Dashboard Stats
  Future<Map<String, int>> getTeacherStats(String teacherId) async {
    final students = await getManagedStudents(teacherId);
    final totalStudents = students.length;
    final journals = await getPendingJournals(teacherId);
    final pendingJournals = journals.length;
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

  // 7. Get Attendance Report for Export
  Future<List<Map<String, dynamic>>> getAttendanceReportForExport(
    String teacherId, {
    int? month,
    int? year,
    String? studentId,
  }) async {
    final students = await getManagedStudents(teacherId);
    if (students.isEmpty) return [];

    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;

    final startOfMonth = DateTime(y, m, 1, 0, 0, 0).toIso8601String();
    final endOfMonth = DateTime(y, m + 1, 0, 23, 59, 59).toIso8601String();

    // Filter studentIds: semua siswa guru, atau 1 siswa tertentu
    final studentIds = studentId != null
        ? [studentId]
        : students.map((s) => s['student_id']).toList();

    final logsResponse = await _supabase
        .from('attendance_logs')
        .select()
        .inFilter('student_id', studentIds)
        .gte('created_at', startOfMonth)
        .lte('created_at', endOfMonth)
        .order('created_at', ascending: false);

    final logs = List<Map<String, dynamic>>.from(logsResponse);

    List<Map<String, dynamic>> flattenedData = [];
    for (var log in logs) {
      final student = students.firstWhere(
        (s) => s['student_id'] == log['student_id'],
        orElse: () => <String, dynamic>{},
      );
      if (student.isNotEmpty) {
        flattenedData.add({...student, ...log});
      }
    }
    return flattenedData;
  }

  // 8. Get Journal Report for Export
  Future<List<Map<String, dynamic>>> getJournalReportForExport(
    String teacherId, {
    int? month,
    int? year,
    String? studentId,
  }) async {
    final students = await getManagedStudents(teacherId);
    if (students.isEmpty) return [];

    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;

    final startOfMonth = DateTime(y, m, 1, 0, 0, 0).toIso8601String();
    final endOfMonth = DateTime(y, m + 1, 0, 23, 59, 59).toIso8601String();

    final studentIds = studentId != null
        ? [studentId]
        : students.map((s) => s['student_id']).toList();

    final response = await _supabase
        .from('daily_journals')
        .select('*, profiles!inner(full_name)')
        .inFilter('student_id', studentIds)
        .gte('created_at', startOfMonth)
        .lte('created_at', endOfMonth)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 9. Get Student Attendance by Month
  Future<List<Map<String, dynamic>>> getStudentAttendanceByMonth(
    String studentId,
    int month,
    int year,
  ) async {
    final startOfMonth = DateTime(year, month, 1, 0, 0, 0).toIso8601String();
    final endOfMonth = DateTime(
      year,
      month + 1,
      0,
      23,
      59,
      59,
    ).toIso8601String();

    final response = await _supabase
        .from('attendance_logs')
        .select()
        .eq('student_id', studentId)
        .gte('created_at', startOfMonth)
        .lte('created_at', endOfMonth)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // 10. Get Student Journals by Month
  Future<List<Map<String, dynamic>>> getStudentJournalsByMonth(
    String studentId,
    int month,
    int year,
  ) async {
    final startOfMonth = DateTime(year, month, 1, 0, 0, 0).toIso8601String();
    final endOfMonth = DateTime(
      year,
      month + 1,
      0,
      23,
      59,
      59,
    ).toIso8601String();

    final response = await _supabase
        .from('daily_journals')
        .select()
        .eq('student_id', studentId)
        .gte('created_at', startOfMonth)
        .lte('created_at', endOfMonth)
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

final managedAttendanceProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, DateTime?>((ref, date) async {
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (user == null) return [];
      return ref
          .watch(teacherRepositoryProvider)
          .getManagedStudentsAttendance(user.id, date: date);
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
