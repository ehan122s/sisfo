import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
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
import { ChevronLeft, ChevronRight, Calendar, Eye, FileSpreadsheet, FileText, Loader2 } from 'lucide-react'
import { exportToExcel, exportToPDF } from '@/lib/export'
import type { DailyJournal } from '@/types'
import { getClassList } from '@/features/reports/services/report-service'

export function JournalsPage() {
    const [page, setPage] = useState(0)
    const [selectedDate, setSelectedDate] = useState<string>('')
    const [selectedClass, setSelectedClass] = useState('Semua')
    const [selectedJournal, setSelectedJournal] = useState<DailyJournal | null>(null)
    const [detailOpen, setDetailOpen] = useState(false)
    const pageSize = 10

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

            // Filter by date
            if (selectedDate) {
                const startOfDay = `${selectedDate}T00:00:00`
                const endOfDay = `${selectedDate}T23:59:59`
                query = query.gte('created_at', startOfDay).lte('created_at', endOfDay)
            }

            // Filter by class
            if (selectedClass !== 'Semua') {
                query = query.eq('profiles.class_name', selectedClass)
            }

            const { data, count, error } = await query.range(start, end)

            if (error) throw error

            return {
                data: (data ?? []) as (DailyJournal & { profiles: { full_name: string; class_name: string; nisn: string } })[],
                count: count ?? 0
            }
        },
    })

    const journals = journalsResult?.data || []
    const totalCount = journalsResult?.count || 0
    const totalPages = Math.ceil(totalCount / pageSize)

    const formatDate = (dateStr: string) => {
        return new Date(dateStr).toLocaleDateString('id-ID', {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
        })
    }

    const formatTime = (dateStr: string) => {
        return new Date(dateStr).toLocaleTimeString('id-ID', {
            hour: '2-digit',
            minute: '2-digit',
        })
    }

    const openDetail = (journal: DailyJournal) => {
        setSelectedJournal(journal)
        setDetailOpen(true)
    }

    const handleExportExcel = () => {
        if (!journals.length) return
        const headers = ['Nama', 'Kelas', 'Tanggal', 'Judul Kegiatan', 'Deskripsi', 'Status']
        const rows = journals.map(j => [
            j.profiles?.full_name || '',
            j.profiles?.class_name || '-',
            formatDate(j.created_at),
            j.activity_title,
            j.description,
            j.is_approved ? 'Disetujui' : 'Menunggu',
        ])
        exportToExcel({ headers, rows, filename: `jurnal_${selectedDate || 'semua'}` })
    }

    const handleExportPDF = () => {
        if (!journals.length) return
        const headers = ['Nama', 'Kelas', 'Tanggal', 'Judul Kegiatan', 'Status']
        const rows = journals.map(j => [
            j.profiles?.full_name || '',
            j.profiles?.class_name || '-',
            formatDate(j.created_at),
            j.activity_title,
            j.is_approved ? 'Disetujui' : 'Menunggu',
        ])
        exportToPDF({
            headers,
            rows,
            filename: `jurnal_${selectedDate || 'semua'}`,
            title: `Laporan Jurnal${selectedDate ? ` - ${new Date(selectedDate).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}` : ''}`
        })
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Laporan Jurnal</h1>
                    <p className="text-muted-foreground">Data jurnal harian siswa PKL per kelas.</p>
                </div>
                <div className="flex gap-2">
                    <Button variant="outline" size="sm" onClick={handleExportExcel}>
                        <FileSpreadsheet className="mr-2 h-4 w-4" />
                        Excel
                    </Button>
                    <Button variant="outline" size="sm" onClick={handleExportPDF}>
                        <FileText className="mr-2 h-4 w-4" />
                        PDF
                    </Button>
                </div>
            </div>

            <Card>
                <CardHeader>
                    <div className="flex flex-wrap items-center gap-4">
                        {/* Date Picker */}
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

                        {/* Class Filter */}
                        <Select value={selectedClass} onValueChange={(v) => { setSelectedClass(v); setPage(0) }}>
                            <SelectTrigger className="w-36">
                                <SelectValue placeholder="Kelas" />
                            </SelectTrigger>
                            <SelectContent>
                                {CLASS_OPTIONS.map((c) => (
                                    <SelectItem key={c} value={c}>{c}</SelectItem>
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
                        <div className="flex h-64 items-center justify-center text-muted-foreground">
                            Tidak ada jurnal ditemukan.
                        </div>
                    ) : (
                        <>
                            <div className="grid gap-4 md:grid-cols-2">
                                {journals.map((journal) => (
                                    <Card key={journal.id} className="overflow-hidden">
                                        <div className="flex">
                                            {/* Thumbnail */}
                                            {journal.evidence_photo ? (
                                                <img
                                                    src={journal.evidence_photo}
                                                    alt="Evidence"
                                                    className="h-32 w-32 object-cover"
                                                />
                                            ) : (
                                                <div className="flex h-32 w-32 items-center justify-center bg-muted text-muted-foreground">
                                                    No Image
                                                </div>
                                            )}

                                            {/* Content */}
                                            <div className="flex flex-1 flex-col justify-between p-4">
                                                <div>
                                                    <div className="flex items-start justify-between">
                                                        <div>
                                                            <h3 className="font-semibold">{journal.profiles?.full_name}</h3>
                                                            <p className="text-sm text-muted-foreground">
                                                                {journal.profiles?.class_name} • {formatDate(journal.created_at)} {formatTime(journal.created_at)}
                                                            </p>
                                                        </div>
                                                        <Badge className={journal.is_approved ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}>
                                                            {journal.is_approved ? 'Disetujui' : 'Menunggu'}
                                                        </Badge>
                                                    </div>
                                                    <p className="mt-2 text-sm font-medium">{journal.activity_title}</p>
                                                    <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">
                                                        {journal.description}
                                                    </p>
                                                </div>
                                                <div className="mt-2 flex justify-end">
                                                    <Button size="sm" variant="outline" onClick={() => openDetail(journal)}>
                                                        <Eye className="mr-1 h-4 w-4" />
                                                        Detail
                                                    </Button>
                                                </div>
                                            </div>
                                        </div>
                                    </Card>
                                ))}
                            </div>

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

            {/* Detail Dialog */}
            <Dialog open={detailOpen} onOpenChange={setDetailOpen}>
                <DialogContent className="max-w-2xl">
                    <DialogHeader>
                        <DialogTitle>Detail Jurnal</DialogTitle>
                    </DialogHeader>
                    {selectedJournal && (
                        <div className="space-y-4">
                            <div className="flex justify-between">
                                <div>
                                    <h3 className="font-semibold">
                                        {(selectedJournal as DailyJournal & { profiles?: { full_name: string } }).profiles?.full_name}
                                    </h3>
                                    <p className="text-sm text-muted-foreground">
                                        {formatDate(selectedJournal.created_at)} • {formatTime(selectedJournal.created_at)}
                                    </p>
                                </div>
                                <Badge className={selectedJournal.is_approved ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'}>
                                    {selectedJournal.is_approved ? 'Disetujui' : 'Menunggu'}
                                </Badge>
                            </div>

                            <div>
                                <h4 className="font-medium">Judul Kegiatan</h4>
                                <p>{selectedJournal.activity_title}</p>
                            </div>

                            <div>
                                <h4 className="font-medium">Deskripsi</h4>
                                <p className="whitespace-pre-wrap">{selectedJournal.description}</p>
                            </div>

                            {selectedJournal.evidence_photo && (
                                <div>
                                    <h4 className="font-medium">Bukti Kegiatan</h4>
                                    <img
                                        src={selectedJournal.evidence_photo}
                                        alt="Evidence"
                                        className="mt-2 max-h-96 rounded-lg object-contain"
                                    />
                                </div>
                            )}
                        </div>
                    )}
                </DialogContent>
            </Dialog>
        </div >
    )
}
