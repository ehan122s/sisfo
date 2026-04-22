import { useState, useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from "sonner"
import { flexRender } from "@tanstack/react-table"
import { supabase } from '@/lib/supabase'
import { Card, CardContent } from '@/components/ui/card'
import { Button, buttonVariants } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
    Building2, UserPlus, Upload, Loader2, FileSpreadsheet,
    LayoutGrid, List, GraduationCap, MapPin, Hash, Users
} from 'lucide-react'
import type { Student, Company } from '@/types'
import { TableSkeleton } from '@/components/ui/table-skeleton'
import { EmptyState } from '@/components/ui/empty-state'
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table'
import { DataTable } from '@/components/ui/data-table/data-table'
import { DataTablePagination } from '@/components/ui/data-table/data-table-pagination'
import { getColumns, getStatusBadge } from './components/columns'
import { DataTableToolbar } from './components/data-table-toolbar'
import { AddStudentDialog } from './components/add-student-dialog'
import { ImportStudentDialog } from './components/import-student-dialog'
import { EditStudentDialog } from './components/edit-student-dialog'
import { DeleteStudentDialog } from './components/delete-student-dialog'
import { useExportStudents } from './hooks/use-export-students'
import { AuditLogService } from '@/features/audit-logs/services/audit-log-service'
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog'
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { getInitials } from '@/lib/utils'
import { cn } from '@/lib/utils'

// ─── Stat Card ───────────────────────────────────────────────────────────────
function StatCard({
    label,
    value,
    icon: Icon,
    accent,
}: {
    label: string
    value: number
    icon: React.ElementType
    accent?: string
}) {
    return (
        <div className={cn(
            "relative flex flex-col gap-3 rounded-xl border bg-card px-5 py-4 overflow-hidden",
            "transition-shadow hover:shadow-sm"
        )}>
            {/* subtle accent strip on the left */}
            <div className={cn("absolute left-0 inset-y-0 w-[3px] rounded-l-xl", accent ?? "bg-primary/40")} />
            <div className="flex items-center justify-between">
                <span className="text-xs font-medium uppercase tracking-widest text-muted-foreground">
                    {label}
                </span>
                <span className={cn(
                    "flex h-7 w-7 items-center justify-center rounded-lg",
                    "bg-blue-50 dark:bg-blue-950/40 text-blue-500 dark:text-blue-400"
                )}>
                    <Icon className="h-3.5 w-3.5" />
                </span>
            </div>
            <span className="text-2xl font-semibold tabular-nums text-foreground leading-none">
                {value}
            </span>
        </div>
    )
}

// ─── Student Card (grid view) ─────────────────────────────────────────────────
function StudentCard({ row }: { row: any }) {
    const student = row.original as Student
    const placement = row.getValue("placement") as string | undefined

    return (
        <div
            onClick={() => (window.location.href = `/monitoring/${student.id}`)}
            className={cn(
                "group relative flex flex-col gap-4 rounded-xl border bg-card px-5 py-5",
                "cursor-pointer transition-all duration-200",
                "hover:border-blue-400/50 hover:shadow-md hover:shadow-blue-500/5 hover:-translate-y-0.5"
            )}
        >
            {/* header */}
            <div className="flex items-start justify-between gap-2">
                <div className="flex items-center gap-3 min-w-0">
                    <Avatar className="h-11 w-11 shrink-0 ring-2 ring-border ring-offset-1 ring-offset-card">
                        <AvatarImage src={student.avatar_url || undefined} />
                        <AvatarFallback className="bg-blue-100 dark:bg-blue-900/40 text-blue-700 dark:text-blue-300 text-xs font-semibold">
                            {getInitials(student.full_name)}
                        </AvatarFallback>
                    </Avatar>
                    <div className="min-w-0">
                        <p className="truncate text-sm font-semibold text-foreground leading-snug group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                            {student.full_name}
                        </p>
                        <p className="text-xs text-muted-foreground mt-0.5 flex items-center gap-1">
                            <Hash className="h-3 w-3 shrink-0" />
                            {student.nisn || '—'}
                        </p>
                    </div>
                </div>
                {getStatusBadge(student.status)}
            </div>

            {/* divider */}
            <div className="h-px bg-border" />

            {/* meta */}
            <div className="flex flex-col gap-2">
                <div className="flex items-center gap-2 text-xs">
                    <GraduationCap className="h-3.5 w-3.5 text-muted-foreground shrink-0" />
                    {student.class_name ? (
                        <Badge variant="secondary" className="font-normal text-xs py-0 h-5">
                            {student.class_name}
                        </Badge>
                    ) : (
                        <span className="text-muted-foreground">—</span>
                    )}
                </div>
                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <MapPin className="h-3.5 w-3.5 shrink-0" />
                    <span className="truncate">
                        {placement || (
                            <span className="italic text-muted-foreground/60">Belum ada tempat PKL</span>
                        )}
                    </span>
                </div>
            </div>
        </div>
    )
}

// ─── Main Page ────────────────────────────────────────────────────────────────
export function StudentsPage() {
    const [viewMode, setViewMode] = useState<'table' | 'grid'>('table')
    const [selectedStudent, setSelectedStudent] = useState<Student | null>(null)
    const [assignDialogOpen, setAssignDialogOpen] = useState(false)
    const [addDialogOpen, setAddDialogOpen] = useState(false)
    const [importDialogOpen, setImportDialogOpen] = useState(false)
    const [editDialogOpen, setEditDialogOpen] = useState(false)
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
    const [bulkDeleteDialogOpen, setBulkDeleteDialogOpen] = useState(false)
    const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())

    const { exportToExcel, isExporting } = useExportStudents()
    const queryClient = useQueryClient()

    const { data: students = [], isLoading } = useQuery({
        queryKey: ['students'],
        queryFn: async () => {
            const PAGE_SIZE = 1000
            let allData: Student[] = []
            let from = 0
            let hasMore = true
            while (hasMore) {
                const { data, error } = await supabase
                    .from('profiles')
                    .select('*, placements(companies(name))')
                    .eq('role', 'student')
                    .order('full_name')
                    .range(from, from + PAGE_SIZE - 1)
                if (error) throw error
                allData = allData.concat((data ?? []) as Student[])
                hasMore = (data?.length ?? 0) === PAGE_SIZE
                from += PAGE_SIZE
            }
            return allData
        },
    })

    const { data: companies = [] } = useQuery({
        queryKey: ['companies'],
        queryFn: async () => {
            const { data } = await supabase.from('companies').select('*').order('name')
            return (data ?? []) as Company[]
        },
    })

    const updateStatusMutation = useMutation({
        mutationFn: async ({ id, status }: { id: string; status: string }) => {
            const { error } = await supabase.from('profiles').update({ status }).eq('id', id)
            if (error) throw error
            await AuditLogService.logAction('UPDATE_STATUS', 'profiles', id, { new_status: status })
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['students'] })
            toast.success('Status siswa diperbarui')
        },
    })

    const assignPlacementMutation = useMutation({
        mutationFn: async ({ studentId, companyId }: { studentId: string; companyId: number }) => {
            const { data: existing } = await supabase
                .from('placements').select().eq('student_id', studentId).maybeSingle()
            if (existing) {
                await supabase.from('placements').update({ company_id: companyId }).eq('id', existing.id)
            } else {
                await supabase.from('placements').insert({
                    student_id: studentId,
                    company_id: companyId,
                    start_date: new Date().toISOString(),
                })
            }
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['students'] })
            setAssignDialogOpen(false)
            toast.success('DUDI berhasil di-assign')
        },
    })

    const bulkDeleteMutation = useMutation({
        mutationFn: async (ids: string[]) => {
            const { error } = await supabase.from('profiles').update({ status: 'suspended' }).in('id', ids)
            if (error) throw error
            await AuditLogService.logAction('BULK_DELETE', 'profiles', 'multiple', { count: ids.length, ids })
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['students'] })
            setSelectedIds(new Set())
            setBulkDeleteDialogOpen(false)
            toast.success('Siswa berhasil dinonaktifkan')
        },
    })

    const columns = useMemo(() => getColumns({
        onEdit: (s) => { setSelectedStudent(s); setEditDialogOpen(true) },
        onDelete: (s) => { setSelectedStudent(s); setDeleteDialogOpen(true) },
        onAssign: (s) => { setSelectedStudent(s); setAssignDialogOpen(true) },
        onUpdateStatus: (id, status) => updateStatusMutation.mutate({ id, status }),
    }), [])

    // derived stats
    const activeCount = students.filter(s => s.status === 'active').length
    const placedCount = students.filter(s => (s as any).placements?.length > 0).length
    const unplacedCount = students.length - placedCount

    return (
        <div className="space-y-7 pb-8">

            {/* ── Page header ─────────────────────────────────────────────── */}
            <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
                <div>
                    <p className="text-xs font-semibold uppercase tracking-widest text-muted-foreground mb-1">
                        E-PKL
                    </p>
                    <h1 className="text-2xl font-bold tracking-tight text-foreground">
                        Manajemen Siswa
                    </h1>
                    <p className="text-sm text-muted-foreground mt-1">
                        Kelola data siswa, penempatan PKL, dan status akun.
                    </p>
                </div>

                <div className="flex flex-wrap items-center gap-2">
                    {selectedIds.size > 0 && (
                        <Button
                            variant="destructive"
                            size="sm"
                            onClick={() => setBulkDeleteDialogOpen(true)}
                            className="gap-1.5"
                        >
                            Hapus ({selectedIds.size})
                        </Button>
                    )}
                    <Button
                        variant="outline"
                        size="sm"
                        onClick={exportToExcel}
                        disabled={isExporting}
                        className="gap-1.5"
                    >
                        {isExporting
                            ? <Loader2 className="h-3.5 w-3.5 animate-spin" />
                            : <FileSpreadsheet className="h-3.5 w-3.5" />}
                        Export
                    </Button>
                    <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setImportDialogOpen(true)}
                        className="gap-1.5"
                    >
                        <Upload className="h-3.5 w-3.5" />
                        Import
                    </Button>
                    <Button
                        size="sm"
                        onClick={() => setAddDialogOpen(true)}
                        className="gap-1.5 bg-blue-600 hover:bg-blue-700 text-white border-0"
                    >
                        <UserPlus className="h-3.5 w-3.5" />
                        Tambah Siswa
                    </Button>
                </div>
            </div>

            {/* ── Stat cards ──────────────────────────────────────────────── */}
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
                <StatCard label="Total Siswa"  value={students.length} icon={Users}          accent="bg-blue-500" />
                <StatCard label="Aktif"         value={activeCount}     icon={GraduationCap}  accent="bg-blue-400" />
                <StatCard label="Sudah PKL"     value={placedCount}     icon={Building2}      accent="bg-blue-300" />
                <StatCard label="Belum PKL"     value={unplacedCount}   icon={MapPin}         accent="bg-blue-200 dark:bg-blue-700" />
            </div>

            {/* ── Table / grid ─────────────────────────────────────────────── */}
            <div className="space-y-4">
                <div className="flex items-center justify-between gap-2">
                    <Badge variant="outline" className="text-xs bg-background px-3 py-1 rounded-full">
                        {students.length} Siswa
                    </Badge>
                    <ToggleGroup
                        type="single"
                        value={viewMode}
                        onValueChange={(v) => v && setViewMode(v as 'table' | 'grid')}
                        className="border rounded-lg p-0.5 bg-muted/50"
                    >
                        <ToggleGroupItem
                            value="table"
                            className="h-7 w-7 p-0 rounded-md data-[state=on]:bg-background data-[state=on]:shadow-sm"
                        >
                            <List className="h-3.5 w-3.5" />
                        </ToggleGroupItem>
                        <ToggleGroupItem
                            value="grid"
                            className="h-7 w-7 p-0 rounded-md data-[state=on]:bg-background data-[state=on]:shadow-sm"
                        >
                            <LayoutGrid className="h-3.5 w-3.5" />
                        </ToggleGroupItem>
                    </ToggleGroup>
                </div>

                {isLoading ? (
                    <TableSkeleton columnCount={7} rowCount={5} />
                ) : students.length === 0 ? (
                    <Card className="border-dashed bg-card">
                        <CardContent className="pt-6">
                            <EmptyState
                                title="Tidak ada siswa"
                                description="Belum ada data siswa."
                            />
                        </CardContent>
                    </Card>
                ) : (
                    <DataTable
                        columns={columns}
                        data={students}
                        toolbar={DataTableToolbar}
                        pageSize={45}
                    >
                        {(table) => {
                            const rows = table.getRowModel().rows

                            if (rows.length === 0) {
                                return (
                                    <Card className="border-dashed bg-card">
                                        <CardContent className="pt-6">
                                            <EmptyState
                                                title="Tidak ditemukan"
                                                description="Tidak ada data yang cocok dengan filter."
                                            />
                                        </CardContent>
                                    </Card>
                                )
                            }

                            if (viewMode === 'table') {
                                return (
                                    <div className="space-y-4">
                                        <div className="rounded-xl border overflow-hidden bg-card">
                                            <Table>
                                                <TableHeader>
                                                    <tr className="border-b bg-muted/40">
                                                        {table.getHeaderGroups().map((hg) =>
                                                            hg.headers.map((header) => (
                                                                <TableHead
                                                                    key={header.id}
                                                                    className="text-xs font-semibold uppercase tracking-wider text-muted-foreground h-10"
                                                                >
                                                                    {flexRender(header.column.columnDef.header, header.getContext())}
                                                                </TableHead>
                                                            ))
                                                        )}
                                                    </tr>
                                                </TableHeader>
                                                <TableBody>
                                                    {rows.map((row) => (
                                                        <TableRow
                                                            key={row.id}
                                                            className="hover:bg-muted/30 transition-colors"
                                                        >
                                                            {row.getVisibleCells().map((cell) => (
                                                                <TableCell key={cell.id} className="py-3 text-sm">
                                                                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                                                                </TableCell>
                                                            ))}
                                                        </TableRow>
                                                    ))}
                                                </TableBody>
                                            </Table>
                                        </div>
                                        <DataTablePagination table={table} />
                                    </div>
                                )
                            }

                            // Grid view
                            return (
                                <div className="space-y-4">
                                    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                                        {rows.map((row) => (
                                            <StudentCard key={row.id} row={row} />
                                        ))}
                                    </div>
                                    <DataTablePagination table={table} />
                                </div>
                            )
                        }}
                    </DataTable>
                )}
            </div>

            {/* ── Dialogs ──────────────────────────────────────────────────── */}
            <AddStudentDialog    open={addDialogOpen}    onOpenChange={setAddDialogOpen} />
            <ImportStudentDialog open={importDialogOpen} onOpenChange={setImportDialogOpen} />
            <EditStudentDialog   open={editDialogOpen}   onOpenChange={setEditDialogOpen}   student={selectedStudent} />
            <DeleteStudentDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen} student={selectedStudent} />

            <Dialog open={assignDialogOpen} onOpenChange={setAssignDialogOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Assign DUDI — {selectedStudent?.full_name}</DialogTitle>
                    </DialogHeader>
                    <div className="space-y-1.5 max-h-[400px] overflow-y-auto pr-1 mt-4">
                        {companies.map((company) => (
                            <Button
                                key={company.id}
                                variant="outline"
                                className={cn(
                                    "w-full justify-start gap-2 font-normal text-sm",
                                    "hover:bg-blue-50 dark:hover:bg-blue-950/30 hover:text-blue-700 dark:hover:text-blue-300 hover:border-blue-300/50 transition-colors"
                                )}
                                onClick={() => {
                                    if (selectedStudent) {
                                        assignPlacementMutation.mutate({
                                            studentId: selectedStudent.id,
                                            companyId: company.id,
                                        })
                                    }
                                }}
                            >
                                <Building2 className="h-4 w-4 shrink-0 text-muted-foreground" />
                                {company.name}
                            </Button>
                        ))}
                    </div>
                </DialogContent>
            </Dialog>

            <AlertDialog open={bulkDeleteDialogOpen} onOpenChange={setBulkDeleteDialogOpen}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>Nonaktifkan {selectedIds.size} Siswa?</AlertDialogTitle>
                        <AlertDialogDescription>
                            Status mereka akan diubah menjadi <strong>Suspended</strong>. Aksi ini bisa dibatalkan nanti.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel>Batal</AlertDialogCancel>
                        <AlertDialogAction
                            onClick={() => bulkDeleteMutation.mutate(Array.from(selectedIds))}
                            className={buttonVariants({ variant: "destructive" })}
                        >
                            Nonaktifkan
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </div>
    )
}