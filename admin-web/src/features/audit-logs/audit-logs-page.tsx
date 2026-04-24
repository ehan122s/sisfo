import { useAuditLogs } from './hooks/use-audit-logs'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table'
import { format } from 'date-fns'
import { id } from 'date-fns/locale'
import { ChevronLeft, ChevronRight, ClipboardList, Clock, Users, Search, Download } from 'lucide-react'
import { TableRowsSkeleton } from '@/components/ui/table-skeleton'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'

export function AuditLogsPage() {
    const { data: logs, isLoading } = useAuditLogs()

    const [page, setPage] = useState(0)
    const [search, setSearch] = useState('')
    const pageSize = 10

    const filteredLogs = logs?.filter((log) => {
        if (!search) return true
        const q = search.toLowerCase()
        return (
            // @ts-ignore
            log.actor?.full_name?.toLowerCase().includes(q) ||
            log.action?.toLowerCase().includes(q) ||
            log.table_name?.toLowerCase().includes(q) ||
            log.record_id?.toLowerCase().includes(q)
        )
    })

    const totalPages = Math.ceil((filteredLogs?.length || 0) / pageSize)
    const paginatedLogs = filteredLogs?.slice(page * pageSize, (page + 1) * pageSize)

    const getActionBadgeClass = (action: string) => {
        switch (action.toUpperCase()) {
            case 'CREATE': return 'bg-[#EAF3DE] text-[#3B6D11] hover:bg-[#d8edbc] border-transparent'
            case 'UPDATE': return 'bg-[#E6F1FB] text-[#185FA5] hover:bg-[#cce3f7] border-transparent'
            case 'DELETE': return 'bg-[#FCEBEB] text-[#A32D2D] hover:bg-[#f9d4d4] border-transparent'
            default:       return 'bg-gray-100 text-gray-700 border-transparent'
        }
    }

    const getActionDotColor = (action: string) => {
        switch (action.toUpperCase()) {
            case 'CREATE': return 'bg-[#3B6D11]'
            case 'UPDATE': return 'bg-[#185FA5]'
            case 'DELETE': return 'bg-[#A32D2D]'
            default:       return 'bg-gray-400'
        }
    }

    const getInitials = (name: string) => {
        if (!name) return '?'
        return name.split(' ').slice(0, 2).map((n) => n[0]).join('').toUpperCase()
    }

    // --- FUNGSI EXPORT LOG ---
    const handleExport = () => {
        // Gunakan filteredLogs jika ingin mengexport sesuai pencarian, 
        // atau gunakan 'logs' jika ingin selalu mengexport semua data.
        const dataToExport = filteredLogs; 
        
        if (!dataToExport || dataToExport.length === 0) return;

        // 1. Definisikan Header CSV
        const headers = ['Waktu', 'Actor', 'Action', 'Target Table', 'Record ID', 'Details'];

        // 2. Map data ke format baris CSV
        const csvRows = dataToExport.map(log => {
            const waktu = format(new Date(log.created_at), 'yyyy-MM-dd HH:mm:ss');
            // @ts-ignore
            const actor = log.actor?.full_name || 'Unknown';
            const action = log.action;
            const target = log.table_name;
            const recordId = log.record_id;
            
            // Escape tanda kutip ganda di dalam JSON string agar CSV tidak rusak
            const details = log.details ? JSON.stringify(log.details).replace(/"/g, '""') : '';

            // Bungkus setiap kolom dengan tanda kutip
            return `"${waktu}","${actor}","${action}","${target}","${recordId}","${details}"`;
        });

        // 3. Gabungkan header dan data dengan newline
        const csvContent = [headers.join(','), ...csvRows].join('\n');

        // 4. Buat Blob dan trigger download via anchor tag
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        
        link.setAttribute('href', url);
        link.setAttribute('download', `Audit_Logs_${format(new Date(), 'yyyyMMdd_HHmmss')}.csv`);
        link.style.visibility = 'hidden';
        
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };
    // -------------------------

    const totalCount = logs?.length || 0
    const todayCount = logs?.filter((log) => {
        const today   = new Date()
        const logDate = new Date(log.created_at)
        return logDate.toDateString() === today.toDateString()
    }).length || 0
    const uniqueActors = new Set(logs?.map((log) => (log as any).actor?.full_name)).size || 0

    return (
        <div className="space-y-6 p-1">

            {/* Breadcrumb */}
            <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <span>E-PKL</span>
                <ChevronRight className="h-3 w-3" />
                <span className="text-foreground font-medium">Audit Logs</span>
            </div>

            {/* Page Header */}
            <div className="flex items-start justify-between">
                <div>
                    <p className="text-[11px] font-semibold text-[#378ADD] uppercase tracking-widest flex items-center gap-1.5 mb-1">
                        <Clock className="h-3 w-3" />
                        Activity Monitor
                    </p>
                    <h1 className="text-3xl font-bold tracking-tight">Audit Logs</h1>
                    <p className="text-muted-foreground text-sm mt-1">
                        Riwayat perubahan data dan aktivitas sistem.
                    </p>
                </div>
                
                {/* TOMBOL EXPORT DIPERBARUI DI SINI */}
                <Button 
                    onClick={handleExport}
                    disabled={isLoading || !filteredLogs?.length}
                    className="bg-[#185FA5] hover:bg-[#0C447C] text-white rounded-xl gap-2 shadow-sm disabled:opacity-50"
                >
                    <Download className="h-4 w-4" />
                    Export Log
                </Button>
            </div>

            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="bg-white dark:bg-card border border-border rounded-2xl p-5 flex items-center gap-4">
                    <div
                        className="w-12 h-12 rounded-[14px] flex items-center justify-center flex-shrink-0"
                        style={{ background: 'linear-gradient(135deg, #378ADD, #185FA5)' }}
                    >
                        <ClipboardList className="h-5 w-5 text-white" />
                    </div>
                    <div>
                        <p className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">Total Aktivitas</p>
                        <p className="text-2xl font-bold text-foreground">{isLoading ? '—' : totalCount}</p>
                    </div>
                </div>

                <div className="bg-white dark:bg-card border border-border rounded-2xl p-5 flex items-center gap-4">
                    <div
                        className="w-12 h-12 rounded-[14px] flex items-center justify-center flex-shrink-0"
                        style={{ background: 'linear-gradient(135deg, #378ADD, #185FA5)' }}
                    >
                        <Clock className="h-5 w-5 text-white" />
                    </div>
                    <div>
                        <p className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">Hari Ini</p>
                        <p className="text-2xl font-bold text-foreground">{isLoading ? '—' : todayCount}</p>
                    </div>
                </div>

                <div className="bg-white dark:bg-card border border-border rounded-2xl p-5 flex items-center gap-4">
                    <div
                        className="w-12 h-12 rounded-[14px] flex items-center justify-center flex-shrink-0"
                        style={{ background: 'linear-gradient(135deg, #378ADD, #185FA5)' }}
                    >
                        <Users className="h-5 w-5 text-white" />
                    </div>
                    <div>
                        <p className="text-[11px] font-semibold text-muted-foreground uppercase tracking-wider">Pengguna Aktif</p>
                        <p className="text-2xl font-bold text-foreground">{isLoading ? '—' : uniqueActors}</p>
                    </div>
                </div>
            </div>

            {/* Table Card */}
            <Card className="rounded-2xl border-border overflow-hidden shadow-sm">
                <CardHeader className="bg-[#F0F6FD] dark:bg-[#0C2340] border-b border-[#B5D4F4] dark:border-[#1a3d6e] px-6 py-4 flex flex-row items-center justify-between space-y-0">
                    <CardTitle className="text-[#185FA5] dark:text-[#85B7EB] text-base font-semibold">
                        Aktivitas Sistem
                    </CardTitle>
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
                        <Input
                            placeholder="Cari aktivitas..."
                            value={search}
                            onChange={(e) => { setSearch(e.target.value); setPage(0) }}
                            className="pl-8 h-8 text-sm w-52 rounded-xl border-[#B5D4F4] focus-visible:ring-[#185FA5] bg-white dark:bg-background"
                        />
                    </div>
                </CardHeader>

                <CardContent className="p-0">
                    <Table>
                        <TableHeader>
                            <TableRow className="bg-[#F0F6FD] dark:bg-[#0C2340] hover:bg-[#F0F6FD]">
                                <TableHead className="text-[#185FA5] dark:text-[#85B7EB] text-[11px] font-semibold uppercase tracking-wider px-6">Waktu</TableHead>
                                <TableHead className="text-[#185FA5] dark:text-[#85B7EB] text-[11px] font-semibold uppercase tracking-wider">Actor</TableHead>
                                <TableHead className="text-[#185FA5] dark:text-[#85B7EB] text-[11px] font-semibold uppercase tracking-wider">Action</TableHead>
                                <TableHead className="text-[#185FA5] dark:text-[#85B7EB] text-[11px] font-semibold uppercase tracking-wider">Target</TableHead>
                                <TableHead className="text-[#185FA5] dark:text-[#85B7EB] text-[11px] font-semibold uppercase tracking-wider">Details</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {isLoading ? (
                                <TableRowsSkeleton columnCount={5} rowCount={10} />
                            ) : paginatedLogs?.map((log) => (
                                <TableRow
                                    key={log.id}
                                    className="hover:bg-[#F7FAFF] dark:hover:bg-[#0C2340]/40 transition-colors"
                                >
                                    {/* Waktu */}
                                    <TableCell className="px-6 whitespace-nowrap">
                                        <div className="text-xs text-muted-foreground">
                                            {format(new Date(log.created_at), 'dd MMM', { locale: id })}
                                        </div>
                                        <div className="text-xs font-semibold text-[#378ADD]">
                                            {format(new Date(log.created_at), 'HH:mm', { locale: id })}
                                        </div>
                                    </TableCell>

                                    {/* Actor */}
                                    <TableCell>
                                        <div className="flex items-center gap-2.5">
                                            <div
                                                className="w-8 h-8 rounded-full flex items-center justify-center text-white text-[11px] font-semibold flex-shrink-0"
                                                style={{ background: 'linear-gradient(135deg, #378ADD, #185FA5)' }}
                                            >
                                                {/* @ts-ignore */}
                                                {getInitials(log.actor?.full_name || '')}
                                            </div>
                                            <span className="text-sm font-medium">
                                                {/* @ts-ignore */}
                                                {log.actor?.full_name || 'Unknown'}
                                            </span>
                                        </div>
                                    </TableCell>

                                    {/* Action */}
                                    <TableCell>
                                        <Badge
                                            className={`${getActionBadgeClass(log.action)} text-[11px] font-semibold gap-1.5 px-2.5 py-0.5 rounded-lg`}
                                            variant="outline"
                                        >
                                            <span className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${getActionDotColor(log.action)}`} />
                                            {log.action}
                                        </Badge>
                                    </TableCell>

                                    {/* Target */}
                                    <TableCell>
                                        <div className="flex flex-col">
                                            <span className="text-[11px] font-semibold uppercase text-[#185FA5]">
                                                {log.table_name}
                                            </span>
                                            <span className="text-xs text-muted-foreground">
                                                {log.record_id}
                                            </span>
                                        </div>
                                    </TableCell>

                                    {/* Details */}
                                    <TableCell>
                                        <span className="inline-block max-w-[200px] truncate text-[11px] font-mono bg-[#F0F6FD] dark:bg-[#0C2340] text-[#185FA5] dark:text-[#85B7EB] border border-[#B5D4F4] dark:border-[#1a3d6e] px-2 py-1 rounded-lg">
                                            {JSON.stringify(log.details)}
                                        </span>
                                    </TableCell>
                                </TableRow>
                            ))}

                            {!isLoading && filteredLogs?.length === 0 && (
                                <TableRow>
                                    <TableCell colSpan={5} className="text-center h-24 text-muted-foreground text-sm">
                                        Tidak ada aktivitas ditemukan.
                                    </TableCell>
                                </TableRow>
                            )}
                        </TableBody>
                    </Table>

                    {/* Pagination */}
                    {!isLoading && (filteredLogs?.length || 0) > 0 && (
                        <div className="flex items-center justify-between px-6 py-3 border-t border-[#B5D4F4] dark:border-[#1a3d6e] bg-[#F7FAFF] dark:bg-[#0C2340]/30">
                            <p className="text-xs text-muted-foreground">
                                Menampilkan{' '}
                                <span className="font-medium text-foreground">
                                    {page * pageSize + 1}–{Math.min((page + 1) * pageSize, filteredLogs?.length || 0)}
                                </span>{' '}
                                dari{' '}
                                <span className="font-medium text-foreground">{filteredLogs?.length}</span> entri
                            </p>

                            <div className="flex items-center gap-1.5">
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => setPage((p) => Math.max(0, p - 1))}
                                    disabled={page === 0}
                                    className="h-8 px-3 rounded-lg border-[#B5D4F4] text-[#185FA5] hover:bg-[#E6F1FB] hover:border-[#378ADD] disabled:opacity-40 text-xs gap-1"
                                >
                                    <ChevronLeft className="h-3.5 w-3.5" />
                                    Previous
                                </Button>

                                {Array.from({ length: totalPages }, (_, i) => (
                                    <Button
                                        key={i}
                                        variant="outline"
                                        size="sm"
                                        onClick={() => setPage(i)}
                                        className={`h-8 w-8 p-0 rounded-lg text-xs font-medium ${
                                            i === page
                                                ? 'bg-[#185FA5] text-white border-[#185FA5] hover:bg-[#0C447C] hover:border-[#0C447C]'
                                                : 'border-[#B5D4F4] text-[#185FA5] hover:bg-[#E6F1FB] hover:border-[#378ADD]'
                                        }`}
                                    >
                                        {i + 1}
                                    </Button>
                                ))}

                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
                                    disabled={page >= totalPages - 1}
                                    className="h-8 px-3 rounded-lg border-[#B5D4F4] text-[#185FA5] hover:bg-[#E6F1FB] hover:border-[#378ADD] disabled:opacity-40 text-xs gap-1"
                                >
                                    Next
                                    <ChevronRight className="h-3.5 w-3.5" />
                                </Button>
                            </div>
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    )
}