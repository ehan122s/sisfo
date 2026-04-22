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

const notificationTypeColors = {
    on_time: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400 border-emerald-200 dark:border-emerald-500/20',
    late: 'bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400 border-amber-200 dark:border-amber-500/20',
    absent: 'bg-red-50 text-red-700 dark:bg-red-500/10 dark:text-red-400 border-red-200 dark:border-red-500/20',
    no_journal: 'bg-blue-50 text-blue-700 dark:bg-blue-500/10 dark:text-blue-400 border-blue-200 dark:border-blue-500/20',
}

const statusColors = {
    sent: 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400',
    failed: 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400',
    pending: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-500/20 dark:text-yellow-400',
}

export function NotificationHistoryPage() {
    const [filters, setFilters] = useState({
        dateFrom: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        dateTo: new Date().toISOString().split('T')[0],
        studentId: '',
        notificationType: '',
        status: '',
    })
    const [selectedLog, setSelectedLog] = useState<NotificationLog | null>(null)

    const { data: logs, isLoading } = useNotificationLogs(filters)
    const { data: stats } = useNotificationStats()

    const handleFilterChange = (key: string, value: string) => {
        setFilters(prev => ({ ...prev, [key]: value }))
    }

    const clearFilters = () => {
        setFilters({
            dateFrom: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
            dateTo: new Date().toISOString().split('T')[0],
            studentId: '',
            notificationType: '',
            status: '',
        })
    }

    return (
        <div className="p-6 space-y-8 min-h-screen transition-colors duration-300 bg-slate-50 dark:bg-slate-950">
            {/* Header Area */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 p-6 rounded-2xl bg-white dark:bg-slate-900 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border dark:border-white/5 relative overflow-hidden group">
                <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500/5 blur-3xl rounded-full -mr-16 -mt-16 group-hover:bg-blue-500/10 transition-all duration-700"></div>
                
                <div className="relative flex items-center gap-5">
                    <div className="relative">
                        <div className="absolute -inset-1 bg-blue-500 rounded-xl blur opacity-25 group-hover:opacity-60 transition duration-1000"></div>
                        <div className="relative p-4 bg-blue-600 rounded-xl shadow-lg shadow-blue-500/50">
                            <IconBellRinging className="h-7 w-7 text-white" />
                        </div>
                    </div>
                    <div>
                        <h1 className="text-3xl font-black tracking-tight text-slate-900 dark:text-white">
                            Riwayat <span className="text-blue-600 dark:text-blue-400">Notifikasi</span>
                        </h1>
                        <p className="text-muted-foreground font-semibold text-sm">Monitoring pengiriman WhatsApp PKL secara real-time.</p>
                    </div>
                </div>
                <div className="relative hidden md:block">
                    <Badge variant="outline" className="bg-blue-50 dark:bg-blue-950 border-blue-200 dark:border-blue-800 text-blue-700 dark:text-blue-300 font-black px-4 py-1.5 animate-pulse">
                        LIVE SYSTEM ACTIVE
                    </Badge>
                </div>
            </div>

            {/* Stats Section */}
            {stats && (
                <div className="grid gap-6 md:grid-cols-4">
                    {[
                        { label: 'Total Hari Ini', value: stats.total, color: 'from-blue-600 to-blue-400', shadow: 'shadow-blue-500/20' },
                        { label: 'Terkirim', value: stats.sent, color: 'from-emerald-600 to-emerald-400', shadow: 'shadow-emerald-500/20' },
                        { label: 'Gagal', value: stats.failed, color: 'from-red-600 to-red-400', shadow: 'shadow-red-500/20' },
                        { label: 'Pending', value: stats.pending, color: 'from-amber-600 to-amber-400', shadow: 'shadow-amber-500/20' }
                    ].map((stat, i) => (
                        <Card key={i} className={`relative overflow-hidden border-none ${stat.shadow} bg-white dark:bg-slate-900 hover:scale-[1.02] transition-all cursor-default`}>
                            <div className={`absolute top-0 left-0 w-full h-1 bg-gradient-to-r ${stat.color}`} />
                            <CardHeader className="pb-2">
                                <CardDescription className="font-bold uppercase text-[10px] tracking-[0.2em] text-slate-500">{stat.label}</CardDescription>
                                <CardTitle className="text-3xl font-black dark:text-white">{stat.value}</CardTitle>
                            </CardHeader>
                        </Card>
                    ))}
                </div>
            )}

            {/* Filter Section dengan Glow Sisi */}
            <Card className="relative group border border-slate-200 dark:border-white/5 shadow-sm bg-white dark:bg-slate-900 overflow-hidden">
                {/* Neon Border Effect */}
                <div className="absolute inset-0 border-2 border-transparent group-hover:border-blue-500/30 transition-all duration-500 rounded-xl pointer-events-none"></div>
                <div className="absolute -left-1 top-0 h-full w-1.5 bg-blue-600 opacity-0 group-hover:opacity-100 transition-all duration-500 shadow-[0_0_15px_rgba(37,99,235,0.8)]"></div>

                <CardHeader className="bg-slate-50/50 dark:bg-slate-800/30 border-b border-slate-100 dark:border-white/10">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <Search className="h-5 w-5 text-blue-500 animate-bounce" />
                            <CardTitle className="text-sm font-black uppercase tracking-widest text-slate-700 dark:text-slate-300">Pencarian Terpadu</CardTitle>
                        </div>
                        <Button variant="ghost" size="sm" onClick={clearFilters} className="font-black text-xs hover:text-red-500 transition-colors">
                            <IconX className="h-4 w-4 mr-1" /> RESET
                        </Button>
                    </div>
                </CardHeader>
                <CardContent className="pt-6">
                    <div className="grid gap-5 md:grid-cols-5">
                        {[
                            { id: 'dateFrom', label: 'Dari Tanggal', type: 'date' },
                            { id: 'dateTo', label: 'Sampai Tanggal', type: 'date' }
                        ].map((f) => (
                            <div key={f.id} className="space-y-2">
                                <Label htmlFor={f.id} className="text-[10px] font-black uppercase text-slate-400 tracking-widest">{f.label}</Label>
                                <Input
                                    id={f.id}
                                    type={f.type}
                                    className="bg-white dark:bg-slate-800/50 border-slate-200 dark:border-white/10 focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all"
                                    value={filters[f.id as keyof typeof filters]}
                                    onChange={(e) => handleFilterChange(f.id, e.target.value)}
                                />
                            </div>
                        ))}
                        <div className="space-y-2">
                            <Label className="text-[10px] font-black uppercase text-slate-400 tracking-widest">Kategori</Label>
                            <Select value={filters.notificationType || 'all'} onValueChange={(v) => handleFilterChange('notificationType', v === 'all' ? '' : v)}>
                                <SelectTrigger className="bg-white dark:bg-slate-800/50 border-slate-200 dark:border-white/10">
                                    <SelectValue placeholder="Pilih Tipe" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="all">Semua Tipe</SelectItem>
                                    <SelectItem value="on_time">Tepat Waktu</SelectItem>
                                    <SelectItem value="late">Terlambat</SelectItem>
                                    <SelectItem value="absent">Tidak Hadir</SelectItem>
                                    <SelectItem value="no_journal">Belum Isi Jurnal</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>
                        <div className="space-y-2">
                            <Label className="text-[10px] font-black uppercase text-slate-400 tracking-widest">Status</Label>
                            <Select value={filters.status || 'all'} onValueChange={(v) => handleFilterChange('status', v === 'all' ? '' : v)}>
                                <SelectTrigger className="bg-white dark:bg-slate-800/50 border-slate-200 dark:border-white/10">
                                    <SelectValue placeholder="Pilih Status" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="all">Semua Status</SelectItem>
                                    <SelectItem value="sent">Terkirim</SelectItem>
                                    <SelectItem value="failed">Gagal</SelectItem>
                                    <SelectItem value="pending">Pending</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>
                        <div className="flex items-end">
                            <Button className="w-full bg-blue-600 hover:bg-blue-700 text-white font-black text-xs shadow-lg shadow-blue-500/40 hover:shadow-blue-500/60 transition-all uppercase tracking-widest active:scale-95">
                                <IconFilter className="h-4 w-4 mr-2" /> TERAPKAN
                            </Button>
                        </div>
                    </div>
                </CardContent>
            </Card>

            {/* Log Activity Section dengan Glow Sisi */}
            <Card className="relative group border border-slate-200 dark:border-white/5 shadow-sm bg-white dark:bg-slate-900 overflow-hidden">
                {/* Efek Sisi Menyala (Glow Sidebar) */}
                <div className="absolute inset-y-0 -left-1 w-1.5 bg-blue-500 opacity-0 group-hover:opacity-100 transition-all duration-700 blur-[2px] shadow-[0_0_20px_rgba(37,99,235,1)]"></div>
                <div className="absolute inset-0 border-r-2 border-transparent group-hover:border-blue-500/10 transition-all duration-700 pointer-events-none"></div>

                <CardHeader className="bg-slate-50/80 dark:bg-slate-800/40 border-b border-slate-100 dark:border-white/10">
                    <div className="flex justify-between items-center">
                        <div className="flex items-center gap-3">
                            <div className="p-2 bg-blue-50 dark:bg-blue-900/30 rounded-lg">
                                <IconActivity className="h-5 w-5 text-blue-600 dark:text-blue-400" />
                            </div>
                            <div>
                                <CardTitle className="text-lg font-black dark:text-white tracking-tight">Log Aktivitas Pengiriman</CardTitle>
                                <CardDescription className="text-blue-600 dark:text-blue-400 font-black text-[10px] uppercase tracking-tighter">
                                    Total {logs?.length || 0} entri ditemukan dalam database
                                </CardDescription>
                            </div>
                        </div>
                    </div>
                </CardHeader>
                <CardContent className="p-0">
                    {isLoading ? (
                        <div className="flex flex-col items-center justify-center py-24 gap-4">
                            <Loader2 className="h-12 w-12 animate-spin text-blue-600" />
                            <p className="text-xs font-black text-slate-400 tracking-widest animate-pulse">MEMUAT DATA...</p>
                        </div>
                    ) : logs && logs.length > 0 ? (
                        <div className="overflow-x-auto">
                            <Table>
                                <TableHeader className="bg-slate-100/50 dark:bg-slate-800/60">
                                    <TableRow className="border-b border-slate-200 dark:border-white/5">
                                        <TableHead className="font-black text-[10px] uppercase text-slate-500 p-4">Waktu</TableHead>
                                        <TableHead className="font-black text-[10px] uppercase text-slate-500 p-4">Nama Siswa</TableHead>
                                        <TableHead className="font-black text-[10px] uppercase text-slate-500 p-4">Kategori</TableHead>
                                        <TableHead className="font-black text-[10px] uppercase text-slate-500 p-4">Status</TableHead>
                                        <TableHead className="text-right font-black text-[10px] uppercase text-slate-500 p-4">Aksi</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {logs.map((log) => {
                                        const Icon = notificationTypeIcons[log.notification_type]
                                        return (
                                            <TableRow key={log.id} className="hover:bg-blue-500/[0.02] dark:hover:bg-blue-500/[0.05] border-b border-slate-100 dark:border-white/5 transition-all group/row">
                                                <TableCell className="font-mono text-[11px] font-bold text-slate-400 p-4 uppercase">
                                                    {format(new Date(log.sent_at), 'dd MMM yy • HH:mm', { locale: localeId })}
                                                </TableCell>
                                                <TableCell className="p-4">
                                                    <div className="flex flex-col">
                                                        <span className="font-black text-slate-900 dark:text-slate-100 group-hover/row:text-blue-600 transition-colors uppercase tracking-tight">{log.profiles?.full_name}</span>
                                                        <span className="text-[10px] font-bold text-slate-400">{log.profiles?.class_name}</span>
                                                    </div>
                                                </TableCell>
                                                <TableCell className="p-4">
                                                    <Badge variant="outline" className={`${notificationTypeColors[log.notification_type]} font-black text-[10px] border-2 shadow-sm`}>
                                                        <Icon className="h-3 w-3 mr-1.5" />
                                                        {notificationTypeLabels[log.notification_type]}
                                                    </Badge>
                                                </TableCell>
                                                <TableCell className="p-4">
                                                    <Badge className={`${statusColors[log.status]} font-black text-[10px] px-3 py-1 ring-2 ring-white dark:ring-slate-900`}>
                                                        {log.status === 'sent' ? 'SUCCESS' : log.status === 'failed' ? 'ERROR' : 'WAITING'}
                                                    </Badge>
                                                </TableCell>
                                                <TableCell className="text-right p-4">
                                                    <Button variant="ghost" size="sm" onClick={() => setSelectedLog(log)} className="hover:bg-blue-600 hover:text-white rounded-lg h-9 w-9 p-0 transition-all border border-transparent hover:border-blue-400 shadow-sm hover:shadow-blue-500/40">
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
                        <div className="flex flex-col items-center justify-center py-28 gap-4">
                            <div className="p-6 bg-slate-50 dark:bg-slate-800 rounded-full border-2 border-dashed border-slate-200 dark:border-slate-700 animate-pulse">
                                <BellOff className="h-14 w-14 text-slate-300" />
                            </div>
                            <p className="text-[10px] font-black uppercase tracking-[0.4em] text-slate-400">Database Kosong</p>
                        </div>
                    )}
                </CardContent>
            </Card>

            {/* Modal Detail */}
            <Dialog open={!!selectedLog} onOpenChange={() => setSelectedLog(null)}>
                <DialogContent className="max-w-2xl border-none shadow-2xl bg-white dark:bg-slate-950 p-0 overflow-hidden rounded-3xl">
                    <div className="h-2 bg-gradient-to-r from-blue-600 via-indigo-600 to-blue-600 animate-gradient-x" />
                    <DialogHeader className="p-8 pb-4">
                        <DialogTitle className="text-2xl font-black dark:text-white flex items-center gap-4">
                           <div className="h-12 w-1.5 bg-blue-600 rounded-full shadow-[0_0_20px_rgba(37,99,235,1)]" />
                           Review Transmisi Notifikasi
                        </DialogTitle>
                        <DialogDescription className="font-mono text-[10px] font-black uppercase text-blue-600 bg-blue-50 dark:bg-blue-900/30 px-4 py-1.5 rounded-full inline-block mt-4 border border-blue-100 dark:border-blue-800 tracking-tighter">
                           ID LOG: {selectedLog?.id} • {selectedLog && format(new Date(selectedLog.sent_at), 'eeee, dd MMMM yyyy - HH:mm', { locale: localeId })}
                        </DialogDescription>
                    </DialogHeader>

                    {selectedLog && (
                        <div className="p-8 space-y-8">
                            <div className="grid grid-cols-2 gap-6 bg-slate-50 dark:bg-slate-900/50 p-6 rounded-3xl border border-slate-100 dark:border-white/5 shadow-inner relative overflow-hidden">
                                <div className="absolute top-0 right-0 p-2 opacity-10">
                                    <IconMessageCheck size={80} />
                                </div>
                                <div className="space-y-2 relative z-10">
                                    <Label className="text-[9px] font-black uppercase text-slate-400 tracking-widest">Profil Siswa Magang</Label>
                                    <p className="font-black text-xl text-slate-950 dark:text-white uppercase leading-none">{selectedLog.profiles?.full_name}</p>
                                    <Badge variant="secondary" className="bg-blue-600 text-white font-black text-[9px] px-3">{selectedLog.profiles?.class_name}</Badge>
                                </div>
                                <div className="space-y-2 text-right relative z-10">
                                    <Label className="text-[9px] font-black uppercase text-slate-400 tracking-widest">Tujuan WhatsApp</Label>
                                    <p className="font-mono font-bold text-lg dark:text-white">{selectedLog.parent_phone_number}</p>
                                    <Badge variant="outline" className="font-black text-[9px] border-emerald-500 text-emerald-600">VERIFIED CONTACT</Badge>
                                </div>
                            </div>

                            <div className="space-y-4">
                                <div className="flex items-center gap-4">
                                    <Label className="text-[9px] font-black uppercase text-slate-400 tracking-widest">Isi Pesan Sistem</Label>
                                    <div className="h-px flex-1 bg-slate-100 dark:bg-white/5" />
                                </div>
                                <div className="relative group">
                                    <div className="absolute -inset-1 bg-blue-600 rounded-2xl blur opacity-5 group-hover:opacity-15 transition duration-1000"></div>
                                    <div className="relative bg-white dark:bg-slate-900 border border-slate-200 dark:border-white/10 p-8 rounded-2xl text-sm leading-relaxed text-slate-700 dark:text-slate-300 italic shadow-sm">
                                        "{selectedLog.message_sent}"
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}
                </DialogContent>
            </Dialog>
        </div>
    )
}