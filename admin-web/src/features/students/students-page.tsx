import { useState, useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from "sonner"
import { flexRender } from "@tanstack/react-table"
import { supabase } from '@/lib/supabase'
import { Card, CardContent } from '@/components/ui/card'
import { Button, buttonVariants } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Building2, UserPlus, Upload, Loader2, FileSpreadsheet, LayoutGrid, List } from 'lucide-react'
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

    // Fetch all students (paginated to bypass PostgREST max-rows=1000 limit)
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

    // Fetch companies for assign dialog
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

    // Mutations
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
                .from('placements')
                .select()
                .eq('student_id', studentId)
                .maybeSingle()

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

    // Table columns
    const columns = useMemo(() => getColumns({
        onEdit: (s) => { setSelectedStudent(s); setEditDialogOpen(true); },
        onDelete: (s) => { setSelectedStudent(s); setDeleteDialogOpen(true); },
        onAssign: (s) => { setSelectedStudent(s); setAssignDialogOpen(true); },
        onUpdateStatus: (id, status) => updateStatusMutation.mutate({ id, status })
    }), [])

    return (
        <div className="space-y-6">
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Manajemen Siswa</h1>
                    <p className="text-muted-foreground mt-1">Kelola data siswa, penempatan PKL, dan status akun.</p>
                </div>
                <div className="flex flex-wrap gap-2">
                    {selectedIds.size > 0 && (
                        <Button
                            variant="destructive"
                            onClick={() => setBulkDeleteDialogOpen(true)}
                        >
                            Hapus ({selectedIds.size})
                        </Button>
                    )}
                    <Button variant="outline" onClick={exportToExcel} disabled={isExporting}>
                        {isExporting ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : <FileSpreadsheet className="h-4 w-4 mr-2" />}
                        Export
                    </Button>
                    <Button onClick={() => setImportDialogOpen(true)} variant="outline">
                        <Upload className="h-4 w-4 mr-2" />
                        Import
                    </Button>
                    <Button
                        onClick={() => setAddDialogOpen(true)}
                    >
                        <UserPlus className="h-4 w-4 mr-2" />
                        Tambah Siswa
                    </Button>
                </div>
            </div>

            <div className="space-y-4">
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                        <ToggleGroup type="single" value={viewMode} onValueChange={(v) => v && setViewMode(v as any)}>
                            <ToggleGroupItem value="table" className="h-9 w-9 p-0 border border-input bg-background">
                                <List className="h-4 w-4" />
                            </ToggleGroupItem>
                            <ToggleGroupItem value="grid" className="h-9 w-9 p-0 border border-input bg-background">
                                <LayoutGrid className="h-4 w-4" />
                            </ToggleGroupItem>
                        </ToggleGroup>
                        <Badge variant="outline" className="text-sm bg-background">
                            {students.length} Total
                        </Badge>
                    </div>
                </div>

                {isLoading ? (
                    <TableSkeleton columnCount={7} rowCount={5} />
                ) : students.length === 0 ? (
                    <Card className="bg-background border-dashed">
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
                                    <Card className="bg-background border-dashed">
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
                                        <div className="rounded-md border overflow-hidden bg-background">
                                            <Table>
                                                <TableHeader className="bg-muted/50 text-xs">
                                                    {table.getHeaderGroups().map((headerGroup) => (
                                                        <TableRow key={headerGroup.id}>
                                                            {headerGroup.headers.map((header) => (
                                                                <TableHead key={header.id}>
                                                                    {flexRender(header.column.columnDef.header, header.getContext())}
                                                                </TableHead>
                                                            ))}
                                                        </TableRow>
                                                    ))}
                                                </TableHeader>
                                                <TableBody>
                                                    {rows.map((row) => (
                                                        <TableRow key={row.id}>
                                                            {row.getVisibleCells().map((cell) => (
                                                                <TableCell key={cell.id}>
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

                            return (
                                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                                    {rows.map((row) => {
                                        const student = row.original
                                        return (
                                            <Card key={student.id} className="bg-background hover:shadow-md transition-shadow cursor-pointer overflow-hidden group" onClick={() => window.location.href = `/monitoring/${student.id}`}>
                                                <CardContent className="p-5">
                                                    <div className="flex items-start justify-between">
                                                        <div className="flex items-center gap-3">
                                                            <Avatar className="h-12 w-12 border-2 border-primary/10">
                                                                <AvatarImage src={student.avatar_url || undefined} />
                                                                <AvatarFallback className="bg-primary/5 text-primary">
                                                                    {getInitials(student.full_name)}
                                                                </AvatarFallback>
                                                            </Avatar>
                                                            <div>
                                                                <h3 className="font-semibold text-sm leading-tight group-hover:text-primary transition-colors">{student.full_name}</h3>
                                                                <p className="text-xs text-muted-foreground mt-0.5">{student.nisn || 'No NISN'}</p>
                                                            </div>
                                                        </div>
                                                        {getStatusBadge(student.status)}
                                                    </div>
                                                    <div className="mt-4 space-y-2">
                                                        <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                                            <Badge variant="secondary" className="font-normal">{student.class_name || '-'}</Badge>
                                                        </div>
                                                        <div className="flex items-center gap-2 text-sm">
                                                            <Building2 className="h-4 w-4 text-muted-foreground shrink-0" />
                                                            <span className="truncate">
                                                                {(row.getValue("placement") as string) || 'Belum ada tempat PKL'}
                                                            </span>
                                                        </div>
                                                    </div>
                                                </CardContent>
                                            </Card>
                                        )
                                    })}
                                </div>
                            )
                        }}
                    </DataTable>
                )}
            </div>

            {/* Dialogs */}
            <AddStudentDialog open={addDialogOpen} onOpenChange={setAddDialogOpen} />
            <ImportStudentDialog open={importDialogOpen} onOpenChange={setImportDialogOpen} />
            <EditStudentDialog open={editDialogOpen} onOpenChange={setEditDialogOpen} student={selectedStudent} />
            <DeleteStudentDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen} student={selectedStudent} />
            
            <Dialog open={assignDialogOpen} onOpenChange={setAssignDialogOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Assign DUDI - {selectedStudent?.full_name}</DialogTitle>
                    </DialogHeader>
                    <div className="space-y-2 max-h-[400px] overflow-y-auto pr-2 mt-4">
                        {companies.map((company) => (
                            <Button
                                key={company.id}
                                variant="outline"
                                className="w-full justify-start font-normal hover:bg-primary/5 hover:text-primary hover:border-primary/20"
                                onClick={() => {
                                    if (selectedStudent) {
                                        assignPlacementMutation.mutate({
                                            studentId: selectedStudent.id,
                                            companyId: company.id,
                                        })
                                    }
                                }}
                            >
                                <Building2 className="mr-2 h-4 w-4 opacity-50" />
                                {company.name}
                            </Button>
                        ))}
                    </div>
                </DialogContent>
            </Dialog>

            <AlertDialog open={bulkDeleteDialogOpen} onOpenChange={setBulkDeleteDialogOpen}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>Hapus {selectedIds.size} Siswa?</AlertDialogTitle>
                        <AlertDialogDescription>
                            Status mereka akan diubah menjadi <strong>Suspended</strong>.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel>Batal</AlertDialogCancel>
                        <AlertDialogAction
                            onClick={() => bulkDeleteMutation.mutate(Array.from(selectedIds))}
                            className={buttonVariants({ variant: "destructive" })}
                        >
                            Hapus
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </div>
    )
}
