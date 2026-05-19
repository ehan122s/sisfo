import { useState, useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { getClassList, getMonthlyAttendanceReport } from '../services/report-service'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
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
import {
    Command,
    CommandEmpty,
    CommandGroup,
    CommandInput,
    CommandItem,
    CommandList,
} from '@/components/ui/command'
import {
    Popover,
    PopoverContent,
    PopoverTrigger,
} from '@/components/ui/popover'
import { cn } from '@/lib/utils'
import {
    Search,
    ChevronLeft,
    ChevronRight,
    CheckCircle,
    MinusCircle,
    AlertCircle,
    Clock,
    Building2,
    Eye,
    LayoutGrid,
    List,
    Check,
    ChevronsUpDown,
    TriangleAlert,
    Users,
    UserCheck,
    UserX,
    Activity,
} from 'lucide-react'
import type { Student, Company } from '@/types'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { TableSkeleton } from '@/components/ui/table-skeleton'
import { EmptyState } from '@/components/ui/empty-state'
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group'
import { getInitials } from '@/lib/utils'
import { useNavigate } from 'react-router-dom'

export function StudentMonitoringPage() {
    const navigate = useNavigate()
    const [viewMode, setViewMode] = useState<'table' | 'grid'>('table')
    const [page, setPage] = useState(0)
    const [search, setSearch] = useState('')
    const [statusFilter, setStatusFilter] = useState('all')
    const [showProblematic, setShowProblematic] = useState(false)
    const [companyFilter, setCompanyFilter] = useState('all')
    const [classFilter, setClassFilter] = useState('')
    const [openClassFilter, setOpenClassFilter] = useState(false)
    const pageSize = 10

    const currentMonth = new Date().getMonth()
    const currentYear = new Date().getFullYear()

    const { data: attendanceSummary = [] } = useQuery({
        queryKey: ['attendance-summary-all', currentMonth, currentYear],
        queryFn: () => getMonthlyAttendanceReport(currentMonth, currentYear),
        staleTime: 1000 * 60 * 10,
    })

    const attendanceMap = useMemo(() => {
        const map = new Map<string, number>()
        attendanceSummary.forEach(item => map.set(item.studentId, item.stats.percentage))
        return map
    }, [attendanceSummary])

    const problematicStudentIds = useMemo(() => {
        const ids = new Set<string>()
        attendanceSummary.forEach(item => {
            if (item.stats.percentage < 75 && item.stats.totalDays > 0) ids.add(item.studentId)
        })
        return ids
    }, [attendanceSummary])

    const { data: studentsResult, isLoading } = useQuery({
        queryKey: ['students-monitoring', page, search, statusFilter, companyFilter, classFilter, showProblematic],
        queryFn: async () => {
            if (showProblematic && problematicStudentIds.size > 0) {
                const ids = Array.from(problematicStudentIds)
                const { data, count, error } = await supabase
                    .from('profiles')
                    .select('*, placements(companies(name))', { count: 'exact' })
                    .eq('role', 'student')
                    .ilike('class_name', 'XII%')
                    .in('id', ids)
                    .order('full_name')
                if (error) throw error
                return { data: (data ?? []) as Student[], count: count ?? 0 }
            }

            const start = page * pageSize
            const end = start + pageSize - 1

            let query = supabase
                .from('profiles')
                .select('*, placements(companies(name))', { count: 'exact' })
                .eq('role', 'student')
                .ilike('class_name', 'XII%')
                .order('full_name')

            if (search) {
                query = query.or(`full_name.ilike.%${search}%,nisn.ilike.%${search}%,class_name.ilike.%${search}%`)
            }
            if (statusFilter !== 'all') {
                query = query.eq('status', statusFilter)
            }
            if (classFilter && classFilter !== 'all') {
                query = query.eq('class_name', classFilter)
            }

            const { data, count, error } = await query.range(start, end)
            if (error) throw error
            return { data: (data ?? []) as Student[], count: count ?? 0 }
        },
        enabled: !showProblematic || problematicStudentIds.size >= 0,
    })

    const { data: classList = [] } = useQuery({
        queryKey: ['class-list', 'XII'],
        queryFn: async () => {
            const all = await getClassList()
            return all.filter((c: string) => c.startsWith('XII'))
        },
        staleTime: 1000 * 60 * 10,
    })

    const studentsData = studentsResult?.data || []
    const totalCount = studentsResult?.count || 0
    const totalPages = Math.ceil(totalCount / pageSize)

    const activeCount = studentsData.filter((s: Student) => s.status === 'active').length
    const problematicCount = problematicStudentIds.size

    const { data: companies = [] } = useQuery({
        queryKey: ['companies'],
        queryFn: async () => {
            const { data } = await supabase.from('companies').select('*').order('name')
            return (data ?? []) as Company[]
        },
    })

    const handleSearchChange = (value: string) => { setSearch(value); setPage(0) }
    const handleStatusFilterChange = (value: string) => { setStatusFilter(value); setPage(0) }
    const handleCompanyFilterChange = (value: string) => { setCompanyFilter(value); setPage(0) }
    const handleClassFilterChange = (value: string) => { setClassFilter(value); setPage(0) }

    const todayLabel = new Date().toLocaleDateString('id-ID', {
        weekday: 'long', day: 'numeric', month: 'long', year: 'numeric',
    })

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'active':
                return (
                    <Badge className="bg-green-100 text-green-700 hover:bg-green-200 border-green-200 dark:bg-green-900/40 dark:text-green-300 flex w-fit items-center gap-1">
                        <CheckCircle className="h-3 w-3" />Aktif
                    </Badge>
                )
            case 'inactive':
                return (
                    <Badge variant="secondary" className="bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300 flex w-fit items-center gap-1">
                        <MinusCircle className="h-3 w-3" />Non-aktif
                    </Badge>
                )
            case 'completed':
                return (
                    <Badge className="bg-blue-100 text-blue-700 border-blue-200 dark:bg-blue-900/40 dark:text-blue-300 flex w-fit items-center gap-1">
                        <CheckCircle className="h-3 w-3" />Selesai
                    </Badge>
                )
            case 'suspended':
                return (
                    <Badge variant="destructive" className="flex w-fit items-center gap-1">
                        <AlertCircle className="h-3 w-3" />Suspended
                    </Badge>
                )
            default:
                return (
                    <Badge variant="outline" className="text-yellow-600 border-yellow-300 bg-yellow-50 dark:bg-yellow-900/20 dark:text-yellow-300 flex w-fit items-center gap-1">
                        <Clock className="h-3 w-3" />Pending
                    </Badge>
                )
        }
    }

    return (
        <div className="space-y-6">
            {/* ── Page Header ── */}
            <div className="flex flex-wrap items-start justify-between gap-4">
                <div>
                    <div className="flex gap-1 mb-2">
                        <div className="h-1 w-8 rounded-full bg-primary" />
                        <div className="h-1 w-4 rounded-full bg-primary/40" />
                    </div>
                    <h1 className="text-3xl font-extrabold tracking-tight italic">
                        MONITORING <span className="text-primary">SISWA PKL</span>
                    </h1>
                    <p className="text-sm text-muted-foreground mt-1">{todayLabel}</p>
                </div>
            </div>

            {/* ── Stat Cards ── */}
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
                {/* Total Siswa */}
                <Card className="border-l-4 border-l-blue-500 dark:border-l-blue-400">
                    <CardContent className="p-4">
                        <div className="flex items-center justify-between">
                            <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Total</p>
                            <Users className="h-5 w-5 text-blue-500 dark:text-blue-400" />
                        </div>
                        <p className="mt-2 text-3xl font-bold text-blue-600 dark:text-blue-400">{totalCount}</p>
                        <div className="mt-2 h-1 w-full rounded-full bg-muted overflow-hidden">
                            <div className="h-1 bg-blue-500 dark:bg-blue-400 rounded-full w-full" />
                        </div>
                        <p className="mt-1 text-xs text-muted-foreground">siswa kelas XII</p>
                    </CardContent>
                </Card>

                {/* Aktif */}
                <Card className="border-l-4 border-l-green-500 dark:border-l-green-400">
                    <CardContent className="p-4">
                        <div className="flex items-center justify-between">
                            <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Aktif</p>
                            <UserCheck className="h-5 w-5 text-green-500 dark:text-green-400" />
                        </div>
                        <p className="mt-2 text-3xl font-bold text-green-600 dark:text-green-400">{activeCount}</p>
                        <div className="mt-2 h-1 w-full rounded-full bg-muted overflow-hidden">
                            <div
                                className="h-1 bg-green-500 dark:bg-green-400 rounded-full transition-all"
                                style={{ width: totalCount ? `${(activeCount / totalCount) * 100}%` : '0%' }}
                            />
                        </div>
                        <p className="mt-1 text-xs text-muted-foreground">
                            {totalCount ? Math.round((activeCount / totalCount) * 100) : 0}% dari total
                        </p>
                    </CardContent>
                </Card>

                {/* Bermasalah */}
                <Card className="border-l-4 border-l-red-500 dark:border-l-red-400">
                    <CardContent className="p-4">
                        <div className="flex items-center justify-between">
                            <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Bermasalah</p>
                            <UserX className="h-5 w-5 text-red-500 dark:text-red-400" />
                        </div>
                        <p className="mt-2 text-3xl font-bold text-red-600 dark:text-red-400">{problematicCount}</p>
                        <div className="mt-2 h-1 w-full rounded-full bg-muted overflow-hidden">
                            <div
                                className="h-1 bg-red-500 dark:bg-red-400 rounded-full transition-all"
                                style={{ width: totalCount ? `${(problematicCount / totalCount) * 100}%` : '0%' }}
                            />
                        </div>
                        <p className="mt-1 text-xs text-muted-foreground">kehadiran &lt; 75%</p>
                    </CardContent>
                </Card>

                {/* Halaman */}
                <Card className="border-l-4 border-l-purple-500 dark:border-l-purple-400">
                    <CardContent className="p-4">
                        <div className="flex items-center justify-between">
                            <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Halaman</p>
                            <Activity className="h-5 w-5 text-purple-500 dark:text-purple-400" />
                        </div>
                        <p className="mt-2 text-3xl font-bold text-purple-600 dark:text-purple-400">{page + 1}</p>
                        <div className="mt-2 h-1 w-full rounded-full bg-muted overflow-hidden">
                            <div
                                className="h-1 bg-purple-500 dark:bg-purple-400 rounded-full transition-all"
                                style={{ width: totalPages ? `${((page + 1) / totalPages) * 100}%` : '100%' }}
                            />
                        </div>
                        <p className="mt-1 text-xs text-muted-foreground">dari {Math.max(1, totalPages)} halaman</p>
                    </CardContent>
                </Card>
            </div>

            {/* ── Alert card for problematic students ── */}
            {problematicStudentIds.size > 0 && (
                <Card className="border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-950/30">
                    <CardContent className="p-4">
                        <div className="flex items-center justify-between gap-4">
                            <div className="flex items-center gap-3">
                                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-red-100 dark:bg-red-900/40">
                                    <TriangleAlert className="h-5 w-5 text-red-600 dark:text-red-400" />
                                </div>
                                <div>
                                    <CardTitle className="text-sm text-red-800 dark:text-red-300">
                                        {problematicStudentIds.size} siswa kehadiran &lt; 75% bulan ini
                                    </CardTitle>
                                    <CardDescription className="text-xs text-red-600 dark:text-red-400">
                                        Siswa berisiko tidak memenuhi syarat kelulusan PKL
                                    </CardDescription>
                                </div>
                            </div>
                            <Button
                                size="sm"
                                variant={showProblematic ? 'destructive' : 'outline'}
                                className={showProblematic ? '' : 'border-red-300 text-red-700 hover:bg-red-100 dark:border-red-700 dark:text-red-400 dark:hover:bg-red-950/40'}
                                onClick={() => { setShowProblematic(p => !p); setPage(0) }}
                            >
                                {showProblematic ? 'Tampilkan Semua' : 'Lihat Bermasalah'}
                            </Button>
                        </div>
                    </CardContent>
                </Card>
            )}

            {/* ── Filter + Table Card ── */}
            <Card>
                <CardHeader>
                    <div className="flex flex-wrap items-center gap-3">
                        <div className="relative flex-1 min-w-[160px]">
                            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                            <Input
                                placeholder="Cari nama, NISN, atau kelas..."
                                value={search}
                                onChange={(e) => handleSearchChange(e.target.value)}
                                className="pl-10"
                            />
                        </div>
                        <div className="w-[160px]">
                            <Select value={statusFilter} onValueChange={handleStatusFilterChange}>
                                <SelectTrigger>
                                    <SelectValue placeholder="Status" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="all">Semua Status</SelectItem>
                                    <SelectItem value="active">Aktif</SelectItem>
                                    <SelectItem value="pending">Pending</SelectItem>
                                    <SelectItem value="suspended">Suspended</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>
                        <div className="w-[180px]">
                            <Select value={companyFilter} onValueChange={handleCompanyFilterChange}>
                                <SelectTrigger>
                                    <SelectValue placeholder="DUDI" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="all">Semua DUDI</SelectItem>
                                    {companies.map((company) => (
                                        <SelectItem key={company.id} value={company.id.toString()}>
                                            {company.name}
                                        </SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>
                        <div className="w-[160px]">
                            <Popover open={openClassFilter} onOpenChange={setOpenClassFilter}>
                                <PopoverTrigger asChild>
                                    <Button variant="outline" role="combobox" aria-expanded={openClassFilter} className="w-full justify-between">
                                        {classFilter && classFilter !== 'all'
                                            ? classList.find((c) => c === classFilter)
                                            : 'Semua Kelas'}
                                        <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                                    </Button>
                                </PopoverTrigger>
                                <PopoverContent className="w-[200px] p-0">
                                    <Command>
                                        <CommandInput placeholder="Cari kelas..." />
                                        <CommandList>
                                            <CommandEmpty>Kelas tidak ditemukan.</CommandEmpty>
                                            <CommandGroup>
                                                <CommandItem value="all" onSelect={() => { handleClassFilterChange('all'); setOpenClassFilter(false) }}>
                                                    <Check className={cn('mr-2 h-4 w-4', classFilter === '' || classFilter === 'all' ? 'opacity-100' : 'opacity-0')} />
                                                    Semua Kelas
                                                </CommandItem>
                                                {classList.map((cls) => (
                                                    <CommandItem key={cls} value={cls} onSelect={(v) => { handleClassFilterChange(v === classFilter ? '' : v); setOpenClassFilter(false) }}>
                                                        <Check className={cn('mr-2 h-4 w-4', classFilter === cls ? 'opacity-100' : 'opacity-0')} />
                                                        {cls}
                                                    </CommandItem>
                                                ))}
                                            </CommandGroup>
                                        </CommandList>
                                    </Command>
                                </PopoverContent>
                            </Popover>
                        </div>

                        <div className="border-l pl-3 ml-1">
                            <ToggleGroup type="single" value={viewMode} onValueChange={(v) => v && setViewMode(v as 'table' | 'grid')}>
                                <ToggleGroupItem value="table" aria-label="Table view">
                                    <List className="h-4 w-4" />
                                </ToggleGroupItem>
                                <ToggleGroupItem value="grid" aria-label="Grid view">
                                    <LayoutGrid className="h-4 w-4" />
                                </ToggleGroupItem>
                            </ToggleGroup>
                        </div>
                    </div>
                </CardHeader>

                <CardContent>
                    {isLoading ? (
                        <TableSkeleton columnCount={6} rowCount={5} />
                    ) : studentsData?.length === 0 ? (
                        <EmptyState
                            title="Tidak ada siswa"
                            description={search ? 'Tidak ditemukan siswa dengan kata kunci pencarian tersebut.' : 'Belum ada data siswa.'}
                        />
                    ) : (
                        <>
                            <Table>
                                <TableHeader>
                                    <TableRow>
                                        <TableHead>Siswa</TableHead>
                                        <TableHead className="hidden md:table-cell">NISN</TableHead>
                                        <TableHead className="hidden sm:table-cell">Kelas</TableHead>
                                        <TableHead className="hidden lg:table-cell">Tempat PKL</TableHead>
                                        <TableHead className="hidden md:table-cell">Hadir Bln Ini</TableHead>
                                        <TableHead>Status</TableHead>
                                        <TableHead className="text-right">Aksi</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {studentsData?.map((student) => {
                                        const placement = student.placements?.[0] as { companies?: { name: string } } | undefined
                                        const companyName = placement?.companies?.name
                                        const attendancePct = attendanceMap.get(student.id)
                                        const isProblematic = problematicStudentIds.has(student.id)

                                        return (
                                            <TableRow
                                                key={student.id}
                                                className={cn(
                                                    'cursor-pointer hover:bg-muted/50',
                                                    isProblematic && 'bg-red-50 hover:bg-red-100 border-l-2 border-l-red-400 dark:bg-red-950/20 dark:hover:bg-red-950/30'
                                                )}
                                                onClick={() => navigate(`/monitoring/${student.id}`)}
                                            >
                                                <TableCell>
                                                    <div className="flex items-center gap-3">
                                                        <Avatar className="h-9 w-9">
                                                            <AvatarImage src={student.avatar_url || undefined} alt={student.full_name} />
                                                            <AvatarFallback className="bg-primary/10 text-primary text-xs">
                                                                {getInitials(student.full_name)}
                                                            </AvatarFallback>
                                                        </Avatar>
                                                        <div className="flex flex-col">
                                                            <div className="flex items-center gap-1.5">
                                                                <span className="font-medium text-sm">{student.full_name}</span>
                                                                {isProblematic && <TriangleAlert className="h-3.5 w-3.5 text-red-500" />}
                                                            </div>
                                                            <span className="text-xs text-muted-foreground">{student.email}</span>
                                                        </div>
                                                    </div>
                                                </TableCell>
                                                <TableCell className="hidden md:table-cell">{student.nisn || '-'}</TableCell>
                                                <TableCell className="hidden sm:table-cell">
                                                    <Badge variant="outline" className="font-normal">
                                                        {student.class_name || '-'}
                                                    </Badge>
                                                </TableCell>
                                                <TableCell className="hidden lg:table-cell">
                                                    {companyName ? (
                                                        <div className="flex items-center gap-1.5 text-sm">
                                                            <Building2 className="h-3.5 w-3.5 text-muted-foreground" />
                                                            {companyName}
                                                        </div>
                                                    ) : (
                                                        <span className="text-muted-foreground text-sm italic">Belum ada</span>
                                                    )}
                                                </TableCell>
                                                <TableCell className="hidden md:table-cell">
                                                    {attendancePct !== undefined ? (
                                                        <Badge
                                                            variant="outline"
                                                            className={cn(
                                                                'font-medium',
                                                                attendancePct >= 90 && 'bg-green-50 text-green-700 border-green-200 dark:bg-green-900/30 dark:text-green-300',
                                                                attendancePct >= 75 && attendancePct < 90 && 'bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/30 dark:text-yellow-300',
                                                                attendancePct < 75 && 'bg-red-100 text-red-700 border-red-300 dark:bg-red-900/30 dark:text-red-300'
                                                            )}
                                                        >
                                                            {attendancePct}%
                                                        </Badge>
                                                    ) : (
                                                        <span className="text-xs text-muted-foreground">-</span>
                                                    )}
                                                </TableCell>
                                                <TableCell>{getStatusBadge(student.status)}</TableCell>
                                                <TableCell className="text-right">
                                                    <Button variant="ghost" size="sm" onClick={(e) => { e.stopPropagation(); navigate(`/monitoring/${student.id}`) }}>
                                                        <Eye className="h-4 w-4 mr-2" />Detail
                                                    </Button>
                                                </TableCell>
                                            </TableRow>
                                        )
                                    })}
                                </TableBody>
                            </Table>

                            {/* Pagination */}
                            <div className="mt-4 flex items-center justify-end space-x-2">
                                <Button variant="outline" size="sm" onClick={() => setPage(p => Math.max(0, p - 1))} disabled={page === 0}>
                                    <ChevronLeft className="h-4 w-4" />Previous
                                </Button>
                                <div className="text-sm text-muted-foreground">
                                    Page {page + 1} of {Math.max(1, totalPages)}
                                </div>
                                <Button variant="outline" size="sm" onClick={() => setPage(p => p + 1)} disabled={page >= totalPages - 1}>
                                    Next<ChevronRight className="h-4 w-4" />
                                </Button>
                            </div>
                        </>
                    )}
                </CardContent>
            </Card>
        </div>
    )
}