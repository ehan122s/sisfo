import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { startOfDay, endOfDay, subDays, format } from 'date-fns'
import { id } from 'date-fns/locale'

export function useDashboardAnalytics(selectedDate: string) {
    // 1. Total Students (all grades including XII)
    const { data: totalStudents = 0, isLoading: isLoadingTotal } = useQuery({
        queryKey: ['totalStudents', 'all'],
        queryFn: async () => {
            const { count } = await supabase
                .from('profiles')
                .select('id', { count: 'exact', head: true })
                .eq('role', 'student')
            return count ?? 0
        },
    })

    // 2. Attendance Stats for Selected Date (all grades) using RPC
    const { data: attendanceStats, isLoading: isLoadingStats } = useQuery({
        queryKey: ['attendanceStats', selectedDate, 'v5-rpc-all'],
        queryFn: async () => {
            // Construct dates in Local Time first to ensure we capture the full local day
            const localStart = new Date(`${selectedDate}T00:00:00`)
            const localEnd = new Date(`${selectedDate}T23:59:59.999`)
            const start = localStart.toISOString()
            const end = localEnd.toISOString()

            const { data, error } = await supabase.rpc('count_attendance_by_grade', {
                start_time: start,
                end_time: end,
                grade_filter: null
            })

            if (error) throw error

            const stats: Record<string, number> = {
                Hadir: 0,
                Terlambat: 0,
                Izin: 0,
                Sakit: 0,
                Alpa: 0,
                'Belum Hadir': 0
            }

            // Map RPC results to stats
            data?.forEach((row: { status: string; count: number }) => {
                if (row.status in stats) {
                    stats[row.status] = row.count
                }
            })

            // Calculate "Belum Hadir"
            const recorded = stats.Hadir + stats.Terlambat + stats.Izin + stats.Sakit + stats.Alpa
            stats['Belum Hadir'] = Math.max(0, totalStudents - recorded)

            return stats
        },
        enabled: totalStudents > 0
    })

    // 3. Weekly Trend (90 Days - all grades) using RPC
    const { data: weeklyTrend, isLoading: isLoadingTrend } = useQuery({
        queryKey: ['weeklyTrend', selectedDate, 'all-rpc'],
        queryFn: async () => {
            const anchorDate = new Date(selectedDate)
            const endDate = endOfDay(anchorDate)
            const startDate = startOfDay(subDays(anchorDate, 90)) // 90 days window for interactive chart

            const { data, error } = await supabase.rpc('get_attendance_trend_by_grade', {
                start_time: startDate.toISOString(),
                end_time: endDate.toISOString(),
                grade_filter: null
            })

            if (error) throw error

            // Initialize map for last 90 days
            const grouped = new Map()
            for (let i = 0; i <= 90; i++) {
                const date = subDays(anchorDate, i)
                const dateKey = format(date, 'yyyy-MM-dd')
                grouped.set(dateKey, {
                    rawDate: date,
                    dateStr: dateKey,
                    date: format(date, 'dd MMM', { locale: id }),
                    Hadir: 0,
                    TidakHadir: 0
                })
            }

            // Fill with data from RPC
            data?.forEach((row: { log_date: string; status: string; count: number }) => {
                const dateKey = row.log_date
                if (grouped.has(dateKey)) {
                    const entry = grouped.get(dateKey)
                    const status = row.status
                    if (status === 'Hadir') {
                        entry.Hadir += row.count
                    } else if (status === 'Terlambat' || status === 'Izin' || status === 'Sakit' || status === 'Alpa') {
                        entry.TidakHadir += row.count
                    }
                }
            })

            // Convert to array and reverse to show oldest to newest
            return Array.from(grouped.values()).reverse()
        },
    })

    return {
        totalStudents,
        attendanceStats,
        weeklyTrend,
        isLoading: isLoadingTotal || isLoadingStats || isLoadingTrend
    }
}
