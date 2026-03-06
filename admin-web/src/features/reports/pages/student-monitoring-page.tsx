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
import { Search, ChevronLeft, ChevronRight, CheckCircle, MinusCircle, AlertCircle, Clock, Building2, Eye, LayoutGrid, List, Check, ChevronsUpDown, TriangleAlert } from 'lucide-react'
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

    // Fetch current month attendance summary for all students (for alert feature)
    const currentMonth = new Date().getMonth()
    const currentYear = new Date().getFullYear()
    const { data: attendanceSummary = [] } = useQuery({
        queryKey: ['attendance-summary-all', currentMonth, currentYear],
        queryFn: () => getMonthlyAttendanceReport(currentMonth, currentYear),
        staleTime: 1000 * 60 * 10, // 10 min cache
    })

    // Build Map<studentId, percentage> and identify problematic students (< 75%)
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

    // Fetch students
    const { data: studentsResult, isLoading } = useQuery({
        queryKey: ['students-monitoring', page, search, statusFilter, companyFilter, classFilter, showProblematic],
        queryFn: async () => {
            // When "showProblematic" is active, filter by known problematic IDs
            if (showProblematic && problematicStudentIds.size > 0) {
                const ids = Array.from(problematicStudentIds)
                let query = supabase
                    .from('profiles')
                    .select('*, placements(companies(name))', { count: 'exact' })
                    .eq('role', 'student')
                    .ilike('class_name', 'XII%')
                    .in('id', ids)
                    .order('full_name')
                const { data, count, error } = await query
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

    // Fetch class list (XII only — monitoring is PKL-specific)
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

    // Fetch companies for filter
    const { data: companies = [] } = useQuery({
        queryKey: ['companies'],
        queryFn: async () => {
            const { data } = await supabase
                .from('companies')
                .select('*')
                .order('name')
            return (data ?? []) as Company[]
        },
    })

    // Reset page when filters change
    const handleSearchChange = (value: string) => {
        setSearch(value)
        setPage(0)
    }

    const handleStatusFilterChange = (value: string) => {
        setStatusFilter(value)
        setPage(0)
    }

    const handleCompanyFilterChange = (value: string) => {
        setCompanyFilter(value)
        setPage(0)
    }

    const handleClassFilterChange = (value: string) => {
        setClassFilter(value)
        setPage(0)
    }

    // Helper for status badge with icon
    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'active':
                return (
                    <Badge className="bg-green-100 text-green-700 hover:bg-green-200 border-green-200 flex w-fit items-center gap-1">
                        <CheckCircle className="h-3 w-3" />
                        Aktif
                    </Badge>
                )
            case 'inactive':
                return (
                    <Badge variant="secondary" className="bg-gray-100 text-gray-700 hover:bg-gray-200 flex w-fit items-center gap-1">
                        <MinusCircle className="h-3 w-3" />
                        Non-aktif
                    </Badge>
                )
            case 'completed':
                return (
                    <Badge className="bg-blue-100 text-blue-700 hover:bg-blue-200 border-blue-200 flex w-fit items-center gap-1">
                        <CheckCircle className="h-3 w-3" />
                        Selesai
                    </Badge>
                )
            case 'suspended':
                return (
                    <Badge variant="destructive" className="flex w-fit items-center gap-1">
                        <AlertCircle className="h-3 w-3" />
                        Suspended
                    </Badge>
                )
            default: // pending or others
                return (
                    <Badge variant="outline" className="text-yellow-600 border-yellow-300 bg-yellow-50 flex w-fit items-center gap-1">
                        <Clock className="h-3 w-3" />
                        Pending
                    </Badge>
                )
        }
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold">Monitoring Siswa PKL</h1>
                    <p className="text-muted-foreground">
                        Pantau aktivitas jurnal dan absensi siswa kelas XII (Program PKL).
                    </p>
                </div>
            </div>

            {/* Alert card for problematic students */}
            {problematicStudentIds.size > 0 && (
                <Card className="border-red-200 bg-red-50">
                    <CardContent className="p-4">
                        <div className="flex items-center justify-between gap-4">
                            <div className="flex items-center gap-3">
                                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-red-100">
                                    <TriangleAlert className="h-5 w-5 text-red-600" />
                                </div>
                                <div>
                                    <CardTitle className="text-sm text-red-800">
                                        {problematicStudentIds.size} siswa kehadiran &lt; 75% bulan ini
                                    </CardTitle>
                                    <CardDescription className="text-xs text-red-600">
                                        Siswa berisiko tidak memenuhi syarat kelulusan PKL
                                    </CardDescription>
                                </div>
                            </div>
                            <Button
                                size="sm"
                                variant={showProblematic ? 'destructive' : 'outline'}
                                className={showProblematic ? '' : 'border-red-300 text-red-700 hover:bg-red-100'}
                                onClick={() => { setShowProblematic(p => !p); setPage(0) }}
                            >
                                {showProblematic ? 'Tampilkan Semua' : 'Lihat Bermasalah'}
                            </Button>
                        </div>
                    </CardContent>
                </Card>
            )}

            <Card>
                <CardHeader>
                    <div className="flex items-center gap-4">
                        <div className="relative flex-1">
                            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                            <Input
                                placeholder="Cari nama, NISN, atau kelas..."
                                value={search}
                                onChange={(e) => handleSearchChange(e.target.value)}
                                className="pl-10"
                            />
                        </div>
                        <div className="w-[180px]">
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
                        <div className="w-[200px]">
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
                        <div className="w-[180px]">
                            <Popover open={openClassFilter} onOpenChange={setOpenClassFilter}>
                                <PopoverTrigger asChild>
                                    <Button
                                        variant="outline"
                                        role="combobox"
                                        aria-expanded={openClassFilter}
                                        className="w-full justify-between"
                                    >
                                        {classFilter && classFilter !== 'all'
                                            ? classList.find((c) => c === classFilter)
                                            : "Semua Kelas"}
                                        <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                                    </Button>
                                </PopoverTrigger>
                                <PopoverContent className="w-[200px] p-0">
                                    <Command>
                                        <CommandInput placeholder="Cari kelas..." />
                                        <CommandList>
                                            <CommandEmpty>Kelas tidak ditemukan.</CommandEmpty>
                                            <CommandGroup>
                                                <CommandItem
                                                    value="all"
                                                    onSelect={() => {
                                                        handleClassFilterChange("all")
                                                        setOpenClassFilter(false)
                                                    }}
                                                >
                                                    <Check
                                                        className={cn(
                                                            "mr-2 h-4 w-4",
                                                            classFilter === "" || classFilter === "all" ? "opacity-100" : "opacity-0"
                                                        )}
                                                    />
                                                    Semua Kelas
                                                </CommandItem>
                                                {classList.map((cls) => (
                                                    <CommandItem
                                                        key={cls}
                                                        value={cls}
                                                        onSelect={(currentValue) => {
                                                            handleClassFilterChange(currentValue === classFilter ? "" : currentValue)
                                                            setOpenClassFilter(false)
                                                        }}
                                                    >
                                                        <Check
                                                            className={cn(
                                                                "mr-2 h-4 w-4",
                                                                classFilter === cls ? "opacity-100" : "opacity-0"
                                                            )}
                                                        />
                                                        {cls}
                                                    </CommandItem>
                                                ))}
                                            </CommandGroup>
                                        </CommandList>
                                    </Command>
                                </PopoverContent>
                            </Popover>
                        </div>

                        <div className="border-l pl-4 ml-2">
                            <ToggleGroup type="single" value={viewMode} onValueChange={(value) => value && setViewMode(value as 'table' | 'grid')}>
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
                            description={search ? "Tidak ditemukan siswa dengan kata kunci pencarian tersebut." : "Belum ada data siswa."}
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
                                                    isProblematic && 'bg-red-50 hover:bg-red-100 border-l-2 border-l-red-400'
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
                                                                attendancePct >= 90 && 'bg-green-50 text-green-700 border-green-200',
                                                                attendancePct >= 75 && attendancePct < 90 && 'bg-yellow-50 text-yellow-700 border-yellow-200',
                                                                attendancePct < 75 && 'bg-red-100 text-red-700 border-red-300'
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
                                                    <Button variant="ghost" size="sm" onClick={(e) => {
                                                        e.stopPropagation()
                                                        navigate(`/monitoring/${student.id}`)
                                                    }}>
                                                        <Eye className="h-4 w-4 mr-2" />
                                                        Detail
                                                    </Button>
                                                </TableCell>
                                            </TableRow>
                                        )
                                    })}
                                </TableBody>
                            </Table>

                            {/* Pagination */}
                            <div className="mt-4 flex items-center justify-end space-x-2">
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => setPage((p) => Math.max(0, p - 1))}
                                    disabled={page === 0}
                                >
                                    <ChevronLeft className="h-4 w-4" />
                                    Previous
                                </Button>
                                <div className="text-sm text-muted-foreground">
                                    Page {page + 1} of {Math.max(1, totalPages)}
                                </div>
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => setPage((p) => p + 1)}
                                    disabled={page >= totalPages - 1}
                                >
                                    Next
                                    <ChevronRight className="h-4 w-4" />
                                </Button>
                            </div>
                        </>
                    )}
                </CardContent>
            </Card >
        </div >
    )
}
