import { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { TableSkeleton } from '@/components/ui/table-skeleton'
import {
    Plus, ChevronLeft, ChevronRight,
    Search, Upload,
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

            {/* ── Page Header ── */}
            <div className="space-y-6">
                <div className="flex flex-wrap items-start justify-between gap-4">
                    <div>
                        <div className="flex gap-1 mb-2">
                            <div className="h-1 w-8 rounded-full bg-primary" />
                            <div className="h-1 w-4 rounded-full bg-primary/40" />
                        </div>
                        <h1 className="text-3xl font-extrabold tracking-tight italic">
                            MANAJEMEN <span className="text-primary">DUDI</span>
                        </h1>
                        <p className="text-sm text-muted-foreground mt-1">
                            {new Date().toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
                        </p>
                    </div>
                </div>

                <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
                    <Card className="border-l-4 border-l-blue-500 dark:border-l-blue-400">
                        <CardContent className="p-4">
                            <div className="flex items-center justify-between">
                                <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                                    Total
                                </p>
                                <Building2 className="h-5 w-5 text-blue-500 dark:text-blue-400" />
                            </div>
                            <p className="mt-2 text-3xl font-bold text-blue-600 dark:text-blue-400">
                                {animTotal}
                            </p>
                            <div className="mt-2 h-1 w-full rounded-full bg-muted overflow-hidden">
                                <div className="h-1 bg-blue-500 dark:bg-blue-400 rounded-full w-full" />
                            </div>
                            <p className="mt-1 text-xs text-muted-foreground">perusahaan mitra</p>
                        </CardContent>
                    </Card>

                    <Card className="border-l-4 border-l-green-500 dark:border-l-green-400">
                        <CardContent className="p-4">
                            <div className="flex items-center justify-between">
                                <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                                    Aktif
                                </p>
                                <Users className="h-5 w-5 text-green-500 dark:text-green-400" />
                            </div>
                            <p className="mt-2 text-3xl font-bold text-green-600 dark:text-green-400">
                                {animStudents}
                            </p>
                            <div className="mt-2 h-1 w-full rounded-full bg-muted overflow-hidden">
                                <div className="h-1 bg-green-500 dark:bg-green-400 rounded-full w-full" />
                            </div>
                            <p className="mt-1 text-xs text-muted-foreground">aktif terdaftar</p>
                        </CardContent>
                    </Card>

                    <Card className="border-l-4 border-l-yellow-500 dark:border-l-yellow-400">
                        <CardContent className="p-4">
                            <div className="flex items-center justify-between">
                                <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                                    Ada Lokasi
                                </p>
                                <Globe className="h-5 w-5 text-yellow-500 dark:text-yellow-400" />
                            </div>
                            <p className="mt-2 text-3xl font-bold text-yellow-600 dark:text-yellow-400">
                                {animWithLocation}
                            </p>
                            <div className="mt-2 h-1 w-full rounded-full bg-muted overflow-hidden">
                                <div className="h-1 bg-yellow-500 dark:bg-yellow-400 rounded-full w-full" />
                            </div>
                            <p className="mt-1 text-xs text-muted-foreground">GPS terkonfigurasi</p>
                        </CardContent>
                    </Card>

                    <Card className="border-l-4 border-l-purple-500 dark:border-l-purple-400">
                        <CardContent className="p-4">
                            <div className="flex items-center justify-between">
                                <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                                    Halaman
                                </p>
                                <TrendingUp className="h-5 w-5 text-purple-500 dark:text-purple-400" />
                            </div>
                            <p className="mt-2 text-3xl font-bold text-purple-600 dark:text-purple-400">
                                {page + 1}
                            </p>
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
                        <div className="grid gap-4 p-6 sm:grid-cols-2 xl:grid-cols-3">
                            {companies.map((company, idx) => (
                                <div
                                    key={company.id}
                                    className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-lg dark:border-slate-700/60 dark:bg-slate-900"
                                >
                                    <div className="flex items-start justify-between gap-4">
                                        <div className="flex items-center gap-3 min-w-0">
                                            <div
                                                className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl text-sm font-semibold text-white"
                                                style={{
                                                    background: `hsl(${(idx * 47 + 200) % 360}, 65%, 50%)`
                                                }}
                                            >
                                                {company.name.slice(0, 2).toUpperCase()}
                                            </div>
                                            <div className="min-w-0">
                                                <p className="text-sm font-semibold text-slate-900 dark:text-slate-100 truncate">
                                                    {company.name}
                                                </p>
                                                <p className="mt-1 text-sm text-slate-500 dark:text-slate-400 line-clamp-2">
                                                    {company.address || 'Belum diisi'}
                                                </p>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-2">
                                            <Button
                                                variant="outline"
                                                size="sm"
                                                onClick={() => handleEdit(company)}
                                            >
                                                Edit
                                            </Button>
                                            <Button
                                                variant="destructive"
                                                size="sm"
                                                onClick={() => handleDelete(company)}
                                            >
                                                Hapus
                                            </Button>
                                        </div>
                                    </div>

                                    <div className="mt-5 grid gap-3 sm:grid-cols-2">
                                        <div className="rounded-2xl bg-slate-50 p-4 dark:bg-slate-800">
                                            <p className="text-xs uppercase tracking-wide text-slate-400">Siswa</p>
                                            <div className="mt-2 flex items-center gap-2 text-lg font-semibold text-slate-900 dark:text-slate-100">
                                                <Users className="h-4 w-4 text-blue-600" />
                                                {/* @ts-ignore */}
                                                {company.placements?.[0]?.count || 0}
                                            </div>
                                        </div>
                                        <div className="rounded-2xl bg-slate-50 p-4 dark:bg-slate-800">
                                            <p className="text-xs uppercase tracking-wide text-slate-400">Radius</p>
                                            <div className="mt-2 text-lg font-semibold text-slate-900 dark:text-slate-100">
                                                {company.radius_meter || 100} m
                                            </div>
                                        </div>
                                        <div className="sm:col-span-2 rounded-2xl bg-slate-50 p-4 dark:bg-slate-800">
                                            <div className="flex items-center justify-between">
                                                <p className="text-xs uppercase tracking-wide text-slate-400">Lokasi GPS</p>
                                                {company.latitude && company.longitude ? (
                                                    <span className="rounded-full bg-emerald-100 px-2 py-1 text-[11px] font-semibold text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-200">
                                                        Tersedia
                                                    </span>
                                                ) : (
                                                    <span className="rounded-full bg-slate-100 px-2 py-1 text-[11px] font-semibold text-slate-500 dark:bg-slate-700 dark:text-slate-400">
                                                        Belum
                                                    </span>
                                                )}
                                            </div>
                                            <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
                                                {company.latitude && company.longitude
                                                    ? `${company.latitude.toFixed(4)}, ${company.longitude.toFixed(4)}`
                                                    : 'Belum ada lokasi GPS'}
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>

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