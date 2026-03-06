import { useState, useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { UserCheck, Pencil, Trash2, Plus, Search } from 'lucide-react'
import {
    Card,
    CardContent,
    CardHeader,
    CardTitle,
    CardDescription,
} from '@/components/ui/card'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group'
import { TableSkeleton } from '@/components/ui/table-skeleton'
import { getAllClasses, getHomeroomAssignments, type HomeroomAssignment } from '../services/homeroom-service'
import { AssignHomeroomDialog } from '../components/assign-homeroom-dialog'
import { RemoveHomeroomDialog } from '../components/remove-homeroom-dialog'

type GradeFilter = 'all' | 'X' | 'XI' | 'XII'

export function HomeroomPage() {
    const [search, setSearch] = useState('')
    const [gradeFilter, setGradeFilter] = useState<GradeFilter>('all')
    const [assignOpen, setAssignOpen] = useState(false)
    const [removeOpen, setRemoveOpen] = useState(false)
    const [selectedClass, setSelectedClass] = useState<{ name: string; teacherId?: string; teacherName?: string } | null>(null)

    const { data: allClasses = [], isLoading: loadingClasses } = useQuery({
        queryKey: ['all-classes'],
        queryFn: getAllClasses,
        staleTime: 1000 * 60 * 10,
    })

    const { data: assignments = [], isLoading: loadingAssignments } = useQuery({
        queryKey: ['homeroom-assignments'],
        queryFn: getHomeroomAssignments,
        staleTime: 1000 * 60 * 2,
    })

    const isLoading = loadingClasses || loadingAssignments

    // Build assignment map for O(1) lookup
    const assignmentMap = useMemo(() => {
        const m = new Map<string, HomeroomAssignment>()
        assignments.forEach((a) => m.set(a.class_name, a))
        return m
    }, [assignments])

    // Merge classes + assignments
    const rows = useMemo(() => {
        return allClasses.map((cls) => ({
            class_name: cls,
            assignment: assignmentMap.get(cls) ?? null,
        }))
    }, [allClasses, assignmentMap])

    // Filter rows
    const filteredRows = useMemo(() => {
        return rows.filter(({ class_name }) => {
            const matchSearch = class_name.toLowerCase().includes(search.toLowerCase())
            if (!matchSearch) return false

            if (gradeFilter === 'all') return true
            if (gradeFilter === 'XII') return class_name.startsWith('XII')
            if (gradeFilter === 'XI') return class_name.startsWith('XI') && !class_name.startsWith('XII')
            if (gradeFilter === 'X') return class_name.startsWith('X') && !class_name.startsWith('XI') && !class_name.startsWith('XII')
            return true
        })
    }, [rows, search, gradeFilter])

    const assignedCount = useMemo(() => rows.filter((r) => r.assignment).length, [rows])
    const unassignedCount = rows.length - assignedCount

    function openAssign(className: string, currentTeacherId?: string) {
        setSelectedClass({ name: className, teacherId: currentTeacherId })
        setAssignOpen(true)
    }

    function openRemove(className: string, teacherName: string) {
        setSelectedClass({ name: className, teacherName })
        setRemoveOpen(true)
    }

    const getGradeBadge = (className: string) => {
        if (className.startsWith('XII')) return <Badge variant="secondary" className="text-xs">XII</Badge>
        if (className.startsWith('XI')) return <Badge variant="outline" className="text-xs">XI</Badge>
        return <Badge variant="outline" className="text-xs text-blue-600 border-blue-200 bg-blue-50">X</Badge>
    }

    return (
        <div className="flex flex-col gap-6">
            {/* Header */}
            <div className="flex items-start justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Wali Kelas</h1>
                    <p className="text-muted-foreground">
                        Kelola penugasan wali kelas untuk setiap rombongan belajar.
                    </p>
                </div>
            </div>

            {/* Stats cards */}
            <div className="grid grid-cols-3 gap-4">
                <Card>
                    <CardContent className="pt-6">
                        <div className="flex items-center gap-3">
                            <div className="rounded-lg bg-primary/10 p-2">
                                <UserCheck className="h-5 w-5 text-primary" />
                            </div>
                            <div>
                                <p className="text-2xl font-bold">{rows.length}</p>
                                <p className="text-sm text-muted-foreground">Total Kelas</p>
                            </div>
                        </div>
                    </CardContent>
                </Card>
                <Card>
                    <CardContent className="pt-6">
                        <div className="flex items-center gap-3">
                            <div className="rounded-lg bg-green-100 p-2">
                                <UserCheck className="h-5 w-5 text-green-600" />
                            </div>
                            <div>
                                <p className="text-2xl font-bold text-green-600">{assignedCount}</p>
                                <p className="text-sm text-muted-foreground">Sudah Ditugaskan</p>
                            </div>
                        </div>
                    </CardContent>
                </Card>
                <Card>
                    <CardContent className="pt-6">
                        <div className="flex items-center gap-3">
                            <div className="rounded-lg bg-amber-100 p-2">
                                <UserCheck className="h-5 w-5 text-amber-600" />
                            </div>
                            <div>
                                <p className="text-2xl font-bold text-amber-600">{unassignedCount}</p>
                                <p className="text-sm text-muted-foreground">Belum Ditugaskan</p>
                            </div>
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Table card */}
            <Card>
                <CardHeader>
                    <div className="flex items-center justify-between gap-4">
                        <div>
                            <CardTitle>Daftar Kelas</CardTitle>
                            <CardDescription className="mt-1">
                                {filteredRows.length} kelas ditampilkan
                            </CardDescription>
                        </div>
                    </div>
                    {/* Filters */}
                    <div className="flex flex-col gap-3 pt-2 sm:flex-row sm:items-center">
                        <div className="relative flex-1 max-w-xs">
                            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                            <Input
                                placeholder="Cari kelas..."
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                                className="pl-9"
                            />
                        </div>
                        <ToggleGroup
                            type="single"
                            value={gradeFilter}
                            onValueChange={(v) => v && setGradeFilter(v as GradeFilter)}
                            className="justify-start"
                        >
                            <ToggleGroupItem value="all" className="text-xs px-3">Semua</ToggleGroupItem>
                            <ToggleGroupItem value="X" className="text-xs px-3">Kelas X</ToggleGroupItem>
                            <ToggleGroupItem value="XI" className="text-xs px-3">Kelas XI</ToggleGroupItem>
                            <ToggleGroupItem value="XII" className="text-xs px-3">Kelas XII</ToggleGroupItem>
                        </ToggleGroup>
                    </div>
                </CardHeader>
                <CardContent className="p-0">
                    {isLoading ? (
                        <div className="p-6">
                            <TableSkeleton columnCount={4} rowCount={8} />
                        </div>
                    ) : (
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead className="pl-6">Kelas / Rombel</TableHead>
                                    <TableHead>Tingkat</TableHead>
                                    <TableHead>Wali Kelas</TableHead>
                                    <TableHead className="text-right pr-6">Aksi</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {filteredRows.length === 0 ? (
                                    <TableRow>
                                        <TableCell colSpan={4} className="py-12 text-center text-muted-foreground">
                                            Tidak ada kelas yang ditemukan.
                                        </TableCell>
                                    </TableRow>
                                ) : (
                                    filteredRows.map(({ class_name, assignment }) => (
                                        <TableRow key={class_name}>
                                            <TableCell className="pl-6 font-medium">{class_name}</TableCell>
                                            <TableCell>{getGradeBadge(class_name)}</TableCell>
                                            <TableCell>
                                                {assignment ? (
                                                    <span className="font-medium">{assignment.teacher_name}</span>
                                                ) : (
                                                    <Badge variant="outline" className="text-amber-600 border-amber-200 bg-amber-50 text-xs">
                                                        Belum Ditugaskan
                                                    </Badge>
                                                )}
                                            </TableCell>
                                            <TableCell className="text-right pr-6">
                                                <div className="flex items-center justify-end gap-2">
                                                    {assignment ? (
                                                        <>
                                                            <Button
                                                                variant="ghost"
                                                                size="sm"
                                                                onClick={() => openAssign(class_name, assignment.teacher_id)}
                                                            >
                                                                <Pencil className="h-4 w-4 mr-1" />
                                                                Ganti
                                                            </Button>
                                                            <Button
                                                                variant="ghost"
                                                                size="sm"
                                                                className="text-destructive hover:text-destructive hover:bg-destructive/10"
                                                                onClick={() => openRemove(class_name, assignment.teacher_name)}
                                                            >
                                                                <Trash2 className="h-4 w-4 mr-1" />
                                                                Hapus
                                                            </Button>
                                                        </>
                                                    ) : (
                                                        <Button
                                                            variant="outline"
                                                            size="sm"
                                                            onClick={() => openAssign(class_name)}
                                                        >
                                                            <Plus className="h-4 w-4 mr-1" />
                                                            Tugaskan
                                                        </Button>
                                                    )}
                                                </div>
                                            </TableCell>
                                        </TableRow>
                                    ))
                                )}
                            </TableBody>
                        </Table>
                    )}
                </CardContent>
            </Card>

            {/* Dialogs */}
            {selectedClass && (
                <>
                    <AssignHomeroomDialog
                        open={assignOpen}
                        onOpenChange={setAssignOpen}
                        className={selectedClass.name}
                        currentTeacherId={selectedClass.teacherId}
                    />
                    <RemoveHomeroomDialog
                        open={removeOpen}
                        onOpenChange={setRemoveOpen}
                        className={selectedClass.name}
                        teacherName={selectedClass.teacherName ?? ''}
                    />
                </>
            )}
        </div>
    )
}
