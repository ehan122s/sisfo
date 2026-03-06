import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table'
import { Plus, Pencil, ChevronLeft, ChevronRight, Search, Trash2, MapPin, Upload, MoreHorizontal, Users } from 'lucide-react'
import type { Company } from '@/types'
import { Badge } from '@/components/ui/badge'
import { TableSkeleton } from '@/components/ui/table-skeleton'
import { EmptyState } from '@/components/ui/empty-state'
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { AddCompanyDialog } from './components/add-company-dialog'
import { EditCompanyDialog } from './components/edit-company-dialog'
import { DeleteCompanyDialog } from './components/delete-company-dialog'
import { ImportCompanyDialog } from './components/import-company-dialog'

export function CompaniesPage() {
    const [page, setPage] = useState(0)
    const [search, setSearch] = useState('')
    const [addDialogOpen, setAddDialogOpen] = useState(false)
    const [editDialogOpen, setEditDialogOpen] = useState(false)
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
    const [importDialogOpen, setImportDialogOpen] = useState(false)
    const [selectedCompany, setSelectedCompany] = useState<Company | null>(null)
    const pageSize = 10

    // Fetch companies
    const { data: companiesResult, isLoading } = useQuery({
        queryKey: ['companies', page, search],
        queryFn: async () => {
            const start = page * pageSize
            const end = start + pageSize - 1

            let query = supabase
                .from('companies')
                .select('*, placements(count)', { count: 'exact' })
                .order('name')

            if (search) {
                query = query.ilike('name', `%${search}%`)
            }

            const { data, count, error } = await query.range(start, end)

            if (error) throw error

            return { data: (data ?? []) as Company[], count: count ?? 0 }
        },
    })

    const companies = companiesResult?.data || []
    const totalCount = companiesResult?.count || 0
    const totalPages = Math.ceil(totalCount / pageSize)

    const handleEdit = (company: Company) => {
        setSelectedCompany(company)
        setEditDialogOpen(true)
    }

    const handleDelete = (company: Company) => {
        setSelectedCompany(company)
        setDeleteDialogOpen(true)
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Manajemen DUDI</h1>
                    <p className="text-muted-foreground">Kelola data perusahaan/industri mitra PKL.</p>
                </div>
                <div className="flex gap-2">
                    <Button variant="outline" onClick={() => setImportDialogOpen(true)}>
                        <Upload className="mr-2 h-4 w-4" />
                        Import CSV
                    </Button>
                    <Button onClick={() => setAddDialogOpen(true)} data-shortcut="new">
                        <Plus className="mr-2 h-4 w-4" />
                        Tambah DUDI
                    </Button>
                </div>
            </div>

            <Card>
                <CardHeader>
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <CardTitle>Daftar Perusahaan</CardTitle>
                            <Badge variant="outline" className="text-sm">
                                {totalCount} Total
                            </Badge>
                        </div>
                        <div className="relative w-64">
                            <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                placeholder="Cari perusahaan..."
                                value={search}
                                onChange={(e) => {
                                    setSearch(e.target.value)
                                    setPage(0)
                                }}
                                className="pl-8"
                            />
                        </div>
                    </div>
                </CardHeader>
                <CardContent>
                    {isLoading ? (
                        <TableSkeleton columnCount={5} rowCount={5} />
                    ) : (
                        <>
                            <Table>
                                <TableHeader>
                                    <TableRow>
                                        <TableHead>Nama</TableHead>
                                        <TableHead className="text-center w-[100px]">Siswa</TableHead>
                                        <TableHead className="hidden md:table-cell">Alamat</TableHead>
                                        <TableHead className="hidden lg:table-cell">Lokasi</TableHead>
                                        <TableHead className="hidden lg:table-cell">Radius (m)</TableHead>
                                        <TableHead className="text-right">Aksi</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {companies.length === 0 ? (
                                        <TableRow>
                                            <TableCell colSpan={5} className="p-0 border-none">
                                                <EmptyState
                                                    title="Tidak ada DUDI"
                                                    description={search ? "Tidak ditemukan perusahaan dengan kata kunci tersebut." : "Belum ada data perusahaan."}
                                                />
                                            </TableCell>
                                        </TableRow>
                                    ) : (
                                        companies.map((company) => (
                                            <TableRow key={company.id}>
                                                <TableCell className="font-medium">{company.name}</TableCell>
                                                <TableCell className="text-center">
                                                    <Badge variant="secondary" className="gap-1">
                                                        <Users className="h-3 w-3" />
                                                        {/* @ts-ignore */}
                                                        {company.placements?.[0]?.count || 0}
                                                    </Badge>
                                                </TableCell>
                                                <TableCell className="max-w-[200px] truncate hidden md:table-cell" title={company.address}>
                                                    {company.address || '-'}
                                                </TableCell>
                                                <TableCell className="hidden lg:table-cell">
                                                    {company.latitude && company.longitude ? (
                                                        <a
                                                            href={`https://www.google.com/maps?q=${company.latitude},${company.longitude}`}
                                                            target="_blank"
                                                            rel="noopener noreferrer"
                                                            className="flex items-center text-blue-600 hover:underline gap-1 text-xs"
                                                        >
                                                            <MapPin className="h-3 w-3" />
                                                            {company.latitude.toFixed(4)}, {company.longitude.toFixed(4)}
                                                        </a>
                                                    ) : (
                                                        <span className="text-muted-foreground">-</span>
                                                    )}
                                                </TableCell>
                                                <TableCell className="hidden lg:table-cell">{company.radius_meter || 100}</TableCell>
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
                                                            <DropdownMenuItem onClick={() => handleEdit(company)}>
                                                                <Pencil className="mr-2 h-4 w-4" />
                                                                Edit
                                                            </DropdownMenuItem>
                                                            <DropdownMenuItem
                                                                className="text-red-600 focus:text-red-600 focus:bg-red-50"
                                                                onClick={() => handleDelete(company)}
                                                            >
                                                                <Trash2 className="mr-2 h-4 w-4" />
                                                                Hapus
                                                            </DropdownMenuItem>
                                                        </DropdownMenuContent>
                                                    </DropdownMenu>
                                                </TableCell>
                                            </TableRow>
                                        ))
                                    )}
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
            </Card>

            {/* Dialogs */}
            <AddCompanyDialog
                open={addDialogOpen}
                onOpenChange={setAddDialogOpen}
            />

            <EditCompanyDialog
                open={editDialogOpen}
                onOpenChange={setEditDialogOpen}
                company={selectedCompany}
            />

            <DeleteCompanyDialog
                open={deleteDialogOpen}
                onOpenChange={setDeleteDialogOpen}
                company={selectedCompany}
            />

            <ImportCompanyDialog
                open={importDialogOpen}
                onOpenChange={setImportDialogOpen}
            />
        </div>
    )
}
