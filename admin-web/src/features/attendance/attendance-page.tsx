import { useState, useMemo, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { format } from 'date-fns'
import { id as idLocale } from 'date-fns/locale'
import { toast } from 'sonner'
import {
    CalendarIcon, Loader2, Search, FileSpreadsheet, FileText,
    LayoutGrid, Table as TableIcon,
    Check, CheckCheck, ChevronsUpDown, ChevronLeft, ChevronRight
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

// 1. Perbaikan Interface: Tambahkan null agar kompatibel dengan DataTable
interface Student {
    id: string
    full_name: string
    class_name: string
    avatar_url?: string
    company_name: string | null 
    status: string
    check_in_time: string | null
    check_out_time: string |null
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

// Interface bantu untuk menghilangkan 'any' saat fetch
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
        badge: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/20 dark:text-emerald-400',
        trigger: 'bg-emerald-100 text-emerald-700 hover:bg-emerald-200 dark:bg-emerald-500/20 dark:text-emerald-400',
    },
    Terlambat: {
        dot: 'bg-amber-500',
        badge: 'bg-amber-100 text-amber-700 dark:bg-amber-500/20 dark:text-amber-400',
        trigger: 'bg-amber-100 text-amber-700 hover:bg-amber-200 dark:bg-amber-500/20 dark:text-amber-400',
    },
    Izin: {
        dot: 'bg-sky-500',
        badge: 'bg-sky-100 text-sky-700 dark:bg-sky-500/20 dark:text-sky-400',
        trigger: 'bg-sky-100 text-sky-700 hover:bg-sky-200 dark:bg-sky-500/20 dark:text-sky-400',
    },
    Sakit: {
        dot: 'bg-purple-500',
        badge: 'bg-purple-100 text-purple-700 dark:bg-purple-500/20 dark:text-purple-400',
        trigger: 'bg-purple-100 text-purple-700 hover:bg-purple-200 dark:bg-purple-500/20 dark:text-purple-400',
    },
    Alpa: {
        dot: 'bg-red-500',
        badge: 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400',
        trigger: 'bg-red-100 text-red-700 hover:bg-red-200 dark:bg-red-500/20 dark:text-red-400',
    },
}

const AVATAR_COLORS = [
    'bg-blue-100 text-blue-700 dark:bg-blue-500/20 dark:text-blue-300',
    'bg-indigo-100 text-indigo-700 dark:bg-indigo-500/20 dark:text-indigo-300',
    'bg-sky-100 text-sky-700 dark:bg-sky-500/20 dark:text-sky-300',
    'bg-violet-100 text-violet-700 dark:bg-violet-500/20 dark:text-violet-300',
    'bg-cyan-100 text-cyan-700 dark:bg-cyan-500/20 dark:text-cyan-300',
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
                const next = new Set(prev);
                next.delete(studentId);
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
                company_name: s.company_name ?? '-', // Pastikan string atau null
                status: s.attendance_status ?? 'Alpa', // KUNCINYA DISINI: Berikan default 'Alpa'
                check_in_time: s.check_in_time ?? undefined,
                check_out_time: s.check_out_time ?? undefined,
            })) as Student[],
            count: raw?.[0]?.total_count ?? 0
        }
    },
    enabled: viewMode === 'report'
})

    // 2. Gunakan useMemo untuk menstabilkan data students agar linter tidak merah
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
                if (idx !== -1) {
                    const n = [...old];
                    n[idx] = { ...n[idx], status };
                    return n
                }
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
        <div className="min-h-screen bg-slate-50 dark:bg-slate-950 -m-6 p-6 space-y-5">
            {/* ── Header ── */}
            <div className="relative overflow-hidden rounded-2xl bg-linear-to-br from-blue-600 via-blue-700 to-indigo-800 px-6 py-7 shadow-lg shadow-blue-500/25">
                <div className="relative flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-white/15 border border-white/20 px-3 py-1 mb-3">
                            <span className="h-1.5 w-1.5 rounded-full bg-blue-200 animate-pulse" />
                            <span className="text-xs font-medium text-blue-100">
                                {format(date, 'EEEE', { locale: idLocale })}
                            </span>
                        </span>
                        <h1 className="text-2xl font-bold text-white tracking-tight">Absensi Siswa</h1>
                        <p className="text-sm text-blue-200 mt-1">
                            {format(date, 'dd MMMM yyyy', { locale: idLocale })}
                        </p>
                    </div>

                    <div className="flex items-center gap-2 rounded-xl bg-white/15 backdrop-blur-sm border border-white/20 px-3.5 py-2 w-fit self-start">
                        <CalendarIcon className="h-4 w-4 text-blue-200 shrink-0" />
                        <Input
                            type="date"
                            value={format(date, 'yyyy-MM-dd')}
                            onChange={(e) => {
                                const d = new Date(e.target.value)
                                if (!isNaN(d.getTime())) setDate(d)
                            }}
                            className="w-36 text-sm border-0 shadow-none bg-transparent p-0 h-auto focus-visible:ring-0 text-white scheme-dark"
                        />
                    </div>
                </div>

                {viewMode === 'input' && students.length > 0 && !isLoading && (
                    <div className="relative mt-5 flex flex-wrap gap-2">
                        {STATUS_OPTIONS.map(status => {
                            const count = summaryStats[status] || 0
                            const statusColors: Record<string, string> = {
                                Hadir: 'bg-emerald-500/20 border-emerald-400/30 text-emerald-200',
                                Terlambat: 'bg-amber-500/20 border-amber-400/30 text-amber-200',
                                Izin: 'bg-sky-400/20 border-sky-400/30 text-sky-200',
                                Sakit: 'bg-purple-500/20 border-purple-400/30 text-purple-200',
                                Alpa: 'bg-red-500/20 border-red-400/30 text-red-200',
                            }
                            return (
                                <div
                                    key={status}
                                    className={cn(
                                        'flex items-center gap-2 rounded-lg border px-3 py-1.5',
                                        statusColors[status]
                                    )}
                                >
                                    <span className={cn('h-2 w-2 rounded-full shrink-0', STATUS_CONFIG[status].dot)} />
                                    <span className="text-sm font-bold">{count}</span>
                                    <span className="text-xs opacity-80">{status}</span>
                                </div>
                            )
                        })}
                    </div>
                )}
            </div>

            {/* ── Main Content ── */}
            <div className="rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
                <Tabs value={viewMode} onValueChange={(v) => setViewMode(v as 'input' | 'report')}>
                    <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between px-5 pt-4 pb-4 border-b border-slate-100 dark:border-slate-800">
                        <TabsList className="w-full sm:w-auto bg-blue-50 dark:bg-blue-950/40 p-1 rounded-xl h-auto border border-blue-100 dark:border-blue-900/60">
                            <TabsTrigger value="input" className="gap-2 flex-1 sm:flex-none rounded-lg text-sm px-4 py-2 font-medium data-[state=active]:bg-blue-600 data-[state=active]:text-white">
                                <LayoutGrid className="h-3.5 w-3.5" /> Input Manual
                            </TabsTrigger>
                            <TabsTrigger value="report" className="gap-2 flex-1 sm:flex-none rounded-lg text-sm px-4 py-2 font-medium data-[state=active]:bg-blue-600 data-[state=active]:text-white">
                                <TableIcon className="h-3.5 w-3.5" /> Lihat Laporan
                            </TabsTrigger>
                        </TabsList>

                        <div className="flex items-center gap-2">
                            {viewMode === 'report' && (
                                <>
                                    <Button variant="outline" size="sm" onClick={handleExportExcel} className="rounded-lg border-blue-200 text-blue-700 hover:bg-blue-50">
                                        <FileSpreadsheet className="mr-1.5 h-3.5 w-3.5" /> Excel
                                    </Button>
                                    <Button variant="outline" size="sm" onClick={handleExportPDF} className="rounded-lg border-blue-200 text-blue-700 hover:bg-blue-50">
                                        <FileText className="mr-1.5 h-3.5 w-3.5" /> PDF
                                    </Button>
                                </>
                            )}
                            {viewMode === 'input' && (
                                <Button size="sm" onClick={handleBulkPresent} disabled={isBulkUpdating || isLoading} className="rounded-lg bg-blue-600 hover:bg-blue-700 text-white">
                                    {isBulkUpdating ? <Loader2 className="mr-1.5 h-3.5 w-3.5 animate-spin" /> : <CheckCheck className="mr-1.5 h-3.5 w-3.5" />}
                                    Hadirkan Semua
                                </Button>
                            )}
                        </div>
                    </div>

                    <div className="flex flex-col gap-2 sm:flex-row sm:items-center px-5 py-3 bg-slate-50/80 dark:bg-slate-800/30 border-b border-slate-100">
                        <div className="relative flex-1 max-w-sm">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400 pointer-events-none" />
                            <Input
                                placeholder="Cari nama siswa..."
                                value={search}
                                onChange={(e) => { setSearch(e.target.value); setPage(0) }}
                                className="pl-9 rounded-lg h-9 text-sm"
                            />
                        </div>
                        <Popover open={openClassFilter} onOpenChange={setOpenClassFilter}>
                            <PopoverTrigger asChild>
                                <Button variant="outline" role="combobox" className="w-full sm:w-44 justify-between h-9 text-sm">
                                    {selectedClass}
                                    <ChevronsUpDown className="ml-2 h-3.5 w-3.5 shrink-0 opacity-40" />
                                </Button>
                            </PopoverTrigger>
                            <PopoverContent className="w-44 p-0">
                                <Command>
                                    <CommandInput placeholder="Cari kelas..." className="text-sm" />
                                    <CommandList>
                                        <CommandEmpty>Tidak ditemukan.</CommandEmpty>
                                        <CommandGroup>
                                            {classes.map((c) => (
                                                <CommandItem key={c} value={c} onSelect={(val) => {
                                                    setSelectedClass(val); setPage(0); setOpenClassFilter(false)
                                                }}>
                                                    <Check className={cn("mr-2 h-3.5 w-3.5 text-blue-600", selectedClass === c ? "opacity-100" : "opacity-0")} />
                                                    {c}
                                                </CommandItem>
                                            ))}
                                        </CommandGroup>
                                    </CommandList>
                                </Command>
                            </PopoverContent>
                        </Popover>
                    </div>

                    <TabsContent value="input" className="mt-0">
                        {isLoading ? (
                            <div className="flex flex-col items-center justify-center py-24 gap-3">
                                <Loader2 className="h-6 w-6 animate-spin text-blue-500" />
                                <p className="text-sm text-slate-400">Memuat data siswa...</p>
                            </div>
                        ) : (
                            <div className="divide-y divide-slate-100 dark:divide-slate-800">
                                {groupedStudents.map(([className, classStudents]) => {
                                    const stats = getClassStats(classStudents)
                                    return (
                                        <section key={className}>
                                            <div className="flex flex-wrap items-center justify-between gap-2 px-5 py-3 bg-blue-50/70 dark:bg-blue-950/20 border-b">
                                                <div className="flex items-center gap-2.5">
                                                    <div className="h-5 w-1 rounded-full bg-blue-500" />
                                                    <h2 className="text-[13px] font-semibold text-blue-900 dark:text-blue-300 uppercase">
                                                        {className}
                                                    </h2>
                                                    <span className="text-xs font-semibold bg-blue-100 px-2 py-0.5 rounded-full">
                                                        {classStudents.length} siswa
                                                    </span>
                                                </div>
                                                <div className="flex flex-wrap gap-1.5">
                                                    {Object.entries(stats).filter(([, n]) => n > 0).map(([status, count]) => (
                                                        <span key={status} className={cn('inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[11px] font-semibold', STATUS_CONFIG[status]?.badge)}>
                                                            <span className={cn('h-1.5 w-1.5 rounded-full', STATUS_CONFIG[status]?.dot)} />
                                                            {count} {status}
                                                        </span>
                                                    ))}
                                                </div>
                                            </div>

                                            <div className="divide-y divide-slate-50 dark:divide-slate-800/50 px-2">
                                                {classStudents.map((student) => {
                                                    const record = initialAttendanceData[student.id] || { status: 'Alpa', student_id: student.id }
                                                    const isSaving = savingStudentId === student.id
                                                    const isSaved = savedStudentIds.has(student.id)
                                                    const cfg = STATUS_CONFIG[record.status] || STATUS_CONFIG['Alpa']
                                                    const checkIn = formatTime(record.check_in_time)

                                                    return (
                                                        <div key={student.id} className="flex items-center gap-3 py-3 px-3 rounded-xl hover:bg-blue-50/50 transition-colors">
                                                            <div className={cn('h-9 w-9 rounded-full shrink-0 flex items-center justify-center text-xs font-bold ring-2 ring-white', !student.avatar_url && getAvatarColor(student.full_name))}>
                                                                {student.avatar_url ? <img src={student.avatar_url} className="h-full w-full object-cover rounded-full" alt="" /> : getInitials(student.full_name)}
                                                            </div>
                                                            <div className="flex-1 min-w-0">
                                                                <div className="flex items-center gap-1.5">
                                                                    <p className="text-sm font-semibold truncate">{student.full_name}</p>
                                                                    {isSaved && <Check size={13} className="text-emerald-500" />}
                                                                    {record.is_from_app && <span className="text-[10px] font-semibold bg-sky-100 text-sky-600 px-1.5 py-0.5 rounded-full">App</span>}
                                                                </div>
                                                                {student.company_name && <p className="text-xs text-slate-400 truncate">{student.company_name}</p>}
                                                            </div>
                                                            {checkIn && <span className="hidden sm:block text-xs bg-slate-100 px-2 py-1 rounded-md">{checkIn}</span>}
                                                            <Select value={record.status} onValueChange={(status) => updateStatusMutation.mutate({ studentId: student.id, status })} disabled={isSaving}>
                                                                <SelectTrigger className={cn('w-28 h-8 text-xs font-semibold border-0 shadow-none', cfg.trigger)}>
                                                                    {isSaving ? <Loader2 className="h-3 w-3 animate-spin" /> : <span className={cn('h-1.5 w-1.5 rounded-full', cfg.dot)} />}
                                                                    <SelectValue />
                                                                </SelectTrigger>
                                                                <SelectContent>
                                                                    {STATUS_OPTIONS.map(opt => (
                                                                        <SelectItem key={opt} value={opt} className="text-xs">
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
                                {/* Paginasi Input Manual */}
                                <div className="flex items-center justify-between px-5 py-4 border-t border-slate-100">
                                    <p className="text-xs text-slate-500">
                                        Menampilkan {students.length} dari {totalCount} siswa
                                    </p>
                                    <div className="flex items-center gap-2">
                                        <Button 
                                            variant="outline" 
                                            size="sm" 
                                            onClick={() => setPage(p => p - 1)} 
                                            disabled={page === 0}
                                            className="rounded-lg h-8 w-8 p-0"
                                        >
                                            <ChevronLeft className="h-4 w-4" />
                                        </Button>
                                        <span className="text-xs font-medium px-2">Halaman {page + 1} dari {totalPages || 1}</span>
                                        <Button 
                                            variant="outline" 
                                            size="sm" 
                                            onClick={() => setPage(p => p + 1)} 
                                            disabled={page >= totalPages - 1}
                                            className="rounded-lg h-8 w-8 p-0"
                                        >
                                            <ChevronRight className="h-4 w-4" />
                                        </Button>
                                    </div>
                                </div>
                            </div>
                        )}
                    </TabsContent>

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