import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { Search, UserCog, MoreHorizontal, Pencil, Trash2, ChevronLeft, ChevronRight, UserPlus, Users, Building2 } from 'lucide-react'
import { TeacherService, type Teacher } from '../services/teacher-service'
import { TeacherDialog } from '../components/teacher-dialog'
import { DeleteTeacherDialog } from '../components/delete-teacher-dialog'
import { Input } from '@/components/ui/input'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table"
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
import { cn } from '@/lib/utils'

// Avatar helpers
const AVATAR_COLORS = [
    'bg-blue-100 text-blue-700 dark:bg-blue-500/20 dark:text-blue-300',
    'bg-indigo-100 text-indigo-700 dark:bg-indigo-500/20 dark:text-indigo-300',
    'bg-sky-100 text-sky-700 dark:bg-sky-500/20 dark:text-sky-300',
    'bg-violet-100 text-violet-700 dark:bg-violet-500/20 dark:text-violet-300',
    'bg-cyan-100 text-cyan-700 dark:bg-cyan-500/20 dark:text-cyan-300',
]
const getAvatarColor = (name: string) => AVATAR_COLORS[name.charCodeAt(0) % AVATAR_COLORS.length]
const getInitials = (name: string) => name.split(' ').map((n: string) => n[0]).join('').toUpperCase().substring(0, 2)

// Stat card config — pola dari AttendancePage
const STAT_CARDS = [
    {
        key: 'total',
        label: 'TOTAL PEMBIMBING',
        icon: Users,
        accent: 'border-t-blue-500',
        iconBg: 'bg-blue-50 text-blue-600 dark:bg-blue-500/15 dark:text-blue-400',
        numColor: 'text-blue-600 dark:text-blue-400',
        bar: 'bg-blue-500',
        barBg: 'bg-blue-100 dark:bg-blue-500/10',
    },
    {
        key: 'assigned',
        label: 'SUDAH DITUGASKAN',
        icon: UserCog,
        accent: 'border-t-emerald-500',
        iconBg: 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400',
        numColor: 'text-emerald-600 dark:text-emerald-400',
        bar: 'bg-emerald-500',
        barBg: 'bg-emerald-100 dark:bg-emerald-500/10',
    },
    {
        key: 'unassigned',
        label: 'BELUM DITUGASKAN',
        icon: UserCog,
        accent: 'border-t-amber-500',
        iconBg: 'bg-amber-50 text-amber-600 dark:bg-amber-500/15 dark:text-amber-400',
        numColor: 'text-amber-600 dark:text-amber-400',
        bar: 'bg-amber-500',
        barBg: 'bg-amber-100 dark:bg-amber-500/10',
    },
    {
        key: 'dudi',
        label: 'TOTAL DUDI',
        icon: Building2,
        accent: 'border-t-purple-500',
        iconBg: 'bg-purple-50 text-purple-600 dark:bg-purple-500/15 dark:text-purple-400',
        numColor: 'text-purple-600 dark:text-purple-400',
        bar: 'bg-purple-500',
        barBg: 'bg-purple-100 dark:bg-purple-500/10',
    },
]

export function TeachersPage() {
    const queryClient = useQueryClient()
    const [page, setPage] = useState(0)
    const [search, setSearch] = useState('')
    const pageSize = 10

    // Dialog states — tidak berubah
    const [addDialogOpen, setAddDialogOpen] = useState(false)
    const [editDialogOpen, setEditDialogOpen] = useState(false)
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
    const [selectedTeacher, setSelectedTeacher] = useState<Teacher | null>(null)

    // Fetch teachers with TanStack Query — tidak berubah
    const { data: teachersResult, isLoading } = useQuery({
        queryKey: ['teachers', page, search],
        queryFn: () => TeacherService.getTeachers(page, pageSize, search)
    })

    const teachers = teachersResult?.data || []
    const totalCount = teachersResult?.count || 0
    const totalPages = Math.ceil(totalCount / pageSize)

    // Stat card values
    const withAssignment = teachers.filter((t: Teacher) => t.assignments && t.assignments.length > 0).length
    const withoutAssignment = teachers.filter((t: Teacher) => !t.assignments || t.assignments.length === 0).length
    const totalCompanies = new Set(
        teachers.flatMap((t: Teacher) => t.assignments?.map((a: { company?: { name?: string } | null }) => a.company?.name).filter(Boolean) ?? [])
    ).size
    const statValues: Record<string, number> = {
        total: totalCount,
        assigned: withAssignment,
        unassigned: withoutAssignment,
        dudi: totalCompanies,
    }

    // Reset page when search changes — tidak berubah
    const handleSearchChange = (value: string) => {
        setSearch(value)
        setPage(0)
    }

    // Handlers — tidak berubah
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
        <div className="min-h-screen bg-slate-50 dark:bg-[#070b14] -m-6 p-6 space-y-5">

            {/* ── HEADER ── */}
            <div className="space-y-5">

                {/* Title row */}
                <div className="flex items-center justify-between">
                    <div>
                        {/* Accent lines */}
                        <div className="flex items-center gap-2 mb-3">
                            <div className="h-1 w-8 rounded-full bg-blue-600 dark:bg-blue-500" />
                            <div className="h-1 w-3 rounded-full bg-blue-300 dark:bg-blue-700" />
                        </div>
                        <h1 className="text-4xl font-black italic uppercase tracking-tight leading-none text-slate-900 dark:text-white">
                            MANAJEMEN{' '}
                            <span className="text-blue-600 dark:text-blue-400">PEMBIMBING</span>
                        </h1>
                        <p className="mt-2 text-sm font-medium text-slate-400 dark:text-slate-500">
                            Kelola akun guru pembimbing dan penempatan pengawasan DUDI.
                        </p>
                    </div>
                    {/* Tombol — data-shortcut dan onClick asli dipertahankan */}
                    <Button
                        onClick={() => setAddDialogOpen(true)}
                        data-shortcut="new"
                        className="rounded-xl bg-blue-600 text-white hover:bg-blue-700 font-black uppercase tracking-wide px-5 h-10 gap-2 shadow-sm shadow-blue-200 dark:bg-blue-500 dark:hover:bg-blue-400 dark:shadow-blue-500/20"
                    >
                        <UserPlus className="h-4 w-4" />
                        Tambah Pembimbing
                    </Button>
                </div>

                {/* Stat Cards — tambahan visual, tidak mengganti fungsi apapun */}
                <div className="grid grid-cols-2 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                    {STAT_CARDS.map(({ key, label, icon: Icon, accent, iconBg, numColor, bar, barBg }) => {
                        const count = statValues[key] || 0
                        const pct = key === 'total' || key === 'dudi'
                            ? 100
                            : totalCount > 0 ? Math.round((count / totalCount) * 100) : 0
                        return (
                            <div
                                key={key}
                                className={cn(
                                    'relative rounded-2xl bg-white border border-slate-100 border-t-[3px] shadow-sm p-4',
                                    'dark:bg-[#111b30] dark:border-white/5',
                                    accent
                                )}
                            >
                                <div className="flex items-start justify-between mb-3">
                                    <div>
                                        <p className="text-[10px] font-bold tracking-widest text-slate-400 dark:text-slate-500 uppercase mb-1">
                                            {label}
                                        </p>
                                        <p className={cn('text-3xl font-black leading-none', numColor)}>
                                            {count}
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
                                    {key === 'total' || key === 'dudi' ? 'terdaftar' : `${pct}% dari total`}
                                </p>
                            </div>
                        )
                    })}
                </div>
            </div>

            {/* ── Main Panel ── */}
            <div className="rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-white/5 dark:bg-[#0d1526]">

                {/* Panel header */}
                <div className="flex items-center justify-between px-5 pt-4 pb-4 border-b border-slate-100 dark:border-white/5">
                    <div className="flex items-center gap-2.5">
                        <div className="h-4 w-[3px] rounded-full bg-blue-500" />
                        <h2 className="text-[11px] font-black uppercase tracking-widest text-blue-900 dark:text-slate-300">
                            Daftar Pembimbing
                        </h2>
                        {/* Badge count — menggantikan <Badge variant="outline"> asli, data sama */}
                        <span className="text-[10px] font-bold bg-blue-100 text-blue-700 border border-blue-200 px-2 py-0.5 rounded-full dark:bg-blue-500/15 dark:text-blue-400 dark:border-blue-500/30">
                            {totalCount} Total
                        </span>
                    </div>
                    {/* Search — logika handleSearchChange asli dipertahankan */}
                    <div className="relative w-64">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400 dark:text-slate-500 pointer-events-none" />
                        <Input
                            placeholder="Cari nama pembimbing..."
                            value={search}
                            onChange={(e) => handleSearchChange(e.target.value)}
                            className="pl-9 rounded-xl h-9 text-sm dark:bg-white/5 dark:border-white/10 dark:text-white dark:placeholder:text-slate-600"
                        />
                    </div>
                </div>

                {/* Content — isLoading, empty, table — semua kondisi asli dipertahankan */}
                <div className="p-0">
                    {isLoading ? (
                        <div className="p-5">
                            <TableSkeleton columnCount={3} rowCount={5} />
                        </div>
                    ) : teachers.length === 0 ? (
                        <div className="p-5">
                            <EmptyState
                                title="Tidak ada pembimbing"
                                description={search ? "Tidak ditemukan pembimbing dengan kata kunci tersebut." : "Belum ada data pembimbing yang ditambahkan."}
                            />
                        </div>
                    ) : (
                        <>
                            {/* Table — struktur asli dipertahankan */}
                            <div className="rounded-none border-0">
                                <Table>
                                    <TableHeader>
                                        <TableRow className="bg-slate-50/80 dark:bg-white/[0.02] hover:bg-slate-50/80 dark:hover:bg-white/[0.02] border-b border-slate-100 dark:border-white/5">
                                            <TableHead className="px-5 py-3 text-[10px] font-black uppercase tracking-widest text-slate-400 dark:text-slate-500">
                                                Nama Pembimbing
                                            </TableHead>
                                            <TableHead className="py-3 text-[10px] font-black uppercase tracking-widest text-slate-400 dark:text-slate-500">
                                                Perusahaan Binaan
                                            </TableHead>
                                            <TableHead className="py-3 pr-5 text-right text-[10px] font-black uppercase tracking-widest text-slate-400 dark:text-slate-500 w-[100px]">
                                                Aksi
                                            </TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {teachers.map((teacher: Teacher) => (
                                            <TableRow
                                                key={teacher.id}
                                                className="border-b border-slate-50 dark:border-white/[0.03] hover:bg-blue-50/40 dark:hover:bg-white/[0.03] transition-colors"
                                            >
                                                <TableCell className="px-5 py-3 font-medium">
                                                    <div className="flex items-center gap-3">
                                                        {/* Avatar initials menggantikan UserCog icon */}
                                                        <div className={cn(
                                                            'h-9 w-9 rounded-full shrink-0 flex items-center justify-center text-xs font-black ring-2 ring-white dark:ring-white/5',
                                                            getAvatarColor(teacher.full_name)
                                                        )}>
                                                            {getInitials(teacher.full_name)}
                                                        </div>
                                                        <div className="flex flex-col">
                                                            <span className="text-sm font-semibold text-slate-800 dark:text-white">
                                                                {teacher.full_name}
                                                            </span>
                                                            {teacher.email && (
                                                                <span className="text-xs text-slate-400 dark:text-slate-500">
                                                                    {teacher.email}
                                                                </span>
                                                            )}
                                                        </div>
                                                    </div>
                                                </TableCell>
                                                <TableCell className="py-3">
                                                    <div className="flex flex-wrap gap-1.5">
                                                        {/* teacher.assignments — logika asli dipertahankan */}
                                                        {teacher.assignments && teacher.assignments.length > 0 ? (
                                                            teacher.assignments.map(a => (
                                                                <span
                                                                    key={a.id}
                                                                    className="inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[10px] font-bold bg-blue-50 text-blue-700 border border-blue-200 dark:bg-blue-500/15 dark:text-blue-400 dark:border-blue-500/30"
                                                                >
                                                                    <span className="h-1.5 w-1.5 rounded-full bg-blue-500 dark:bg-blue-400" />
                                                                    {a.company?.name || 'Unknown'}
                                                                </span>
                                                            ))
                                                        ) : (
                                                            <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-[10px] font-bold bg-slate-100 text-slate-400 border border-slate-200 dark:bg-white/5 dark:text-slate-500 dark:border-white/10">
                                                                Belum ada penempatan
                                                            </span>
                                                        )}
                                                    </div>
                                                </TableCell>
                                                <TableCell className="py-3 pr-5 text-right">
                                                    {/* DropdownMenu — handleEdit & handleDelete asli dipertahankan */}
                                                    <DropdownMenu>
                                                        <DropdownMenuTrigger asChild>
                                                            <Button variant="ghost" className="h-8 w-8 p-0 rounded-lg hover:bg-slate-100 dark:hover:bg-white/10">
                                                                <span className="sr-only">Open menu</span>
                                                                <MoreHorizontal className="h-4 w-4 text-slate-400 dark:text-slate-500" />
                                                            </Button>
                                                        </DropdownMenuTrigger>
                                                        <DropdownMenuContent align="end" className="dark:bg-[#111b30] dark:border-white/10">
                                                            <DropdownMenuLabel className="text-[10px] font-black uppercase tracking-widest text-slate-400 dark:text-slate-500">
                                                                Aksi
                                                            </DropdownMenuLabel>
                                                            <DropdownMenuSeparator className="dark:border-white/10" />
                                                            <DropdownMenuItem
                                                                onClick={() => handleEdit(teacher)}
                                                                className="gap-2 text-sm dark:text-slate-300 dark:focus:text-white dark:focus:bg-white/10"
                                                            >
                                                                <Pencil className="mr-2 h-4 w-4" />
                                                                Edit
                                                            </DropdownMenuItem>
                                                            <DropdownMenuItem
                                                                className="text-red-600 focus:text-red-600 focus:bg-red-50 dark:text-red-400 dark:focus:bg-red-500/10"
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

                            {/* Pagination — logika asli (Math.max, disabled) dipertahankan */}
                            {totalPages > 1 && (
                                <div className="flex items-center justify-between px-5 py-4 border-t border-slate-100 dark:border-white/5">
                                    <p className="text-xs text-slate-400 dark:text-slate-600">
                                        Menampilkan {teachers.length} dari {totalCount} pembimbing
                                    </p>
                                    <div className="flex items-center gap-2">
                                        <Button
                                            variant="outline"
                                            size="sm"
                                            onClick={() => setPage((p) => Math.max(0, p - 1))}
                                            disabled={page === 0}
                                            className="rounded-lg h-8 w-8 p-0 dark:bg-white/5 dark:border-white/10 dark:text-slate-400 dark:hover:bg-white/10 dark:hover:text-white"
                                        >
                                            <ChevronLeft className="h-4 w-4" />
                                        </Button>
                                        <span className="text-xs font-semibold text-slate-500 dark:text-slate-400 px-2">
                                            {page + 1} / {totalPages}
                                        </span>
                                        <Button
                                            variant="outline"
                                            size="sm"
                                            onClick={() => setPage((p) => p + 1)}
                                            disabled={page >= totalPages - 1}
                                            className="rounded-lg h-8 w-8 p-0 dark:bg-white/5 dark:border-white/10 dark:text-slate-400 dark:hover:bg-white/10 dark:hover:text-white"
                                        >
                                            <ChevronRight className="h-4 w-4" />
                                        </Button>
                                    </div>
                                </div>
                            )}
                        </>
                    )}
                </div>
            </div>

            {/* Dialogs — props asli tidak berubah sama sekali */}
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