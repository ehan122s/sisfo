import { useState, useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from "sonner"
import { flexRender, type Row } from "@tanstack/react-table"
import { supabase } from '@/lib/supabase'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
    Building2, UserPlus, Upload, Loader2, FileSpreadsheet,
    LayoutGrid, List, GraduationCap, MapPin, Hash, Users,
    ChevronRight, Search
} from 'lucide-react' 
import type { Student, Company } from '@/types'
import { TableSkeleton } from '@/components/ui/table-skeleton'

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
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { getInitials, cn } from '@/lib/utils'

// ─── Stat Card Component ─────────────────────────────────────────────────────
interface StatCardProps {
    label: string
    value: number
    icon: React.ElementType
    accentClass: string
    iconClass: string
}

function StatCard({ label, value, icon: Icon, accentClass, iconClass }: StatCardProps) {
    return (
        <Card className="relative overflow-hidden border-none shadow-sm bg-linear-to-br from-card to-muted/20">
            <div className={cn("absolute top-0 left-0 w-1 h-full", accentClass)} />
            <CardContent className="p-6">
                <div className="flex items-center justify-between">
                    <div>
                        <p className="text-sm font-medium text-muted-foreground mb-1">{label}</p>
                        <h3 className="text-3xl font-bold tracking-tight">{value}</h3>
                    </div>
                    <div className={cn("p-3 rounded-2xl", iconClass)}>
                        <Icon className="h-6 w-6" />
                    </div>
                </div>
            </CardContent>
        </Card>
    )
}

// ─── Student Card Component ──────────────────────────────────────────────────
function StudentCard({ row }: { row: Row<Student> }) {
    const student = row.original
    const placement = student.placements && student.placements.length > 0
        ? student.placements[0].companies?.name
        : undefined

    return (
        <div
            onClick={() => (window.location.href = `/monitoring/${student.id}`)}
            className={cn(
                "group relative flex flex-col rounded-2xl border bg-card p-5 cursor-pointer transition-all duration-300 hover:border-primary/50 hover:shadow-xl hover:shadow-primary/5 hover:-translate-y-1"
            )}
        >
            <div className="flex justify-between items-start mb-4">
                <Avatar className="h-14 w-14 ring-4 ring-muted transition-transform group-hover:scale-105">
                    <AvatarImage src={student.avatar_url || undefined} />
                    <AvatarFallback className="bg-primary/10 text-primary font-bold">
                        {getInitials(student.full_name)}
                    </AvatarFallback>
                </Avatar>
                {getStatusBadge(student.status)}
            </div>
            <div className="space-y-1 mb-4">
                <h3 className="font-bold text-lg leading-tight group-hover:text-primary transition-colors line-clamp-1">
                    {student.full_name}
                </h3>
                <div className="flex items-center text-muted-foreground text-sm">
                    <Hash className="h-3.5 w-3.5 mr-1" />
                    {student.nisn || '—'}
                </div>
            </div>
            <div className="mt-auto space-y-3">
                <div className="flex items-center gap-2 p-2 rounded-lg bg-muted/50">
                    <GraduationCap className="h-4 w-4 text-primary" />
                    <span className="text-xs font-medium truncate">{student.class_name || 'Tanpa Kelas'}</span>
                </div>
                <div className="flex items-center gap-2 px-2">
                    <Building2 className="h-4 w-4 text-muted-foreground shrink-0" />
                    <span className="text-xs text-muted-foreground truncate">{placement || "Belum ada tempat PKL"}</span>
                </div>
            </div>
            <div className="absolute bottom-5 right-5 opacity-0 group-hover:opacity-100 transition-opacity">
                <ChevronRight className="h-5 w-5 text-primary" />
            </div>
        </div>
    )
}

// ─── Main Page Component ─────────────────────────────────────────────────────
export function StudentsPage() {
    const [viewMode, setViewMode] = useState<'table' | 'grid'>('table')
    const [globalFilter, setGlobalFilter] = useState('')
    const [selectedStudent, setSelectedStudent] = useState<Student | null>(null)
    const [assignDialogOpen, setAssignDialogOpen] = useState(false)
    const [addDialogOpen, setAddDialogOpen] = useState(false)
    const [importDialogOpen, setImportDialogOpen] = useState(false)
    const [editDialogOpen, setEditDialogOpen] = useState(false)
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
    
    const { exportToExcel, isExporting } = useExportStudents()
    const queryClient = useQueryClient()

    const { data: students = [], isLoading } = useQuery<Student[]>({
        queryKey: ['students'],
        queryFn: async () => {
            const { data, error } = await supabase
                .from('profiles')
                .select('*, placements(companies(name))')
                .eq('role', 'student')
                .order('full_name')
            if (error) throw error
            return (data ?? []) as Student[]
        },
    })

    const { data: companies = [] } = useQuery<Company[]>({
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
            const { data: existing } = await supabase.from('placements').select().eq('student_id', studentId).maybeSingle()
            if (existing) {
                await supabase.from('placements').update({ company_id: companyId }).eq('id', existing.id)
            } else {
                await supabase.from('placements').insert({ student_id: studentId, company_id: companyId, start_date: new Date().toISOString() })
            }
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['students'] })
            setAssignDialogOpen(false)
            toast.success('DUDI berhasil di-assign')
        },
    })

    const columns = useMemo(() => getColumns({
        onEdit: (s) => { setSelectedStudent(s); setEditDialogOpen(true) },
        onDelete: (s) => { setSelectedStudent(s); setDeleteDialogOpen(true) },
        onAssign: (s) => { setSelectedStudent(s); setAssignDialogOpen(true) },
        onUpdateStatus: (id, status) => updateStatusMutation.mutate({ id, status }),
    }), [updateStatusMutation]);

    // LOGIKA FILTER MANUAL: Memastikan pencarian bekerja meski kolom tidak dikonfigurasi khusus
    const filteredStudents = useMemo(() => {
        if (!globalFilter) return students;
        const target = globalFilter.toLowerCase();
        return students.filter(s => 
            s.full_name?.toLowerCase().includes(target) || 
            s.nisn?.toLowerCase().includes(target) ||
            s.class_name?.toLowerCase().includes(target)
        );
    }, [students, globalFilter]);

    const activeCount = students.filter(s => s.status === 'active').length
    const placedCount = students.filter(s => s.placements && s.placements.length > 0).length
    const unplacedCount = students.length - placedCount

    return (
        <div className="container mx-auto max-w-7xl space-y-8 py-8 animate-in fade-in duration-500">
            <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
                <div>
                    <Badge variant="outline" className="mb-2 px-3 py-0.5 text-primary border-primary/20 bg-primary/5">Siswa & Penempatan</Badge>
                    <h1 className="text-4xl font-extrabold tracking-tight">Manajemen Siswa</h1>
                </div>
                <div className="flex flex-wrap items-center gap-3">
                    <div className="flex items-center gap-2 bg-muted/50 p-1.5 rounded-xl border">
                        <Button variant="ghost" size="sm" onClick={exportToExcel} disabled={isExporting}>
                            {isExporting ? <Loader2 className="h-4 w-4 animate-spin" /> : <FileSpreadsheet className="h-4 w-4 mr-2" />} Export
                        </Button>
                        <Button variant="ghost" size="sm" onClick={() => setImportDialogOpen(true)}><Upload className="h-4 w-4 mr-2" /> Import</Button>
                    </div>
                    <Button onClick={() => setAddDialogOpen(true)} className="rounded-xl px-6"><UserPlus className="h-4 w-4 mr-2" /> Tambah Siswa</Button>
                </div>
            </div>

            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <StatCard label="Total Siswa" value={students.length} icon={Users} accentClass="bg-blue-500" iconClass="bg-blue-500/10 text-blue-600" />
                <StatCard label="Siswa Aktif" value={activeCount} icon={GraduationCap} accentClass="bg-emerald-500" iconClass="bg-emerald-500/10 text-emerald-600" />
                <StatCard label="Sudah Penempatan" value={placedCount} icon={Building2} accentClass="bg-violet-500" iconClass="bg-violet-500/10 text-violet-600" />
                <StatCard label="Menunggu PKL" value={unplacedCount} icon={MapPin} accentClass="bg-orange-500" iconClass="bg-orange-500/10 text-orange-600" />
            </div>

            <div className="flex flex-col sm:flex-row items-center justify-between gap-4 border-b pb-4">
                <div className="flex items-center gap-4 w-full sm:w-auto">
                    <div className="relative flex-1 sm:min-w-75">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <input
                            type="text"
                            placeholder="Cari nama atau NISN siswa..."
                            value={globalFilter}
                            onChange={(e) => setGlobalFilter(e.target.value)}
                            className="h-10 w-full rounded-full border bg-background pl-10 pr-4 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                        />
                    </div>
                </div>
                <ToggleGroup type="single" value={viewMode} onValueChange={(v) => v && setViewMode(v as 'table' | 'grid')} className="bg-muted/50 p-1 rounded-xl border">
                    <ToggleGroupItem value="table" className="rounded-lg px-4"><List className="h-4 w-4 mr-2" /> Table</ToggleGroupItem>
                    <ToggleGroupItem value="grid" className="rounded-lg px-4"><LayoutGrid className="h-4 w-4 mr-2" /> Grid</ToggleGroupItem>
                </ToggleGroup>
            </div>

            <div className="min-h-100">
                {isLoading ? (
                    <TableSkeleton columnCount={7} rowCount={6} />
                ) : (
                    <DataTable
                        columns={columns}
                        data={filteredStudents} 
                        toolbar={DataTableToolbar}
                    >
                        {(table) => {
                            const rows = table.getRowModel().rows
                            if (viewMode === 'table') {
                                return (
                                    <Card className="border-none shadow-sm overflow-hidden rounded-2xl">
                                        <Table>
                                            <TableHeader className="bg-muted/50">
                                                {table.getHeaderGroups().map((hg) => (
                                                    <TableRow key={hg.id}>
                                                        {hg.headers.map((header) => (
                                                            <TableHead key={header.id} className="h-12 font-bold text-foreground">
                                                                {flexRender(header.column.columnDef.header, header.getContext())}
                                                            </TableHead>
                                                        ))}
                                                    </TableRow>
                                                ))}
                                            </TableHeader>
                                            <TableBody>
                                                {rows.length > 0 ? rows.map((row) => (
                                                    <TableRow key={row.id}>
                                                        {row.getVisibleCells().map((cell) => (
                                                            <TableCell key={cell.id} className="py-4">{flexRender(cell.column.columnDef.cell, cell.getContext())}</TableCell>
                                                        ))}
                                                    </TableRow>
                                                )) : (
                                                    <TableRow>
                                                        <TableCell colSpan={columns.length} className="h-24 text-center text-muted-foreground italic">Data siswa tidak ditemukan.</TableCell>
                                                    </TableRow>
                                                )}
                                            </TableBody>
                                        </Table>
                                        <div className="p-4 border-t"><DataTablePagination table={table} /></div>
                                    </Card>
                                )
                            }
                            return (
                                <div className="space-y-6">
                                    <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
                                        {rows.map((row) => <StudentCard key={row.id} row={row} />)}
                                    </div>
                                    <DataTablePagination table={table} />
                                </div>
                            )
                        }}
                    </DataTable>
                )}
            </div>

            <AddStudentDialog open={addDialogOpen} onOpenChange={setAddDialogOpen} />
            <ImportStudentDialog open={importDialogOpen} onOpenChange={setImportDialogOpen} />
            <EditStudentDialog open={editDialogOpen} onOpenChange={setEditDialogOpen} student={selectedStudent} />
            <DeleteStudentDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen} student={selectedStudent} />

            <Dialog open={assignDialogOpen} onOpenChange={setAssignDialogOpen}>
                <DialogContent className="sm:max-w-md rounded-3xl">
                    <DialogHeader><DialogTitle className="text-2xl font-bold">Pilih Penempatan</DialogTitle></DialogHeader>
                    <div className="space-y-2 max-h-87.5 overflow-y-auto mt-4 pr-2">
                        {companies.map((company) => (
                            <button
                                key={company.id}
                                onClick={() => selectedStudent && assignPlacementMutation.mutate({ studentId: selectedStudent.id, companyId: company.id })}
                                className="w-full flex items-center justify-between p-3 rounded-xl border hover:bg-primary/5 transition-all text-left"
                            >
                                <span className="text-sm font-semibold">{company.name}</span>
                                <ChevronRight className="h-4 w-4" />
                            </button>
                        ))}
                    </div>
                </DialogContent>
            </Dialog>
        </div>
    )

}