import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { Search, UserCog, MoreHorizontal, Pencil, Trash2, ChevronLeft, ChevronRight, UserPlus } from 'lucide-react'
import { TeacherService, type Teacher } from '../services/teacher-service'
import { TeacherDialog } from '../components/teacher-dialog'
import { DeleteTeacherDialog } from '../components/delete-teacher-dialog'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table"
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { TableSkeleton } from '@/components/ui/table-skeleton'
import { EmptyState } from '@/components/ui/empty-state'

export function TeachersPage() {
    const queryClient = useQueryClient()
    const [page, setPage] = useState(0)
    const [search, setSearch] = useState('')
    const pageSize = 10

    // Dialog states
    const [addDialogOpen, setAddDialogOpen] = useState(false)
    const [editDialogOpen, setEditDialogOpen] = useState(false)
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
    const [selectedTeacher, setSelectedTeacher] = useState<Teacher | null>(null)

    // Fetch teachers with TanStack Query
    const { data: teachersResult, isLoading } = useQuery({
        queryKey: ['teachers', page, search],
        queryFn: () => TeacherService.getTeachers(page, pageSize, search)
    })

    const teachers = teachersResult?.data || []
    const totalCount = teachersResult?.count || 0
    const totalPages = Math.ceil(totalCount / pageSize)

    // Reset page when search changes
    const handleSearchChange = (value: string) => {
        setSearch(value)
        setPage(0)
    }

    const handleEdit = (teacher: Teacher) => {
        setSelectedTeacher(teacher)
        setEditDialogOpen(true)
    }

    const handleDelete = (teacher: Teacher) => {
        setSelectedTeacher(teacher)
        setDeleteDialogOpen(true)
    }

    const handleSuccess = () => {
        queryClient.invalidateQueries({ queryKey: ['teachers'] })
        setAddDialogOpen(false)
        setEditDialogOpen(false)
        setSelectedTeacher(null)
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Manajemen Pembimbing</h1>
                    <p className="text-muted-foreground">
                        Kelola akun guru pembimbing dan penempatan pengawasan DUDI.
                    </p>
                </div>
                <Button onClick={() => setAddDialogOpen(true)} data-shortcut="new">
                    <UserPlus className="mr-2 h-4 w-4" />
                    Tambah Pembimbing
                </Button>
            </div>

            <Card>
                <CardHeader>
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <CardTitle>Daftar Pembimbing</CardTitle>
                            <Badge variant="outline" className="text-sm">
                                {totalCount} Total
                            </Badge>
                        </div>
                        <div className="relative w-64">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                placeholder="Cari nama pembimbing..."
                                value={search}
                                onChange={(e) => handleSearchChange(e.target.value)}
                                className="pl-8"
                            />
                        </div>
                    </div>
                </CardHeader>
                <CardContent>
                    {isLoading ? (
                        <TableSkeleton columnCount={3} rowCount={5} />
                    ) : teachers.length === 0 ? (
                        <EmptyState
                            title="Tidak ada pembimbing"
                            description={search ? "Tidak ditemukan pembimbing dengan kata kunci tersebut." : "Belum ada data pembimbing yang ditambahkan."}
                        />
                    ) : (
                        <>
                            <div className="rounded-md border">
                                <Table>
                                    <TableHeader>
                                        <TableRow>
                                            <TableHead>Nama Pembimbing</TableHead>
                                            <TableHead>Perusahaan Binaan</TableHead>
                                            <TableHead className="text-right w-[100px]">Aksi</TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {teachers.map((teacher) => (
                                            <TableRow key={teacher.id}>
                                                <TableCell className="font-medium">
                                                    <div className="flex items-center gap-3">
                                                        <div className="h-9 w-9 rounded-full bg-primary/10 flex items-center justify-center">
                                                            <UserCog className="h-4 w-4 text-primary" />
                                                        </div>
                                                        <div className="flex flex-col">
                                                            <span>{teacher.full_name}</span>
                                                            {teacher.email && (
                                                                <span className="text-xs text-muted-foreground">{teacher.email}</span>
                                                            )}
                                                        </div>
                                                    </div>
                                                </TableCell>
                                                <TableCell>
                                                    <div className="flex flex-wrap gap-1">
                                                        {teacher.assignments && teacher.assignments.length > 0 ? (
                                                            teacher.assignments.map(a => (
                                                                <Badge key={a.id} variant="secondary" className="font-normal">
                                                                    {a.company?.name || 'Unknown'}
                                                                </Badge>
                                                            ))
                                                        ) : (
                                                            <span className="text-muted-foreground text-sm italic">Belum ada penempatan</span>
                                                        )}
                                                    </div>
                                                </TableCell>
                                                <TableCell className="text-right">
                                                    <DropdownMenu>
                                                        <DropdownMenuTrigger asChild>
                                                            <Button variant="ghost" className="h-8 w-8 p-0">
                                                                <span className="sr-only">Open menu</span>
                                                                <MoreHorizontal className="h-4 w-4" />
                                                            </Button>
                                                        </DropdownMenuTrigger>
                                                        <DropdownMenuContent align="end">
                                                            <DropdownMenuLabel>Aksi</DropdownMenuLabel>

                                                            <DropdownMenuSeparator />
                                                            <DropdownMenuItem onClick={() => handleEdit(teacher)}>
                                                                <Pencil className="mr-2 h-4 w-4" />
                                                                Edit
                                                            </DropdownMenuItem>
                                                            <DropdownMenuItem
                                                                className="text-red-600 focus:text-red-600 focus:bg-red-50"
                                                                onClick={() => handleDelete(teacher)}
                                                            >
                                                                <Trash2 className="mr-2 h-4 w-4" />
                                                                Hapus
                                                            </DropdownMenuItem>
                                                        </DropdownMenuContent>
                                                    </DropdownMenu>
                                                </TableCell>
                                            </TableRow>
                                        ))}
                                    </TableBody>
                                </Table>
                            </div>

                            {/* Pagination */}
                            {totalPages > 1 && (
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
                                        Page {page + 1} of {totalPages}
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
                            )}
                        </>
                    )}
                </CardContent>
            </Card>

            {/* Dialogs */}
            <TeacherDialog
                open={addDialogOpen}
                onOpenChange={setAddDialogOpen}
                onSuccess={handleSuccess}
            />

            <TeacherDialog
                open={editDialogOpen}
                onOpenChange={setEditDialogOpen}
                teacher={selectedTeacher || undefined}
                onSuccess={handleSuccess}
            />

            <DeleteTeacherDialog
                open={deleteDialogOpen}
                onOpenChange={setDeleteDialogOpen}
                teacher={selectedTeacher}
            />
        </div>
    )
}
