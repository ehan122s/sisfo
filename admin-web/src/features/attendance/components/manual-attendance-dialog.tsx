import { useState, useMemo } from 'react'
import { useMutation, useQueryClient, useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { Loader2, Plus, Search } from 'lucide-react'
import { toast } from 'sonner'
import { ScrollArea } from '@/components/ui/scroll-area'

const STATUS_OPTIONS = ['Hadir', 'Terlambat', 'Belum Hadir', 'Izin', 'Sakit', 'Alpha']

export function ManualAttendanceDialog() {
    const [open, setOpen] = useState(false)
    const [selectedStudentId, setSelectedStudentId] = useState<string>('')
    const [date, setDate] = useState<string>(new Date().toISOString().split('T')[0])
    const [checkInTime, setCheckInTime] = useState<string>('')
    const [checkOutTime, setCheckOutTime] = useState<string>('')
    const [status, setStatus] = useState<string>('Hadir')
    const [notes, setNotes] = useState<string>('')
    const [studentSearch, setStudentSearch] = useState('')

    const queryClient = useQueryClient()

    // Fetch active students for the searchable list
    const { data: students } = useQuery({
        queryKey: ['activeStudentsForManualInput'],
        queryFn: async () => {
            const { data } = await supabase
                .from('profiles')
                .select('id, full_name, class_name')
                .eq('role', 'student')
                .eq('status', 'active')
                .order('full_name')
            return data || []
        },
        enabled: open, // Only fetch when dialog is open
    })

    const filteredStudents = useMemo(() => {
        if (!students) return []
        if (!studentSearch) return students
        const lowerSearch = studentSearch.toLowerCase()
        return students.filter(s => 
            s.full_name?.toLowerCase().includes(lowerSearch) || 
            s.class_name?.toLowerCase().includes(lowerSearch)
        )
    }, [students, studentSearch])

    const selectedStudent = students?.find(s => s.id === selectedStudentId)

    const createMutation = useMutation({
        mutationFn: async () => {
            if (!selectedStudentId) throw new Error('Pilih siswa terlebih dahulu')
            if (!date) throw new Error('Pilih tanggal')
            
            // Construct timestamps
            let checkInTimestamp = null
            let checkOutTimestamp = null

            if (checkInTime) {
                checkInTimestamp = `${date}T${checkInTime}:00`
            }
            if (checkOutTime) {
                checkOutTimestamp = `${date}T${checkOutTime}:00`
            }

            // Insert new log
            const { error } = await supabase.from('attendance_logs').insert({
                student_id: selectedStudentId,
                status,
                check_in_time: checkInTimestamp,
                check_out_time: checkOutTimestamp,
                check_in_photo_url: 'manual_input', // Marker for manual entry
                created_at: `${date}T12:00:00`, // Default to noon for the log date if times are empty
            })

            if (error) throw error
        },
        onSuccess: () => {
            toast.success('Absensi berhasil ditambahkan')
            setOpen(false)
            resetForm()
            queryClient.invalidateQueries({ queryKey: ['attendanceLogs'] })
        },
        onError: (err: any) => {
            toast.error(err.message || 'Gagal menambahkan absensi')
        }
    })

    const resetForm = () => {
        setSelectedStudentId('')
        setCheckInTime('')
        setCheckOutTime('')
        setStatus('Hadir')
        setNotes('')
        setStudentSearch('')
    }

    const handleSubmit = () => {
        createMutation.mutate()
    }

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button>
                    <Plus className="mr-2 h-4 w-4" />
                    Input Manual
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[425px]">
                <DialogHeader>
                    <DialogTitle>Input Absensi Manual</DialogTitle>
                </DialogHeader>
                <div className="grid gap-4 py-4">
                    {/* Student Selection */}
                    <div className="grid gap-2">
                        <Label>Siswa</Label>
                        {selectedStudent ? (
                            <div className="flex items-center justify-between p-2 border rounded-md">
                                <div>
                                    <p className="font-medium text-sm">{selectedStudent.full_name}</p>
                                    <p className="text-xs text-muted-foreground">{selectedStudent.class_name}</p>
                                </div>
                                <Button variant="ghost" size="sm" onClick={() => setSelectedStudentId('')}>
                                    Ganti
                                </Button>
                            </div>
                        ) : (
                            <div className="space-y-2 border rounded-md p-2">
                                <div className="flex items-center px-2 border-b pb-2">
                                    <Search className="mr-2 h-4 w-4 opacity-50" />
                                    <input 
                                        className="flex h-9 w-full rounded-md bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50"
                                        placeholder="Cari nama siswa..."
                                        value={studentSearch}
                                        onChange={(e) => setStudentSearch(e.target.value)}
                                    />
                                </div>
                                <ScrollArea className="h-[150px]">
                                    {filteredStudents.length === 0 ? (
                                        <p className="text-sm text-center text-muted-foreground py-4">Tidak ditemukan</p>
                                    ) : (
                                        <div className="space-y-1">
                                            {filteredStudents.map(student => (
                                                <div 
                                                    key={student.id} 
                                                    className="cursor-pointer hover:bg-slate-100 p-2 rounded text-sm"
                                                    onClick={() => setSelectedStudentId(student.id)}
                                                >
                                                    <div className="font-medium">{student.full_name}</div>
                                                    <div className="text-xs text-muted-foreground">{student.class_name}</div>
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                </ScrollArea>
                            </div>
                        )}
                    </div>

                    {/* Date */}
                    <div className="grid gap-2">
                        <Label htmlFor="date">Tanggal</Label>
                        <Input 
                            id="date" 
                            type="date" 
                            value={date} 
                            onChange={(e) => setDate(e.target.value)} 
                        />
                    </div>

                    {/* Times */}
                    <div className="grid grid-cols-2 gap-4">
                        <div className="grid gap-2">
                            <Label htmlFor="checkin">Jam Masuk</Label>
                            <Input 
                                id="checkin" 
                                type="time" 
                                value={checkInTime} 
                                onChange={(e) => setCheckInTime(e.target.value)} 
                            />
                        </div>
                        <div className="grid gap-2">
                            <Label htmlFor="checkout">Jam Pulang</Label>
                            <Input 
                                id="checkout" 
                                type="time" 
                                value={checkOutTime} 
                                onChange={(e) => setCheckOutTime(e.target.value)} 
                            />
                        </div>
                    </div>

                    {/* Status */}
                    <div className="grid gap-2">
                        <Label>Status</Label>
                        <Select value={status} onValueChange={setStatus}>
                            <SelectTrigger>
                                <SelectValue placeholder="Pilih status" />
                            </SelectTrigger>
                            <SelectContent>
                                {STATUS_OPTIONS.map((s) => (
                                    <SelectItem key={s} value={s}>{s}</SelectItem>
                                ))}
                            </SelectContent>
                        </Select>
                    </div>

                    {/* Notes */}
                    <div className="grid gap-2">
                        <Label htmlFor="notes">Keterangan (Opsional)</Label>
                        <Textarea 
                            id="notes" 
                            value={notes} 
                            onChange={(e) => setNotes(e.target.value)}
                            placeholder="Alasan manual input..." 
                        />
                    </div>
                </div>
                <DialogFooter>
                    <Button variant="outline" onClick={() => setOpen(false)}>Batal</Button>
                    <Button onClick={handleSubmit} disabled={createMutation.isPending || !selectedStudentId || !date}>
                        {createMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Simpan
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    )
}
