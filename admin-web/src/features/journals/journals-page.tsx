import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog'
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select'
import {
    ChevronLeft,
    ChevronRight,
    Calendar,
    Eye,
    FileSpreadsheet,
    FileText,
    Loader2,
    CheckCircle,
    XCircle,
    BookOpen,
    Clock,
    CheckSquare,
    AlertCircle,
} from 'lucide-react'
import { exportToExcel, exportToPDF } from '@/lib/export'
import { toast } from 'sonner'
import { getClassList } from '@/features/reports/services/report-service'

export function JournalsPage() {
    const [page, setPage] = useState(0)
    const [selectedDate, setSelectedDate] = useState<string>('')
    const [selectedClass, setSelectedClass] = useState('Semua')
    const [selectedJournal, setSelectedJournal] = useState<any | null>(null)
    const [detailOpen, setDetailOpen] = useState(false)
    const pageSize = 10
    const queryClient = useQueryClient()

    // Fetch class list dynamically
    const { data: classListData = [] } = useQuery({
        queryKey: ['class-list'],
        queryFn: getClassList,
    })
    const CLASS_OPTIONS = ['Semua', ...classListData]

    // Fetch journals with filters
    const { data: journalsResult, isLoading } = useQuery({
        queryKey: ['journals', page, selectedDate, selectedClass],
        queryFn: async () => {
            const start = page * pageSize
            const end = start + pageSize - 1

            let query = supabase
                .from('daily_journals')
                .select('*, profiles!inner(full_name, class_name, nisn)', { count: 'exact' })
                .order('created_at', { ascending: false })

            if (selectedDate) {
                query = query
                    .gte('created_at', `${selectedDate}T00:00:00`)
                    .lte('created_at', `${selectedDate}T23:59:59`)
            }

            if (selectedClass !== 'Semua') {
                query = query.eq('profiles.class_name', selectedClass)
            }

            const { data, count, error } = await query.range(start, end)
            if (error) throw error

            return {
                data: (data ?? []) as any[],
                count: count ?? 0,
            }
        },
    })

    const journals = journalsResult?.data || []
    const totalCount = journalsResult?.count || 0
    const totalPages = Math.ceil(totalCount / pageSize)

    // Stat counts
    const totalJournals = totalCount
    const approved = journals.filter((j: any) => j.is_approved).length
    const pending = journals.filter((j: any) => !j.is_approved).length

    // Approve / Reject mutation
    const approveMutation = useMutation({
        mutationFn: async ({ id, approved }: { id: number; approved: boolean }) => {
            const { error } = await supabase
                .from('daily_journals')
                .update({ is_approved: approved })
                .eq('id', id)
            if (error) throw error
        },
        onSuccess: (_, { approved }) => {
            toast.success(approved ? 'Jurnal berhasil disetujui!' : 'Jurnal ditolak.')
            queryClient.invalidateQueries({ queryKey: ['journals'] })
            if (selectedJournal) {
                setSelectedJournal((prev: any) => ({ ...prev, is_approved: approved }))
            }
        },
        onError: () => toast.error('Gagal mengubah status jurnal'),
    })

    const formatDate = (dateStr: string) =>
        new Date(dateStr).toLocaleDateString('id-ID', {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
        })
    const formatTime = (dateStr: string) =>
        new Date(dateStr).toLocaleTimeString('id-ID', {
            hour: '2-digit',
            minute: '2-digit',
        })

    const openDetail = (journal: any) => {
        setSelectedJournal(journal)
        setDetailOpen(true)
    }

    const getImageUrl = (journal: any) =>
        journal.evidence_url || journal.image_url || null

    const handleExportExcel = () => {
        if (!journals.length) return
        const headers = ['Nama', 'Kelas', 'Tanggal', 'Kegiatan', 'Deskripsi', 'Status']
        const rows = journals.map((j: any) => [
            j.profiles?.full_name || '',
            j.profiles?.class_name || '-',
            formatDate(j.created_at),
            j.activity_title || j.activities || '-',
            j.description || j.notes || '-',
            j.is_approved ? 'Disetujui' : 'Menunggu',
        ])
        exportToExcel({ headers, rows, filename: `jurnal_${selectedDate || 'semua'}` })
    }

    const handleExportPDF = () => {
        if (!journals.length) return
        const headers = ['Nama', 'Kelas', 'Tanggal', 'Kegiatan', 'Status']
        const rows = journals.map((j: any) => [
            j.profiles?.full_name || '',
            j.profiles?.class_name || '-',
            formatDate(j.created_at),
            j.activity_title || j.activities || '-',
            j.is_approved ? 'Disetujui' : 'Menunggu',
        ])
        exportToPDF({
            headers,
            rows,
            filename: `jurnal_${selectedDate || 'semua'}`,
            title: `Laporan Jurnal${
                selectedDate
                    ? ` - ${new Date(selectedDate).toLocaleDateString('id-ID', {
                          day: 'numeric',
                          month: 'long',
                          year: 'numeric',
                      })}`
                    : ''
            }`,
        })
    }

    // Today's display date (like Absensi Siswa header)
    const todayLabel = new Date().toLocaleDateString('id-ID', {
        weekday: 'long',
        day: 'numeric',
        month: 'long',
        year: 'numeric',
    })

    return (
        <div className="space-y-6">
            {/* ── Page Header (matches Absensi Siswa style) ── */}
            <div className="flex flex-wrap items-start justify-between gap-4">
                <div>
                    {/* Accent bar */}
                    <div className="flex gap-1 mb-2">
                        <div className="h-1 w-8 rounded-full bg-primary" />
                        <div className="h-1 w-4 rounded-full bg-primary/40" />
                    </div>
                    <h1 className="text-3xl font-extrabold tracking-tight italic">
                        LAPORAN <span className="text-primary">JURNAL</span>
                    </h1>
                    <p className="text-sm text-muted-foreground mt-1">{todayLabel}</p>
                </div>

                {/* Export buttons (top-right like Absensi's HADIRKAN SEMUA) */}
                <div className="flex gap-2">
                    <Button variant="outline" size="sm" onClick={handleExportExcel}>
                        <FileSpreadsheet className="mr-2 h-4 w-4" />
                        Excel
                    </Button>
                    <Button size="sm" onClick={handleExportPDF}
                        className="bg-primary hover:bg-primary/90 text-primary-foreground font-semibold">
                        <FileText className="mr-2 h-4 w-4" />
                        PDF
                    </Button>
                </div>
            </div>

            {/* ── Stat Cards (matches Absensi Siswa stat cards) ── */}
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
                {/* Total */}
                <Card className="border-l-4 border-l-blue-500 dark:border-l-blue-400">
                    <CardContent className="p-4">
                        <div className="flex items-center justify-between">
                            <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                                Total
                            </p>
                            <BookOpen className="h-5 w-5 text-blue-500 dark:text-blue-400" />
                        </div>
                        <p className="mt-2 text-3xl font-bold text-blue-600 dark:text-blue-400">
                            {totalJournals}
                        </p>
                        <div className="mt-2 h-1 w-full rounded-full bg-muted overflow-hidden">
                            <div className="h-1 bg-blue-500 dark:bg-blue-400 rounded-full w-full" />
                        </div>
                        <p className="mt-1 text-xs text-muted-foreground">jurnal ditemukan</p>
                    </CardContent>
                </Card>

                {/* Disetujui */}
                <Card className="border-l-4 border-l-green-500 dark:border-l-green-400">
                    <CardContent className="p-4">
                        <div className="flex items-center justify-between">
                            <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                                Disetujui
                            </p>
                            <CheckSquare className="h-5 w-5 text-green-500 dark:text-green-400" />
                        </div>
                        <p className="mt-2 text-3xl font-bold text-green-600 dark:text-green-400">
                            {approved}
                        </p>
                        <div className="mt-2 h-1 w-full rounded-full bg-muted overflow-hidden">
                            <div
                                className="h-1 bg-green-500 dark:bg-green-400 rounded-full transition-all"
                                style={{ width: totalJournals ? `${(approved / totalJournals) * 100}%` : '0%' }}
                            />
                        </div>
                        <p className="mt-1 text-xs text-muted-foreground">
                            {totalJournals ? Math.round((approved / totalJournals) * 100) : 0}% dari total
                        </p>
                    </CardContent>
                </Card>

                {/* Menunggu */}
                <Card className="border-l-4 border-l-yellow-500 dark:border-l-yellow-400">
                    <CardContent className="p-4">
                        <div className="flex items-center justify-between">
                            <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                                Menunggu
                            </p>
                            <Clock className="h-5 w-5 text-yellow-500 dark:text-yellow-400" />
                        </div>
                        <p className="mt-2 text-3xl font-bold text-yellow-600 dark:text-yellow-400">
                            {pending}
                        </p>
                        <div className="mt-2 h-1 w-full rounded-full bg-muted overflow-hidden">
                            <div
                                className="h-1 bg-yellow-500 dark:bg-yellow-400 rounded-full transition-all"
                                style={{ width: totalJournals ? `${(pending / totalJournals) * 100}%` : '0%' }}
                            />
                        </div>
                        <p className="mt-1 text-xs text-muted-foreground">
                            {totalJournals ? Math.round((pending / totalJournals) * 100) : 0}% dari total
                        </p>
                    </CardContent>
                </Card>

                {/* Halaman */}
                <Card className="border-l-4 border-l-purple-500 dark:border-l-purple-400">
                    <CardContent className="p-4">
                        <div className="flex items-center justify-between">
                            <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                                Halaman
                            </p>
                            <AlertCircle className="h-5 w-5 text-purple-500 dark:text-purple-400" />
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

            {/* ── Filter + Table Card ── */}
            <Card>
                <CardHeader className="pb-3">
                    {/* Filter row */}
                    <div className="flex flex-wrap items-center gap-3">
                        <div className="flex items-center gap-2">
                            <Calendar className="h-4 w-4 text-muted-foreground" />
                            <Input
                                type="date"
                                value={selectedDate}
                                onChange={(e) => {
                                    setSelectedDate(e.target.value)
                                    setPage(0)
                                }}
                                className="w-40"
                            />
                            {selectedDate && (
                                <Button variant="ghost" size="sm" onClick={() => setSelectedDate('')}>
                                    Clear
                                </Button>
                            )}
                        </div>
                        <Select
                            value={selectedClass}
                            onValueChange={(v) => {
                                setSelectedClass(v)
                                setPage(0)
                            }}
                        >
                            <SelectTrigger className="w-36">
                                <SelectValue placeholder="Kelas" />
                            </SelectTrigger>
                            <SelectContent>
                                {CLASS_OPTIONS.map((c) => (
                                    <SelectItem key={c} value={c}>
                                        {c}
                                    </SelectItem>
                                ))}
                            </SelectContent>
                        </Select>
                    </div>
                </CardHeader>

                <CardContent>
                    {isLoading ? (
                        <div className="flex h-64 items-center justify-center">
                            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                        </div>
                    ) : journals.length === 0 ? (
                        <div className="flex h-64 flex-col items-center justify-center gap-2 text-muted-foreground">
                            <BookOpen className="h-10 w-10 opacity-30" />
                            <p>Tidak ada jurnal ditemukan.</p>
                        </div>
                    ) : (
                        <>
                            <div className="grid gap-4 md:grid-cols-2">
                                {journals.map((journal: any) => {
                                    const imgUrl = getImageUrl(journal)
                                    return (
                                        <Card
                                            key={journal.id}
                                            className="overflow-hidden transition-shadow hover:shadow-md dark:hover:shadow-primary/10"
                                        >
                                            <div className="flex">
                                                {/* Thumbnail */}
                                                {imgUrl ? (
                                                    <img
                                                        src={imgUrl}
                                                        alt="Evidence"
                                                        className="h-32 w-32 object-cover shrink-0"
                                                        onError={(e) => {
                                                            ;(e.target as HTMLImageElement).style.display = 'none'
                                                        }}
                                                    />
                                                ) : (
                                                    <div className="flex h-32 w-32 shrink-0 items-center justify-center bg-muted text-xs text-muted-foreground">
                                                        No Image
                                                    </div>
                                                )}

                                                {/* Content */}
                                                <div className="flex flex-1 flex-col justify-between p-4 min-w-0">
                                                    <div>
                                                        <div className="flex items-start justify-between gap-2">
                                                            <div className="min-w-0">
                                                                <h3 className="font-semibold truncate">
                                                                    {journal.profiles?.full_name}
                                                                </h3>
                                                                <p className="text-xs text-muted-foreground">
                                                                    {journal.profiles?.class_name} •{' '}
                                                                    {formatDate(journal.created_at)}{' '}
                                                                    {formatTime(journal.created_at)}
                                                                </p>
                                                            </div>
                                                            <Badge
                                                                className={`shrink-0 ${
                                                                    journal.is_approved
                                                                        ? 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-300'
                                                                        : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/40 dark:text-yellow-300'
                                                                }`}
                                                            >
                                                                {journal.is_approved ? 'Disetujui' : 'Menunggu'}
                                                            </Badge>
                                                        </div>
                                                        <p className="mt-2 text-sm font-medium line-clamp-1">
                                                            {journal.activity_title || journal.activities}
                                                        </p>
                                                        <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">
                                                            {journal.description || journal.notes}
                                                        </p>
                                                    </div>
                                                    <div className="mt-2 flex justify-end">
                                                        <Button
                                                            size="sm"
                                                            variant="outline"
                                                            onClick={() => openDetail(journal)}
                                                        >
                                                            <Eye className="mr-1 h-4 w-4" />
                                                            Detail
                                                        </Button>
                                                    </div>
                                                </div>
                                            </div>
                                        </Card>
                                    )
                                })}
                            </div>

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

            {/* ── Detail Dialog ── */}
            <Dialog open={detailOpen} onOpenChange={setDetailOpen}>
                <DialogContent className="max-w-2xl">
                    <DialogHeader>
                        <DialogTitle>Detail Jurnal</DialogTitle>
                    </DialogHeader>
                    {selectedJournal && (
                        <div className="space-y-4">
                            {/* Header */}
                            <div className="flex justify-between items-start">
                                <div>
                                    <h3 className="font-semibold text-lg">
                                        {selectedJournal.profiles?.full_name}
                                    </h3>
                                    <p className="text-sm text-muted-foreground">
                                        {selectedJournal.profiles?.class_name} •{' '}
                                        {formatDate(selectedJournal.created_at)}{' '}
                                        {formatTime(selectedJournal.created_at)}
                                    </p>
                                </div>
                                <Badge
                                    className={
                                        selectedJournal.is_approved
                                            ? 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-300'
                                            : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/40 dark:text-yellow-300'
                                    }
                                >
                                    {selectedJournal.is_approved ? 'Disetujui' : 'Menunggu'}
                                </Badge>
                            </div>

                            {/* Kegiatan */}
                            <div>
                                <h4 className="font-medium text-sm text-muted-foreground mb-1">Kegiatan</h4>
                                <p className="font-semibold">
                                    {selectedJournal.activity_title || selectedJournal.activities}
                                </p>
                            </div>

                            {/* Deskripsi */}
                            {(selectedJournal.description || selectedJournal.notes) && (
                                <div>
                                    <h4 className="font-medium text-sm text-muted-foreground mb-1">
                                        Deskripsi / Catatan
                                    </h4>
                                    <p className="whitespace-pre-wrap text-sm">
                                        {selectedJournal.description || selectedJournal.notes}
                                    </p>
                                </div>
                            )}

                            {/* Tantangan */}
                            {selectedJournal.challenges && (
                                <div>
                                    <h4 className="font-medium text-sm text-muted-foreground mb-1">Tantangan</h4>
                                    <p className="text-sm">{selectedJournal.challenges}</p>
                                </div>
                            )}

                            {/* Foto bukti */}
                            {getImageUrl(selectedJournal) && (
                                <div>
                                    <h4 className="font-medium text-sm text-muted-foreground mb-2">
                                        Bukti Kegiatan
                                    </h4>
                                    <img
                                        src={getImageUrl(selectedJournal)!}
                                        alt="Evidence"
                                        className="max-h-72 w-full rounded-lg object-contain bg-muted"
                                    />
                                </div>
                            )}

                            {/* Approve / Reject buttons */}
                            <div className="flex gap-3 pt-2 border-t">
                                <Button
                                    className="flex-1 bg-green-600 hover:bg-green-700 text-white dark:bg-green-700 dark:hover:bg-green-600"
                                    disabled={selectedJournal.is_approved || approveMutation.isPending}
                                    onClick={() =>
                                        approveMutation.mutate({ id: selectedJournal.id, approved: true })
                                    }
                                >
                                    {approveMutation.isPending ? (
                                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    ) : (
                                        <CheckCircle className="mr-2 h-4 w-4" />
                                    )}
                                    {selectedJournal.is_approved ? 'Sudah Disetujui' : 'Setujui Jurnal'}
                                </Button>
                                <Button
                                    variant="outline"
                                    className="flex-1 border-red-200 text-red-600 hover:bg-red-50 dark:border-red-800 dark:text-red-400 dark:hover:bg-red-950/40"
                                    disabled={!selectedJournal.is_approved || approveMutation.isPending}
                                    onClick={() =>
                                        approveMutation.mutate({ id: selectedJournal.id, approved: false })
                                    }
                                >
                                    <XCircle className="mr-2 h-4 w-4" />
                                    Batalkan Persetujuan
                                </Button>
                            </div>
                        </div>
                    )}
                </DialogContent>
            </Dialog>
        </div>
    )
}