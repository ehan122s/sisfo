import { useState } from 'react'
import { useWhatsAppLogs } from '@/hooks/use-notification-logs'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog'
import {
    IconEye,
    IconFilter,
    IconBell,
    IconFilterOff,
} from '@tabler/icons-react'
import { format } from 'date-fns'
import { id as localeId } from 'date-fns/locale'

const DEFAULT_FILTERS = {
    dateFrom: '',
    dateTo: '',
    notificationType: '',
    status: '',
}

export function NotificationHistoryPage() {
    const [filters, setFilters] = useState(DEFAULT_FILTERS)
    const [appliedFilters, setAppliedFilters] = useState(DEFAULT_FILTERS)
    const [selectedLog, setSelectedLog] = useState<any | null>(null)

    // Hanya menggunakan hook logs utama agar tidak memicu error stats undefined
    const { data: result, isLoading } = useWhatsAppLogs(appliedFilters)

    const logs = result?.data || []
    const totalCount = result?.count || 0

    const handleApply = () => setAppliedFilters({ ...filters })
    const handleReset = () => {
        setFilters(DEFAULT_FILTERS)
        setAppliedFilters(DEFAULT_FILTERS)
    }

    const hasActiveFilters = Object.values(appliedFilters).some(v => v !== '')

    return (
        <div className="bg-slate-50 dark:bg-[#0b0f19] min-h-screen p-6 space-y-6 text-slate-800 dark:text-slate-200 font-sans transition-colors duration-200">
            
            {/* Header Utama */}
            <div className="flex items-start justify-between border-b border-slate-200 dark:border-slate-800 pb-5">
                <div>
                    <h1 className="text-3xl font-black tracking-tight uppercase italic text-slate-900 dark:text-slate-100 flex items-center gap-2">
                        RIWAYAT <span className="text-blue-600 dark:text-blue-500">NOTIFIKASI</span>
                    </h1>
                    <p className="text-xs text-slate-500 dark:text-slate-400 mt-1 font-medium tracking-wide">
                        Monitoring pengiriman WhatsApp PKL secara real-time.
                    </p>
                </div>
                <div className="flex items-center gap-2 bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 rounded-full px-3 py-1.5 text-xs font-bold tracking-wider">
                    <span className="w-2 h-2 rounded-full bg-emerald-500 dark:bg-emerald-400 animate-pulse" />
                    LIVE SYSTEM ACTIVE
                </div>
            </div>

            {/* PANEL PENCARIAN TERPADU (Garis Biru di Kiri) */}
            <div className="bg-white dark:bg-[#111827] border border-slate-200 dark:border-slate-800 border-l-4 border-l-blue-600 dark:border-l-blue-500 rounded-xl p-5 shadow-sm dark:shadow-xl">
                <div className="flex items-center justify-between mb-4 border-b border-slate-100 dark:border-slate-800 pb-2.5">
                    <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                        <IconFilter className="h-4 w-4 text-blue-600 dark:text-blue-500" />
                        PENCARIAN TERPADU
                        {hasActiveFilters && (
                            <span className="px-2 py-0.5 text-[10px] bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-500/20 rounded">
                                Filter Active
                            </span>
                        )}
                    </div>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4 items-end">
                    {/* DARI TANGGAL */}
                    <div className="space-y-1.5">
                        <label className="text-[10px] font-bold tracking-wider text-slate-500 dark:text-slate-400 uppercase">Dari Tanggal</label>
                        <Input
                            type="date"
                            className="bg-slate-50 dark:bg-[#0b0f19] border-slate-200 dark:border-slate-800 text-slate-800 dark:text-slate-200 h-9 text-xs focus:border-blue-500 focus:ring-0"
                            value={filters.dateFrom}
                            onChange={e => setFilters(f => ({ ...f, dateFrom: e.target.value }))}
                        />
                    </div>

                    {/* SAMPAI TANGGAL */}
                    <div className="space-y-1.5">
                        <label className="text-[10px] font-bold tracking-wider text-slate-500 dark:text-slate-400 uppercase">Sampai Tanggal</label>
                        <Input
                            type="date"
                            className="bg-slate-50 dark:bg-[#0b0f19] border-slate-200 dark:border-slate-800 text-slate-800 dark:text-slate-200 h-9 text-xs focus:border-blue-500 focus:ring-0"
                            value={filters.dateTo}
                            onChange={e => setFilters(f => ({ ...f, dateTo: e.target.value }))}
                        />
                    </div>

                    {/* KATEGORI DROPDOWN (Menggunakan Select HTML Standar agar bebas error) */}
                    <div className="space-y-1.5">
                        <label className="text-[10px] font-bold tracking-wider text-slate-500 dark:text-slate-400 uppercase">Kategori</label>
                        <select
                            className="flex w-full rounded-md border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#0b0f19] text-slate-800 dark:text-slate-200 h-9 text-xs px-3 focus:border-blue-500 focus:outline-none"
                            value={filters.notificationType}
                            onChange={e => setFilters(f => ({ ...f, notificationType: e.target.value }))}
                        >
                            <option value="">Semua Tipe</option>
                            <option value="tepat_waktu">Tepat Waktu</option>
                            <option value="terlambat">Terlambat</option>
                            <option value="tidak_hadir">Tidak Hadir</option>
                            <option value="belum_isi_jurnal">Belum Isi Jurnal</option>
                        </select>
                    </div>

                    {/* STATUS DROPDOWN (Menggunakan Select HTML Standar agar bebas error) */}
                    <div className="space-y-1.5">
                        <label className="text-[10px] font-bold tracking-wider text-slate-500 dark:text-slate-400 uppercase">Status</label>
                        <select
                            className="flex w-full rounded-md border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#0b0f19] text-slate-800 dark:text-slate-200 h-9 text-xs px-3 focus:border-blue-500 focus:outline-none"
                            value={filters.status}
                            onChange={e => setFilters(f => ({ ...f, status: e.target.value }))}
                        >
                            <option value="">Semua Status</option>
                            <option value="terkirim">Terkirim</option>
                            <option value="gagal">Gagal</option>
                            <option value="pending">Pending</option>
                        </select>
                    </div>
                </div>

                {/* Tombol Aksi */}
                <div className="flex justify-end gap-2 mt-4">
                    {hasActiveFilters && (
                        <Button 
                            variant="outline"
                            onClick={handleReset} 
                            className="border-slate-200 dark:border-slate-800 bg-transparent hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-300 font-bold text-xs px-4 h-9 tracking-wider uppercase rounded-lg gap-1.5"
                        >
                            <IconFilterOff className="h-3.5 w-3.5" />
                            Reset
                        </Button>
                    )}
                    <Button 
                        onClick={handleApply} 
                        className="bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs px-5 h-9 tracking-wider uppercase rounded-lg shadow-md gap-1.5"
                    >
                        <IconFilter className="h-3.5 w-3.5" />
                        TERAPKAN
                    </Button>
                </div>
            </div>

            {/* TABEL DATA LOG (Garis Biru di Kiri) */}
            <div className="bg-white dark:bg-[#111827] border border-slate-200 dark:border-slate-800 border-l-4 border-l-blue-600 dark:border-l-blue-500 rounded-xl shadow-sm dark:shadow-2xl overflow-hidden">
                <div className="p-4 border-b border-slate-100 dark:border-slate-800/80 flex items-center justify-between">
                    <div className="flex items-center gap-2 text-xs font-bold text-slate-600 dark:text-slate-300 uppercase tracking-wider">
                        <span className="p-1 rounded bg-blue-500/10 text-blue-600 dark:text-blue-400">
                            <IconBell className="h-3.5 w-3.5" />
                        </span>
                        Log Aktivitas Notifikasi
                    </div>
                    <span className="text-[10px] font-bold tracking-widest text-slate-400 dark:text-slate-500 uppercase">
                        TOTAL {totalCount} ENTRI DITEMUKAN
                    </span>
                </div>

                <div className="overflow-x-auto">
                    {isLoading ? (
                        <div className="text-center py-20 text-xs text-slate-400 dark:text-slate-500 font-bold tracking-widest animate-pulse">
                            MEMUAT DATA DATABASE...
                        </div>
                    ) : logs.length > 0 ? (
                        <Table>
                            <TableHeader className="bg-slate-50/70 dark:bg-[#0b0f19]/60 border-b border-slate-200 dark:border-slate-800">
                                <TableRow className="hover:bg-transparent border-slate-200 dark:border-slate-800">
                                    <TableHead className="text-slate-500 dark:text-slate-400 font-bold text-[11px] uppercase tracking-wider h-11">Waktu</TableHead>
                                    <TableHead className="text-slate-500 dark:text-slate-400 font-bold text-[11px] uppercase tracking-wider h-11">Nama Siswa</TableHead>
                                    <TableHead className="text-slate-500 dark:text-slate-400 font-bold text-[11px] uppercase tracking-wider h-11">Kelas</TableHead>
                                    <TableHead className="text-slate-500 dark:text-slate-400 font-bold text-[11px] uppercase tracking-wider h-11">Judul Notifikasi</TableHead>
                                    <TableHead className="text-slate-500 dark:text-slate-400 font-bold text-[11px] uppercase tracking-wider h-11">Tipe</TableHead>
                                    <TableHead className="text-slate-500 dark:text-slate-400 font-bold text-[11px] uppercase tracking-wider h-11">Status</TableHead>
                                    <TableHead className="text-slate-500 dark:text-slate-400 font-bold text-[11px] uppercase tracking-wider h-11 text-center">Aksi</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {logs.map((log: any) => (
                                    <TableRow key={log.id} className="border-slate-100 dark:border-slate-800/50 hover:bg-slate-50 dark:hover:bg-slate-800/20 transition-colors">
                                        <TableCell className="font-mono text-xs text-slate-500 dark:text-slate-400 whitespace-nowrap py-3.5">
                                            {log.created_at ? format(new Date(log.created_at), 'dd MMM yy • HH:mm', { locale: localeId }) : '-'}
                                        </TableCell>
                                        <TableCell className="py-3.5">
                                            <div className="font-bold text-xs text-slate-800 dark:text-slate-200">{log.profiles?.full_name || 'Admin'}</div>
                                        </TableCell>
                                        <TableCell className="py-3.5">
                                            <div className="text-[10px] text-slate-400 dark:text-slate-500 font-semibold">{log.profiles?.class_name || '-'}</div>
                                        </TableCell>
                                        <TableCell className="max-w-[240px] truncate text-xs text-slate-600 dark:text-slate-300 py-3.5 font-medium">
                                            {log.title || '-'}
                                        </TableCell>
                                        <TableCell className="py-3.5">
                                            <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300">
                                                {log.type ? log.type.replace('_', ' ') : 'Info'}
                                            </span>
                                        </TableCell>
                                        <TableCell className="py-3.5">
                                            <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider ${
                                                log.status?.toLowerCase() === 'terkirim' || log.is_read
                                                    ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20' 
                                                    : log.status?.toLowerCase() === 'gagal'
                                                    ? 'bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-500/20'
                                                    : 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20'
                                            }`}>
                                                {log.status || (log.is_read ? 'Terkirim' : 'Pending')}
                                            </span>
                                        </TableCell>
                                        <TableCell className="text-center py-3.5">
                                            <Button variant="ghost" size="sm" onClick={() => setSelectedLog(log)} className="h-7 w-7 p-0 text-slate-400 hover:text-slate-800 dark:hover:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-800">
                                                <IconEye className="h-4 w-4" />
                                            </Button>
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    ) : (
                        <div className="text-center py-24 flex flex-col items-center justify-center gap-2 bg-white dark:bg-[#111827]">
                            <div className="p-3.5 rounded-full bg-slate-50 dark:bg-[#0b0f19] border border-slate-100 dark:border-slate-800 text-slate-400 dark:text-slate-600 shadow-inner">
                                <IconBell className="h-6 w-6 opacity-30" />
                            </div>
                            <p className="text-[11px] font-bold tracking-widest text-slate-400 dark:text-slate-500 uppercase mt-2">DATABASE KOSONG</p>
                        </div>
                    )}
                </div>
            </div>

            {/* DETAIL MODAL DRAWER */}
            <Dialog open={!!selectedLog} onOpenChange={() => setSelectedLog(null)}>
                <DialogContent className="bg-white dark:bg-[#111827] border-slate-200 dark:border-slate-800 text-slate-800 dark:text-slate-100 max-w-md rounded-xl">
                    <DialogHeader className="border-b border-slate-100 dark:border-slate-800 pb-3">
                        <DialogTitle className="text-sm font-bold uppercase tracking-wider text-slate-600 dark:text-slate-300">Detail Notifikasi</DialogTitle>
                    </DialogHeader>
                    {selectedLog && (
                        <div className="space-y-4 pt-2 text-xs">
                            <div className="grid grid-cols-2 gap-4 bg-slate-50 dark:bg-[#0b0f19] p-3 rounded-lg border border-slate-200 dark:border-slate-800">
                                <div>
                                    <p className="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider mb-0.5">Siswa</p>
                                    <p className="font-bold text-slate-800 dark:text-slate-200">{selectedLog.profiles?.full_name || 'Admin'}</p>
                                </div>
                                <div>
                                    <p className="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider mb-0.5">Kelas</p>
                                    <p className="text-slate-600 dark:text-slate-300 font-medium">{selectedLog.profiles?.class_name || '-'}</p>
                                </div>
                                <div>
                                    <p className="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider mb-0.5">Waktu Kirim</p>
                                    <p className="font-mono text-slate-500 dark:text-slate-400">
                                        {selectedLog.created_at ? format(new Date(selectedLog.created_at), 'dd MMM yyyy • HH:mm:ss', { locale: localeId }) : '-'}
                                    </p>
                                </div>
                                <div>
                                    <p className="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider mb-0.5">Status</p>
                                    <span className={`text-[10px] font-bold uppercase ${
                                        selectedLog.status?.toLowerCase() === 'terkirim' || selectedLog.is_read ? 'text-emerald-600 dark:text-emerald-400' : 'text-amber-600 dark:text-amber-400'
                                    }`}>
                                        {selectedLog.status || 'PENDING'}
                                    </span>
                                </div>
                            </div>
                            <div>
                                <p className="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider mb-1">Judul Notifikasi</p>
                                <p className="font-bold text-slate-800 dark:text-slate-200 bg-slate-50 dark:bg-[#0b0f19] px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-800">{selectedLog.title || '-'}</p>
                            </div>
                            {selectedLog.message && (
                                <div>
                                    <p className="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider mb-1">Isi Pesan WhatsApp</p>
                                    <div className="bg-slate-50 dark:bg-[#0b0f19] border border-slate-200 dark:border-slate-800 rounded-lg p-3 text-slate-700 dark:text-slate-300 font-mono whitespace-pre-wrap leading-relaxed text-[11px] max-h-48 overflow-y-auto">
                                        {selectedLog.message}
                                    </div>
                                </div>
                            )}
                        </div>
                    )}
                </DialogContent>
            </Dialog>
        </div>
    )
}