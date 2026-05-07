// lib/features/teacher/data/teacher_repository.dart
//
// Terhubung ke tabel Supabase:
//   - profiles           (role, class_name, company_id)
//   - attendance_logs    (status, date, student_id)
//   - daily_journals     (is_approved, student_id)
//   - placements         (student_id, company_id, status)
//   - companies          (name)
//   - supervisor_assignments (teacher_id, company_id)
//   - class_homeroom_teachers (teacher_id, class_name)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';
import '../../authentication/data/auth_repository.dart';

class TeacherRepository {
  // ─────────────────────────────────────────────
  // DASHBOARD STATS
  // ─────────────────────────────────────────────

  /// Mengembalikan stats untuk dashboard:
  ///   total_students   → jumlah siswa yang dibimbing guru ini
  ///   present_today    → hadir/terlambat hari ini
  ///   pending_journals → jurnal yang belum disetujui (is_approved = false)
  Future<Map<String, dynamic>> getDashboardStats(String teacherId) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // 1. Cari class_name yang dipegang guru ini (homeroom teacher)
    //    Sekaligus cari company yang diawasi (supervisor_assignments)
    final assignedCompanies = await supabase
        .from('supervisor_assignments')
        .select('company_id')
        .eq('teacher_id', teacherId);

    final homeroomClasses = await supabase
        .from('class_homeroom_teachers')
        .select('class_name')
        .eq('teacher_id', teacherId);

    // Kumpulkan semua student_id yang relevan
    // (siswa dari kelas yang dipegang ATAU siswa di perusahaan yang diawasi)
    final List<String> studentIds = [];

    if (homeroomClasses.isNotEmpty) {
      final classNames =
          homeroomClasses.map((e) => e['class_name'] as String).toList();

      final studentsInClass = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'student')
          .inFilter('class_name', classNames);

      studentIds.addAll(
        studentsInClass.map((e) => e['id'] as String),
      );
    }

    if (assignedCompanies.isNotEmpty) {
      final companyIds =
          assignedCompanies.map((e) => e['company_id'] as int).toList();

      final studentsInCompany = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'student')
          .inFilter('company_id', companyIds);

      for (final s in studentsInCompany) {
        final id = s['id'] as String;
        if (!studentIds.contains(id)) studentIds.add(id);
      }
    }

    // Jika tidak ada assignment sama sekali, fallback: semua siswa
    final List<String> effectiveStudentIds = studentIds.isEmpty
        ? await _getAllStudentIds()
        : studentIds;

    final totalStudents = effectiveStudentIds.length;

    // 2. Hitung hadir hari ini
    int presentToday = 0;
    if (effectiveStudentIds.isNotEmpty) {
      final attendanceToday = await supabase
          .from('attendance_logs')
          .select('id, status')
          .eq('date', todayStr)
          .inFilter('student_id', effectiveStudentIds)
          .inFilter('status', ['Hadir', 'Terlambat']);

      presentToday = attendanceToday.length;
    }

    // 3. Hitung jurnal pending (belum disetujui)
    int pendingJournals = 0;
    if (effectiveStudentIds.isNotEmpty) {
      final pending = await supabase
          .from('daily_journals')
          .select('id')
          .eq('is_approved', false)
          .inFilter('student_id', effectiveStudentIds);

      pendingJournals = pending.length;
    }

    return {
      'total_students': totalStudents,
      'present_today': presentToday,
      'pending_journals': pendingJournals,
    };
  }

  Future<List<String>> _getAllStudentIds() async {
    final result = await supabase
        .from('profiles')
        .select('id')
        .eq('role', 'student');
    return result.map((e) => e['id'] as String).toList();
  }

  // ─────────────────────────────────────────────
  // EXPORT ABSENSI
  // ─────────────────────────────────────────────

  /// Data absensi bulan ini untuk semua siswa bimbingan guru ini.
  /// Dipakai oleh ExcelService().generateAttendanceReport()
  Future<List<Map<String, dynamic>>> getAttendanceReportForExport(
    String teacherId,
  ) async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    final firstDayStr =
        '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}';
    final lastDayStr =
        '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';

    // Ambil student IDs yang relevan (sama dengan getDashboardStats)
    final assignedCompanies = await supabase
        .from('supervisor_assignments')
        .select('company_id')
        .eq('teacher_id', teacherId);

    final homeroomClasses = await supabase
        .from('class_homeroom_teachers')
        .select('class_name')
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

    if (assignedCompanies.isNotEmpty) {
      final companyIds =
          assignedCompanies.map((e) => e['company_id'] as int).toList();
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

    if (studentIds.isEmpty) return [];

    // Ambil data absensi + join profil siswa + join perusahaan via placements
    final data = await supabase
        .from('attendance_logs')
        .select('''
          id,
          date,
          status,
          check_in_time,
          check_out_time,
          notes,
          student_id,
          profiles!attendance_logs_student_id_fkey (
            full_name,
            class_name,
            nisn
          ),
          placements!attendance_logs_placement_id_fkey (
            companies (
              name
            )
          )
        ''')
        .inFilter('student_id', studentIds)
        .gte('date', firstDayStr)
        .lte('date', lastDayStr)
        .order('date', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ─────────────────────────────────────────────
  // DAFTAR SISWA
  // ─────────────────────────────────────────────

  /// Ambil semua siswa bimbingan guru ini beserta info perusahaan & status
  Future<List<Map<String, dynamic>>> getStudentList(String teacherId) async {
    final homeroomClasses = await supabase
        .from('class_homeroom_teachers')
        .select('class_name')
        .eq('teacher_id', teacherId);

    if (homeroomClasses.isEmpty) return [];

    final classNames =
        homeroomClasses.map((e) => e['class_name'] as String).toList();

    final students = await supabase
        .from('profiles')
        .select('''
          id, full_name, class_name, nisn, status, phone_number,
          companies (name)
        ''')
        .eq('role', 'student')
        .inFilter('class_name', classNames)
        .order('full_name');

    return List<Map<String, dynamic>>.from(students);
  }
}

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository();
});

/// Provider stats dashboard — dipakai sebagai: ref.watch(dashboardStatsProvider)
final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    return {'total_students': 0, 'present_today': 0, 'pending_journals': 0};
  }
  return ref.read(teacherRepositoryProvider).getDashboardStats(user.id);
});