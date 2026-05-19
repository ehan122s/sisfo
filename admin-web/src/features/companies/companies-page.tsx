import { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { TableSkeleton } from '@/components/ui/table-skeleton'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table'
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
    Plus, Pencil, ChevronLeft, ChevronRight,
    Search, Trash2, MapPin, Upload, MoreHorizontal,
    Users, Building2, TrendingUp, Globe
} from 'lucide-react'
import type { Company } from '@/types'
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

    const { data: companiesResult, isLoading } = useQuery({
        queryKey: ['companies', page, search],
        queryFn: async () => {
            const start = page * pageSize
            const end = start + pageSize - 1
            let query = supabase
                .from('companies')
                .select('*, placements(count)', { count: 'exact' })
                .order('name')
            if (search) query = query.ilike('name', `%${search}%`)
            const { data, count, error } = await query.range(start, end)
            if (error) throw error
            return { data: (data ?? []) as Company[], count: count ?? 0 }
        },
    })

    const companies = companiesResult?.data || []
    const totalCount = companiesResult?.count || 0
    const totalPages = Math.ceil(totalCount / pageSize)
    const totalStudents = companies.reduce((sum, c) => {
        // @ts-ignore
        return sum + (c.placements?.[0]?.count || 0)
    }, 0)
    const withLocation = companies.filter(c => c.latitude && c.longitude).length

    // Animated counters for livelier UI
    const [animTotal, setAnimTotal] = useState(0)
    const [animStudents, setAnimStudents] = useState(0)
    const [animWithLocation, setAnimWithLocation] = useState(0)

    useEffect(() => {
        let rafId = 0
        const duration = 700
        const start = performance.now()

        const tick = (now: number) => {
            const t = Math.min(1, (now - start) / duration)
            // smooth easeOutCubic
            const ease = 1 - Math.pow(1 - t, 3)
            setAnimTotal(Math.round(totalCount * ease))
            setAnimStudents(Math.round(totalStudents * ease))
            setAnimWithLocation(Math.round(withLocation * ease))
            if (t < 1) rafId = requestAnimationFrame(tick)
        }

        rafId = requestAnimationFrame(tick)
        return () => cancelAnimationFrame(rafId)
    }, [totalCount, totalStudents, withLocation])

    const handleEdit = (company: Company) => { setSelectedCompany(company); setEditDialogOpen(true) }
    const handleDelete = (company: Company) => { setSelectedCompany(company); setDeleteDialogOpen(true) }

    return (
        <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50/30 to-slate-50 p-6 space-y-6 dark:bg-gradient-to-br dark:from-slate-900 dark:via-slate-800/60 dark:to-slate-900">

            {/* ── Header ── */}
            <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-blue-700 via-blue-600 to-blue-500 p-8 shadow-xl shadow-blue-200/50 dark:from-slate-900 dark:via-slate-800 dark:to-slate-900 dark:shadow-none">
                {/* Decorative circles */}
                <div className="pointer-events-none absolute -right-10 -top-10 h-48 w-48 rounded-full bg-white/10 dark:bg-white/5" />
                <div className="pointer-events-none absolute -right-4 top-16 h-24 w-24 rounded-full bg-white/10 dark:bg-white/5" />
                <div className="pointer-events-none absolute left-1/2 bottom-0 h-32 w-32 -translate-x-1/2 rounded-full bg-blue-800/20 dark:bg-slate-800/30" />

                <div className="relative flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
                    <div>
                            <div className="mb-1 flex items-center gap-2">
                            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-white/20 dark:bg-white/5">
                                <Building2 className="h-4 w-4 text-white" />
                            </div>
                            <span className="text-sm font-medium text-blue-100 tracking-wide uppercase">Manajemen</span>
                        </div>
                        <h1 className="text-3xl font-bold text-white tracking-tight">Data DUDI</h1>
                        <p className="mt-1 text-blue-100/80 text-sm">
                            Kelola perusahaan & industri mitra PKL
                        </p>
                    </div>

                    {/* Stat cards — each with distinct solid color */}
                    <div className="flex flex-wrap gap-3 items-stretch">
                        {/* Total DUDI — blue */}
                        <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-blue-600 to-blue-500 px-6 py-6 min-w-[180px] sm:min-w-[200px] h-36 sm:h-44 flex flex-col justify-between transform-gpu hover:scale-105 transition-all shadow-lg ring-1 ring-white/10 dark:from-blue-500/90 dark:to-blue-700/90 dark:ring-white/5">
                            <div className="absolute -right-6 -bottom-6 h-20 w-20 rounded-full bg-white/10 animate-pulse dark:bg-white/5" />
                            <div className="flex items-center justify-start">
                                <div className="mb-1 flex h-10 w-10 items-center justify-center rounded-lg bg-white/20 dark:bg-white/5 shadow-sm">
                                    <Building2 className="h-5 w-5 text-white" />
                                </div>
                            </div>
                            <div>
                                <p className="text-xs font-bold uppercase tracking-widest text-blue-100">Total DUDI</p>
                                <p className="text-3xl sm:text-4xl font-extrabold text-white leading-tight">{animTotal}</p>
                            </div>
                            <div>
                                <p className="text-xs text-blue-200 mt-1">perusahaan mitra</p>
                            </div>
                        </div>

                        {/* Siswa PKL — violet */}
                        <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-violet-700 to-violet-600 px-6 py-6 min-w-[180px] sm:min-w-[200px] h-36 sm:h-44 flex flex-col justify-between transform-gpu hover:scale-105 transition-all shadow-lg ring-1 ring-white/10 dark:from-violet-600/90 dark:to-violet-500/90 dark:ring-white/5">
                            <div className="absolute -right-6 -bottom-6 h-20 w-20 rounded-full bg-white/10 opacity-70 dark:bg-white/5" />
                            <div className="flex items-center justify-start">
                                <div className="mb-1 flex h-10 w-10 items-center justify-center rounded-lg bg-white/20 dark:bg-white/5 shadow-sm">
                                    <Users className="h-5 w-5 text-white" />
                                </div>
                            </div>
                            <div>
                                <p className="text-xs font-bold uppercase tracking-widest text-violet-200">Siswa PKL</p>
                                <p className="text-3xl sm:text-4xl font-extrabold text-white leading-tight">{animStudents}</p>
                            </div>
                            <div>
                                <p className="text-xs text-violet-300 mt-1">aktif terdaftar</p>
                            </div>
                        </div>

                        {/* Ada Lokasi — teal */}
                        <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-teal-600 to-emerald-500 px-6 py-6 min-w-[180px] sm:min-w-[200px] h-36 sm:h-44 flex flex-col justify-between transform-gpu hover:scale-105 transition-all shadow-lg ring-1 ring-white/10 dark:from-emerald-600/90 dark:to-emerald-500/90 dark:ring-white/5">
                            <div className="absolute -right-6 -bottom-6 h-20 w-20 rounded-full bg-white/10 opacity-60 dark:bg-white/5" />
                            <div className="flex items-center justify-start">
                                <div className="mb-1 flex h-10 w-10 items-center justify-center rounded-lg bg-white/20 dark:bg-white/5 shadow-sm">
                                    <Globe className="h-5 w-5 text-white" />
                                </div>
                            </div>
                            <div>
                                <p className="text-xs font-bold uppercase tracking-widest text-teal-100">Ada Lokasi</p>
                                <p className="text-3xl sm:text-4xl font-extrabold text-white leading-tight">{animWithLocation}</p>
                            </div>
                            <div>
                                <p className="text-xs text-teal-200 mt-1">GPS terkonfigurasi</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* ── Toolbar ── */}
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                    <div className="relative max-w-xs w-full">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 dark:text-slate-300" />
                    <Input
                        placeholder="Cari perusahaan..."
                        value={search}
                        onChange={(e) => { setSearch(e.target.value); setPage(0) }}
                        className="pl-9 h-10 rounded-xl border-slate-200 bg-white shadow-sm focus-visible:ring-blue-500/30 focus-visible:border-blue-400 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-slate-400 dark:text-slate-100 dark:!bg-slate-700 dark:!border-slate-600 dark:!text-slate-100"
                    />
                </div>
                <div className="flex gap-2 shrink-0">
                    <Button
                        variant="outline"
                        onClick={() => setImportDialogOpen(true)}
                        className="h-10 rounded-xl border-slate-200 bg-white text-slate-600 shadow-sm hover:border-blue-300 hover:text-blue-700 hover:bg-blue-50 transition-all dark:bg-slate-700 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-700"
                    >
                        <Upload className="mr-2 h-4 w-4" />
                        Import CSV
                    </Button>
                    <Button
                        onClick={() => setAddDialogOpen(true)}
                        data-shortcut="new"
                        className="h-10 rounded-xl bg-blue-600 hover:bg-blue-700 shadow-md shadow-blue-200 transition-all hover:shadow-blue-300 dark:bg-blue-500 dark:hover:bg-blue-600"
                    >
                        <Plus className="mr-2 h-4 w-4" />
                        Tambah DUDI
                    </Button>
                </div>
            </div>

            {/* ── Table Card ── */}
            <div className="rounded-2xl border border-slate-200/80 bg-white shadow-sm overflow-hidden dark:border-slate-700/60 dark:bg-slate-800 dark:text-slate-200">

                {/* Card header */}
                <div className="flex items-center justify-between border-b border-slate-100 px-6 py-4">
                        <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-50 dark:bg-slate-700">
                            <TrendingUp className="h-4 w-4 text-blue-600" />
                        </div>
                        <h2 className="font-semibold text-slate-800 dark:text-slate-100">Daftar Perusahaan</h2>
                    </div>
                    <Badge
                        variant="secondary"
                        className="bg-blue-50 text-blue-700 border-blue-100 px-3 py-1 rounded-full text-xs font-semibold dark:bg-slate-700 dark:text-blue-200 dark:border-slate-600"
                    >
                        {totalCount} total
                    </Badge>
                </div>

                {/* Table */}
                {isLoading ? (
                    <div className="p-6">
                        <TableSkeleton columnCount={5} rowCount={5} />
                    </div>
                ) : companies.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-20 text-center">
                        <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-blue-50 dark:bg-slate-700">
                            <Building2 className="h-8 w-8 text-blue-300 dark:text-blue-200" />
                        </div>
                        <p className="text-slate-800 font-medium dark:text-slate-100">
                            {search ? 'Tidak ditemukan' : 'Belum ada DUDI'}
                        </p>
                        <p className="mt-1 text-sm text-slate-400 dark:text-slate-400">
                            {search
                                ? `Tidak ada perusahaan dengan kata kunci "${search}"`
                                : 'Tambahkan perusahaan mitra PKL pertama Anda'}
                        </p>
                        {!search && (
                            <Button
                                onClick={() => setAddDialogOpen(true)}
                                className="mt-5 rounded-xl bg-blue-600 hover:bg-blue-700 shadow-sm"
                            >
                                <Plus className="mr-2 h-4 w-4" />
                                Tambah DUDI
                            </Button>
                        )}
                    </div>
                ) : (
                    <>
                        <Table>
                            <TableHeader>
                                <TableRow className="bg-slate-50/70 hover:bg-slate-50/70 dark:bg-slate-900/50 dark:hover:bg-slate-900/60">
                                    <TableHead className="pl-6 text-xs font-semibold uppercase tracking-wider text-slate-400">Perusahaan</TableHead>
                                    <TableHead className="text-center text-xs font-semibold uppercase tracking-wider text-slate-400 w-[100px]">Siswa</TableHead>
                                    <TableHead className="hidden md:table-cell text-xs font-semibold uppercase tracking-wider text-slate-400">Alamat</TableHead>
                                    <TableHead className="hidden lg:table-cell text-xs font-semibold uppercase tracking-wider text-slate-400 w-[240px] px-4">Lokasi GPS</TableHead>
                                    <TableHead className="hidden lg:table-cell text-xs font-semibold uppercase tracking-wider text-slate-400 w-[140px] px-4">Radius</TableHead>
                                    <TableHead className="pr-6 text-right text-xs font-semibold uppercase tracking-wider text-slate-400">Aksi</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {companies.map((company, idx) => (
                                    <TableRow
                                        key={company.id}
                                        className="group border-slate-100 dark:border-slate-700 hover:bg-blue-50/40 dark:hover:bg-slate-900/60 transition-colors"
                                    >
                                        {/* Name cell with avatar */}
                                        <TableCell className="pl-6 py-4">
                                            <div className="flex items-center gap-3">
                                                <div
                                                    className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-xs font-bold text-white"
                                                    style={{
                                                        background: `hsl(${(idx * 47 + 200) % 360}, 65%, 50%)`
                                                    }}
                                                >
                                                    {company.name.slice(0, 2).toUpperCase()}
                                                </div>
                                                <span className="font-medium text-slate-800 dark:text-slate-100">{company.name}</span>
                                            </div>
                                        </TableCell>

                                        {/* Student badge */}
                                        <TableCell className="text-center">
                                            <span className="inline-flex items-center gap-1.5 rounded-full bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700 border border-blue-100 dark:bg-slate-700 dark:text-blue-200 dark:border-slate-600">
                                                <Users className="h-3 w-3" />
                                                {/* @ts-ignore */}
                                                {company.placements?.[0]?.count || 0}
                                            </span>
                                        </TableCell>

                                        {/* Address */}
                                        <TableCell
                                            className="max-w-[200px] truncate hidden md:table-cell text-sm text-slate-500"
                                            title={company.address}
                                        >
                                            {company.address || (
                                                <span className="text-slate-300 italic">Belum diisi</span>
                                            )}
                                        </TableCell>

                                        {/* GPS link */}
                                        <TableCell className="hidden lg:table-cell px-4">
                                            {company.latitude && company.longitude ? (
                                                <a
                                                    href={`https://www.google.com/maps?q=${company.latitude},${company.longitude}`}
                                                    target="_blank"
                                                    rel="noopener noreferrer"
                                                    className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-50 px-2.5 py-1 text-xs font-medium text-emerald-700 border border-emerald-100 hover:bg-emerald-100 transition-colors dark:bg-emerald-900/20 dark:text-emerald-200 dark:border-emerald-700 dark:hover:bg-emerald-800/30"
                                                >
                                                    <MapPin className="h-3 w-3" />
                                                    {company.latitude.toFixed(4)}, {company.longitude.toFixed(4)}
                                                </a>
                                            ) : (
                                                <span className="text-xs text-slate-300 italic dark:text-slate-400">Belum ada</span>
                                            )}
                                        </TableCell>

                                        {/* Radius */}
                                        <TableCell className="hidden lg:table-cell px-4">
                                            <span className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-3 py-1 text-sm font-medium text-slate-600 dark:bg-slate-700 dark:text-slate-200">
                                                {company.radius_meter || 100} m
                                            </span>
                                        </TableCell>

                                        {/* Actions */}
                                        <TableCell className="pr-6 text-right">
                                            <DropdownMenu>
                                                    <DropdownMenuTrigger asChild>
                                                    <Button
                                                        variant="ghost"
                                                        className="h-8 w-8 p-0 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg hover:bg-blue-100 hover:text-blue-700 dark:hover:bg-slate-700 dark:hover:text-blue-200"
                                                    >
                                                        <span className="sr-only">Open menu</span>
                                                        <MoreHorizontal className="h-4 w-4" />
                                                    </Button>
                                                </DropdownMenuTrigger>
                                                <DropdownMenuContent align="end" className="rounded-xl shadow-lg border-slate-200 dark:bg-slate-800 dark:border-slate-700 dark:shadow-none dark:text-slate-200">
                                                    <DropdownMenuLabel className="text-xs text-slate-400 dark:text-slate-400">Aksi</DropdownMenuLabel>
                                                    <DropdownMenuSeparator className="dark:border-slate-700" />
                                                    <DropdownMenuItem
                                                        onClick={() => handleEdit(company)}
                                                        className="rounded-lg cursor-pointer gap-2 focus:bg-blue-50 focus:text-blue-700"
                                                    >
                                                        <Pencil className="h-4 w-4" />
                                                        Edit
                                                    </DropdownMenuItem>
                                                    <DropdownMenuItem
                                                        className="rounded-lg cursor-pointer gap-2 text-red-600 focus:text-red-600 focus:bg-red-50"
                                                        onClick={() => handleDelete(company)}
                                                    >
                                                        <Trash2 className="h-4 w-4" />
                                                        Hapus
                                                    </DropdownMenuItem>
                                                    </DropdownMenuContent>
                                            </DropdownMenu>
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>

                        {/* Pagination */}
                        <div className="flex items-center justify-between border-t border-slate-100 px-6 py-4 dark:border-slate-700">
                            <p className="text-sm text-slate-400">
                                Menampilkan{' '}
                                <span className="font-medium text-slate-600">
                                    {page * pageSize + 1}–{Math.min((page + 1) * pageSize, totalCount)}
                                </span>{' '}
                                dari <span className="font-medium text-slate-600">{totalCount}</span> DUDI
                            </p>
                            <div className="flex items-center gap-2">
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => setPage((p) => Math.max(0, p - 1))}
                                    disabled={page === 0}
                                    className="h-9 rounded-xl border-slate-200 text-slate-600 hover:border-blue-300 hover:text-blue-700 hover:bg-blue-50 disabled:opacity-40 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-700 dark:hover:text-blue-200"
                                >
                                    <ChevronLeft className="h-4 w-4 mr-1" />
                                    Prev
                                </Button>
                                <div className="flex items-center justify-center h-9 min-w-[80px] rounded-xl bg-blue-50 border border-blue-100 text-sm font-medium text-blue-700 px-3 dark:bg-slate-700 dark:border-slate-600 dark:text-blue-200">
                                    {page + 1} / {Math.max(1, totalPages)}
                                </div>
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => setPage((p) => p + 1)}
                                    disabled={page >= totalPages - 1}
                                    className="h-9 rounded-xl border-slate-200 text-slate-600 hover:border-blue-300 hover:text-blue-700 hover:bg-blue-50 disabled:opacity-40 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-700 dark:hover:text-blue-200"
                                >
                                    Next
                                    <ChevronRight className="h-4 w-4 ml-1" />
                                </Button>
                            </div>
                        </div>
                    </>
                )}
            </div>

            {/* Dialogs */}
            <AddCompanyDialog open={addDialogOpen} onOpenChange={setAddDialogOpen} />
            <EditCompanyDialog open={editDialogOpen} onOpenChange={setEditDialogOpen} company={selectedCompany} />
            <DeleteCompanyDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen} company={selectedCompany} />
            <ImportCompanyDialog open={importDialogOpen} onOpenChange={setImportDialogOpen} />
        </div>
    )
}