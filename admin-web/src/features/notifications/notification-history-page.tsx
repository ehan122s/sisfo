import { useState } from 'react'
import { useNotificationLogs, useNotificationStats } from '@/hooks/use-notification-logs'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { IconFilter, IconX, IconMessageCheck, IconClock, IconUserX, IconBook, IconEye, IconBellRinging, IconActivity } from '@tabler/icons-react'
import { Loader2, BellOff, Search } from 'lucide-react'
import { format } from 'date-fns'
import { id as localeId } from 'date-fns/locale'
import type { NotificationLog } from '@/types'

const notificationTypeLabels = {
    on_time: 'Tepat Waktu',
    late: 'Terlambat',
    absent: 'Tidak Hadir',
    no_journal: 'Belum Isi Jurnal',
}

const notificationTypeIcons = {
    on_time: IconMessageCheck,
    late: IconClock,
    absent: IconUserX,
    no_journal: IconBook,
}

// FIX: Menggunakan background transparan murni, teks berwarna kontras, dan mematikan shadow bawaan
const notificationTypeColors = {
    on_time: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20 shadow-none hover:bg-emerald-500/15',
    late: 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20 shadow-none hover:bg-amber-500/15',
    absent: 'bg-red-500/10 text-red-600 dark:text-red-400 border-red-500/20 shadow-none hover:bg-red-500/15',
    no_journal: 'bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/20 shadow-none hover:bg-blue-500/15',
}

const statusColors = {
    sent: 'bg-green-500/10 text-green-600 dark:text-green-400 border-green-500/20 shadow-none hover:bg-green-500/15',
    failed: 'bg-red-500/10 text-red-600 dark:text-red-400 border-red-500/20 shadow-none hover:bg-red-500/15',
    pending: 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20 shadow-none hover:bg-amber-500/15',
}

const DEFAULT_FILTERS = {
    dateFrom: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    dateTo: new Date().toISOString().split('T')[0],
    studentId: '',
    notificationType: '',
    status: '',
}

export function NotificationHistoryPage() {
    const [tempFilters, setTempFilters] = useState(DEFAULT_FILTERS)
    const [appliedFilters, setAppliedFilters] = useState(DEFAULT_FILTERS)
    const [selectedLog, setSelectedLog] = useState<NotificationLog | null>(null)

    const { data: logs, isLoading, refetch } = useNotificationLogs(appliedFilters)
    const { data: stats } = useNotificationStats()

    const handleFilterChange = (key: string, value: string) => {
        setTempFilters(prev => ({ ...prev, [key]: value }))
    }

    const applyFilters = () => {
        setAppliedFilters(tempFilters)
        if (refetch) refetch()
    }

    const clearFilters = () => {
        setTempFilters(DEFAULT_FILTERS)
        setAppliedFilters(DEFAULT_FILTERS)
    }

    return (
        <div className="p-6 space-y-6 min-h-screen bg-slate-50/50 dark:bg-transparent transition-colors duration-300">

            {/* ── Header ── */}
            <div className="flex flex-col md:flex-row md:items-start justify-between gap-4">
                <div>
                    <div className="flex gap-1 mb-3">
                        <div className="h-1 w-8 rounded-full bg-blue-500" />
                        <div className="h-1 w-4 rounded-full bg-blue-800" />
                    </div>
                    <h1 className="text-4xl md:text-5xl font-black italic tracking-tight text-slate-900 dark:text-white uppercase transition-colors">
                        RIWAYAT{" "}
                        <span className="text-blue-600 dark:text-blue-400">NOTIFIKASI</span>
                    </h1>
                    <p className="text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
                        Monitoring pengiriman WhatsApp PKL secara real-time.
                    </p>
                </div>
                <div className="mt-2 md:mt-1">
                    {/* FIX: Variant outline agar tidak ngeblok */}
                    <Badge variant="outline" className="bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 font-black text-xs px-4 py-1.5 uppercase tracking-widest shadow-none">
                        <span className="relative flex h-2 w-2 mr-2">
                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                        </span>
                        Live System Active
                    </Badge>
                </div>
            </div>

            {/* ── Stats Cards ── */}
            {stats && (
                <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 md:grid-cols-4">
                    {[
                        { label: 'Total Hari Ini', value: stats.total, barColor: 'bg-blue-500' },
                        { label: 'Terkirim', value: stats.sent, barColor: 'bg-emerald-500' },
                        { label: 'Gagal', value: stats.failed, barColor: 'bg-red-500' },
                        { label: 'Pending', value: stats.pending, barColor: 'bg-amber-400' }
                    ].map((stat, i) => (
                        <Card key={i} className="bg-white dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800/80 rounded-2xl overflow-hidden shadow-sm transition-all duration-300">
                            <CardContent className="p-5">
                                <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-1">{stat.label}</p>
                                <p className="text-4xl font-black text-slate-900 dark:text-white tracking-tight">{stat.value}</p>
                                <div className="h-1 w-full bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden mt-3">
                                    <div className={`h-full rounded-full ${stat.barColor}`} style={{ width: '100%' }} />
                                </div>
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}

            {/* ── Filter Form Section ── */}
            <Card className="bg-white dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800/80 rounded-2xl overflow-hidden shadow-sm transition-all duration-300">
                <CardHeader className="border-b border-slate-100 dark:border-slate-800/60 px-6 py-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                            <Search className="h-4 w-4 text-slate-400" />
                            <CardTitle className="text-xs font-black uppercase tracking-widest text-slate-400 dark:text-slate-500">Pencarian Terpadu</CardTitle>
                        </div>
                        <Button variant="ghost" size="sm" onClick={clearFilters} className="font-black text-xs text-slate-400 dark:text-slate-500 hover:text-red-500 hover:bg-red-500/10 dark:hover:bg-red-500/10 transition-colors rounded-xl">
                            <IconX className="h-4 w-4 mr-1" /> Reset
                        </Button>
                    </div>
                </CardHeader>
                <CardContent className="pt-5 px-6 pb-6">
                    <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 md:grid-cols-5">
                        {[
                            { id: 'dateFrom', label: 'Dari Tanggal', type: 'date' },
                            { id: 'dateTo', label: 'Sampai Tanggal', type: 'date' }
                        ].map((f) => (
                            <div key={f.id} className="space-y-2">
                                <Label htmlFor={f.id} className="text-[10px] font-black uppercase text-slate-400 dark:text-slate-500 tracking-widest">{f.label}</Label>
                                <Input
                                    id={f.id}
                                    type={f.type}
                                    className="bg-slate-50 dark:bg-slate-800 border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus-visible:ring-blue-500 rounded-xl"
                                    value={tempFilters[f.id as keyof typeof tempFilters]}
                                    onChange={(e) => handleFilterChange(f.id, e.target.value)}
                                />
                            </div>
                        ))}
                        <div className="space-y-2">
                            <Label className="text-[10px] font-black uppercase text-slate-400 dark:text-slate-500 tracking-widest">Kategori</Label>
                            <Select value={tempFilters.notificationType || 'all'} onValueChange={(v) => handleFilterChange('notificationType', v === 'all' ? '' : v)}>
                                <SelectTrigger className="bg-slate-50 dark:bg-slate-800 border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus:ring-blue-500 rounded-xl">
                                    <SelectValue placeholder="Semua Tipe" />
                                </SelectTrigger>
                                <SelectContent className="bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-800 rounded-xl">
                                    <SelectItem value="all">Semua Tipe</SelectItem>
                                    <SelectItem value="on_time">Tepat Waktu</SelectItem>
                                    <SelectItem value="late">Terlambat</SelectItem>
                                    <SelectItem value="absent">Tidak Hadir</SelectItem>
                                    <SelectItem value="no_journal">Belum Isi Jurnal</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>
                        <div className="space-y-2">
                            <Label className="text-[10px] font-black uppercase text-slate-400 dark:text-slate-500 tracking-widest">Status</Label>
                            <Select value={tempFilters.status || 'all'} onValueChange={(v) => handleFilterChange('status', v === 'all' ? '' : v)}>
                                <SelectTrigger className="bg-slate-50 dark:bg-slate-800 border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus:ring-blue-500 rounded-xl">
                                    <SelectValue placeholder="Semua Status" />
                                </SelectTrigger>
                                <SelectContent className="bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-800 rounded-xl">
                                    <SelectItem value="all">Semua Status</SelectItem>
                                    <SelectItem value="sent">Terkirim</SelectItem>
                                    <SelectItem value="failed">Gagal</SelectItem>
                                    <SelectItem value="pending">Pending</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>
                        <div className="flex items-end">
                            <Button
                                onClick={applyFilters}
                                className="w-full bg-blue-600 hover:bg-blue-700 text-white font-black text-xs uppercase tracking-widest rounded-xl shadow-none transition-colors py-5"
                            >
                                <IconFilter className="h-4 w-4 mr-2" /> Terapkan
                            </Button>
                        </div>
                    </div>
                </CardContent>
            </Card>

            {/* ── Log Activity Table Card ── */}
            <Card className="bg-white dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800/80 rounded-2xl overflow-hidden shadow-sm transition-all duration-300">
                <CardHeader className="border-b border-slate-100 dark:border-slate-800/60 px-6 py-4">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-blue-500/10 rounded-xl">
                            <IconActivity className="h-4 w-4 text-blue-500 dark:text-blue-400" />
                        </div>
                        <div>
                            <CardTitle className="text-sm font-black text-slate-900 dark:text-white">Log Aktivitas Pengiriman</CardTitle>
                            <CardDescription className="text-[10px] font-black uppercase tracking-widest text-slate-400 dark:text-slate-500 mt-0.5">
                                Total {logs?.length || 0} entri ditemukan dalam database
                            </CardDescription>
                        </div>
                    </div>
                </CardHeader>
                <CardContent className="p-0">
                    {isLoading ? (
                        <div className="flex flex-col items-center justify-center py-24 gap-4">
                            <Loader2 className="h-10 w-10 animate-spin text-blue-500" />
                            <p className="text-xs font-black text-slate-500 tracking-widest uppercase animate-pulse">Memuat Data...</p>
                        </div>
                    ) : logs && logs.length > 0 ? (
                        <div className="overflow-x-auto">
                            <Table>
                                <TableHeader className="bg-slate-50/70 dark:bg-slate-800/40 border-b border-slate-100 dark:border-slate-800/60">
                                    <TableRow className="border-none hover:bg-transparent">
                                        <TableHead className="font-black text-[10px] uppercase text-slate-400 dark:text-slate-500 p-4 tracking-widest">Waktu</TableHead>
                                        <TableHead className="font-black text-[10px] uppercase text-slate-400 dark:text-slate-500 p-4 tracking-widest">Nama Siswa</TableHead>
                                        <TableHead className="font-black text-[10px] uppercase text-slate-400 dark:text-slate-500 p-4 tracking-widest">Kategori</TableHead>
                                        <TableHead className="font-black text-[10px] uppercase text-slate-400 dark:text-slate-500 p-4 tracking-widest">Status</TableHead>
                                        <TableHead className="text-right font-black text-[10px] uppercase text-slate-400 dark:text-slate-500 p-4 tracking-widest w-[80px]">Aksi</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {logs.map((log) => {
                                        const Icon = notificationTypeIcons[log.notification_type as keyof typeof notificationTypeIcons] || IconBellRinging
                                        return (
                                            <TableRow key={log.id} className="border-b border-slate-100 dark:border-slate-800/60 last:border-none hover:bg-slate-50/50 dark:hover:bg-slate-800/30 transition-colors">
                                                <TableCell className="font-mono text-[11px] font-bold text-slate-500 dark:text-slate-400 p-4 uppercase">
                                                    {format(new Date(log.sent_at), 'dd MMM yy • HH:mm', { locale: localeId })}
                                                </TableCell>
                                                <TableCell className="p-4">
                                                    <div className="flex flex-col">
                                                        <span className="font-black text-slate-800 dark:text-slate-200 text-sm">{log.profiles?.full_name}</span>
                                                        <span className="text-[10px] font-bold text-slate-400 dark:text-slate-500">{log.profiles?.class_name}</span>
                                                    </div>
                                                </TableCell>
                                                <TableCell className="p-4">
                                                    {/* FIX: Menggunakan variant="outline" agar background solid hitam/putih bawaan shadcn hilang */}
                                                    <Badge variant="outline" className={`${notificationTypeColors[log.notification_type as keyof typeof notificationTypeColors]} font-black text-[10px]`}>
                                                        <Icon className="h-3 w-3 mr-1.5" />
                                                        {notificationTypeLabels[log.notification_type as keyof typeof notificationTypeLabels]}
                                                    </Badge>
                                                </TableCell>
                                                <TableCell className="p-4">
                                                    {/* FIX: Menggunakan variant="outline" agar background solid hitam/putih bawaan shadcn hilang */}
                                                    <Badge variant="outline" className={`${statusColors[log.status as keyof typeof statusColors]} font-black text-[10px] px-3 py-1`}>
                                                        {log.status === 'sent' ? 'SUCCESS' : log.status === 'failed' ? 'ERROR' : 'WAITING'}
                                                    </Badge>
                                                </TableCell>
                                                <TableCell className="text-right p-4">
                                                    <Button variant="ghost" size="sm" onClick={() => setSelectedLog(log)} className="h-8 w-8 p-0 rounded-lg text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors">
                                                        <IconEye className="h-4 w-4" />
                                                    </Button>
                                                </TableCell>
                                            </TableRow>
                                        )
                                    })}
                                </TableBody>
                            </Table>
                        </div>
                    ) : (
                        <div className="flex flex-col items-center justify-center py-24 gap-4">
                            <div className="p-6 bg-slate-50 dark:bg-slate-800/60 rounded-full border border-dashed border-slate-200 dark:border-slate-700">
                                <BellOff className="h-12 w-12 text-slate-300 dark:text-slate-600" />
                            </div>
                            <p className="text-[10px] font-black uppercase tracking-widest text-slate-400 dark:text-slate-500">Database Kosong</p>
                        </div>
                    )}
                </CardContent>
            </Card>

            {/* ── Modal Detail Dialog ── */}
            <Dialog open={!!selectedLog} onOpenChange={() => setSelectedLog(null)}>
                <DialogContent className="max-w-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-0 overflow-hidden shadow-2xl transition-all">
                    <div className="h-1 bg-blue-600 w-full" />
                    <DialogHeader className="p-7 pb-4">
                        <DialogTitle className="text-xl font-black text-slate-900 dark:text-white flex items-center gap-3">
                            <div className="h-10 w-1 bg-blue-600 rounded-full" />
                            Review Transmisi Notifikasi
                        </DialogTitle>
                        <div className="flex mt-3">
                            <DialogDescription className="font-mono text-[10px] font-black uppercase text-blue-600 dark:text-blue-400 bg-blue-500/10 px-3 py-1.5 rounded-lg border border-blue-500/20 tracking-tighter">
                                ID LOG: {selectedLog?.id} • {selectedLog && format(new Date(selectedLog.sent_at), 'eeee, dd MMMM yyyy - HH:mm', { locale: localeId })}
                            </DialogDescription>
                        </div>
                    </DialogHeader>

                    {selectedLog && (
                        <div className="px-7 pb-7 space-y-6">
                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 bg-slate-50/80 dark:bg-slate-800/40 p-5 rounded-xl border border-slate-100 dark:border-slate-800/80">
                                <div className="space-y-2">
                                    <Label className="text-[9px] font-black uppercase text-slate-400 dark:text-slate-500 tracking-widest">Profil Siswa Magang</Label>
                                    <p className="font-black text-lg text-slate-900 dark:text-white uppercase leading-none">{selectedLog.profiles?.full_name}</p>
                                    {/* FIX: Variant outline pada badge modal */}
                                    <Badge variant="outline" className="bg-blue-500/15 text-blue-600 dark:text-blue-400 border-blue-500/20 font-black text-[9px] px-3 shadow-none mt-1">{selectedLog.profiles?.class_name}</Badge>
                                </div>
                                <div className="space-y-2 sm:text-right">
                                    <Label className="text-[9px] font-black uppercase text-slate-400 dark:text-slate-500 tracking-widest">Tujuan WhatsApp</Label>
                                    <p className="font-mono font-bold text-lg text-slate-800 dark:text-slate-200 leading-none">{selectedLog.parent_phone_number}</p>
                                    {/* FIX: Variant outline pada badge modal */}
                                    <Badge variant="outline" className="bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border-emerald-500/20 font-black text-[9px] shadow-none mt-1">VERIFIED CONTACT</Badge>
                                </div>
                            </div>

                            <div className="space-y-3">
                                <Label className="text-[9px] font-black uppercase text-slate-400 dark:text-slate-500 tracking-widest">Isi Pesan Sistem</Label>
                                <div className="bg-slate-50/50 dark:bg-slate-800/20 border border-slate-200 dark:border-slate-800 p-5 rounded-xl text-sm leading-relaxed text-slate-600 dark:text-slate-300 italic whitespace-pre-wrap">
                                    "{selectedLog.message_sent}"
                                </div>
                            </div>
                        </div>
                    )}
                </DialogContent>
            </Dialog>
        </div>
    )
}