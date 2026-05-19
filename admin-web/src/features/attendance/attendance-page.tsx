import { useState, useMemo, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { format } from 'date-fns'
import { id as idLocale } from 'date-fns/locale'
import { toast } from 'sonner'
import {
    CalendarIcon, Loader2, Search, FileSpreadsheet, FileText,
    LayoutGrid, Table as TableIcon,
    Check, CheckCheck, ChevronsUpDown, ChevronLeft, ChevronRight,
    Users, Clock, UserCheck, UserX
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { getClassList } from '../reports/services/report-service'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from '@/components/ui/command'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Input } from '@/components/ui/input'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { exportToExcel, exportToPDF } from '@/lib/export'
import { useDebounce } from '../../hooks/use-debounce'
import { columns } from './components/attendance-table/columns'
import { DataTable } from './components/attendance-table/data-table'

interface Student {
    id: string
    full_name: string
    class_name: string
    avatar_url?: string
    company_name: string | null
    status: string
    check_in_time: string | null
    check_out_time: string | null
}

interface AttendanceRecord {
    id?: number
    student_id: string
    status: string
    check_in_time?: string
    check_out_time?: string
    is_from_app?: boolean
    created_at?: string
}

interface RawProfile {
    id: string
    full_name: string
    class_name: string
    avatar_url: string | null
    placements: { companies: { name: string } | null }[] | null
}

interface RawReport {
    id: string
    full_name: string
    class_name: string
    avatar_url: string | null
    company_name: string | null
    attendance_status: string | null
    check_in_time: string | null
    check_out_time: string | null
    total_count: number
}

const STATUS_OPTIONS = ['Hadir', 'Terlambat', 'Izin', 'Sakit', 'Alpa']
const REPORT_FETCH_LIMIT = 1000
const PAGE_SIZE = 45

const STATUS_CONFIG: Record<string, { dot: string; badge: string; trigger: string }> = {
    Hadir: {
        dot: 'bg-emerald-500',
        badge: 'bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-500/15 dark:text-emerald-400 dark:border-emerald-500/30',
        trigger: 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200 dark:bg-emerald-500/15 dark:text-emerald-400 dark:hover:bg-emerald-500/25 dark:border-emerald-500/30',
    },
    Terlambat: {
        dot: 'bg-amber-500',
        badge: 'bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-500/15 dark:text-amber-400 dark:border-amber-500/30',
        trigger: 'bg-amber-50 text-amber-700 hover:bg-amber-100 border border-amber-200 dark:bg-amber-500/15 dark:text-amber-400 dark:hover:bg-amber-500/25 dark:border-amber-500/30',
    },
    Izin: {
        dot: 'bg-sky-500',
        badge: 'bg-sky-50 text-sky-700 border border-sky-200 dark:bg-sky-500/15 dark:text-sky-400 dark:border-sky-500/30',
        trigger: 'bg-sky-50 text-sky-700 hover:bg-sky-100 border border-sky-200 dark:bg-sky-500/15 dark:text-sky-400 dark:hover:bg-sky-500/25 dark:border-sky-500/30',
    },
    Sakit: {
        dot: 'bg-purple-500',
        badge: 'bg-purple-50 text-purple-700 border border-purple-200 dark:bg-purple-500/15 dark:text-purple-400 dark:border-purple-500/30',
        trigger: 'bg-purple-50 text-purple-700 hover:bg-purple-100 border border-purple-200 dark:bg-purple-500/15 dark:text-purple-400 dark:hover:bg-purple-500/25 dark:border-purple-500/30',
    },
    Alpa: {
        dot: 'bg-red-500',
        badge: 'bg-red-50 text-red-700 border border-red-200 dark:bg-red-500/15 dark:text-red-400 dark:border-red-500/30',
        trigger: 'bg-red-50 text-red-700 hover:bg-red-100 border border-red-200 dark:bg-red-500/15 dark:text-red-400 dark:hover:bg-red-500/25 dark:border-red-500/30',
    },
}

const AVATAR_COLORS = [
    'bg-blue-100 text-blue-700 dark:bg-blue-500/20 dark:text-blue-300',
    'bg-indigo-100 text-indigo-700 dark:bg-indigo-500/20 dark:text-indigo-300',
    'bg-sky-100 text-sky-700 dark:bg-sky-500/20 dark:text-sky-300',
    'bg-violet-100 text-violet-700 dark:bg-violet-500/20 dark:text-violet-300',
    'bg-cyan-100 text-cyan-700 dark:bg-cyan-500/20 dark:text-cyan-300',
]

// Accent colors per stat card: top border + icon bg + number color
const STAT_CARDS = [
    {
        key: 'Hadir',
        label: 'HADIR',
        icon: UserCheck,
        accent: 'border-t-emerald-500',
        iconBg: 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400',
        numColor: 'text-emerald-600 dark:text-emerald-400',
        bar: 'bg-emerald-500',
        barBg: 'bg-emerald-100 dark:bg-emerald-500/10',
        darkColor: 'dark:text-emerald-400',
    },
    {
        key: 'Terlambat',
        label: 'TERLAMBAT',
        icon: Clock,
        accent: 'border-t-amber-500',
        iconBg: 'bg-amber-50 text-amber-600 dark:bg-amber-500/15 dark:text-amber-400',
        numColor: 'text-amber-600 dark:text-amber-400',
        bar: 'bg-amber-500',
        barBg: 'bg-amber-100 dark:bg-amber-500/10',
        darkColor: 'dark:text-amber-400',
    },
    {
        key: 'Izin',
        label: 'IZIN',
        icon: Users,
        accent: 'border-t-sky-500',
        iconBg: 'bg-sky-50 text-sky-600 dark:bg-sky-500/15 dark:text-sky-400',
        numColor: 'text-sky-600 dark:text-sky-400',
        bar: 'bg-sky-500',
        barBg: 'bg-sky-100 dark:bg-sky-500/10',
        darkColor: 'dark:text-sky-400',
    },
    {
        key: 'Sakit',
        label: 'SAKIT',
        icon: UserX,
        accent: 'border-t-purple-500',
        iconBg: 'bg-purple-50 text-purple-600 dark:bg-purple-500/15 dark:text-purple-400',
        numColor: 'text-purple-600 dark:text-purple-400',
        bar: 'bg-purple-500',
        barBg: 'bg-purple-100 dark:bg-purple-500/10',
        darkColor: 'dark:text-purple-400',
    },
    {
        key: 'Alpa',
        label: 'ALPA',
        icon: UserX,
        accent: 'border-t-red-500',
        iconBg: 'bg-red-50 text-red-600 dark:bg-red-500/15 dark:text-red-400',
        numColor: 'text-red-600 dark:text-red-400',
        bar: 'bg-red-500',
        barBg: 'bg-red-100 dark:bg-red-500/10',
        darkColor: 'dark:text-red-400',
    },
]

export function AttendancePage() {
    const [date, setDate] = useState<Date>(new Date())
    const [page, setPage] = useState(0)
    const [search, setSearch] = useState('')
    const [selectedClass, setSelectedClass] = useState('Semua')
    const [openClassFilter, setOpenClassFilter] = useState(false)
    const [viewMode, setViewMode] = useState<'input' | 'report'>('input')
    const [savingStudentId, setSavingStudentId] = useState<string | null>(null)
    const [savedStudentIds, setSavedStudentIds] = useState<Set<string>>(new Set())
    const [isBulkUpdating, setIsBulkUpdating] = useState(false)
    const queryClient = useQueryClient()

    const clearSavedIndicator = useCallback((studentId: string) => {
        setTimeout(() => {
            setSavedStudentIds(prev => {
                const next = new Set(prev)
                next.delete(studentId)
                return next
            })
        }, 1500)
    }, [])

    const debouncedSearch = useDebounce(search, 500)
    const dateStr = format(date, 'yyyy-MM-dd')

    const { data: classes = [] } = useQuery<string[]>({
        queryKey: ['classes'],
        queryFn: async () => {
            const uniqueClasses = await getClassList()
            return ['Semua', ...uniqueClasses]
        },
    })

    const { data: studentsData, isLoading: isLoadingStudents } = useQuery({
        queryKey: ['students-for-attendance', page, debouncedSearch, selectedClass],
        queryFn: async () => {
            let query = supabase
                .from('profiles')
                .select('id, full_name, class_name, avatar_url, placements(companies(name))', { count: 'exact' })
                .eq('role', 'student').eq('status', 'active')
                .order('class_name').order('full_name')

            if (selectedClass !== 'Semua') query = query.eq('class_name', selectedClass)
            if (debouncedSearch) query = query.ilike('full_name', `%${debouncedSearch}%`)

            const from = page * PAGE_SIZE
            const { data, error, count } = await query.range(from, from + PAGE_SIZE - 1)
            if (error) throw error

            const raw = (data || []) as unknown as RawProfile[]
            return {
                students: raw.map((s) => ({
                    id: s.id,
                    full_name: s.full_name,
                    class_name: s.class_name,
                    avatar_url: s.avatar_url ?? undefined,
                    company_name: s.placements?.[0]?.companies?.name ?? null,
                })) as Student[],
                count: count || 0
            }
        },
        enabled: viewMode === 'input'
    })

    const { data: reportStudentsData, isLoading: isLoadingReportStudents } = useQuery({
        queryKey: ['students-for-report-all', dateStr],
        queryFn: async () => {
            const { data, error } = await supabase.rpc('get_students_by_attendance_status', {
                target_date: dateStr,
                status_filter: null,
                class_filter: null,
                search_term: null,
                page_offset: 0,
                page_limit: REPORT_FETCH_LIMIT
            })
            if (error) throw error

            const raw = (data || []) as RawReport[]
            return {
                students: raw.map((s) => ({
                    id: s.id,
                    full_name: s.full_name,
                    class_name: s.class_name,
                    avatar_url: s.avatar_url ?? undefined,
                    company_name: s.company_name ?? '-',
                    status: s.attendance_status ?? 'Alpa',
                    check_in_time: s.check_in_time ?? undefined,
                    check_out_time: s.check_out_time ?? undefined,
                })) as Student[],
                count: raw?.[0]?.total_count ?? 0
            }
        },
        enabled: viewMode === 'report'
    })

    const students = useMemo(() => {
        return viewMode === 'input' ? (studentsData?.students || []) : (reportStudentsData?.students || [])
    }, [viewMode, studentsData?.students, reportStudentsData?.students])

    const totalCount = viewMode === 'input' ? (studentsData?.count || 0) : (reportStudentsData?.count || 0)
    const totalPages = Math.ceil(totalCount / PAGE_SIZE)

    const activeQueryKey = useMemo(() => ['attendance_logs', dateStr, students.map(s => s.id).join(',')], [dateStr, students])

    const { data: attendanceLogs = [], isLoading: isLoadingAttendance } = useQuery<AttendanceRecord[]>({
        queryKey: activeQueryKey,
        enabled: students.length > 0,
        queryFn: async () => {
            const startOfDay = `${dateStr}T00:00:00`
            const endOfDay = `${dateStr}T23:59:59`
            const studentIds = students.map(s => s.id)
            if (studentIds.length === 0) return []
            const { data, error } = await supabase.from('attendance_logs')
                .select('*')
                .in('student_id', studentIds)
                .gte('created_at', startOfDay)
                .lte('created_at', endOfDay)
            if (error) throw error
            return data as AttendanceRecord[]
        },
    })

    const initialAttendanceData = useMemo(() => {
        const mapping: Record<string, AttendanceRecord> = {}
        students.forEach((student: Student) => {
            const existing = attendanceLogs.find(log => log.student_id === student.id)
            mapping[student.id] = existing
                ? { ...existing, is_from_app: !!existing.check_in_time }
                : { student_id: student.id, status: 'Alpa', is_from_app: false }
        })
        return mapping
    }, [students, attendanceLogs])

    const summaryStats = useMemo(() => {
        const counts: Record<string, number> = {}
        STATUS_OPTIONS.forEach(s => counts[s] = 0)
        students.forEach((student: Student) => {
            const status = initialAttendanceData[student.id]?.status || 'Alpa'
            counts[status] = (counts[status] || 0) + 1
        })
        return counts
    }, [students, initialAttendanceData])

    const groupedStudents = useMemo(() => {
        const groups: Record<string, Student[]> = {}
        students.forEach((student: Student) => {
            const cls = student.class_name || 'Tanpa Kelas'
            if (!groups[cls]) groups[cls] = []
            groups[cls].push(student)
        })
        return Object.entries(groups).sort(([a], [b]) => a.localeCompare(b))
    }, [students])

    const updateStatusMutation = useMutation({
        mutationFn: async ({ studentId, status }: { studentId: string; status: string }) => {
            setSavingStudentId(studentId)
            const existingLog = attendanceLogs.find(l => l.student_id === studentId)
            if (existingLog?.id && existingLog.id > 0) {
                const { data, error } = await supabase.from('attendance_logs')
                    .update({ status }).eq('id', existingLog.id).select().single()
                if (error) throw error
                return data
            } else {
                const { data, error } = await supabase.from('attendance_logs')
                    .insert({ student_id: studentId, status, created_at: `${dateStr}T12:00:00` })
                    .select().single()
                if (error) throw error
                return data
            }
        },
        onMutate: async ({ studentId, status }) => {
            await queryClient.cancelQueries({ queryKey: activeQueryKey })
            const previousLogs = queryClient.getQueryData<AttendanceRecord[]>(activeQueryKey)
            queryClient.setQueryData<AttendanceRecord[]>(activeQueryKey, (old = []) => {
                const idx = old.findIndex(l => l.student_id === studentId)
                if (idx !== -1) { const n = [...old]; n[idx] = { ...n[idx], status }; return n }
                return [...old, { student_id: studentId, status, created_at: `${dateStr}T12:00:00`, id: -Date.now() }]
            })
            return { previousLogs }
        },
        onError: (_err, _vars, context) => {
            if (context?.previousLogs) queryClient.setQueryData(activeQueryKey, context.previousLogs)
            setSavingStudentId(null)
            toast.error("Gagal menyimpan perubahan")
        },
        onSuccess: (data, { studentId }) => {
            if (data) {
                queryClient.setQueryData<AttendanceRecord[]>(activeQueryKey, (old = []) => {
                    const idx = old.findIndex(l => l.student_id === studentId)
                    const updated = { ...data, is_from_app: !!data.check_in_time }
                    if (idx !== -1) { const n = [...old]; n[idx] = updated; return n }
                    return [...old, updated]
                })
            }
            setSavedStudentIds(prev => new Set(prev).add(studentId))
            clearSavedIndicator(studentId)
        },
        onSettled: () => setSavingStudentId(null),
    })

    const getInitials = (name: string) =>
        name.split(' ').map(n => n[0]).join('').toUpperCase().substring(0, 2)

    const getAvatarColor = (name: string) =>
        AVATAR_COLORS[name.charCodeAt(0) % AVATAR_COLORS.length]

    const formatTime = (time?: string) =>
        time ? new Date(time).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : null

    const getClassStats = (classStudents: Student[]) => {
        const counts: Record<string, number> = {}
        classStudents.forEach(s => {
            const status = initialAttendanceData[s.id]?.status || 'Alpa'
            counts[status] = (counts[status] || 0) + 1
        })
        return counts
    }

    const handleExportExcel = () => {
        toast.info("Sedang menyiapkan data...")
        const run = async () => {
            let q = supabase.from('profiles').select('id, full_name, class_name, placements(companies(name))')
                .eq('role', 'student').eq('status', 'active').order('class_name').order('full_name')
            if (selectedClass !== 'Semua') q = q.eq('class_name', selectedClass)
            if (search) q = q.ilike('full_name', `%${search}%`)
            const { data } = await q
            if (!data) return
            const raw = data as unknown as RawProfile[]
            exportToExcel({
                headers: ['Nama', 'Kelas', 'DUDI', 'Status', 'Check In', 'Check Out'],
                rows: raw.map((s) => {
                    const log = attendanceLogs.find(l => l.student_id === s.id)
                    return [s.full_name, s.class_name || '-', s.placements?.[0]?.companies?.name || '-',
                        log?.status || 'Alpa', formatTime(log?.check_in_time) || '-', formatTime(log?.check_out_time) || '-']
                }),
                filename: `absensi_${dateStr}`
            })
        }
        run()
    }

    const handleExportPDF = () => {
        toast.info("Sedang menyiapkan data...")
        const run = async () => {
            let q = supabase.from('profiles').select('id, full_name, class_name, placements(companies(name))')
                .eq('role', 'student').eq('status', 'active').order('class_name').order('full_name')
            if (selectedClass !== 'Semua') q = q.eq('class_name', selectedClass)
            if (search) q = q.ilike('full_name', `%${search}%`)
            const { data } = await q
            if (!data) return
            const raw = data as unknown as RawProfile[]
            exportToPDF({
                headers: ['Nama', 'Kelas', 'DUDI', 'Status', 'Check In', 'Check Out'],
                rows: raw.map((s) => {
                    const log = attendanceLogs.find(l => l.student_id === s.id)
                    return [s.full_name, s.class_name || '-', s.placements?.[0]?.companies?.name || '-',
                        log?.status || 'Alpa', formatTime(log?.check_in_time) || '-', formatTime(log?.check_out_time) || '-']
                }),
                filename: `absensi_${dateStr}`,
                title: `Laporan Absensi - ${format(date, 'dd MMMM yyyy', { locale: idLocale })}`
            })
        }
        run()
    }

    const handleBulkPresent = async () => {
        setIsBulkUpdating(true)
        toast.info('Memproses hadirkan semua...')
        try {
            let q = supabase.from('profiles').select('id').eq('role', 'student').eq('status', 'active')
            if (selectedClass !== 'Semua') q = q.eq('class_name', selectedClass)
            const { data: allStudents, error: studentsError } = await q
            if (studentsError) throw studentsError
            if (!allStudents?.length) { toast.warning('Tidak ada siswa'); setIsBulkUpdating(false); return }

            const { data: currentLogs, error: logsError } = await supabase.from('attendance_logs').select('*')
                .in('student_id', allStudents.map(s => s.id))
                .gte('created_at', `${dateStr}T00:00:00`).lte('created_at', `${dateStr}T23:59:59`)
            if (logsError) throw logsError

            const logsMap = new Map<string, AttendanceRecord>()
            currentLogs?.forEach(log => logsMap.set(log.student_id, log))

            const toUpdate = allStudents
                .filter(s => !logsMap.get(s.id)?.check_in_time)
                .map(s => ({ student_id: s.id, existingLog: logsMap.get(s.id) }))

            if (!toUpdate.length) { toast.info('Semua sudah diabsen via app'); setIsBulkUpdating(false); return }

            const prev = queryClient.getQueryData<AttendanceRecord[]>(['attendance_logs', dateStr]) || []
            const optimistic = [...prev]
            toUpdate.forEach(({ student_id }) => {
                const idx = optimistic.findIndex(l => l.student_id === student_id)
                if (idx >= 0) optimistic[idx] = { ...optimistic[idx], status: 'Hadir' }
                else optimistic.push({ student_id, status: 'Hadir', created_at: `${dateStr}T12:00:00`, id: -Date.now() - Math.random() })
            })
            queryClient.setQueryData(['attendance_logs', dateStr], optimistic)

            const toInsert = toUpdate
                .filter(({ existingLog }) => !(existingLog?.id && existingLog.id > 0))
                .map(({ student_id }) => ({ student_id, status: 'Hadir', created_at: `${dateStr}T12:00:00` }))
            const toUpdateIds = toUpdate
                .filter(({ existingLog }) => existingLog?.id && existingLog.id > 0)
                .map(({ existingLog }) => existingLog!.id!)

            if (toInsert.length) {
                const { error } = await supabase.from('attendance_logs').insert(toInsert).select()
                if (error) { queryClient.setQueryData(['attendance_logs', dateStr], prev); throw error }
            }
            if (toUpdateIds.length) {
                await Promise.all(toUpdateIds.map(id =>
                    supabase.from('attendance_logs').update({ status: 'Hadir' }).eq('id', id)
                ))
            }

            await queryClient.invalidateQueries({ queryKey: ['attendance_logs'] })
            const skipped = allStudents.length - toUpdate.length
            toast.success(`${toUpdate.length} siswa dihadirkan` + (skipped > 0 ? `, ${skipped} sudah via app` : ''))
        } catch (err) {
            console.error(err)
            toast.error('Gagal menghadirkan semua siswa')
            await queryClient.invalidateQueries({ queryKey: ['attendance_logs'] })
        } finally {
            setIsBulkUpdating(false)
        }
    }

    const isLoading = viewMode === 'input' ? (isLoadingStudents || isLoadingAttendance) : isLoadingReportStudents

    return (
        <div className="min-h-screen bg-slate-50 dark:bg-[#070b14] -m-6 p-6 space-y-5">

            {/* ── HEADER ── */}
            <div className="space-y-5">
                {/* Title row */}
                <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                        {/* Accent line above title */}
                        <div className="flex items-center gap-2 mb-3">
                            <div className="h-1 w-8 rounded-full bg-blue-600 dark:bg-blue-500" />
                            <div className="h-1 w-3 rounded-full bg-blue-300 dark:bg-blue-700" />
                        </div>
                        <h1 className="text-4xl font-black italic uppercase tracking-tight leading-none text-slate-900 dark:text-white">
                            ABSENSI{' '}
                            <span className="text-blue-600 dark:text-blue-400">SISWA</span>
                        </h1>
                        <p className="mt-2 text-sm font-medium text-slate-400 dark:text-slate-500">
                            {format(date, 'EEEE, dd MMMM yyyy', { locale: idLocale })}
                        </p>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-3 self-start flex-wrap">
                        {/* Date picker */}
                        <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-white shadow-sm px-3.5 py-2.5 dark:border-white/10 dark:bg-white/5">
                            <CalendarIcon className="h-4 w-4 text-slate-400 dark:text-blue-400 shrink-0" />
                            <Input
                                type="date"
                                value={format(date, 'yyyy-MM-dd')}
                                onChange={(e) => {
                                    const d = new Date(e.target.value)
                                    if (!isNaN(d.getTime())) setDate(d)
                                }}
                                className="w-36 text-sm border-0 shadow-none bg-transparent p-0 h-auto focus-visible:ring-0 text-slate-800 dark:text-white"
                            />
                        </div>

                        {viewMode === 'input' && (
                            <Button
                                onClick={handleBulkPresent}
                                disabled={isBulkUpdating || isLoading}
                                className="rounded-xl bg-blue-600 text-white hover:bg-blue-700 font-black uppercase tracking-wide px-5 h-10 gap-2 shadow-sm shadow-blue-200 dark:bg-blue-500 dark:hover:bg-blue-400 dark:shadow-blue-500/20"
                            >
                                {isBulkUpdating
                                    ? <Loader2 className="h-4 w-4 animate-spin" />
                                    : <CheckCheck className="h-4 w-4" />}
                                Hadirkan Semua
                            </Button>
                        )}
                        {viewMode === 'report' && (
                            <div className="flex gap-2">
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={handleExportExcel}
                                    className="rounded-xl border-slate-200 bg-white shadow-sm text-slate-600 hover:bg-slate-50 gap-2 font-semibold dark:border-white/10 dark:bg-white/5 dark:text-slate-300"
                                >
                                    <FileSpreadsheet className="h-4 w-4 text-emerald-500" /> EXPORT
                                </Button>
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={handleExportPDF}
                                    className="rounded-xl border-slate-200 bg-white shadow-sm text-slate-600 hover:bg-slate-50 gap-2 font-semibold dark:border-white/10 dark:bg-white/5 dark:text-slate-300"
                                >
                                    <FileText className="h-4 w-4 text-red-500" /> PDF
                                </Button>
                            </div>
                        )}
                    </div>
                </div>

                {/* Stat Cards */}
                {viewMode === 'input' && students.length > 0 && !isLoading && (
                    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
                        {STAT_CARDS.map(({ key, label, icon: Icon, accent, iconBg, numColor, bar, barBg, }) => {
                            const count = summaryStats[key] || 0
                            const pct = totalCount > 0 ? Math.round((count / totalCount) * 100) : 0
                            return (
                                <div

                                    key={key}
                                    className={cn(
                                        // White card, border top accent (3px), subtle shadow
                                        'relative rounded-2xl bg-white border border-slate-100 border-t-[3px] shadow-sm',
                                        'dark:bg-[#111b30] dark:border-white/5 dark:border-t-[3px]',
                                        'p-4',
                                        accent
                                    )}
                                >
                                    <div className="flex items-start justify-between mb-3">
                                        <div>
                                            <p className="text-[10px] font-bold tracking-widest text-slate-400 dark:text-slate-500 uppercase mb-1">
                                                {label}
                                            </p>
                                            <p className={cn('text-3xl font-black leading-none', numColor)}>
                                                {count}
                                            </p>
                                        </div>
                                        <div className={cn('h-9 w-9 rounded-xl flex items-center justify-center shrink-0', iconBg)}>
                                            <Icon className="h-4 w-4" />
                                        </div>
                                    </div>
                                    {/* Progress bar with colored track */}
                                    <div className={cn('h-1.5 w-full rounded-full overflow-hidden', barBg)}>
                                        <div
                                            className={cn('h-full rounded-full transition-all duration-500', bar)}
                                            style={{ width: `${pct}%` }}
                                        />
                                    </div>
                                    <p className="mt-1.5 text-[10px] font-semibold text-slate-400 dark:text-slate-600">
                                        {pct}% dari total
                                    </p>
                                </div>
                            )
                        })}
                    </div>
                )}
            </div>

            {/* ── Main Panel ── */}
            <div className="rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-white/5 dark:bg-[#0d1526]">
                <Tabs value={viewMode} onValueChange={(v) => setViewMode(v as 'input' | 'report')}>

                    {/* Tab bar */}
                    <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between px-5 pt-4 pb-4 border-b border-slate-100 dark:border-white/5">
                        <TabsList className="w-full sm:w-auto bg-blue-50 border border-blue-100 dark:bg-white/5 dark:border-white/5 p-1 rounded-xl h-auto">
                            <TabsTrigger
                                value="input"
                                className="gap-2 flex-1 sm:flex-none rounded-lg text-sm px-4 py-2 font-bold uppercase tracking-wide text-slate-500 data-[state=active]:bg-blue-600 data-[state=active]:text-white dark:text-slate-400 dark:data-[state=active]:bg-blue-500"
                            >
                                <LayoutGrid className="h-3.5 w-3.5" /> Input Manual
                            </TabsTrigger>
                            <TabsTrigger
                                value="report"
                                className="gap-2 flex-1 sm:flex-none rounded-lg text-sm px-4 py-2 font-bold uppercase tracking-wide text-slate-500 data-[state=active]:bg-blue-600 data-[state=active]:text-white dark:text-slate-400 dark:data-[state=active]:bg-blue-500"
                            >
                                <TableIcon className="h-3.5 w-3.5" /> Lihat Laporan
                            </TabsTrigger>
                        </TabsList>
                    </div>

                    {/* Filters */}
                    <div className="flex flex-col gap-2 sm:flex-row sm:items-center px-5 py-3 border-b border-slate-100 bg-slate-50/80 dark:border-white/5 dark:bg-white/[0.02]">
                        <div className="relative flex-1 max-w-sm">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400 dark:text-slate-500 pointer-events-none" />
                            <Input
                                placeholder="Cari nama siswa..."
                                value={search}
                                onChange={(e) => { setSearch(e.target.value); setPage(0) }}
                                className="pl-9 rounded-xl h-9 text-sm dark:bg-white/5 dark:border-white/10 dark:text-white dark:placeholder:text-slate-600"
                            />
                        </div>
                        <Popover open={openClassFilter} onOpenChange={setOpenClassFilter}>
                            <PopoverTrigger asChild>
                                <Button
                                    variant="outline"
                                    role="combobox"
                                    className="w-full sm:w-44 justify-between h-9 text-sm rounded-xl dark:bg-white/5 dark:border-white/10 dark:text-slate-300 dark:hover:bg-white/10 dark:hover:text-white"
                                >
                                    {selectedClass}
                                    <ChevronsUpDown className="ml-2 h-3.5 w-3.5 shrink-0 opacity-40" />
                                </Button>
                            </PopoverTrigger>
                            <PopoverContent className="w-44 p-0 dark:bg-[#111b30] dark:border-white/10">
                                <Command className="dark:bg-transparent">
                                    <CommandInput placeholder="Cari kelas..." className="text-sm dark:text-white" />
                                    <CommandList>
                                        <CommandEmpty className="text-sm py-3 text-center text-slate-500">Tidak ditemukan.</CommandEmpty>
                                        <CommandGroup>
                                            {classes.map((c) => (
                                                <CommandItem
                                                    key={c}
                                                    value={c}
                                                    className="dark:text-slate-300 dark:hover:text-white"
                                                    onSelect={(val) => { setSelectedClass(val); setPage(0); setOpenClassFilter(false) }}
                                                >
                                                    <Check className={cn("mr-2 h-3.5 w-3.5 text-blue-600 dark:text-blue-400", selectedClass === c ? "opacity-100" : "opacity-0")} />
                                                    {c}
                                                </CommandItem>
                                            ))}
                                        </CommandGroup>
                                    </CommandList>
                                </Command>
                            </PopoverContent>
                        </Popover>
                    </div>

                    {/* INPUT TAB */}
                    <TabsContent value="input" className="mt-0">
                        {isLoading ? (
                            <div className="flex flex-col items-center justify-center py-24 gap-3">
                                <Loader2 className="h-6 w-6 animate-spin text-blue-500" />
                                <p className="text-sm text-slate-400">Memuat data siswa...</p>
                            </div>
                        ) : (
                            <div className="divide-y divide-slate-100 dark:divide-white/5">
                                {groupedStudents.map(([className, classStudents]) => {
                                    const stats = getClassStats(classStudents)
                                    return (
                                        <section key={className}>
                                            {/* Class header — subtle blue-tinted bg */}
                                            <div className="flex flex-wrap items-center justify-between gap-2 px-5 py-3 bg-blue-50/60 border-b border-blue-100/40 dark:bg-white/[0.03] dark:border-white/5">
                                                <div className="flex items-center gap-2.5">
                                                    {/* Left accent bar */}
                                                    <div className="h-4 w-[3px] rounded-full bg-blue-500" />
                                                    <h2 className="text-[11px] font-black uppercase tracking-widest text-blue-900 dark:text-slate-300">
                                                        {className}
                                                    </h2>
                                                    <span className="text-[10px] font-bold bg-blue-100 text-blue-700 border border-blue-200 px-2 py-0.5 rounded-full dark:bg-blue-500/15 dark:text-blue-400 dark:border-blue-500/30">
                                                        {classStudents.length} siswa
                                                    </span>
                                                </div>
                                                <div className="flex flex-wrap gap-1.5">
                                                    {Object.entries(stats).filter(([, n]) => n > 0).map(([status, count]) => (
                                                        <span key={status} className={cn('inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[10px] font-bold', STATUS_CONFIG[status]?.badge)}>
                                                            <span className={cn('h-1.5 w-1.5 rounded-full', STATUS_CONFIG[status]?.dot)} />
                                                            {count} {status}
                                                        </span>
                                                    ))}
                                                </div>
                                            </div>

                                            <div className="divide-y divide-slate-50 dark:divide-white/[0.03] px-2">
                                                {classStudents.map((student) => {
                                                    const record = initialAttendanceData[student.id] || { status: 'Alpa', student_id: student.id }
                                                    const isSaving = savingStudentId === student.id
                                                    const isSaved = savedStudentIds.has(student.id)
                                                    const cfg = STATUS_CONFIG[record.status] || STATUS_CONFIG['Alpa']
                                                    const checkIn = formatTime(record.check_in_time)

                                                    return (
                                                        <div
                                                            key={student.id}
                                                            className="flex items-center gap-3 py-3 px-3 rounded-xl hover:bg-blue-50/40 dark:hover:bg-white/[0.03] transition-colors"
                                                        >
                                                            {/* Avatar */}
                                                            <div className={cn(
                                                                'h-9 w-9 rounded-full shrink-0 flex items-center justify-center text-xs font-black ring-2 ring-white dark:ring-white/5',
                                                                !student.avatar_url && getAvatarColor(student.full_name)
                                                            )}>
                                                                {student.avatar_url
                                                                    ? <img src={student.avatar_url} className="h-full w-full object-cover rounded-full" alt="" />
                                                                    : getInitials(student.full_name)}
                                                            </div>

                                                            {/* Info */}
                                                            <div className="flex-1 min-w-0">
                                                                <div className="flex items-center gap-1.5">
                                                                    <p className="text-sm font-semibold text-slate-800 dark:text-white truncate">{student.full_name}</p>
                                                                    {isSaved && <Check size={13} className="text-emerald-500 dark:text-emerald-400 shrink-0" />}
                                                                    {record.is_from_app && (
                                                                        <span className="text-[10px] font-bold bg-sky-50 text-sky-600 border border-sky-200 px-1.5 py-0.5 rounded-full shrink-0 dark:bg-sky-500/15 dark:text-sky-400 dark:border-sky-500/30">
                                                                            App
                                                                        </span>
                                                                    )}
                                                                </div>
                                                                {student.company_name && (
                                                                    <p className="text-xs text-slate-400 truncate">{student.company_name}</p>
                                                                )}
                                                            </div>

                                                            {/* Check-in time */}
                                                            {checkIn && (
                                                                <span className="hidden sm:block text-xs bg-slate-100 text-slate-500 px-2 py-1 rounded-lg font-mono dark:bg-white/5 dark:border dark:border-white/10 dark:text-slate-400">
                                                                    {checkIn}
                                                                </span>
                                                            )}

                                                            {/* Status select */}
                                                            <Select
                                                                value={record.status}
                                                                onValueChange={(status) => updateStatusMutation.mutate({ studentId: student.id, status })}
                                                                disabled={isSaving}
                                                            >
                                                                <SelectTrigger className={cn('w-28 h-8 text-xs font-bold shadow-none rounded-lg', cfg.trigger)}>
                                                                    {isSaving
                                                                        ? <Loader2 className="h-3 w-3 animate-spin" />
                                                                        : <span className={cn('h-1.5 w-1.5 rounded-full', cfg.dot)} />}
                                                                    <SelectValue />
                                                                </SelectTrigger>
                                                                <SelectContent className="dark:bg-[#111b30] dark:border-white/10">
                                                                    {STATUS_OPTIONS.map(opt => (
                                                                        <SelectItem key={opt} value={opt} className="text-xs dark:text-slate-300 dark:focus:text-white dark:focus:bg-white/10">
                                                                            <div className="flex items-center gap-2">
                                                                                <span className={cn('h-1.5 w-1.5 rounded-full', STATUS_CONFIG[opt]?.dot)} />
                                                                                {opt}
                                                                            </div>
                                                                        </SelectItem>
                                                                    ))}
                                                                </SelectContent>
                                                            </Select>
                                                        </div>
                                                    )
                                                })}
                                            </div>
                                        </section>
                                    )
                                })}

                                {/* Pagination */}
                                <div className="flex items-center justify-between px-5 py-4 border-t border-slate-100 dark:border-white/5">
                                    <p className="text-xs text-slate-400 dark:text-slate-600">
                                        Menampilkan {students.length} dari {totalCount} siswa
                                    </p>
                                    <div className="flex items-center gap-2">
                                        <Button
                                            variant="outline"
                                            size="sm"
                                            onClick={() => setPage(p => p - 1)}
                                            disabled={page === 0}
                                            className="rounded-lg h-8 w-8 p-0 dark:bg-white/5 dark:border-white/10 dark:text-slate-400 dark:hover:bg-white/10 dark:hover:text-white"
                                        >
                                            <ChevronLeft className="h-4 w-4" />
                                        </Button>
                                        <span className="text-xs font-semibold text-slate-500 dark:text-slate-400 px-2">
                                            {page + 1} / {totalPages || 1}
                                        </span>
                                        <Button
                                            variant="outline"
                                            size="sm"
                                            onClick={() => setPage(p => p + 1)}
                                            disabled={page >= totalPages - 1}
                                            className="rounded-lg h-8 w-8 p-0 dark:bg-white/5 dark:border-white/10 dark:text-slate-400 dark:hover:bg-white/10 dark:hover:text-white"
                                        >
                                            <ChevronRight className="h-4 w-4" />
                                        </Button>
                                    </div>
                                </div>
                            </div>
                        )}
                    </TabsContent>

                    {/* REPORT TAB */}
                    <TabsContent value="report" className="mt-0 p-5">
                        <DataTable
                            columns={columns}
                            data={reportStudentsData?.students || []}
                            classList={classes.filter((c) => c !== 'Semua')}
                        />
                    </TabsContent>
                </Tabs>
            </div>
        </div>
    )
}