import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { format, startOfMonth, endOfMonth, isSameDay } from 'date-fns'
import { id } from 'date-fns/locale'
import { 
    Calendar, 
    Clock, 
    MapPin, 
    Image as ImageIcon, 
    ArrowLeft, 
    RefreshCw, 
    FileText, 
    User, 
    Phone, 
    Home, 
    Pencil, 
    CheckCircle2, 
    AlertCircle, 
    XCircle,
    CalendarDays,
    ChevronLeft,
    ChevronRight,
    Download
} from 'lucide-react'
import { useParams, useNavigate } from 'react-router-dom'
import { useState, useMemo } from 'react'
import { type Student } from '@/types'
import { cn } from '@/lib/utils'
import { EditStudentDialog } from '@/features/students/components/edit-student-dialog'
import { StudentYearlyReport } from '../components/student-yearly-report'
import { Skeleton } from '@/components/ui/skeleton'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'

export function StudentDetailPage() {
    const { studentId } = useParams()
    const navigate = useNavigate()
    const [selectedDate, setSelectedDate] = useState<Date>(new Date())
    const [editDialogOpen, setEditDialogOpen] = useState(false)
    const [reportDialogOpen, setReportDialogOpen] = useState(false)

    // Fetch Student Basic Info
    const { data: student, isLoading: isLoadingStudent } = useQuery({
        queryKey: ['student', studentId],
        queryFn: async () => {
            if (!studentId) return null
            const { data, error } = await supabase
                .from('profiles')
                .select('*, placements(companies(name))')
                .eq('id', studentId)
                .single()

            if (error) throw error
            return data
        },
        enabled: !!studentId,
    })

    // Fetch Monthly Attendance
    const { data: attendanceLogs = [], isLoading: isLoadingAttendance } = useQuery({
        queryKey: ['attendance', studentId, format(selectedDate, 'yyyy-MM')],
        queryFn: async () => {
            if (!studentId) return []
            const start = startOfMonth(selectedDate).toISOString()
            const end = endOfMonth(selectedDate).toISOString()

            const { data, error } = await supabase
                .from('attendance_logs')
                .select('*')
                .eq('student_id', studentId)
                .gte('created_at', start)
                .lte('created_at', end)
                .order('created_at', { ascending: false })

            if (error) throw error
            return data
        },
        enabled: !!studentId
    })

    // Fetch Monthly Journals
    const { data: journals = [], isLoading: isLoadingJournals } = useQuery({
        queryKey: ['journals', studentId, format(selectedDate, 'yyyy-MM')],
        queryFn: async () => {
            if (!studentId) return []
            const start = startOfMonth(selectedDate).toISOString()
            const end = endOfMonth(selectedDate).toISOString()

            const { data, error } = await supabase
                .from('daily_journals')
                .select('*')
                .eq('student_id', studentId)
                .gte('created_at', start)
                .lte('created_at', end)
                .order('created_at', { ascending: false })

            if (error) throw error
            return data
        },
        enabled: !!studentId
    })

    // Calculate monthly stats
    const stats = useMemo(() => {
        const priorityByStatus: Record<string, number> = {
            '': 0,
            alpa: 1,
            alpha: 1,
            absent: 1,
            'belum hadir': 1,
            izin: 2,
            sakit: 2,
            permission: 2,
            hadir: 3,
            terlambat: 3,
            telat: 3,
            present: 3,
            late: 3,
        }
        const dayMap = new Map<string, string>()
        attendanceLogs.forEach((log) => {
            const date = new Date(log.created_at)
            if (Number.isNaN(date.getTime())) return
            const dayKey = format(date, 'yyyy-MM-dd')
            const status = (log.status || '').trim().toLowerCase()
            const current = dayMap.get(dayKey) || ''
            if ((priorityByStatus[status] || 0) > (priorityByStatus[current] || 0)) {
                dayMap.set(dayKey, status)
            }
        })

        let present = 0
        let late = 0
        let permission = 0

        dayMap.forEach((status) => {
            if (status === 'hadir' || status === 'present') present += 1
            else if (status === 'terlambat' || status === 'telat' || status === 'late') late += 1
            else if (status === 'izin' || status === 'sakit' || status === 'permission') permission += 1
        })

        const totalDays = dayMap.size
        const attendanceRate = totalDays > 0 ? Math.round(((present + late) / totalDays) * 100) : 0
        
        return {
            attendanceRate,
            totalJournals: journals.length,
            lateCount: late,
            permissionCount: permission
        }
    }, [attendanceLogs, journals])

    if (isLoadingStudent) {
        return (
            <div className="container mx-auto py-8 space-y-8">
                <Skeleton className="h-8 w-32" />
                <div className="flex justify-between items-center border-b pb-6">
                    <div className="space-y-2">
                        <Skeleton className="h-10 w-64" />
                        <Skeleton className="h-4 w-48" />
                    </div>
                    <Skeleton className="h-10 w-32" />
                </div>
                <div className="grid md:grid-cols-3 gap-4">
                    <Skeleton className="h-32" />
                    <Skeleton className="h-32" />
                    <Skeleton className="h-32" />
                </div>
            </div>
        )
    }

    if (!student) {
        return (
            <div className="p-16 text-center space-y-4">
                <div className="flex justify-center">
                    <AlertCircle className="h-12 w-12 text-muted-foreground opacity-20" />
                </div>
                <h2 className="text-xl font-bold">Siswa tidak ditemukan</h2>
                <Button variant="outline" onClick={() => navigate('/monitoring')}>Kembali ke Monitoring</Button>
            </div>
        )
    }

    const handlePrevMonth = () => {
        const newDate = new Date(selectedDate)
        newDate.setMonth(newDate.getMonth() - 1)
        setSelectedDate(newDate)
    }

    const handleNextMonth = () => {
        const newDate = new Date(selectedDate)
        newDate.setMonth(newDate.getMonth() + 1)
        if (newDate <= new Date()) {
            setSelectedDate(newDate)
        }
    }

    return (
        <div className="container mx-auto py-6 max-w-6xl space-y-8 px-4 md:px-6">
            {/* Breadcrumb / Back */}
            <nav className="flex items-center gap-2 text-sm text-muted-foreground">
                <Button 
                    variant="ghost" 
                    size="sm" 
                    className="-ml-2 h-8 gap-1 font-normal hover:bg-transparent hover:text-foreground"
                    onClick={() => navigate('/monitoring')}
                >
                    <ArrowLeft className="h-4 w-4" /> Monitoring
                </Button>
                <span>/</span>
                <span className="text-foreground font-medium truncate">{student.full_name}</span>
            </nav>

            {/* Header Section */}
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
                <div className="flex items-center gap-4">
                    <Avatar className="h-20 w-20 md:h-24 md:w-24 rounded-xl border">
                        <AvatarImage src={student.avatar_url || undefined} alt={student.full_name} className="object-cover" />
                        <AvatarFallback className="rounded-xl bg-muted text-foreground text-2xl font-semibold">
                            {getInitials(student.full_name)}
                        </AvatarFallback>
                    </Avatar>
                    <div>
                        <div className="flex flex-wrap items-center gap-2 mb-1.5">
                            <h1 className="text-2xl md:text-3xl font-bold tracking-tight">{student.full_name}</h1>
                            <Badge variant={student.status === 'active' ? 'default' : 'secondary'} className="rounded-full">
                                {student.status === 'active' ? 'Aktif' : 'Non-Aktif'}
                            </Badge>
                        </div>
                        <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-muted-foreground text-sm">
                            <div className="flex items-center gap-1.5">
                                <Badge variant="outline" className="font-medium">{student.class_name}</Badge>
                            </div>
                            <div className="hidden sm:block text-muted-foreground/30">•</div>
                            <div className="flex items-center gap-1.5">
                                <Building2 className="h-4 w-4 opacity-70" />
                                <span className="font-medium text-foreground">{student.placements?.[0]?.companies?.name || 'Belum ada DUDI'}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="flex flex-wrap items-center gap-3">
                    <Button 
                        variant="outline" 
                        className="shadow-sm" 
                        onClick={() => window.open(`/monitoring/${studentId}/report/${selectedDate.getFullYear()}`, '_blank')}
                    >
                        <Download className="mr-2 h-4 w-4" /> Laporan
                    </Button>
                    <Button onClick={() => setEditDialogOpen(true)} className="shadow-sm bg-foreground text-background hover:bg-foreground/90">
                        <Pencil className="mr-2 h-4 w-4" /> Edit Profil
                    </Button>
                </div>
            </div>

            {/* Monthly Controls & Quick Stats */}
            <div className="space-y-4">
                <div className="flex items-center justify-between">
                    <h2 className="text-lg font-semibold flex items-center gap-2">
                        <CalendarDays className="h-5 w-5 text-primary" />
                        Ringkasan {format(selectedDate, 'MMMM yyyy', { locale: id })}
                    </h2>
                    
                    <div className="flex items-center gap-1 bg-background border rounded-md p-1 shadow-sm">
                        <Button variant="ghost" size="icon" className="h-8 w-8" onClick={handlePrevMonth}>
                            <ChevronLeft className="h-4 w-4" />
                        </Button>
                        <div className="px-3 text-sm font-medium min-w-[120px] text-center">
                            {format(selectedDate, 'MMM yyyy', { locale: id })}
                        </div>
                        <Button 
                            variant="ghost" 
                            size="icon" 
                            className="h-8 w-8" 
                            onClick={handleNextMonth}
                            disabled={isSameDay(startOfMonth(selectedDate), startOfMonth(new Date()))}
                        >
                            <ChevronRight className="h-4 w-4" />
                        </Button>
                    </div>
                </div>

                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                    <Card className="bg-primary/[0.03] border-primary/10">
                        <CardContent className="p-4 flex flex-col items-center justify-center text-center space-y-1">
                            <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Kehadiran</span>
                            <div className="text-2xl font-bold text-primary">{stats.attendanceRate}%</div>
                            <div className="text-[10px] text-muted-foreground">{attendanceLogs.length} Hari tercatat</div>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardContent className="p-4 flex flex-col items-center justify-center text-center space-y-1">
                            <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Jurnal</span>
                            <div className="text-2xl font-bold">{stats.totalJournals}</div>
                            <div className="text-[10px] text-muted-foreground">Total laporan harian</div>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardContent className="p-4 flex flex-col items-center justify-center text-center space-y-1">
                            <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Terlambat</span>
                            <div className="text-2xl font-bold text-orange-600">{stats.lateCount}</div>
                            <div className="text-[10px] text-muted-foreground">Kali bulan ini</div>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardContent className="p-4 flex flex-col items-center justify-center text-center space-y-1">
                            <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Izin/Sakit</span>
                            <div className="text-2xl font-bold text-blue-600">{stats.permissionCount}</div>
                            <div className="text-[10px] text-muted-foreground">Hari disetujui</div>
                        </CardContent>
                    </Card>
                </div>
            </div>

            {/* Main Tabs */}
            <Tabs defaultValue="profile" className="space-y-6">
                <TabsList className="w-full h-auto justify-start gap-1 overflow-x-auto overflow-y-hidden no-scrollbar">
                    <TabsTrigger
                        value="profile"
                        className="whitespace-nowrap"
                    >
                        Profil & Data
                    </TabsTrigger>
                    <TabsTrigger
                        value="attendance"
                        className="whitespace-nowrap"
                    >
                        Log Absensi
                    </TabsTrigger>
                    <TabsTrigger
                        value="journals"
                        className="whitespace-nowrap"
                    >
                        Jurnal PKL
                    </TabsTrigger>
                </TabsList>

                <TabsContent value="profile" className="mt-0 space-y-6 outline-none animate-in fade-in-50 duration-300">
                    <div className="grid lg:grid-cols-3 gap-6">
                        {/* Data Akademik & Pribadi */}
                        <div className="lg:col-span-2 space-y-6">
                            <Card className="overflow-hidden">
                                <CardHeader className="bg-muted/30 border-b py-4">
                                    <CardTitle className="text-base flex items-center gap-2">
                                        <User className="h-4 w-4 text-primary" />
                                        Informasi Akademik & Pribadi
                                    </CardTitle>
                                </CardHeader>
                                <CardContent className="p-0">
                                    <div className="grid sm:grid-cols-2 divide-y sm:divide-y-0 sm:divide-x border-b">
                                        <div className="p-4 space-y-1">
                                            <p className="text-[10px] uppercase font-bold text-muted-foreground tracking-wider">Nama Lengkap</p>
                                            <p className="text-sm font-medium">{student.full_name}</p>
                                        </div>
                                        <div className="p-4 space-y-1">
                                            <p className="text-[10px] uppercase font-bold text-muted-foreground tracking-wider">NISN / NIPD</p>
                                            <p className="text-sm font-medium">{student.nisn || '-'} / {student.nipd || '-'}</p>
                                        </div>
                                    </div>
                                    <div className="grid sm:grid-cols-2 divide-y sm:divide-y-0 sm:divide-x border-b">
                                        <div className="p-4 space-y-1">
                                            <p className="text-[10px] uppercase font-bold text-muted-foreground tracking-wider">Jenis Kelamin</p>
                                            <p className="text-sm font-medium">
                                                {student.gender === 'L' ? 'Laki-laki' : student.gender === 'P' ? 'Perempuan' : '-'}
                                            </p>
                                        </div>
                                        <div className="p-4 space-y-1">
                                            <p className="text-[10px] uppercase font-bold text-muted-foreground tracking-wider">Tempat, Tanggal Lahir</p>
                                            <p className="text-sm font-medium">
                                                {student.birth_place || '-'}, {student.birth_date ? format(new Date(student.birth_date), 'dd MMM yyyy', { locale: id }) : '-'}
                                            </p>
                                        </div>
                                    </div>
                                    <div className="grid sm:grid-cols-2 divide-y sm:divide-y-0 sm:divide-x">
                                        <div className="p-4 space-y-1">
                                            <p className="text-[10px] uppercase font-bold text-muted-foreground tracking-wider">NIK</p>
                                            <p className="text-sm font-medium font-mono">{student.nik || '-'}</p>
                                        </div>
                                        <div className="p-4 space-y-1">
                                            <p className="text-[10px] uppercase font-bold text-muted-foreground tracking-wider">Agama</p>
                                            <p className="text-sm font-medium">{student.religion || '-'}</p>
                                        </div>
                                    </div>
                                </CardContent>
                            </Card>

                            <Card className="overflow-hidden">
                                <CardHeader className="bg-muted/30 border-b py-4">
                                    <CardTitle className="text-base flex items-center gap-2">
                                        <Home className="h-4 w-4 text-primary" />
                                        Alamat & Tempat Tinggal
                                    </CardTitle>
                                </CardHeader>
                                <CardContent className="p-6">
                                    <p className="text-sm leading-relaxed">{student.address || 'Alamat belum dilengkapi.'}</p>
                                </CardContent>
                            </Card>
                        </div>

                        {/* Kontak & Orang Tua */}
                        <div className="space-y-6">
                            <Card className="overflow-hidden">
                                <CardHeader className="bg-muted/30 border-b py-4">
                                    <CardTitle className="text-base flex items-center gap-2">
                                        <Phone className="h-4 w-4 text-primary" />
                                        Kontak
                                    </CardTitle>
                                </CardHeader>
                                <CardContent className="p-4 space-y-4">
                                    <div className="flex items-center justify-between">
                                        <div className="space-y-0.5">
                                            <p className="text-[10px] uppercase font-bold text-muted-foreground">No. WhatsApp</p>
                                            <p className="text-sm font-medium">{student.phone_number || '-'}</p>
                                        </div>
                                        {student.phone_number && (
                                            <Button variant="outline" size="sm" className="h-8" onClick={() => window.open(`https://wa.me/${student.phone_number.replace(/\D/g, '')}`, '_blank')}>
                                                Chat
                                            </Button>
                                        )}
                                    </div>
                                    <div className="flex items-center justify-between">
                                        <div className="space-y-0.5">
                                            <p className="text-[10px] uppercase font-bold text-muted-foreground">Email</p>
                                            <p className="text-sm font-medium truncate max-w-[150px]">{student.email || '-'}</p>
                                        </div>
                                    </div>
                                </CardContent>
                            </Card>

                            <Card className="overflow-hidden border-primary/10">
                                <CardHeader className="bg-primary/[0.03] border-b py-4">
                                    <CardTitle className="text-base flex items-center gap-2">
                                        <User className="h-4 w-4 text-primary" />
                                        Orang Tua / Wali
                                    </CardTitle>
                                </CardHeader>
                                <CardContent className="p-4 space-y-4">
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="space-y-0.5">
                                            <p className="text-[10px] uppercase font-bold text-muted-foreground">Ayah</p>
                                            <p className="text-sm font-medium">{student.father_name || '-'}</p>
                                        </div>
                                        <div className="space-y-0.5">
                                            <p className="text-[10px] uppercase font-bold text-muted-foreground">Ibu</p>
                                            <p className="text-sm font-medium">{student.mother_name || '-'}</p>
                                        </div>
                                    </div>
                                    <Separator />
                                    <div className="flex items-center justify-between">
                                        <div className="space-y-0.5">
                                            <p className="text-[10px] uppercase font-bold text-muted-foreground">No. WhatsApp Ortu</p>
                                            <p className="text-sm font-medium">{student.parent_phone_number || '-'}</p>
                                        </div>
                                        {student.parent_phone_number && (
                                            <Button variant="outline" size="sm" className="h-8" onClick={() => window.open(`https://wa.me/${student.parent_phone_number.replace(/\D/g, '')}`, '_blank')}>
                                                Hubungi
                                            </Button>
                                        )}
                                    </div>
                                </CardContent>
                            </Card>
                        </div>
                    </div>
                </TabsContent>

                <TabsContent value="attendance" className="mt-0 space-y-4 outline-none animate-in fade-in-50 duration-300">
                    <Card>
                        <CardHeader className="pb-0">
                            <CardTitle className="text-base">Data Absensi Harian</CardTitle>
                            <CardDescription>Menampilkan riwayat masuk dan pulang pada periode terpilih.</CardDescription>
                        </CardHeader>
                        <CardContent className="pt-6">
                            {isLoadingAttendance ? (
                                <div className="space-y-3">
                                    {[1, 2, 3].map(i => <Skeleton key={i} className="h-16 w-full" />)}
                                </div>
                            ) : attendanceLogs.length === 0 ? (
                                <div className="py-12 flex flex-col items-center justify-center text-center border-2 border-dashed rounded-lg bg-muted/20">
                                    <Calendar className="h-10 w-10 text-muted-foreground mb-3 opacity-20" />
                                    <p className="text-sm font-medium">Belum ada data absensi</p>
                                    <p className="text-xs text-muted-foreground mt-1">Siswa tidak melakukan absensi di bulan ini.</p>
                                </div>
                            ) : (
                                <div className="space-y-3">
                                    {attendanceLogs.map((log) => (
                                        <div key={log.id} className="flex flex-col md:flex-row md:items-center justify-between p-4 rounded-xl border bg-background hover:bg-muted/30 transition-colors gap-4">
                                            <div className="flex items-start gap-4">
                                                <div className={cn(
                                                    "h-10 w-10 rounded-lg flex items-center justify-center shrink-0",
                                                    log.status === 'Hadir' ? "bg-green-100 text-green-600" : 
                                                    log.status === 'Terlambat' ? "bg-orange-100 text-orange-600" : "bg-red-100 text-red-600"
                                                )}>
                                                    {log.status === 'Hadir' ? <CheckCircle2 className="h-5 w-5" /> : 
                                                     log.status === 'Terlambat' ? <Clock className="h-5 w-5" /> : <XCircle className="h-5 w-5" />}
                                                </div>
                                                <div className="space-y-0.5">
                                                    <p className="font-semibold text-sm">{format(new Date(log.created_at), 'EEEE, d MMMM yyyy', { locale: id })}</p>
                                                    <div className="flex items-center gap-3 text-xs text-muted-foreground">
                                                        <span className="flex items-center gap-1">
                                                            <Clock className="h-3 w-3" /> {log.check_in_time ? format(new Date(log.check_in_time), 'HH:mm') : '--:--'}
                                                        </span>
                                                        <span className="opacity-30">|</span>
                                                        <span className="flex items-center gap-1">
                                                            <RefreshCw className="h-3 w-3" /> {log.check_out_time ? format(new Date(log.check_out_time), 'HH:mm') : '--:--'}
                                                        </span>
                                                    </div>
                                                </div>
                                            </div>
                                            
                                            <div className="flex flex-wrap items-center gap-4 md:text-right">
                                                <div className="flex flex-col gap-1">
                                                    {log.check_in_location && (
                                                        <div className="flex items-center gap-1 text-[10px] md:justify-end text-emerald-600 font-medium">
                                                            <MapPin className="h-3 w-3" /> {log.check_in_location}
                                                        </div>
                                                    )}
                                                    {log.check_out_location && (
                                                        <div className="flex items-center gap-1 text-[10px] md:justify-end text-blue-600 font-medium">
                                                            <MapPin className="h-3 w-3" /> {log.check_out_location}
                                                        </div>
                                                    )}
                                                </div>
                                                <Badge className="min-w-[80px] justify-center" variant={
                                                    log.status === 'Hadir' ? 'default' : 
                                                    log.status === 'Terlambat' ? 'outline' : 'destructive'
                                                }>
                                                    {log.status}
                                                </Badge>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="journals" className="mt-0 space-y-4 outline-none animate-in fade-in-50 duration-300">
                    {isLoadingJournals ? (
                        <div className="grid md:grid-cols-2 gap-4">
                            {[1, 2].map(i => <Skeleton key={i} className="h-40 w-full" />)}
                        </div>
                    ) : journals.length === 0 ? (
                        <div className="py-20 flex flex-col items-center justify-center text-center border-2 border-dashed rounded-xl bg-muted/20">
                            <FileText className="h-12 w-12 text-muted-foreground mb-3 opacity-20" />
                            <p className="text-base font-semibold">Jurnal masih kosong</p>
                            <p className="text-sm text-muted-foreground mt-1 max-w-[250px]">Siswa belum mengunggah laporan aktivitas harian di bulan ini.</p>
                        </div>
                    ) : (
                        <div className="grid md:grid-cols-2 gap-6">
                            {journals.map((journal) => (
                                <Card key={journal.id} className="overflow-hidden hover:shadow-md transition-shadow group border-primary/5">
                                    <div className="p-5 space-y-4">
                                        <div className="flex items-center justify-between">
                                            <div className="bg-primary/5 px-2 py-1 rounded text-[10px] font-bold text-primary flex items-center gap-1.5">
                                                <Calendar className="h-3 w-3" />
                                                {format(new Date(journal.created_at), 'dd MMM yyyy', { locale: id })}
                                            </div>
                                            <Badge variant={journal.is_approved ? 'default' : 'secondary'} className="text-[10px] h-5">
                                                {journal.is_approved ? 'Disetujui' : 'Menunggu'}
                                            </Badge>
                                        </div>
                                        
                                        <div className="space-y-2">
                                            <h4 className="font-bold text-sm line-clamp-1">{journal.activity_title}</h4>
                                            <p className="text-xs text-muted-foreground leading-relaxed line-clamp-3 italic">
                                                "{journal.description}"
                                            </p>
                                        </div>
                                    </div>

                                    {journal.evidence_photo && (
                                        <div 
                                            className="h-40 bg-muted relative cursor-zoom-in overflow-hidden"
                                            onClick={() => window.open(journal.evidence_photo, '_blank')}
                                        >
                                            <img 
                                                src={journal.evidence_photo} 
                                                alt="Bukti Aktivitas" 
                                                className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" 
                                            />
                                            <div className="absolute inset-0 bg-black/20 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                                                <ImageIcon className="h-6 w-6 text-white" />
                                            </div>
                                        </div>
                                    )}
                                </Card>
                            ))}
                        </div>
                    )}
                </TabsContent>
            </Tabs>

            <EditStudentDialog
                open={editDialogOpen}
                onOpenChange={setEditDialogOpen}
                student={student}
            />

            <StudentYearlyReport
                student={student as Student}
                year={selectedDate.getFullYear()}
                isOpen={reportDialogOpen}
                onOpenChange={setReportDialogOpen}
            />
        </div>
    )
}

function Separator() {
    return <div className="h-px bg-border w-full" />
}

function Building2(props: any) {
    return (
        <svg
            {...props}
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
        >
            <path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z" />
            <path d="M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2" />
            <path d="M18 9h2a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-2" />
            <path d="M10 6h4" />
            <path d="M10 10h4" />
            <path d="M10 14h4" />
            <path d="M10 18h4" />
        </svg>
    )
}

function getInitials(name: string) {
    return name
        .split(' ')
        .map((n) => n[0])
        .join('')
        .toUpperCase()
        .substring(0, 2)
}
