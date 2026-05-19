import { useState, useEffect, useCallback, useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { format } from 'date-fns'
import { id as localeId } from 'date-fns/locale'
import { supabase } from '@/lib/supabase'
import { toast } from 'sonner'
import {
    CalendarIcon,
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
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select'
import { Input } from '@/components/ui/input'
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

const STATUS_OPTIONS: AttendanceStatus[] = ['Hadir', 'Izin', 'Sakit', 'Alpha', 'Cuti']

const STATUS_CONFIG: Record<AttendanceStatus, { dot: string; badge: string; trigger: string }> = {
    Hadir: {
        dot: 'bg-emerald-500',
        badge: 'bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-500/15 dark:text-emerald-400 dark:border-emerald-500/30',
        trigger: 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200 dark:bg-emerald-500/15 dark:text-emerald-400 dark:hover:bg-emerald-500/25 dark:border-emerald-500/30',
    },
    Sakit: {
        dot: 'bg-amber-500',
        badge: 'bg-amber-50 text-amber-700 border border-amber-200 dark:bg-amber-500/15 dark:text-amber-400 dark:border-amber-500/30',
        trigger: 'bg-amber-50 text-amber-700 hover:bg-amber-100 border border-amber-200 dark:bg-amber-500/15 dark:text-amber-400 dark:hover:bg-amber-500/25 dark:border-amber-500/30',
    },
    Izin: {
        dot: 'bg-sky-500',
        badge: 'bg-sky-50 text-sky-700 border border-sky-200 dark:bg-sky-500/15 dark:text-sky-400 dark:border-sky-500/30',
        trigger: 'bg-sky-50 text-sky-700 hover:bg-sky-100 border border-sky-200 dark:bg-sky-500/15 dark:text-sky-400 dark:hover:bg-sky-500/25 dark:border-sky-500/30',
    },
    Alpha: {
        dot: 'bg-red-500',
        badge: 'bg-red-50 text-red-700 border border-red-200 dark:bg-red-500/15 dark:text-red-400 dark:border-red-500/30',
        trigger: 'bg-red-50 text-red-700 hover:bg-red-100 border border-red-200 dark:bg-red-500/15 dark:text-red-400 dark:hover:bg-emerald-500/25 dark:border-red-500/30',
    },
    Cuti: {
        dot: 'bg-violet-500',
        badge: 'bg-violet-50 text-violet-700 border border-violet-200 dark:bg-violet-500/15 dark:text-violet-400 dark:border-violet-500/30',
        trigger: 'bg-violet-50 text-violet-700 hover:bg-violet-100 border border-violet-200 dark:bg-violet-500/15 dark:text-violet-400 dark:hover:bg-violet-500/25 dark:border-violet-500/30',
    },
}

const AVATAR_COLORS = [
    'bg-blue-100 text-blue-700 dark:bg-blue-500/20 dark:text-blue-300',
    'bg-indigo-100 text-indigo-700 dark:bg-indigo-500/20 dark:text-indigo-300',
    'bg-sky-100 text-sky-700 dark:bg-sky-500/20 dark:text-sky-300',
    'bg-violet-100 text-violet-700 dark:bg-violet-500/20 dark:text-violet-300',
    'bg-cyan-100 text-cyan-700 dark:bg-cyan-500/20 dark:text-cyan-300',
]

const STAT_CARDS = [
    {
        key: 'Hadir' as AttendanceStatus,
        label: 'HADIR',
        icon: UserCheck,
        accent: 'border-t-emerald-500',
        iconBg: 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400',
        numColor: 'text-emerald-600 dark:text-emerald-400',
        bar: 'bg-emerald-500',
        barBg: 'bg-emerald-100 dark:bg-emerald-500/10',
    },
    {
        key: 'Sakit' as AttendanceStatus,
        label: 'SAKIT',
        icon: Clock,
        accent: 'border-t-amber-500',
        iconBg: 'bg-amber-50 text-amber-600 dark:bg-amber-500/15 dark:text-amber-400',
        numColor: 'text-amber-600 dark:text-amber-400',
        bar: 'bg-amber-500',
        barBg: 'bg-amber-100 dark:bg-amber-500/10',
    },
    {
        key: 'Izin' as AttendanceStatus,
        label: 'IZIN',
        icon: Users,
        accent: 'border-t-sky-500',
        iconBg: 'bg-sky-50 text-sky-600 dark:bg-sky-500/15 dark:text-sky-400',
        numColor: 'text-sky-600 dark:text-sky-400',
        bar: 'bg-sky-500',
        barBg: 'bg-sky-100 dark:bg-sky-500/10',
    },
    {
        key: 'Alpha' as AttendanceStatus,
        label: 'ALPHA',
        icon: UserX,
        accent: 'border-t-red-500',
        iconBg: 'bg-red-50 text-red-600 dark:bg-red-500/15 dark:text-red-400',
        numColor: 'text-red-600 dark:text-red-400',
        bar: 'bg-red-500',
        barBg: 'bg-red-100 dark:bg-red-500/10',
    },
    {
        key: 'Cuti' as AttendanceStatus,
        label: 'CUTI',
        icon: UserX,
        accent: 'border-t-violet-500',
        iconBg: 'bg-violet-50 text-violet-600 dark:bg-violet-500/15 dark:text-violet-400',
        numColor: 'text-violet-600 dark:text-violet-400',
        bar: 'bg-violet-500',
        barBg: 'bg-violet-100 dark:bg-violet-500/10',
    },
]

// ─── Helpers ──────────────────────────────────────────────────────────────────

function getInitials(name: string) {
    return name.split(' ').map((n) => n[0]).join('').toUpperCase().substring(0, 2)
}

function getAvatarColor(name: string) {
    return AVATAR_COLORS[name.charCodeAt(0) % AVATAR_COLORS.length]
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export function TeacherAttendancePage() {
    const [date, setDate] = useState<Date>(new Date())
    const [search, setSearch] = useState('')
    const [pendingNotes, setPendingNotes] = useState<Record<string, string>>({})
    const [savingTeacherId, setSavingTeacherId] = useState<string | null>(null)
    const [savedTeacherIds, setSavedTeacherIds] = useState<Set<string>>(new Set())
    
    // Perbaikan ESLint: Menyimpan track tanggal sebelumnya untuk mendeteksi perubahan saat render
    const [prevDateStr, setPrevDateStr] = useState<string>(format(date, 'yyyy-MM-dd'))
    
    const queryClient = useQueryClient()
    const dateStr = format(date, 'yyyy-MM-dd')

    // Lakukan reset secara langsung saat proses render (Pattern resmi dari tim React untuk menggantikan useEffect sync)
    if (dateStr !== prevDateStr) {
        setPrevDateStr(dateStr)
        setPendingNotes({})
        setSavedTeacherIds(new Set())
    }

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
                    notes: '',
                }
            )
        },
        [attendanceLogs, dateStr]
    )

    const updateStatusMutation = useMutation({
        mutationFn: async ({ teacherId, status }: { teacherId: string; status: AttendanceStatus }) => {
            setSavingTeacherId(teacherId)
            const currentRecord = getAttendanceRecord(teacherId)
            const noteToSave =
                pendingNotes[teacherId] !== undefined
                    ? pendingNotes[teacherId]
                    : currentRecord.notes || ''
            const { error } = await supabase
                .from('teacher_attendance_logs')
                .upsert(
                    { teacher_id: teacherId, date: dateStr, status, notes: noteToSave || null },
                    { onConflict: 'teacher_id,date' }
                )
            if (error) throw error
        },
        onSuccess: (_data, { teacherId }) => {
            setSavedTeacherIds((prev) => new Set(prev).add(teacherId))
            clearSavedIndicator(teacherId)
            queryClient.invalidateQueries({ queryKey: ['teacher_attendance', dateStr] })
        },
        onError: () => toast.error('Gagal menyimpan status'),
        onSettled: () => setSavingTeacherId(null),
    })

    const updateNotesMutation = useMutation({
        mutationFn: async ({ teacherId, notes }: { teacherId: string; notes: string }) => {
            setSavingTeacherId(teacherId)
            const currentRecord = getAttendanceRecord(teacherId)
            const { error } = await supabase
                .from('teacher_attendance_logs')
                .upsert(
                    { teacher_id: teacherId, date: dateStr, status: currentRecord.status, notes: notes || null },
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

    const filteredTeachers = useMemo(() => {
        return teachers.filter((t) =>
            t.full_name.toLowerCase().includes(search.toLowerCase())
        )
    }, [teachers, search])

    const countByStatus = useCallback((status: AttendanceStatus) => {
        return teachers.filter((t) => getAttendanceRecord(t.id).status === status).length
    }, [teachers, getAttendanceRecord])

    const isLoading = isLoadingTeachers || isLoadingAttendance
    const totalCount = teachers.length

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
                            <span className="text-blue-600 dark:text-blue-400">GURU</span>
                        </h1>
                        <p className="mt-2 text-sm font-medium text-slate-400 dark:text-slate-500">
                            {format(date, 'EEEE, dd MMMM yyyy', { locale: localeId })}
                        </p>
                    </div>

                    {/* Date picker */}
                    <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-white shadow-sm px-3.5 py-2.5 dark:border-white/10 dark:bg-white/5 self-start">
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
                </div>

                {/* Stat Cards */}
                {teachers.length > 0 && !isLoading && (
                    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
                        {STAT_CARDS.map(({ key, label, icon: Icon, accent, iconBg, numColor, bar, barBg }) => {
                            const count = countByStatus(key)
                            const pct = totalCount > 0 ? Math.round((count / totalCount) * 100) : 0
                            return (
                                <div
                                    key={key}
                                    className={cn(
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

                {/* Search bar */}
                <div className="flex flex-col gap-2 sm:flex-row sm:items-center px-5 py-3 border-b border-slate-100 bg-slate-50/80 dark:border-white/5 dark:bg-white/[0.02]">
                    <div className="relative flex-1 max-w-sm">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400 dark:text-slate-500 pointer-events-none" />
                        <Input
                            placeholder="Cari nama guru..."
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                            className="pl-9 rounded-xl h-9 text-sm dark:bg-white/5 dark:border-white/10 dark:text-white dark:placeholder:text-slate-600"
                        />
                    </div>
                </div>

                {/* List */}
                {isLoading ? (
                    <div className="flex flex-col items-center justify-center py-24 gap-3">
                        <Loader2 className="h-6 w-6 animate-spin text-blue-500" />
                        <p className="text-sm text-slate-400">Memuat data guru...</p>
                    </div>
                ) : filteredTeachers.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-24 gap-2">
                        <p className="text-sm text-slate-400 dark:text-slate-600">Guru tidak ditemukan.</p>
                    </div>
                ) : (
                    <div className="divide-y divide-slate-50 dark:divide-white/[0.03] px-2 py-2">
                        {filteredTeachers.map((teacher) => {
                            const record = getAttendanceRecord(teacher.id)
                            const isSaving = savingTeacherId === teacher.id
                            const isSaved = savedTeacherIds.has(teacher.id)
                            const cfg = STATUS_CONFIG[record.status] || STATUS_CONFIG['Alpha']

                            return (
                                <div
                                    key={teacher.id}
                                    className="flex items-center gap-3 py-3 px-3 rounded-xl hover:bg-blue-50/40 dark:hover:bg-white/[0.03] transition-colors"
                                >
                                    {/* Avatar */}
                                    <div className={cn(
                                        'h-9 w-9 rounded-full shrink-0 flex items-center justify-center text-xs font-black ring-2 ring-white dark:ring-white/5',
                                        !teacher.avatar_url && getAvatarColor(teacher.full_name)
                                    )}>
                                        {teacher.avatar_url
                                            ? <img src={teacher.avatar_url} className="h-full w-full object-cover rounded-full" alt="" />
                                            : getInitials(teacher.full_name)}
                                    </div>

                                    {/* Info */}
                                    <div className="flex-1 min-w-0">
                                        <div className="flex items-center gap-1.5">
                                            <p className="text-sm font-semibold text-slate-800 dark:text-white truncate">
                                                {teacher.full_name}
                                            </p>
                                            {isSaved && <Check size={13} className="text-emerald-500 dark:text-emerald-400 shrink-0" />}
                                        </div>
                                        {teacher.email && (
                                            <p className="text-xs text-slate-400 truncate">{teacher.email}</p>
                                        )}
                                    </div>

                                    {/* Notes input */}
                                    <Input
                                        placeholder="Catatan..."
                                        value={pendingNotes[teacher.id] ?? record.notes ?? ''}
                                        onChange={(e) =>
                                            setPendingNotes((prev) => ({ ...prev, [teacher.id]: e.target.value }))
                                        }
                                        className="hidden sm:block w-52 h-8 text-xs rounded-lg dark:bg-white/5 dark:border-white/10 dark:text-white dark:placeholder:text-slate-600"
                                    />

                                    {/* Status select */}
                                    <Select
                                        value={record.status}
                                        onValueChange={(status) =>
                                            updateStatusMutation.mutate({ teacherId: teacher.id, status: status as AttendanceStatus })
                                        }
                                        disabled={isSaving}
                                    >
                                        <SelectTrigger className={cn('w-28 h-8 text-xs font-bold shadow-none rounded-lg', cfg.trigger)}>
                                            {isSaving
                                                ? <Loader2 className="h-3 w-3 animate-spin" />
                                                : <span className={cn('h-1.5 w-1.5 rounded-full', cfg.dot)} />}
                                            <SelectValue />
                                        </SelectTrigger>
                                        <SelectContent className="dark:bg-[#111b30] dark:border-white/10">
                                            {STATUS_OPTIONS.map((opt) => (
                                                <SelectItem
                                                    key={opt}
                                                    value={opt}
                                                    className="text-xs dark:text-slate-300 dark:focus:text-white dark:focus:bg-white/10"
                                                >
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
                )}

                {/* Footer count */}
                {!isLoading && filteredTeachers.length > 0 && (
                    <div className="px-5 py-3 border-t border-slate-100 dark:border-white/5">
                        <p className="text-xs text-slate-400 dark:text-slate-600">
                            Menampilkan {filteredTeachers.length} dari {totalCount} guru
                        </p>
                    </div>
                )}
            </div>
        </div>
    )
}