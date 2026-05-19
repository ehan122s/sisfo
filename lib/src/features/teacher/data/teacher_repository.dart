import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';
import '../../authentication/data/auth_repository.dart';

class TeacherRepository {
  // ───────────────────────────────────────────────
  // HELPER: ambil student IDs bimbingan guru
  // ───────────────────────────────────────────────

  Future<List<String>> getManagedStudentIds(String teacherId) async {
    final homeroomClasses = await supabase
        .from('class_homeroom_teachers')
        .select('class_name')
        .eq('teacher_id', teacherId);

    final supervisorCompanies = await supabase
        .from('supervisor_assignments')
        .select('company_id')
        .eq('teacher_id', teacherId);

    final List<String> studentIds = [];

    if (homeroomClasses.isNotEmpty) {
      final classNames =
          homeroomClasses.map((e) => e['class_name'] as String).toList();
      final students = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'student')
          .inFilter('class_name', classNames);
      studentIds.addAll(students.map((e) => e['id'] as String));
    }

    if (supervisorCompanies.isNotEmpty) {
      final companyIds =
          supervisorCompanies.map((e) => e['company_id'] as int).toList();
      final students = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'student')
          .inFilter('company_id', companyIds);
      for (final s in students) {
        final id = s['id'] as String;
        if (!studentIds.contains(id)) studentIds.add(id);
      }
    }

    return studentIds;
  }

  // ───────────────────────────────────────────────
  // DASHBOARD STATS
  // ───────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats(String teacherId) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final studentIds = await getManagedStudentIds(teacherId);
    final totalStudents = studentIds.length;

    int presentToday = 0;
    int pendingJournals = 0;

    if (studentIds.isNotEmpty) {
      final attendanceToday = await supabase
          .from('attendance_logs')
          .select('id')
          .eq('date', todayStr)
          .inFilter('student_id', studentIds)
          .inFilter('status', ['Hadir', 'Terlambat']);
      presentToday = attendanceToday.length;

      final pending = await supabase
          .from('daily_journals')
          .select('id')
          .eq('is_approved', false)
          .inFilter('student_id', studentIds);
      pendingJournals = pending.length;
    }

    return {
      'total_students': totalStudents,
      'present_today': presentToday,
      'pending_journals': pendingJournals,
    };
  }

  // ───────────────────────────────────────────────
  // MONITORING ABSENSI
  // ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getManagedAttendance(
      String teacherId) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final studentIds = await getManagedStudentIds(teacherId);
    if (studentIds.isEmpty) return [];

    final students = await supabase
        .from('profiles')
        .select('id, full_name, class_name, avatar_url, company_id')
        .eq('role', 'student')
        .inFilter('id', studentIds)
        .order('full_name');

    final companies = await supabase.from('companies').select('id, name');
    final companyMap = {
      for (final c in companies) c['id'] as int: c['name'] as String,
    };

    final attendance = await supabase
        .from('attendance_logs')
        .select('student_id, status, check_in_time, check_out_time')
        .eq('date', todayStr)
        .inFilter('student_id', studentIds);

    final attendanceMap = {
      for (final a in attendance) a['student_id'] as String: a,
    };

    return students.map((s) {
      final companyId = s['company_id'] as int?;
      final log = attendanceMap[s['id'] as String];
      return {
        ...s,
        'company_name': companyId != null ? companyMap[companyId] : '-',
        'attendance_log': log,
        'attendance_status': log?['status'] as String? ?? 'Belum Hadir',
      };
    }).toList();
  }

  // ───────────────────────────────────────────────
  // JURNAL PENDING (DIPERBAIKI - CASTING)
  // ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPendingJournals(
      String teacherId) async {
    final studentIds = await getManagedStudentIds(teacherId);
    if (studentIds.isEmpty) return [];

    final result = await supabase
        .from('daily_journals')
        .select('''
          id, date, description, activities, evidence_url, image_url,
          is_approved, created_at, student_id,
          profiles!daily_journals_student_id_fkey (
            full_name, class_name, avatar_url
          )
        ''')
        .eq('is_approved', false)
        .inFilter('student_id', studentIds)
        .order('created_at', ascending: false);

    // Transformasi dengan casting yang benar
    final transformed = (result as List).map((journal) {
      final activities = journal['activities'] as String? ?? '';
      final title = activities.split('\n').first.trim();
      return {
        ...journal,
        'activity_title': title.isNotEmpty ? title : 'Kegiatan Prakerin',
        'evidence_photo': journal['evidence_url'] ?? journal['image_url'],
      };
    }).toList();

    return transformed.cast<Map<String, dynamic>>();
  }

  /// Setujui atau tolak jurnal
  Future<void> updateJournalStatus(int journalId, bool approve) async {
    await supabase
        .from('daily_journals')
        .update({
          'is_approved': approve,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', journalId);
  }

  // ───────────────────────────────────────────────
  // DAFTAR SISWA
  // ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getManagedStudents(
      String teacherId) async {
    final studentIds = await getManagedStudentIds(teacherId);
    if (studentIds.isEmpty) return [];

    final students = await supabase
        .from('profiles')
        .select(
            'id, full_name, class_name, nisn, avatar_url, phone_number, status, company_id, address')
        .eq('role', 'student')
        .inFilter('id', studentIds)
        .order('full_name');

    final companies = await supabase.from('companies').select('id, name');
    final companyMap = {
      for (final c in companies) c['id'] as int: c['name'] as String,
    };

    return students.map((s) {
      final companyId = s['company_id'] as int?;
      return {
        ...s,
        'student_id': s['id'],
        'company_name': companyId != null ? companyMap[companyId] : null,
      };
    }).toList();
  }

  // ───────────────────────────────────────────────
  // DETAIL SISWA — absensi per bulan
  // ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getStudentAttendanceByMonth(
    String studentId,
    int month,
    int year,
  ) async {
    final firstDay = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDayDate = DateTime(year, month + 1, 0);
    final lastDay =
        '$year-${month.toString().padLeft(2, '0')}-${lastDayDate.day.toString().padLeft(2, '0')}';

    final result = await supabase
        .from('attendance_logs')
        .select(
            'id, date, status, check_in_time, check_out_time, notes, created_at')
        .eq('student_id', studentId)
        .gte('date', firstDay)
        .lte('date', lastDay)
        .order('date', ascending: false);

    return List<Map<String, dynamic>>.from(result);
  }

  // ───────────────────────────────────────────────
  // DETAIL SISWA — jurnal per bulan (DIPERBAIKI - CASTING)
  // ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getStudentJournalsByMonth(
    String studentId,
    int month,
    int year,
  ) async {
    final firstDay = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDayDate = DateTime(year, month + 1, 0);
    final lastDay =
        '$year-${month.toString().padLeft(2, '0')}-${lastDayDate.day.toString().padLeft(2, '0')}';

    final result = await supabase
        .from('daily_journals')
        .select('''
          id, date, activities, description, challenges, notes, 
          evidence_url, image_url, is_approved, created_at
        ''')
        .eq('student_id', studentId)
        .gte('date', firstDay)
        .lte('date', lastDay)
        .order('date', ascending: false);

    // Transformasi dengan casting yang benar
    final transformed = (result as List).map((journal) {
      final activities = journal['activities'] as String? ?? '';
      final title = activities.split('\n').first.trim();
      return {
        ...journal,
        'activity_title': title.isNotEmpty ? title : 'Kegiatan Prakerin',
        'evidence_photo': journal['evidence_url'] ?? journal['image_url'],
      };
    }).toList();

    return transformed.cast<Map<String, dynamic>>();
  }

  // ───────────────────────────────────────────────
  // EXPORT ABSENSI
  // ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAttendanceReportForExport(
      String teacherId) async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final firstDayStr =
        '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-01';
    final lastDayStr =
        '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';

    final studentIds = await getManagedStudentIds(teacherId);
    if (studentIds.isEmpty) return [];

    final data = await supabase
        .from('attendance_logs')
        .select('''
          id, date, status, check_in_time, check_out_time, notes, student_id,
          profiles!attendance_logs_student_id_fkey (full_name, class_name, nisn)
        ''')
        .inFilter('student_id', studentIds)
        .gte('date', firstDayStr)
        .lte('date', lastDayStr)
        .order('date', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}

// ───────────────────────────────────────────────
// PROVIDERS
// ───────────────────────────────────────────────

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository();
});

/// Stats untuk dashboard utama
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    return {'total_students': 0, 'present_today': 0, 'pending_journals': 0};
  }
  return ref.read(teacherRepositoryProvider).getDashboardStats(user.id);
});

/// Absensi hari ini — TeacherAttendanceMonitorScreen
final managedAttendanceProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return [];
  return ref.read(teacherRepositoryProvider).getManagedAttendance(user.id);
});

/// Jurnal pending — TeacherJournalApprovalScreen
final pendingJournalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return [];
  return ref.read(teacherRepositoryProvider).getPendingJournals(user.id);
});

/// Daftar siswa — TeacherStudentListScreen
final managedStudentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return [];
  return ref.read(teacherRepositoryProvider).getManagedStudents(user.id);
});