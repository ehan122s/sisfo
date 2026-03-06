import { useState, useMemo, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { format } from 'date-fns'
import { id as idLocale } from 'date-fns/locale'
import { toast } from 'sonner'
import { Calendar as CalendarIcon, Loader2, Search, FileSpreadsheet, FileText, LayoutGrid, Table as TableIcon, ChevronLeft, ChevronRight, Check as CheckIcon, CheckCheck } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { getClassList } from '../reports/services/report-service'
import {
    Popover,
    PopoverContent,
    PopoverTrigger,
} from '@/components/ui/popover'
import {
    Command,
    CommandEmpty,
    CommandGroup,
    CommandInput,
    CommandItem,
    CommandList,
} from '@/components/ui/command'
import { Check, ChevronsUpDown } from 'lucide-react'
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select'
import { Input } from '@/components/ui/input'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { exportToExcel, exportToPDF } from '@/lib/export'
import { useDebounce } from '../../hooks/use-debounce'

// New imports for DataTable
import { columns } from './components/attendance-table/columns'
import { DataTable } from './components/attendance-table/data-table'

interface Student {
    id: string
    full_name: string
    class_name: string
    avatar_url?: string
    company_name?: string
}

interface AttendanceRecord {
    id?: number
    student_id: string
    status: string
    check_in_time?: string
    check_out_time?: string
    is_from_app?: boolean // To indicate if this came from mobile app
    created_at?: string
}

const STATUS_OPTIONS = ['Hadir', 'Terlambat', 'Izin', 'Sakit', 'Alpa']
// Limit increased for client-side pagination in report mode
const REPORT_FETCH_LIMIT = 1000 
const PAGE_SIZE = 45

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

    // Clear saved indicator after delay
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

    // Fetch Classes
    const { data: classes = [] } = useQuery({
        queryKey: ['classes'],
        queryFn: async () => {
            const uniqueClasses = await getClassList()
            return ['Semua', ...uniqueClasses]
        }
    })

    // Fetch Students with Pagination (for Input mode - no status filter)
    const { data: studentsData, isLoading: isLoadingStudents } = useQuery({
        queryKey: ['students-for-attendance', page, debouncedSearch, selectedClass],
        queryFn: async () => {
            let query = supabase
                .from('profiles')
                .select('id, full_name, class_name, avatar_url, placements(companies(name))', { count: 'exact' })
                .eq('role', 'student')
                .eq('status', 'active')
                .order('class_name')
                .order('full_name')

            if (selectedClass !== 'Semua') {
                query = query.eq('class_name', selectedClass)
            }

            if (debouncedSearch) {
                query = query.ilike('full_name', `%${debouncedSearch}%`)
            }

            const from = page * PAGE_SIZE
            const to = from + PAGE_SIZE - 1

            const { data, error, count } = await query.range(from, to)

            if (error) throw error

            const formattedStudents = (data || []).map((s: any) => ({
                id: s.id,
                full_name: s.full_name,
                class_name: s.class_name,
                avatar_url: s.avatar_url,
                company_name: s.placements?.[0]?.companies?.name,
            })) as Student[]

            return { students: formattedStudents, count: count || 0 }
        },
        enabled: viewMode === 'input'
    })

    // Fetch Students for Report mode (Fetch ALL for client-side table features)
    const { data: reportStudentsData, isLoading: isLoadingReportStudents } = useQuery({
        queryKey: ['students-for-report-all', dateStr], // Simplified key, fetch all for date
        queryFn: async () => {
            // We fetch all students for the date to enable client-side filtering/pagination
            const { data, error } = await supabase.rpc('get_students_by_attendance_status', {
                target_date: dateStr,
                status_filter: null, // Fetch all statuses
                class_filter: null,  // Fetch all classes (or maybe optimization: use selectedClass if known?)
                search_term: null,   // Fetch all names
                page_offset: 0,
                page_limit: REPORT_FETCH_LIMIT 
            })

            if (error) throw error

            const formattedStudents = (data || []).map((s: any) => ({
                id: s.id,
                full_name: s.full_name,
                class_name: s.class_name,
                avatar_url: s.avatar_url,
                company_name: s.company_name,
                status: s.attendance_status || 'Alpa', // Default to Alpa if null
                check_in_time: s.check_in_time,
                check_out_time: s.check_out_time,
            }))

            const totalCount = data?.[0]?.total_count ?? 0

            return { students: formattedStudents, count: totalCount }
        },
        enabled: viewMode === 'report'
    })

    // Choose the right data based on view mode
    const students = viewMode === 'input'
        ? (studentsData?.students || [])
        : (reportStudentsData?.students || [])
    const totalCount = viewMode === 'input'
        ? (studentsData?.count || 0)
        : (reportStudentsData?.count || 0)
    const totalPages = Math.ceil(totalCount / PAGE_SIZE)
    // const isLoadingCurrentStudents = viewMode === 'input' ? isLoadingStudents : isLoadingReportStudents

    // Define active query key based on current filter to ensure consistency across mutations
    const activeQueryKey = ['attendance_logs', dateStr, students.map((s: Student) => s.id).join(',')]

    // Fetch Attendance for selected date
    const { data: attendanceLogs = [], isLoading: isLoadingAttendance } = useQuery({
        queryKey: activeQueryKey,
        enabled: students.length > 0,
        queryFn: async () => {
            const startOfDay = `${dateStr}T00:00:00`
            const endOfDay = `${dateStr}T23:59:59`

            const studentIds = students.map((s: Student) => s.id)

            if (studentIds.length === 0) return []

            if (studentIds.length < 200) {
                const { data, error } = await supabase
                    .from('attendance_logs')
                    .select('*')
                    .in('student_id', studentIds)
                    .gte('created_at', startOfDay)
                    .lte('created_at', endOfDay)

                if (error) throw error
                return data as AttendanceRecord[]
            } else {
                const { data, error } = await supabase
                    .from('attendance_logs')
                    .select('*')
                    .gte('created_at', startOfDay)
                    .lte('created_at', endOfDay)
                    .range(0, 4999)

                if (error) throw error
                return data as AttendanceRecord[]
            }
        },
    })

    // Compute initial attendance data from fetched logs using useMemo
    const initialAttendanceData = useMemo(() => {
        const mapping: Record<string, AttendanceRecord> = {}
        students.forEach((student: Student) => {
            const existing = attendanceLogs.find(log => log.student_id === student.id)
            if (existing) {
                mapping[student.id] = {
                    ...existing,
                    is_from_app: existing.check_in_time ? true : false
                }
            } else {
                mapping[student.id] = {
                    student_id: student.id,
                    status: 'Alpa',
                    is_from_app: false
                }
            }
        })
        return mapping
    }, [students, attendanceLogs])

    // -- OPTIMISTIC UPDATE MUTATION --
    const updateStatusMutation = useMutation({
        mutationFn: async ({ studentId, status }: { studentId: string, status: string }) => {
            setSavingStudentId(studentId)
            const existingLog = attendanceLogs.find(l => l.student_id === studentId)

            if (existingLog?.id && existingLog.id > 0) {
                const { data, error } = await supabase
                    .from('attendance_logs')
                    .update({ status: status })
                    .eq('id', existingLog.id)
                    .select()
                    .single()

                if (error) throw error
                return data
            } else {
                const { data, error } = await supabase
                    .from('attendance_logs')
                    .insert({
                        student_id: studentId,
                        status: status,
                        created_at: `${dateStr}T12:00:00`
                    })
                    .select()
                    .single()

                if (error) throw error
                return data
            }
        },
        onMutate: async ({ studentId, status }) => {
            await queryClient.cancelQueries({ queryKey: activeQueryKey })
            const previousLogs = queryClient.getQueryData<AttendanceRecord[]>(activeQueryKey)
            queryClient.setQueryData<AttendanceRecord[]>(activeQueryKey, (old = []) => {
                const existingIndex = old.findIndex(l => l.student_id === studentId)
                if (existingIndex !== -1) {
                    const newLogs = [...old]
                    newLogs[existingIndex] = { ...newLogs[existingIndex], status }
                    return newLogs
                } else {
                    return [...old, {
                        student_id: studentId,
                        status,
                        created_at: `${dateStr}T12:00:00`,
                        id: -Date.now()
                    }]
                }
            })
            return { previousLogs }
        },
        onError: (_err, { studentId: _studentId }, context) => {
            if (context?.previousLogs) {
                queryClient.setQueryData(activeQueryKey, context.previousLogs)
            }
            setSavingStudentId(null)
            toast.error("Gagal menyimpan perubahan")
        },
        onSuccess: (data, { studentId }) => {
            if (data) {
                queryClient.setQueryData<AttendanceRecord[]>(activeQueryKey, (old = []) => {
                    const existingIndex = old.findIndex(l => l.student_id === studentId)
                    if (existingIndex !== -1) {
                        const newLogs = [...old]
                        newLogs[existingIndex] = { ...data, is_from_app: !!data.check_in_time }
                        return newLogs
                    }
                    return [...old, { ...data, is_from_app: !!data.check_in_time }]
                })
            }
            setSavedStudentIds(prev => new Set(prev).add(studentId))
            clearSavedIndicator(studentId)
        },
        onSettled: () => {
            setSavingStudentId(null)
        },
    })

    const getInitials = (name: string) => {
        return name
            .split(' ')
            .map((n) => n[0])
            .join('')
            .toUpperCase()
            .substring(0, 2)
    }

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'Hadir': return 'bg-green-50 text-green-700 border-green-200'
            case 'Terlambat': return 'bg-yellow-50 text-yellow-700 border-yellow-200'
            case 'Izin': return 'bg-blue-50 text-blue-700 border-blue-200'
            case 'Sakit': return 'bg-purple-50 text-purple-700 border-purple-200'
            case 'Alpa': return 'bg-red-50 text-red-700 border-red-200'
            default: return 'bg-gray-50 text-gray-700 border-gray-200'
        }
    }

    const formatTime = (time?: string) => {
        if (!time) return '-'
        return new Date(time).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
    }

    const handleExportExcel = () => {
        toast.info("Sedang menyiapkan data untuk export semua halaman...")
        const fetchAllForExport = async () => {
            let query = supabase
                .from('profiles')
                .select('id, full_name, class_name, placements(companies(name))')
                .eq('role', 'student')
                .eq('status', 'active')
                .order('class_name')
                .order('full_name')

            if (selectedClass !== 'Semua') {
                query = query.eq('class_name', selectedClass)
            }
            if (search) {
                query = query.ilike('full_name', `%${search}%`)
            }

            const { data: allStudents } = await query

            if (!allStudents) return

            const headers = ['Nama', 'Kelas', 'DUDI', 'Status', 'Check In', 'Check Out']
            const rows = allStudents.map((s: any) => {
                const log = attendanceLogs.find(l => l.student_id === s.id)
                const status = log?.status || 'Alpha'

                return [
                    s.full_name,
                    s.class_name || '-',
                    s.placements?.[0]?.companies?.name || '-',
                    status,
                    formatTime(log?.check_in_time),
                    formatTime(log?.check_out_time),
                ]
            })
            exportToExcel({ headers, rows, filename: `absensi_${dateStr}` })
        }
        fetchAllForExport()
    }

    const handleExportPDF = () => {
        toast.info("Sedang menyiapkan data untuk export semua halaman...")
        const fetchAllForExport = async () => {
            let query = supabase
                .from('profiles')
                .select('id, full_name, class_name, placements(companies(name))')
                .eq('role', 'student')
                .eq('status', 'active')
                .order('class_name')
                .order('full_name')

            if (selectedClass !== 'Semua') {
                query = query.eq('class_name', selectedClass)
            }
            if (search) {
                query = query.ilike('full_name', `%${search}%`)
            }

            const { data: allStudents } = await query

            if (!allStudents) return

            const headers = ['Nama', 'Kelas', 'DUDI', 'Status', 'Check In', 'Check Out']
            const rows = allStudents.map((s: any) => {
                const log = attendanceLogs.find(l => l.student_id === s.id)
                const status = log?.status || 'Alpha'

                return [
                    s.full_name,
                    s.class_name || '-',
                    s.placements?.[0]?.companies?.name || '-',
                    status,
                    formatTime(log?.check_in_time),
                    formatTime(log?.check_out_time),
                ]
            })
            exportToPDF({
                headers,
                rows,
                filename: `absensi_${dateStr}`,
                title: `Laporan Absensi - ${format(date, 'dd MMMM yyyy', { locale: idLocale })}`
            })
        }
        fetchAllForExport()
    }

    // -- BULK PRESENT MUTATION --
    const handleBulkPresent = async () => {
        setIsBulkUpdating(true)
        toast.info('Memproses hadirkan semua...')

        try {
            let query = supabase
                .from('profiles')
                .select('id')
                .eq('role', 'student')
                .eq('status', 'active')

            if (selectedClass !== 'Semua') {
                query = query.eq('class_name', selectedClass)
            }

            const { data: allStudents, error: studentsError } = await query
            if (studentsError) throw studentsError

            if (!allStudents || allStudents.length === 0) {
                toast.warning('Tidak ada siswa untuk dihadirkan')
                setIsBulkUpdating(false)
                return
            }

            const studentIds = allStudents.map(s => s.id)

            const { data: currentLogs, error: logsError } = await supabase
                .from('attendance_logs')
                .select('*')
                .in('student_id', studentIds)
                .gte('created_at', `${dateStr}T00:00:00`)
                .lte('created_at', `${dateStr}T23:59:59`)

            if (logsError) throw logsError

            const logsMap = new Map<string, AttendanceRecord>()
            currentLogs?.forEach(log => logsMap.set(log.student_id, log))

            const studentsToUpdate: { student_id: string; existingLog?: AttendanceRecord }[] = []

            for (const student of allStudents) {
                const existingLog = logsMap.get(student.id)
                if (existingLog?.check_in_time) continue
                studentsToUpdate.push({ student_id: student.id, existingLog })
            }

            if (studentsToUpdate.length === 0) {
                toast.info('Semua siswa sudah diabsen via aplikasi')
                setIsBulkUpdating(false)
                return
            }

            const previousLogs = queryClient.getQueryData<AttendanceRecord[]>(['attendance_logs', dateStr]) || []
            const optimisticLogs = [...previousLogs]
            for (const { student_id } of studentsToUpdate) {
                const existingIndex = optimisticLogs.findIndex(l => l.student_id === student_id)
                if (existingIndex >= 0) {
                    optimisticLogs[existingIndex] = { ...optimisticLogs[existingIndex], status: 'Hadir' }
                } else {
                    optimisticLogs.push({
                        student_id: student_id,
                        status: 'Hadir',
                        created_at: `${dateStr}T12:00:00`,
                        id: -Date.now() - Math.random()
                    })
                }
            }
            queryClient.setQueryData(['attendance_logs', dateStr], optimisticLogs)

            const recordsToInsert: any[] = []
            const recordsToUpdate: { id: number; status: string }[] = []

            for (const { student_id, existingLog } of studentsToUpdate) {
                if (existingLog?.id && existingLog.id > 0) {
                    recordsToUpdate.push({ id: existingLog.id, status: 'Hadir' })
                } else {
                    recordsToInsert.push({
                        student_id: student_id,
                        status: 'Hadir',
                        created_at: `${dateStr}T12:00:00`
                    })
                }
            }

            if (recordsToInsert.length > 0) {
                const { error: insertError } = await supabase
                    .from('attendance_logs')
                    .insert(recordsToInsert)
                    .select()

                if (insertError) {
                    queryClient.setQueryData(['attendance_logs', dateStr], previousLogs)
                    throw insertError
                }
            }

            if (recordsToUpdate.length > 0) {
                const updatePromises = recordsToUpdate.map(record =>
                    supabase
                        .from('attendance_logs')
                        .update({ status: 'Hadir' })
                        .eq('id', record.id)
                )
                await Promise.all(updatePromises)
            }

            await queryClient.invalidateQueries({ queryKey: ['attendance_logs'] })

            const skippedCount = allStudents.length - studentsToUpdate.length
            toast.success(
                `Berhasil menghadirkan ${studentsToUpdate.length} siswa` +
                (skippedCount > 0 ? `, ${skippedCount} siswa sudah diabsen via app` : '')
            )
        } catch (error) {
            console.error('Bulk present error:', error)
            toast.error('Gagal menghadirkan semua siswa')
            await queryClient.invalidateQueries({ queryKey: ['attendance_logs'] })
        } finally {
            setIsBulkUpdating(false)
        }
    }

    return (
        <div className="space-y-4 sm:space-y-6">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">Absensi Siswa</h1>
                <div className="flex items-center gap-2">
                    <CalendarIcon className="h-4 w-4 text-muted-foreground" />
                    <Input
                        type="date"
                        value={format(date, 'yyyy-MM-dd')}
                        onChange={(e) => {
                            const newDate = new Date(e.target.value)
                            if (!isNaN(newDate.getTime())) {
                                setDate(newDate)
                            }
                        }}
                        className="w-40"
                    />
                </div>
            </div>

            <Tabs value={viewMode} onValueChange={(v) => setViewMode(v as 'input' | 'report')}>
                <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                    <TabsList className="grid w-full sm:w-auto grid-cols-2">
                        <TabsTrigger value="input" className="gap-2">
                            <LayoutGrid className="h-4 w-4" />
                            <span className="hidden sm:inline">Input Manual</span>
                            <span className="sm:hidden">Input</span>
                        </TabsTrigger>
                        <TabsTrigger value="report" className="gap-2">
                            <TableIcon className="h-4 w-4" />
                            <span className="hidden sm:inline">Lihat Laporan</span>
                            <span className="sm:hidden">Laporan</span>
                        </TabsTrigger>
                    </TabsList>

                    {viewMode === 'report' && (
                        <div className="flex gap-2">
                            <Button variant="outline" size="sm" onClick={handleExportExcel}>
                                <FileSpreadsheet className="mr-2 h-4 w-4" />
                                Excel
                            </Button>
                            <Button variant="outline" size="sm" onClick={handleExportPDF}>
                                <FileText className="mr-2 h-4 w-4" />
                                PDF
                            </Button>
                        </div>
                    )}

                    {viewMode === 'input' && (
                        <Button
                            onClick={handleBulkPresent}
                            disabled={isBulkUpdating || isLoadingStudents || isLoadingAttendance}
                        >
                            {isBulkUpdating ? (
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            ) : (
                                <CheckCheck className="mr-2 h-4 w-4" />
                            )}
                            <span className="hidden sm:inline">Hadirkan Semua</span>
                            <span className="sm:hidden">Hadir Semua</span>
                        </Button>
                    )}
                </div>

                <div className="flex flex-col gap-3 sm:flex-row sm:items-center mt-4">
                    <div className="relative flex-1 max-w-sm">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <Input
                            placeholder="Cari nama siswa..."
                            value={search}
                            onChange={(e) => {
                                setSearch(e.target.value)
                                setPage(0)
                            }}
                            className="pl-9"
                        />
                    </div>
                    <div className="w-full sm:w-[150px]">
                        <Popover open={openClassFilter} onOpenChange={setOpenClassFilter}>
                            <PopoverTrigger asChild>
                                <Button
                                    variant="outline"
                                    role="combobox"
                                    aria-expanded={openClassFilter}
                                    className="w-full justify-between"
                                >
                                    {selectedClass}
                                    <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                                </Button>
                            </PopoverTrigger>
                            <PopoverContent className="w-[150px] p-0">
                                <Command>
                                    <CommandInput placeholder="Cari kelas..." />
                                    <CommandList>
                                        <CommandEmpty>Kelas tidak ditemukan.</CommandEmpty>
                                        <CommandGroup>
                                            {classes.map((c: string) => (
                                                <CommandItem
                                                    key={c}
                                                    value={c}
                                                    onSelect={(currentValue) => {
                                                        const originalValue = classes.find((item: string) => item.toLowerCase() === currentValue.toLowerCase()) || currentValue
                                                        setSelectedClass(originalValue)
                                                        setPage(0)
                                                        setOpenClassFilter(false)
                                                    }}
                                                >
                                                    <Check
                                                        className={cn(
                                                            "mr-2 h-4 w-4",
                                                            selectedClass === c ? "opacity-100" : "opacity-0"
                                                        )}
                                                    />
                                                    {c}
                                                </CommandItem>
                                            ))}
                                        </CommandGroup>
                                    </CommandList>
                                </Command>
                            </PopoverContent>
                        </Popover>
                    </div>
                </div>

                <TabsContent value="input" className="mt-4">
                    {isLoadingStudents || isLoadingAttendance ? (
                        <div className="flex justify-center p-8">
                            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                        </div>
                    ) : students.length === 0 ? (
                        <div className="text-center py-8 text-muted-foreground">
                            Tidak ada siswa ditemukan
                        </div>
                    ) : (
                        <div className="space-y-4">
                            <div className="grid gap-3 sm:gap-4">
                                {students.map((student: Student) => {
                                    const record = initialAttendanceData[student.id] || { status: 'Alpa', student_id: student.id }
                                    return (
                                        <Card key={student.id} className="overflow-hidden">
                                            <CardContent className="p-3 sm:p-4">
                                                <div className="flex items-center gap-3">
                                                    <Avatar className="h-10 w-10 sm:h-12 sm:w-12 shrink-0">
                                                        <AvatarImage src={student.avatar_url} />
                                                        <AvatarFallback className="text-xs sm:text-sm">{getInitials(student.full_name)}</AvatarFallback>
                                                    </Avatar>

                                                    <div className="flex-1 min-w-0">
                                                        <div className="flex items-center gap-2 flex-wrap">
                                                            <p className="font-medium text-sm sm:text-base truncate">{student.full_name}</p>
                                                            {record.is_from_app && (
                                                                <Badge variant="outline" className="text-xs bg-blue-50 text-blue-600 border-blue-200">
                                                                    App
                                                                </Badge>
                                                            )}
                                                        </div>
                                                        <div className="flex items-center gap-2 text-xs sm:text-sm text-muted-foreground">
                                                            <span>{student.class_name}</span>
                                                            {student.company_name && (
                                                                <>
                                                                    <span>•</span>
                                                                    <span className="truncate">{student.company_name}</span>
                                                                </>
                                                            )}
                                                        </div>
                                                        {record.check_in_time && (
                                                            <div className="text-xs text-muted-foreground mt-1">
                                                                Masuk: {formatTime(record.check_in_time)}
                                                                {record.check_out_time && ` • Pulang: ${formatTime(record.check_out_time)}`}
                                                            </div>
                                                        )}
                                                    </div>

                                                    <div className="flex items-center gap-2">
                                                        <Select
                                                            value={record.status}
                                                            onValueChange={(val) => updateStatusMutation.mutate({ studentId: student.id, status: val })}
                                                            disabled={savingStudentId === student.id}
                                                        >
                                                            <SelectTrigger className={cn(
                                                                "w-[100px] sm:w-[120px] shrink-0 text-xs sm:text-sm font-medium transition-all",
                                                                getStatusColor(record.status),
                                                                savingStudentId === student.id && "opacity-70"
                                                            )}>
                                                                <SelectValue />
                                                            </SelectTrigger>
                                                            <SelectContent>
                                                                {STATUS_OPTIONS.map((s) => (
                                                                    <SelectItem key={s} value={s}>{s}</SelectItem>
                                                                ))}
                                                            </SelectContent>
                                                        </Select>

                                                        {savingStudentId === student.id && (
                                                            <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
                                                        )}

                                                        {savedStudentIds.has(student.id) && savingStudentId !== student.id && (
                                                            <div className="flex items-center gap-1 text-green-600 animate-in fade-in duration-200">
                                                                <CheckIcon className="h-4 w-4" />
                                                                <span className="text-xs hidden sm:inline">Tersimpan</span>
                                                            </div>
                                                        )}
                                                    </div>
                                                </div>
                                            </CardContent>
                                        </Card>
                                    )
                                })}
                            </div>

                            <div className="flex items-center justify-between py-4">
                                <span className="text-sm text-muted-foreground">
                                    Halaman {page + 1} dari {totalPages}
                                </span>
                                <div className="space-x-2">
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={() => setPage(p => Math.max(0, p - 1))}
                                        disabled={page === 0}
                                    >
                                        <ChevronLeft className="h-4 w-4" />
                                        Previous
                                    </Button>
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={() => setPage(p => Math.min(totalPages - 1, p + 1))}
                                        disabled={page >= totalPages - 1}
                                    >
                                        Next
                                        <ChevronRight className="h-4 w-4" />
                                    </Button>
                                </div>
                            </div>
                        </div>
                    )}
                </TabsContent>

                <TabsContent value="report" className="mt-4">
                    <Card>
                        <CardContent className="p-0 sm:p-6">
                            {isLoadingReportStudents ? (
                                <div className="flex justify-center p-8">
                                    <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                                </div>
                            ) : (
                                <DataTable 
                                    columns={columns} 
                                    data={reportStudentsData?.students || []} 
                                    classList={classes.filter((c: string) => c !== 'Semua')}
                                />
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>
            </Tabs>
        </div>
    )
}
