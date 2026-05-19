import { useState, useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from "sonner"
import { flexRender, type Row } from "@tanstack/react-table"
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
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

// ─── Stat Card ────────────────────────────────────────────────────────────────

interface StatCardProps {
    label: string
    value: number
    total: number
    icon: React.ElementType
    accent: string
    iconBg: string
    numColor: string
    bar: string
    barBg: string
}

function StatCard({ label, value, total, icon: Icon, accent, iconBg, numColor, bar, barBg }: StatCardProps) {
    const pct = total > 0 ? Math.round((value / total) * 100) : 0
    return (
        <div className={cn(
            'relative rounded-2xl bg-white border border-slate-100 border-t-[3px] shadow-sm',
            'dark:bg-[#111b30] dark:border-white/5 dark:border-t-[3px]',
            'p-4',
            accent
        )}>
            <div className="flex items-start justify-between mb-3">
                <div>
                    <p className="text-[10px] font-bold tracking-widest text-slate-400 dark:text-slate-500 uppercase mb-1">
                        {label}
                    </p>
                    <p className={cn('text-3xl font-black leading-none', numColor)}>
                        {value}
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
}

// ─── Student Card (grid view) ─────────────────────────────────────────────────

function StudentCard({ row }: { row: Row<Student> }) {
    const student = row.original
    const placement = student.placements && student.placements.length > 0
        ? student.placements[0].companies?.name
        : undefined

    return (
        <div
            onClick={() => (window.location.href = `/monitoring/${student.id}`)}
            className="group relative flex flex-col rounded-2xl border border-slate-100 dark:border-white/5 bg-white dark:bg-[#111b30] p-5 cursor-pointer transition-all duration-300 hover:border-blue-200 dark:hover:border-blue-500/30 shadow-sm hover:shadow-md hover:-translate-y-1 overflow-hidden"
        >
            {/* Top accent line on hover */}
            <div className="absolute top-0 left-0 right-0 h-[3px] bg-blue-600 dark:bg-blue-500 opacity-0 group-hover:opacity-100 transition-opacity rounded-t-2xl" />

            <div className="flex justify-between items-start mb-4">
                <Avatar className="h-12 w-12 ring-2 ring-white dark:ring-white/5">
                    <AvatarImage src={student.avatar_url || undefined} />
                    <AvatarFallback className="bg-blue-50 dark:bg-blue-500/15 text-blue-700 dark:text-blue-400 font-black text-sm">
                        {getInitials(student.full_name)}
                    </AvatarFallback>
                </Avatar>
                {getStatusBadge(student.status)}
            </div>

            <div className="space-y-0.5 mb-4">
                <h3 className="font-bold text-sm text-slate-800 dark:text-white truncate">
                    {student.full_name}
                </h3>
                <div className="flex items-center text-slate-400 dark:text-slate-500 text-[10px] font-semibold tracking-widest uppercase">
                    <Hash className="h-2.5 w-2.5 mr-1" /> {student.nisn || '-'}
                </div>
            </div>

            <div className="mt-auto space-y-2">
                <div className="flex items-center gap-2 px-2.5 py-2 rounded-lg bg-slate-50 dark:bg-white/[0.03] border border-slate-100 dark:border-white/5">
                    <GraduationCap className="h-3.5 w-3.5 text-blue-500 shrink-0" />
                    <span className="text-[11px] font-bold text-slate-700 dark:text-slate-300 uppercase tracking-tight truncate">
                        {student.class_name || 'Reguler'}
                    </span>
                </div>
                <div className="flex items-center gap-2 px-1">
                    <Building2 className="h-3 w-3 text-slate-400 dark:text-slate-600 shrink-0" />
                    <span className="text-[11px] text-slate-400 dark:text-slate-500 truncate">
                        {placement || 'Belum ditempatkan'}
                    </span>
                </div>
            </div>

            <ChevronRight className="absolute bottom-4 right-4 h-4 w-4 text-blue-500 opacity-0 group-hover:opacity-100 translate-x-1 group-hover:translate-x-0 transition-all" />
        </div>
    )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

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
    }), [updateStatusMutation])

    const filteredStudents = useMemo(() => {
        if (!globalFilter) return students
        const target = globalFilter.toLowerCase()
        return students.filter(s =>
            s.full_name?.toLowerCase().includes(target) ||
            s.nisn?.toLowerCase().includes(target) ||
            s.class_name?.toLowerCase().includes(target)
        )
    }, [students, globalFilter])

    const activeCount = students.filter(s => s.status === 'active').length
    const placedCount = students.filter(s => s.placements && s.placements.length > 0).length
    const unplacedCount = students.length - placedCount

    return (
        <div className="min-h-screen bg-slate-50 dark:bg-[#070b14] -m-6 p-6 space-y-5">

            {/* ── HEADER ── */}
            <div className="space-y-5">
                {/* Title row */}
                <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                        <div className="flex items-center gap-2 mb-3">
                            <div className="h-1 w-8 rounded-full bg-blue-600 dark:bg-blue-500" />
                            <div className="h-1 w-3 rounded-full bg-blue-300 dark:bg-blue-700" />
                        </div>
                        <h1 className="text-4xl font-black italic uppercase tracking-tight leading-none text-slate-900 dark:text-white">
                            MANAJEMEN{' '}
                            <span className="text-blue-600 dark:text-blue-400">SISWA</span>
                        </h1>
                        <p className="mt-2 text-sm font-medium text-slate-400 dark:text-slate-500">
                            Kelola data dan penempatan siswa PKL
                        </p>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-3 self-start flex-wrap">
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={exportToExcel}
                            disabled={isExporting}
                            className="rounded-xl border-slate-200 bg-white shadow-sm text-slate-600 hover:bg-slate-50 gap-2 font-semibold dark:border-white/10 dark:bg-white/5 dark:text-slate-300"
                        >
                            {isExporting
                                ? <Loader2 className="h-4 w-4 animate-spin" />
                                : <FileSpreadsheet className="h-4 w-4 text-emerald-500" />}
                            EXPORT
                        </Button>
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={() => setImportDialogOpen(true)}
                            className="rounded-xl border-slate-200 bg-white shadow-sm text-slate-600 hover:bg-slate-50 gap-2 font-semibold dark:border-white/10 dark:bg-white/5 dark:text-slate-300"
                        >
                            <Upload className="h-4 w-4 text-blue-500" /> IMPORT
                        </Button>
                        <Button
                            onClick={() => setAddDialogOpen(true)}
                            className="rounded-xl bg-blue-600 text-white hover:bg-blue-700 font-black uppercase tracking-wide px-5 h-10 gap-2 shadow-sm shadow-blue-200 dark:bg-blue-500 dark:hover:bg-blue-400 dark:shadow-blue-500/20"
                        >
                            <UserPlus className="h-4 w-4" /> Tambah Siswa
                        </Button>
                    </div>
                </div>

                {/* Stat Cards */}
                {students.length > 0 && !isLoading && (
                    <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
                        <StatCard
                            label="Total Siswa" value={students.length} total={students.length}
                            icon={Users}
                            accent="border-t-blue-500"
                            iconBg="bg-blue-50 text-blue-600 dark:bg-blue-500/15 dark:text-blue-400"
                            numColor="text-blue-600 dark:text-blue-400"
                            bar="bg-blue-500" barBg="bg-blue-100 dark:bg-blue-500/10"
                        />
                        <StatCard
                            label="Siswa Aktif" value={activeCount} total={students.length}
                            icon={GraduationCap}
                            accent="border-t-emerald-500"
                            iconBg="bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400"
                            numColor="text-emerald-600 dark:text-emerald-400"
                            bar="bg-emerald-500" barBg="bg-emerald-100 dark:bg-emerald-500/10"
                        />
                        <StatCard
                            label="Sudah Penempatan" value={placedCount} total={students.length}
                            icon={Building2}
                            accent="border-t-sky-500"
                            iconBg="bg-sky-50 text-sky-600 dark:bg-sky-500/15 dark:text-sky-400"
                            numColor="text-sky-600 dark:text-sky-400"
                            bar="bg-sky-500" barBg="bg-sky-100 dark:bg-sky-500/10"
                        />
                        <StatCard
                            label="Belum Penempatan" value={unplacedCount} total={students.length}
                            icon={MapPin}
                            accent="border-t-amber-500"
                            iconBg="bg-amber-50 text-amber-600 dark:bg-amber-500/15 dark:text-amber-400"
                            numColor="text-amber-600 dark:text-amber-400"
                            bar="bg-amber-500" barBg="bg-amber-100 dark:bg-amber-500/10"
                        />
                    </div>
                )}
            </div>

            {/* ── Main Panel ── */}
            <div className="rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-white/5 dark:bg-[#0d1526]">

                {/* Toolbar: search + view toggle */}
                <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between px-5 py-3 border-b border-slate-100 bg-slate-50/80 dark:border-white/5 dark:bg-white/[0.02]">
                    <div className="relative flex-1 max-w-sm">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400 dark:text-slate-500 pointer-events-none" />
                        <input
                            type="text"
                            placeholder="Cari nama, NISN, atau kelas..."
                            value={globalFilter}
                            onChange={(e) => setGlobalFilter(e.target.value)}
                            className="w-full pl-9 pr-4 h-9 rounded-xl text-sm border border-slate-200 dark:border-white/10 bg-white dark:bg-white/5 text-slate-800 dark:text-white placeholder:text-slate-400 dark:placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500/30"
                        />
                    </div>
                    <ToggleGroup
                        type="single"
                        value={viewMode}
                        onValueChange={(v) => v && setViewMode(v as 'table' | 'grid')}
                        className="bg-blue-50 border border-blue-100 dark:bg-white/5 dark:border-white/5 p-1 rounded-xl h-auto self-start sm:self-auto"
                    >
                        <ToggleGroupItem
                            value="table"
                            className="gap-1.5 rounded-lg text-sm px-4 py-2 font-bold uppercase tracking-wide text-slate-500 data-[state=on]:bg-blue-600 data-[state=on]:text-white dark:text-slate-400 dark:data-[state=on]:bg-blue-500"
                        >
                            <List className="h-3.5 w-3.5" /> List
                        </ToggleGroupItem>
                        <ToggleGroupItem
                            value="grid"
                            className="gap-1.5 rounded-lg text-sm px-4 py-2 font-bold uppercase tracking-wide text-slate-500 data-[state=on]:bg-blue-600 data-[state=on]:text-white dark:text-slate-400 dark:data-[state=on]:bg-blue-500"
                        >
                            <LayoutGrid className="h-3.5 w-3.5" /> Grid
                        </ToggleGroupItem>
                    </ToggleGroup>
                </div>

                {/* Content */}
                <div className="p-5">
                    {isLoading ? (
                        <TableSkeleton columnCount={7} rowCount={6} />
                    ) : (
                        <DataTable columns={columns} data={filteredStudents} toolbar={DataTableToolbar}>
                            {(table) => {
                                const rows = table.getRowModel().rows
                                if (viewMode === 'table') {
                                    return (
                                        <div className="rounded-xl border border-slate-100 dark:border-white/5 overflow-hidden">
                                            <Table>
                                                <TableHeader className="bg-slate-50/80 dark:bg-white/[0.02]">
                                                    {table.getHeaderGroups().map((hg) => (
                                                        <TableRow key={hg.id} className="border-slate-100 dark:border-white/5 hover:bg-transparent">
                                                            {hg.headers.map((header) => (
                                                                <TableHead key={header.id} className="h-11 font-bold uppercase text-[10px] tracking-widest text-slate-400 dark:text-slate-500 px-4">
                                                                    {flexRender(header.column.columnDef.header, header.getContext())}
                                                                </TableHead>
                                                            ))}
                                                        </TableRow>
                                                    ))}
                                                </TableHeader>
                                                <TableBody>
                                                    {rows.length > 0 ? rows.map((row) => (
                                                        <TableRow key={row.id} className="border-slate-50 dark:border-white/[0.03] hover:bg-blue-50/40 dark:hover:bg-white/[0.03] transition-colors">
                                                            {row.getVisibleCells().map((cell) => (
                                                                <TableCell key={cell.id} className="py-3 px-4 text-sm text-slate-700 dark:text-slate-300 font-medium">
                                                                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                                                                </TableCell>
                                                            ))}
                                                        </TableRow>
                                                    )) : (
                                                        <TableRow>
                                                            <TableCell colSpan={columns.length} className="h-40 text-center text-slate-400 dark:text-slate-600 text-sm">
                                                                Tidak ada data siswa.
                                                            </TableCell>
                                                        </TableRow>
                                                    )}
                                                </TableBody>
                                            </Table>
                                            <div className="px-4 py-3 border-t border-slate-100 dark:border-white/5 bg-slate-50/50 dark:bg-white/[0.01]">
                                                <DataTablePagination table={table} />
                                            </div>
                                        </div>
                                    )
                                }
                                return (
                                    <div className="space-y-5">
                                        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                                            {rows.map((row) => <StudentCard key={row.id} row={row} />)}
                                        </div>
                                        <div className="px-4 py-3 rounded-xl border border-slate-100 dark:border-white/5 bg-slate-50/50 dark:bg-white/[0.02]">
                                            <DataTablePagination table={table} />
                                        </div>
                                    </div>
                                )
                            }}
                        </DataTable>
                    )}
                </div>
            </div>

            {/* ── Dialogs (unchanged) ── */}
            <AddStudentDialog open={addDialogOpen} onOpenChange={setAddDialogOpen} />
            <ImportStudentDialog open={importDialogOpen} onOpenChange={setImportDialogOpen} />
            <EditStudentDialog open={editDialogOpen} onOpenChange={setEditDialogOpen} student={selectedStudent} />
            <DeleteStudentDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen} student={selectedStudent} />

            <Dialog open={assignDialogOpen} onOpenChange={setAssignDialogOpen}>
                <DialogContent className="sm:max-w-md rounded-2xl bg-white dark:bg-[#0d1526] border-slate-200 dark:border-white/10">
                    <DialogHeader>
                        <DialogTitle className="text-xl font-black italic uppercase tracking-tight">PILIH <span className="text-blue-600 dark:text-blue-400">PENEMPATAN</span>
                        </DialogTitle>
                    </DialogHeader>
                    <div className="space-y-2 max-h-96 overflow-y-auto mt-4 pr-1">
                        {companies.map((company) => (
                            <button
                                key={company.id}
                                onClick={() => selectedStudent && assignPlacementMutation.mutate({ studentId: selectedStudent.id, companyId: company.id })}
                                className="w-full flex items-center justify-between px-4 py-3 rounded-xl border border-slate-100 dark:border-white/5 bg-slate-50 dark:bg-white/[0.03] hover:bg-blue-50 dark:hover:bg-blue-500/10 hover:border-blue-200 dark:hover:border-blue-500/30 transition-colors text-left group"
                            >
                                <div className="flex items-center gap-3">
                                    <div className="h-8 w-8 rounded-lg bg-blue-50 dark:bg-blue-500/15 flex items-center justify-center shrink-0">
                                        <Building2 className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                                    </div>
                                    <span className="text-sm font-semibold text-slate-700 dark:text-slate-300">{company.name}</span>
                                </div>
                                <ChevronRight className="h-4 w-4 text-slate-300 dark:text-slate-600 group-hover:text-blue-500 transition-colors" />
                            </button>
                        ))}
                    </div>
                </DialogContent>
            </Dialog>
        </div>
    )
}