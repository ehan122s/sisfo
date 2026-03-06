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
import { IconFilter, IconX, IconMessageCheck, IconClock, IconUserX, IconBook, IconEye } from '@tabler/icons-react'
import { Loader2 } from 'lucide-react'
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
    on_time: 'bg-emerald-100 text-emerald-700 border-emerald-200',
    late: 'bg-amber-100 text-amber-700 border-amber-200',
    absent: 'bg-red-100 text-red-700 border-red-200',
    no_journal: 'bg-blue-100 text-blue-700 border-blue-200',
}

const statusColors = {
    sent: 'bg-green-100 text-green-700',
    failed: 'bg-red-100 text-red-700',
    pending: 'bg-yellow-100 text-yellow-700',
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
        <div className="p-6 space-y-6">
            <div>
                <h1 className="text-3xl font-bold">Riwayat Notifikasi</h1>
                <p className="text-muted-foreground mt-2">
                    Lacak semua notifikasi WhatsApp yang terkirim ke orang tua siswa
                </p>
            </div>

            {/* Stats Cards */}
            {stats && (
                <div className="grid gap-4 md:grid-cols-4">
                    <Card>
                        <CardHeader className="pb-2">
                            <CardDescription>Total Hari Ini</CardDescription>
                            <CardTitle className="text-3xl">{stats.total}</CardTitle>
                        </CardHeader>
                    </Card>
                    <Card>
                        <CardHeader className="pb-2">
                            <CardDescription>Terkirim</CardDescription>
                            <CardTitle className="text-3xl text-green-600">{stats.sent}</CardTitle>
                        </CardHeader>
                    </Card>
                    <Card>
                        <CardHeader className="pb-2">
                            <CardDescription>Gagal</CardDescription>
                            <CardTitle className="text-3xl text-red-600">{stats.failed}</CardTitle>
                        </CardHeader>
                    </Card>
                    <Card>
                        <CardHeader className="pb-2">
                            <CardDescription>Pending</CardDescription>
                            <CardTitle className="text-3xl text-yellow-600">{stats.pending}</CardTitle>
                        </CardHeader>
                    </Card>
                </div>
            )}

            {/* Filters */}
            <Card>
                <CardHeader>
                    <div className="flex items-center justify-between">
                        <CardTitle className="text-sm font-medium">Filter</CardTitle>
                        <Button variant="ghost" size="sm" onClick={clearFilters}>
                            <IconX className="h-4 w-4 mr-2" />
                            Reset
                        </Button>
                    </div>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-4 md:grid-cols-5">
                        <div className="space-y-2">
                            <Label htmlFor="dateFrom">Dari Tanggal</Label>
                            <Input
                                id="dateFrom"
                                type="date"
                                value={filters.dateFrom}
                                onChange={(e) => handleFilterChange('dateFrom', e.target.value)}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="dateTo">Sampai Tanggal</Label>
                            <Input
                                id="dateTo"
                                type="date"
                                value={filters.dateTo}
                                onChange={(e) => handleFilterChange('dateTo', e.target.value)}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="type">Tipe Notifikasi</Label>
                            <Select value={filters.notificationType || 'all'} onValueChange={(value) => handleFilterChange('notificationType', value === 'all' ? '' : value)}>
                                <SelectTrigger>
                                    <SelectValue placeholder="Semua Tipe" />
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
                            <Label htmlFor="status">Status</Label>
                            <Select value={filters.status || 'all'} onValueChange={(value) => handleFilterChange('status', value === 'all' ? '' : value)}>
                                <SelectTrigger>
                                    <SelectValue placeholder="Semua Status" />
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
                            <Button className="w-full" variant="outline">
                                <IconFilter className="h-4 w-4 mr-2" />
                                Filter
                            </Button>
                        </div>
                    </div>
                </CardContent>
            </Card>

            {/* Table */}
            <Card>
                <CardHeader>
                    <CardTitle>Daftar Notifikasi</CardTitle>
                    <CardDescription>
                        {logs?.length || 0} notifikasi ditemukan
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    {isLoading ? (
                        <div className="flex items-center justify-center py-12">
                            <Loader2 className="h-8 w-8 animate-spin text-primary" />
                        </div>
                    ) : logs && logs.length > 0 ? (
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead>Waktu</TableHead>
                                    <TableHead>Siswa</TableHead>
                                    <TableHead>Tipe</TableHead>
                                    <TableHead>No. HP</TableHead>
                                    <TableHead>Status</TableHead>
                                    <TableHead className="text-right">Aksi</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {logs.map((log) => {
                                    const Icon = notificationTypeIcons[log.notification_type]
                                    return (
                                        <TableRow key={log.id}>
                                            <TableCell className="font-mono text-xs">
                                                {format(new Date(log.sent_at), 'dd MMM yyyy HH:mm', { locale: localeId })}
                                            </TableCell>
                                            <TableCell>
                                                <div>
                                                    <div className="font-medium">{log.profiles?.full_name}</div>
                                                    <div className="text-xs text-muted-foreground">{log.profiles?.class_name}</div>
                                                </div>
                                            </TableCell>
                                            <TableCell>
                                                <Badge variant="outline" className={notificationTypeColors[log.notification_type]}>
                                                    <Icon className="h-3 w-3 mr-1" />
                                                    {notificationTypeLabels[log.notification_type]}
                                                </Badge>
                                            </TableCell>
                                            <TableCell className="font-mono text-xs">{log.parent_phone_number}</TableCell>
                                            <TableCell>
                                                <Badge className={statusColors[log.status]}>
                                                    {log.status === 'sent' ? 'Terkirim' : log.status === 'failed' ? 'Gagal' : 'Pending'}
                                                </Badge>
                                            </TableCell>
                                            <TableCell className="text-right">
                                                <Button
                                                    variant="ghost"
                                                    size="sm"
                                                    onClick={() => setSelectedLog(log)}
                                                >
                                                    <IconEye className="h-4 w-4" />
                                                </Button>
                                            </TableCell>
                                        </TableRow>
                                    )
                                })}
                            </TableBody>
                        </Table>
                    ) : (
                        <div className="text-center py-12 text-muted-foreground">
                            Tidak ada notifikasi ditemukan
                        </div>
                    )}
                </CardContent>
            </Card>

            {/* Detail Dialog */}
            <Dialog open={!!selectedLog} onOpenChange={() => setSelectedLog(null)}>
                <DialogContent className="max-w-2xl">
                    <DialogHeader>
                        <DialogTitle>Detail Notifikasi</DialogTitle>
                        <DialogDescription>
                            {selectedLog && format(new Date(selectedLog.sent_at), 'dd MMMM yyyy, HH:mm:ss', { locale: localeId })}
                        </DialogDescription>
                    </DialogHeader>

                    {selectedLog && (
                        <div className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <Label className="text-xs text-muted-foreground">Siswa</Label>
                                    <p className="font-medium">{selectedLog.profiles?.full_name}</p>
                                    <p className="text-sm text-muted-foreground">{selectedLog.profiles?.class_name}</p>
                                </div>
                                <div>
                                    <Label className="text-xs text-muted-foreground">Nomor HP Orang Tua</Label>
                                    <p className="font-mono">{selectedLog.parent_phone_number}</p>
                                </div>
                                <div>
                                    <Label className="text-xs text-muted-foreground">Tipe Notifikasi</Label>
                                    <Badge variant="outline" className={`mt-1 ${notificationTypeColors[selectedLog.notification_type]}`}>
                                        {notificationTypeLabels[selectedLog.notification_type]}
                                    </Badge>
                                </div>
                                <div>
                                    <Label className="text-xs text-muted-foreground">Status</Label>
                                    <Badge className={`mt-1 ${statusColors[selectedLog.status]}`}>
                                        {selectedLog.status === 'sent' ? 'Terkirim' : selectedLog.status === 'failed' ? 'Gagal' : 'Pending'}
                                    </Badge>
                                </div>
                            </div>

                            <div>
                                <Label className="text-xs text-muted-foreground">Isi Pesan</Label>
                                <div className="mt-2 bg-muted p-4 rounded-md whitespace-pre-wrap text-sm">
                                    {selectedLog.message_sent}
                                </div>
                            </div>
                        </div>
                    )}
                </DialogContent>
            </Dialog>
        </div>
    )
}
