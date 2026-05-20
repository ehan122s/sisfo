import { supabase } from '@/lib/supabase'

export interface AttendanceReportItem {
    studentId: string
    studentName: string
    className: string
    companyName: string
    start_date?: string
    stats: {
        hadir: number
        terlambat: number
        sakit: number
        izin: number
        alpa: number
        totalDays: number
        percentage: number
    }
}

interface RpcReportRow {
    student_id: string
    student_name: string
    class_name: string
    company_name: string
    hadir: number
    terlambat: number
    sakit: number
    izin: number
    alpa: number
    total_days: number
    percentage: number
}

// Interface untuk kolom output dari get_yearly_attendance_report (pakai prefix out_)
interface RpcYearlyReportRow {
    out_student_id: string
    out_student_name: string
    out_class_name: string
    out_company_name: string
    out_hadir: number
    out_terlambat: number
    out_sakit: number
    out_izin: number
    out_alpa: number
    out_total_days: number
    out_percentage: number
}

// Interface baru untuk mendefinisikan struktur data kembalian dari rpc 'get_distinct_classes'
interface RpcClassRow {
    class_name: string
}

export const getMonthlyAttendanceReport = async (
    month: number, // 0-indexed (JS Date convention)
    year: number,
    className?: string
): Promise<AttendanceReportItem[]> => {
    const { data, error } = await supabase
        .rpc('get_monthly_attendance_report', {
            p_year: year,
            p_month: month + 1, // Convert 0-indexed to 1-indexed
            p_class: className && className !== 'all' ? className : null
        })

    if (error) throw error
    if (!data) return []

    return (data as RpcReportRow[]).map(row => ({
        studentId: row.student_id,
        studentName: row.student_name || 'Unnamed',
        className: row.class_name || '-',
        companyName: row.company_name || '-',
        stats: {
            hadir: row.hadir,
            terlambat: row.terlambat,
            sakit: row.sakit,
            izin: row.izin,
            alpa: row.alpa,
            totalDays: row.total_days,
            percentage: row.percentage
        }
    }))
}

export const getStudentYearlyAttendance = async (
    studentId: string,
    year: number
) => {
    const startDate = new Date(year, 0, 1).toISOString()
    const endDate = new Date(year, 11, 31, 23, 59, 59).toISOString()

    const { data, error } = await supabase
        .from('attendance_logs')
        .select('id, status, created_at')
        .eq('student_id', studentId)
        .gte('created_at', startDate)
        .lte('created_at', endDate)
        .order('created_at', { ascending: false })

    if (error) throw error
    return data
}

export const getClassList = async (): Promise<string[]> => {
    // Use RPC to get distinct classes efficiently and bypass row limits
    const { data, error } = await supabase.rpc('get_distinct_classes')

    if (error) throw error

    // Menentukan tipe data d secara eksplisit sebagai RpcClassRow agar tidak dianggap 'any'
    const classes = (data as RpcClassRow[] || []).map((d: RpcClassRow) => d.class_name).filter(Boolean)
    return classes.sort() as string[]
}

export const getYearlyAttendanceReport = async (
    year: number,
    className?: string
): Promise<AttendanceReportItem[]> => {
    const { data, error } = await supabase
        .rpc('get_yearly_attendance_report', {
            p_year: year,
            p_class: className && className !== 'all' ? className : null
        })

    if (error) throw error
    if (!data) return []

    return (data as RpcYearlyReportRow[]).map(row => ({
        studentId: row.out_student_id,
        studentName: row.out_student_name || 'Unnamed',
        className: row.out_class_name || '-',
        companyName: row.out_company_name || '-',
        stats: {
            hadir: row.out_hadir,
            terlambat: row.out_terlambat,
            sakit: row.out_sakit,
            izin: row.out_izin,
            alpa: row.out_alpa,
            totalDays: row.out_total_days,
            percentage: row.out_percentage
        }
    }))
}