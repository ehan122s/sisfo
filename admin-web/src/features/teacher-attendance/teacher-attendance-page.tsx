import { useState, useEffect, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { format } from 'date-fns'
import { supabase } from '@/lib/supabase'
import { toast } from "sonner"
import { Calendar as CalendarIcon, Loader2, Search, Check } from 'lucide-react'
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
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { useDebounce } from '@/hooks/use-debounce'

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

export function TeacherAttendancePage() {
    const [date, setDate] = useState<Date>(new Date())
    const [search, setSearch] = useState('')
    const [pendingNotes, setPendingNotes] = useState<Record<string, string>>({})
    const [savingTeacherId, setSavingTeacherId] = useState<string | null>(null)
    const [savedTeacherIds, setSavedTeacherIds] = useState<Set<string>>(new Set())
    const queryClient = useQueryClient()
    const dateStr = format(date, 'yyyy-MM-dd')

    // Clear saved indicators after delay
    const clearSavedIndicator = useCallback((teacherId: string) => {
        setTimeout(() => {
            setSavedTeacherIds(prev => {
                const next = new Set(prev)
                next.delete(teacherId)
                return next
            })
        }, 1500)
    }, [])

    // Fetch Teachers
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

    // Fetch Attendance for selected date
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

    // Build attendance map from fetched data
    const getAttendanceRecord = (teacherId: string): AttendanceRecord => {
        const existing = attendanceLogs.find(log => log.teacher_id === teacherId)
        if (existing) return existing
        return {
            teacher_id: teacherId,
            date: dateStr,
            status: 'Alpha',
        }
    }

    // Auto-save mutation for status changes
    const updateStatusMutation = useMutation({
        mutationFn: async ({ teacherId, status }: { teacherId: string, status: AttendanceRecord['status'] }) => {
            setSavingTeacherId(teacherId)
            const { error } = await supabase
                .from('teacher_attendance_logs')
                .upsert({
                    teacher_id: teacherId,
                    date: dateStr,
                    status: status,
                    notes: pendingNotes[teacherId] ?? getAttendanceRecord(teacherId).notes,
                }, { onConflict: 'teacher_id,date' })

            if (error) throw error
        },
        onMutate: async ({ teacherId, status }) => {
            // Cancel any outgoing refetches
            await queryClient.cancelQueries({ queryKey: ['teacher_attendance', dateStr] })

            // Snapshot previous value
            const previousLogs = queryClient.getQueryData<AttendanceRecord[]>(['teacher_attendance', dateStr])

            // Optimistically update
            queryClient.setQueryData<AttendanceRecord[]>(['teacher_attendance', dateStr], (old = []) => {
                const existingIndex = old.findIndex(log => log.teacher_id === teacherId)
                if (existingIndex >= 0) {
                    const updated = [...old]
                    updated[existingIndex] = { ...updated[existingIndex], status }
                    return updated
                } else {
                    return [...old, { teacher_id: teacherId, date: dateStr, status }]
                }
            })

            return { previousLogs }
        },
        onError: (_err, { teacherId: _teacherId }, context) => {
            if (context?.previousLogs) {
                queryClient.setQueryData(['teacher_attendance', dateStr], context.previousLogs)
            }
            setSavingTeacherId(null)
            toast.error("Gagal menyimpan perubahan")
        },
        onSuccess: (_data, { teacherId }) => {
            setSavedTeacherIds(prev => new Set(prev).add(teacherId))
            clearSavedIndicator(teacherId)
        },
        onSettled: () => {
            setSavingTeacherId(null)
            queryClient.invalidateQueries({ queryKey: ['teacher_attendance', dateStr] })
        },
    })

    // Auto-save mutation for notes
    const updateNotesMutation = useMutation({
        mutationFn: async ({ teacherId, notes }: { teacherId: string, notes: string }) => {
            setSavingTeacherId(teacherId)
            const record = getAttendanceRecord(teacherId)
            const { error } = await supabase
                .from('teacher_attendance_logs')
                .upsert({
                    teacher_id: teacherId,
                    date: dateStr,
                    status: record.status,
                    notes: notes,
                }, { onConflict: 'teacher_id,date' })

            if (error) throw error
        },
        onMutate: async ({ teacherId, notes }) => {
            await queryClient.cancelQueries({ queryKey: ['teacher_attendance', dateStr] })
            const previousLogs = queryClient.getQueryData<AttendanceRecord[]>(['teacher_attendance', dateStr])

            queryClient.setQueryData<AttendanceRecord[]>(['teacher_attendance', dateStr], (old = []) => {
                const existingIndex = old.findIndex(log => log.teacher_id === teacherId)
                if (existingIndex >= 0) {
                    const updated = [...old]
                    updated[existingIndex] = { ...updated[existingIndex], notes }
                    return updated
                } else {
                    return [...old, { teacher_id: teacherId, date: dateStr, status: 'Alpha', notes }]
                }
            })

            return { previousLogs }
        },
        onError: (_err, { teacherId: _teacherId }, context) => {
            if (context?.previousLogs) {
                queryClient.setQueryData(['teacher_attendance', dateStr], context.previousLogs)
            }
            setSavingTeacherId(null)
            toast.error("Gagal menyimpan catatan")
        },
        onSuccess: (_data, { teacherId }) => {
            setSavedTeacherIds(prev => new Set(prev).add(teacherId))
            clearSavedIndicator(teacherId)
            // Clear pending notes after successful save
            setPendingNotes(prev => {
                const next = { ...prev }
                delete next[teacherId]
                return next
            })
        },
        onSettled: () => {
            setSavingTeacherId(null)
            queryClient.invalidateQueries({ queryKey: ['teacher_attendance', dateStr] })
        },
    })

    // Handle status change - immediate save
    const handleStatusChange = (teacherId: string, status: AttendanceRecord['status']) => {
        updateStatusMutation.mutate({ teacherId, status })
    }

    // Handle notes change - update local state
    const handleNotesChange = (teacherId: string, notes: string) => {
        setPendingNotes(prev => ({ ...prev, [teacherId]: notes }))
    }

    // Debounce notes for auto-save
    const debouncedNotes = useDebounce(pendingNotes, 1000)

    // Auto-save notes when debounced value changes
    useEffect(() => {
        Object.entries(debouncedNotes).forEach(([teacherId, notes]) => {
            const currentNotes = getAttendanceRecord(teacherId).notes || ''
            if (notes !== currentNotes) {
                updateNotesMutation.mutate({ teacherId, notes })
            }
        })
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [debouncedNotes])

    // Clear pending notes when date changes
    useEffect(() => {
        setPendingNotes({})
        setSavedTeacherIds(new Set())
    }, [dateStr])

    const filteredTeachers = teachers.filter(t =>
        t.full_name.toLowerCase().includes(search.toLowerCase())
    )

    const getInitials = (name: string) => {
        return name
            .split(' ')
            .map((n) => n[0])
            .join('')
            .toUpperCase()
            .substring(0, 2)
    }

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Absensi Guru</h1>
                    <p className="text-muted-foreground">Catat dan pantau kehadiran guru pembimbing.</p>
                </div>
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

            <Card>
                <CardHeader>
                    <div className="flex items-center justify-between">
                        <CardTitle className="text-lg font-medium">
                            Daftar Guru & Pembimbing
                        </CardTitle>
                        <div className="relative w-64">
                            <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                placeholder="Cari nama..."
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                                className="pl-8"
                            />
                        </div>
                    </div>
                </CardHeader>
                <CardContent>
                    {isLoadingTeachers || isLoadingAttendance ? (
                        <div className="flex justify-center p-8">
                            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                        </div>
                    ) : filteredTeachers.length === 0 ? (
                        <div className="text-center py-8 text-muted-foreground">
                            Tidak ada data guru ditemukan
                        </div>
                    ) : (
                        <div className="rounded-md border">
                            <Table>
                                <TableHeader>
                                    <TableRow>
                                        <TableHead>Nama Guru</TableHead>
                                        <TableHead className="w-[200px]">Status Kehadiran</TableHead>
                                        <TableHead>Catatan</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {filteredTeachers.map((teacher) => {
                                        const record = getAttendanceRecord(teacher.id)
                                        const localNotes = pendingNotes[teacher.id]
                                        const displayNotes = localNotes !== undefined ? localNotes : (record.notes || '')
                                        const isSaving = savingTeacherId === teacher.id
                                        const isSaved = savedTeacherIds.has(teacher.id)

                                        return (
                                            <TableRow key={teacher.id}>
                                                <TableCell>
                                                    <div className="flex items-center gap-3">
                                                        <Avatar>
                                                            <AvatarImage src={teacher.avatar_url} />
                                                            <AvatarFallback>{getInitials(teacher.full_name)}</AvatarFallback>
                                                        </Avatar>
                                                        <div className="flex flex-col">
                                                            <span className="font-medium">{teacher.full_name}</span>
                                                            <span className="text-xs text-muted-foreground">{teacher.email}</span>
                                                        </div>
                                                    </div>
                                                </TableCell>
                                                <TableCell>
                                                    <div className="flex items-center gap-2">
                                                        <Select
                                                            value={record.status}
                                                            onValueChange={(val: 'Hadir' | 'Izin' | 'Sakit' | 'Alpha' | 'Cuti') => handleStatusChange(teacher.id, val)}
                                                            disabled={isSaving}
                                                        >
                                                            <SelectTrigger className={cn(
                                                                "w-full",
                                                                record.status === 'Hadir' && "bg-green-50 text-green-700 border-green-200",
                                                                record.status === 'Sakit' && "bg-yellow-50 text-yellow-700 border-yellow-200",
                                                                record.status === 'Izin' && "bg-blue-50 text-blue-700 border-blue-200",
                                                                record.status === 'Alpha' && "bg-red-50 text-red-700 border-red-200",
                                                                record.status === 'Cuti' && "bg-purple-50 text-purple-700 border-purple-200",
                                                            )}>
                                                                <SelectValue />
                                                            </SelectTrigger>
                                                            <SelectContent>
                                                                <SelectItem value="Hadir">Hadir</SelectItem>
                                                                <SelectItem value="Sakit">Sakit</SelectItem>
                                                                <SelectItem value="Izin">Izin</SelectItem>
                                                                <SelectItem value="Cuti">Cuti</SelectItem>
                                                                <SelectItem value="Alpha">Alpha</SelectItem>
                                                            </SelectContent>
                                                        </Select>
                                                        {/* Loading indicator */}
                                                        {isSaving && (
                                                            <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
                                                        )}
                                                        {/* Success indicator */}
                                                        {isSaved && !isSaving && (
                                                            <Check className="h-4 w-4 text-green-500 animate-in fade-in duration-200" />
                                                        )}
                                                    </div>
                                                </TableCell>
                                                <TableCell>
                                                    <Input
                                                        placeholder="Keterangan (opsional)..."
                                                        value={displayNotes}
                                                        onChange={(e) => handleNotesChange(teacher.id, e.target.value)}
                                                        className="max-w-md"
                                                    />
                                                </TableCell>
                                            </TableRow>
                                        )
                                    })}
                                </TableBody>
                            </Table>
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    )
}
