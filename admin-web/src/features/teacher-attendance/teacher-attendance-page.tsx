import { useState, useEffect, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { format } from 'date-fns'
import { id as localeId } from 'date-fns/locale'
import { supabase } from '@/lib/supabase'
import { toast } from 'sonner'
import {
    CalendarDays,
    Loader2,
    Search,
    Check,
    Users,
    UserCheck,
    UserX,
    Clock,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table'
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select'
import { Input } from '@/components/ui/input'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { useDebounce } from '@/hooks/use-debounce'

// ─── Types ────────────────────────────────────────────────────────────────────

interface Teacher {
    id: string
    full_name: string
    email: string
    avatar_url?: string
}

interface AttendanceRecord {
    id?: number
    teacher_id: string
    date: string
    status: 'Hadir' | 'Izin' | 'Sakit' | 'Alpha' | 'Cuti'
    notes?: string
}

type AttendanceStatus = AttendanceRecord['status']

// ─── Config ───────────────────────────────────────────────────────────────────

const STATUS_CONFIG: Record<
    AttendanceStatus,
    { dotClass: string; triggerClass: string }
> = {
    Hadir: {
        dotClass: 'bg-emerald-500',
        triggerClass:
            'bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/20',
    },
    Sakit: {
        dotClass: 'bg-amber-500',
        triggerClass:
            'bg-amber-50 text-amber-700 border-amber-200 hover:bg-amber-100 dark:bg-amber-500/10 dark:text-amber-400 dark:border-amber-500/20',
    },
    Izin: {
        dotClass: 'bg-sky-500',
        triggerClass:
            'bg-sky-50 text-sky-700 border-sky-200 hover:bg-sky-100 dark:bg-sky-500/10 dark:text-sky-400 dark:border-sky-500/20',
    },
    Alpha: {
        dotClass: 'bg-rose-500',
        triggerClass:
            'bg-rose-50 text-rose-700 border-rose-200 hover:bg-rose-100 dark:bg-rose-500/10 dark:text-rose-400 dark:border-rose-500/20',
    },
    Cuti: {
        dotClass: 'bg-violet-500',
        triggerClass:
            'bg-violet-50 text-violet-700 border-violet-200 hover:bg-violet-100 dark:bg-violet-500/10 dark:text-violet-400 dark:border-violet-500/20',
    },
}

const AVATAR_COLORS = [
    'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
    'bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300',
    'bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-300',
    'bg-cyan-100 text-cyan-700 dark:bg-cyan-900/30 dark:text-cyan-300',
    'bg-violet-100 text-violet-700 dark:bg-violet-900/30 dark:text-violet-300',
    'bg-teal-100 text-teal-700 dark:bg-teal-900/30 dark:text-teal-300',
]

// ─── Helpers ──────────────────────────────────────────────────────────────────

function getInitials(name: string) {
    return name.split(' ').map((n) => n[0]).join('').toUpperCase().substring(0, 2)
}

function getAvatarColor(name: string) {
    return AVATAR_COLORS[name.charCodeAt(0) % AVATAR_COLORS.length]
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

interface StatCardProps {
    label: string
    count: number
    total: number
    icon: React.ReactNode
    accentClass: string
    bgClass: string
    textClass: string
}

function StatCard({ label, count, total, icon, accentClass, bgClass, textClass }: StatCardProps) {
    const pct = total > 0 ? Math.round((count / total) * 100) : 0
    return (
        <div className="relative overflow-hidden rounded-2xl bg-white dark:bg-slate-900 border border-slate-100 dark:border-slate-800 shadow-sm p-5 transition-colors">
            <div className={cn('absolute top-0 left-0 right-0 h-1', accentClass)} />
            <div className="flex items-start justify-between">
                <div>
                    <p className="text-xs font-semibold uppercase tracking-widest text-slate-400 dark:text-slate-500 mb-1">
                        {label}
                    </p>
                    <p className={cn('text-4xl font-bold leading-none', textClass)}>{count}</p>
                    <p className="text-xs text-slate-400 dark:text-slate-500 mt-2">dari {total} guru</p>
                </div>
                <div className={cn('w-10 h-10 rounded-xl flex items-center justify-center shrink-0', bgClass)}>
                    {icon}
                </div>
            </div>
            <div className="mt-4 h-1 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                <div
                    className={cn('h-full rounded-full transition-all duration-500', accentClass)}
                    style={{ width: `${pct}%` }}
                />
            </div>
        </div>
    )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export function TeacherAttendancePage() {
    const [date, setDate] = useState<Date>(new Date())
    const [search, setSearch] = useState('')
    const [pendingNotes, setPendingNotes] = useState<Record<string, string>>({})
    const [savingTeacherId, setSavingTeacherId] = useState<string | null>(null)
    const [savedTeacherIds, setSavedTeacherIds] = useState<Set<string>>(new Set())
    const queryClient = useQueryClient()
    const dateStr = format(date, 'yyyy-MM-dd')

    const clearSavedIndicator = useCallback((teacherId: string) => {
        setTimeout(() => {
            setSavedTeacherIds((prev) => {
                const next = new Set(prev)
                next.delete(teacherId)
                return next
            })
        }, 1500)
    }, [])

    const { data: teachers = [], isLoading: isLoadingTeachers } = useQuery({
        queryKey: ['teachers'],
        queryFn: async () => {
            const { data, error } = await supabase
                .from('profiles')
                .select('*')
                .eq('role', 'teacher')
                .order('full_name')
            if (error) throw error
            return data as Teacher[]
        },
    })

    const { data: attendanceLogs = [], isLoading: isLoadingAttendance } = useQuery({
        queryKey: ['teacher_attendance', dateStr],
        queryFn: async () => {
            const { data, error } = await supabase
                .from('teacher_attendance_logs')
                .select('*')
                .eq('date', dateStr)
            if (error) throw error
            return data as AttendanceRecord[]
        },
    })

    const getAttendanceRecord = useCallback(
        (teacherId: string): AttendanceRecord => {
            return (
                attendanceLogs.find((log) => log.teacher_id === teacherId) ?? {
                    teacher_id: teacherId,
                    date: dateStr,
                    status: 'Alpha',
                    notes: ''
                }
            )
        },
        [attendanceLogs, dateStr]
    )

    const updateStatusMutation = useMutation({
        mutationFn: async ({
            teacherId,
            status,
        }: {
            teacherId: string
            status: AttendanceStatus
        }) => {
            setSavingTeacherId(teacherId)
            const currentRecord = getAttendanceRecord(teacherId)
            const noteToSave = pendingNotes[teacherId] !== undefined 
                ? pendingNotes[teacherId] 
                : (currentRecord.notes || '')

            const { error } = await supabase
                .from('teacher_attendance_logs')
                .upsert(
                    {
                        teacher_id: teacherId,
                        date: dateStr,
                        status: status,
                        notes: noteToSave || null,
                    },
                    { onConflict: 'teacher_id,date' }
                )
            if (error) throw error
        },
        onSuccess: (_data, { teacherId }) => {
            setSavedTeacherIds((prev) => new Set(prev).add(teacherId))
            clearSavedIndicator(teacherId)
            queryClient.invalidateQueries({ queryKey: ['teacher_attendance', dateStr] })
        },
        onError: () => {
            toast.error('Gagal menyimpan status')
        },
        onSettled: () => setSavingTeacherId(null),
    })

    const updateNotesMutation = useMutation({
        mutationFn: async ({
            teacherId,
            notes,
        }: {
            teacherId: string
            notes: string
        }) => {
            setSavingTeacherId(teacherId)
            const currentRecord = getAttendanceRecord(teacherId)
            const { error } = await supabase
                .from('teacher_attendance_logs')
                .upsert(
                    {
                        teacher_id: teacherId,
                        date: dateStr,
                        status: currentRecord.status,
                        notes: notes || null,
                    },
                    { onConflict: 'teacher_id,date' }
                )
            if (error) throw error
        },
        onSuccess: (_data, { teacherId }) => {
            setSavedTeacherIds((prev) => new Set(prev).add(teacherId))
            clearSavedIndicator(teacherId)
            queryClient.invalidateQueries({ queryKey: ['teacher_attendance', dateStr] })
        },
        onSettled: () => setSavingTeacherId(null),
    })

    const debouncedNotes = useDebounce(pendingNotes, 1000)

    useEffect(() => {
        Object.entries(debouncedNotes).forEach(([teacherId, notes]) => {
            const currentNotes = getAttendanceRecord(teacherId).notes || ''
            if (notes !== currentNotes) {
                updateNotesMutation.mutate({ teacherId, notes })
            }
        })
    }, [debouncedNotes, getAttendanceRecord, updateNotesMutation])

    // Reset notes and saved indicator when date changes
    // Membungkus setter dalam callback untuk menghindari error cascading renders
    useEffect(() => {
        const resetData = () => {
            setPendingNotes({})
            setSavedTeacherIds(new Set())
        }
        resetData()
    }, [dateStr])

    const filteredTeachers = teachers.filter((t) =>
        t.full_name.toLowerCase().includes(search.toLowerCase())
    )

    const countByStatus = (status: AttendanceStatus) =>
        teachers.filter((t) => getAttendanceRecord(t.id).status === status).length

    const isLoading = isLoadingTeachers || isLoadingAttendance

    return (
        <div className="min-h-screen bg-slate-50 dark:bg-slate-950 bg-linear-to-br from-slate-50 via-blue-50/30 to-indigo-50/20 dark:from-slate-950 dark:via-slate-900 dark:to-slate-950 transition-colors duration-300">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 py-8 space-y-8">
                
                {/* Header Section */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div className="flex items-center gap-4">
                        <div className="relative">
                            <div className="w-14 h-14 rounded-2xl bg-linear-to-br from-blue-500 to-blue-700 flex items-center justify-center shadow-lg shadow-blue-200 dark:shadow-none">
                                <Users className="w-7 h-7 text-white" />
                            </div>
                        </div>
                        <div>
                            <h1 className="text-2xl font-bold text-slate-800 dark:text-slate-100 tracking-tight">Absensi Guru</h1>
                            <p className="text-sm text-slate-500 dark:text-slate-400">Monitoring kehadiran harian pembimbing PKL.</p>
                        </div>
                    </div>

                    <div className="flex items-center gap-2 px-4 py-2 rounded-xl bg-white dark:bg-slate-900 border border-slate-100 dark:border-slate-800 shadow-sm transition-colors hover:border-blue-400">
                        <CalendarDays className="w-4 h-4 text-blue-500 shrink-0" />
                        <Input
                            type="date"
                            value={format(date, 'yyyy-MM-dd')}
                            onChange={(e) => setDate(new Date(e.target.value))}
                            className="border-0 p-0 h-auto text-sm font-medium bg-transparent dark:text-slate-100 focus-visible:ring-0 cursor-pointer"
                        />
                    </div>
                </div>

                {/* Stats Section */}
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                    <StatCard label="Hadir" count={countByStatus('Hadir')} total={teachers.length} icon={<UserCheck className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />} accentClass="bg-emerald-500" bgClass="bg-emerald-50 dark:bg-emerald-500/10" textClass="text-emerald-700 dark:text-emerald-400" />
                    <StatCard label="Sakit" count={countByStatus('Sakit')} total={teachers.length} icon={<Clock className="w-5 h-5 text-amber-600 dark:text-amber-400" />} accentClass="bg-amber-400" bgClass="bg-amber-50 dark:bg-amber-500/10" textClass="text-amber-700 dark:text-amber-400" />
                    <StatCard label="Izin" count={countByStatus('Izin')} total={teachers.length} icon={<CalendarDays className="w-5 h-5 text-sky-600 dark:text-sky-400" />} accentClass="bg-sky-500" bgClass="bg-sky-50 dark:bg-sky-500/10" textClass="text-sky-700 dark:text-sky-400" />
                    <StatCard label="Alpha" count={countByStatus('Alpha')} total={teachers.length} icon={<UserX className="w-5 h-5 text-rose-600 dark:text-rose-400" />} accentClass="bg-rose-500" bgClass="bg-rose-50 dark:bg-rose-500/10" textClass="text-rose-700 dark:text-rose-400" />
                </div>

                {/* Table Section */}
                <div className="rounded-2xl bg-white dark:bg-slate-900 border border-slate-100 dark:border-slate-800 shadow-sm overflow-hidden">
                    <div className="px-6 py-4 bg-linear-to-r from-blue-600 to-blue-700 dark:from-blue-700 dark:to-blue-900 flex flex-col sm:flex-row justify-between items-center gap-4">
                        <div className="flex items-center gap-2">
                            <h2 className="text-sm font-semibold text-white">Daftar Guru</h2>
                            <div className="px-2 py-0.5 rounded bg-white/20 text-white text-xs">
                                {format(date, 'dd MMM yyyy', { locale: localeId })}
                            </div>
                        </div>
                        <div className="flex items-center gap-2">
                            <div className="relative">
                                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-blue-200" />
                                <input
                                    type="text"
                                    placeholder="Cari guru..."
                                    value={search}
                                    onChange={(e) => setSearch(e.target.value)}
                                    className="pl-8 pr-3 py-1.5 rounded-lg bg-white/10 border border-white/20 text-white text-sm outline-none w-40 focus:bg-white/20 transition-all placeholder:text-blue-200"
                                />
                            </div>
                        </div>
                    </div>

                    <Table>
                        <TableHeader>
                            <TableRow className="bg-slate-50/50 dark:bg-slate-800/50 border-b dark:border-slate-800">
                                <TableHead className="pl-6 dark:text-slate-400 h-12">Nama Lengkap</TableHead>
                                <TableHead className="dark:text-slate-400 h-12">Status</TableHead>
                                <TableHead className="pr-6 dark:text-slate-400 h-12">Keterangan</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {isLoading ? (
                                <TableRow><TableCell colSpan={3} className="text-center py-20 dark:text-slate-500">
                                    <Loader2 className="w-6 h-6 animate-spin mx-auto mb-2 text-blue-500" />
                                    Memuat data absensi...
                                </TableCell></TableRow>
                            ) : filteredTeachers.length === 0 ? (
                                <TableRow><TableCell colSpan={3} className="text-center py-20 dark:text-slate-500">Guru tidak ditemukan.</TableCell></TableRow>
                            ) : filteredTeachers.map((teacher, idx) => {
                                const record = getAttendanceRecord(teacher.id)
                                const isSaving = savingTeacherId === teacher.id
                                const isSaved = savedTeacherIds.has(teacher.id)
                                const cfg = STATUS_CONFIG[record.status]

                                return (
                                    <TableRow key={teacher.id} className={cn(
                                        'border-b dark:border-slate-800 transition-colors',
                                        idx % 2 === 0 ? 'bg-white dark:bg-slate-900' : 'bg-slate-50/30 dark:bg-slate-800/20'
                                    )}>
                                        <TableCell className="pl-6 py-4">
                                            <div className="flex items-center gap-3">
                                                <Avatar className="w-10 h-10 border-2 border-white dark:border-slate-800 shadow-sm">
                                                    <AvatarImage src={teacher.avatar_url} />
                                                    <AvatarFallback className={cn("font-bold", getAvatarColor(teacher.full_name))}>
                                                        {getInitials(teacher.full_name)}
                                                    </AvatarFallback>
                                                </Avatar>
                                                <div className="flex flex-col">
                                                    <span className="text-sm font-bold dark:text-slate-100">{teacher.full_name}</span>
                                                    <span className="text-xs text-slate-400">{teacher.email}</span>
                                                </div>
                                            </div>
                                        </TableCell>
                                        <TableCell>
                                            <div className="flex items-center gap-2">
                                                <Select
                                                    value={record.status}
                                                    onValueChange={(val: AttendanceStatus) => updateStatusMutation.mutate({ teacherId: teacher.id, status: val })}
                                                    disabled={isSaving}
                                                >
                                                    <SelectTrigger className={cn('h-8 text-xs font-bold rounded-full w-32 shrink-0 border-0 shadow-sm transition-all', cfg.triggerClass)}>
                                                        <SelectValue />
                                                    </SelectTrigger>
                                                    <SelectContent className="dark:bg-slate-900 dark:border-slate-800">
                                                        {(Object.keys(STATUS_CONFIG) as AttendanceStatus[]).map((s) => (
                                                            <SelectItem key={s} value={s} className="text-xs font-medium dark:text-slate-100 cursor-pointer">{s}</SelectItem>
                                                        ))}
                                                    </SelectContent>
                                                </Select>
                                                {isSaving && <Loader2 className="w-4 h-4 animate-spin text-blue-500 shrink-0" />}
                                                {isSaved && <div className="w-4 h-4 bg-emerald-500 rounded-full flex items-center justify-center shrink-0"><Check className="w-2.5 h-2.5 text-white stroke-[4]" /></div>}
                                            </div>
                                        </TableCell>
                                        <TableCell className="pr-6">
                                            <Input
                                                placeholder="Tambahkan alasan atau catatan..."
                                                value={pendingNotes[teacher.id] ?? record.notes ?? ''}
                                                onChange={(e) => setPendingNotes(prev => ({ ...prev, [teacher.id]: e.target.value }))}
                                                className="h-9 text-xs dark:bg-slate-800/50 dark:border-slate-700 dark:text-slate-100 focus-visible:ring-blue-500/20"
                                            />
                                        </TableCell>
                                    </TableRow>
                                )
                            })}
                        </TableBody>
                    </Table>
                </div>
            </div>
        </div>
    )
}