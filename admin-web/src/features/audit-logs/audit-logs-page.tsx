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
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { TableRowsSkeleton } from '@/components/ui/table-skeleton'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'

export function AuditLogsPage() {
    const { data: logs, isLoading } = useAuditLogs()

    const getActionColor = (action: string) => {
        switch (action.toUpperCase()) {
            case 'CREATE': return 'bg-green-100 text-green-800 hover:bg-green-200'
            case 'UPDATE': return 'bg-blue-100 text-blue-800 hover:bg-blue-200'
            case 'DELETE': return 'bg-red-100 text-red-800 hover:bg-red-200'
            default: return 'bg-gray-100 text-gray-800'
        }
    }

    // Loading handled inside TableBody now
    // if (isLoading) {
    //     return <div className="flex justify-center items-center h-96"><Loader2 className="h-8 w-8 animate-spin" /></div>
    // }

    const [page, setPage] = useState(0)
    const pageSize = 10

    const totalPages = Math.ceil((logs?.length || 0) / pageSize)
    const paginatedLogs = logs?.slice(page * pageSize, (page + 1) * pageSize)

    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Audit Logs</h1>
                <p className="text-muted-foreground">Riwayat perubahan data dan aktivitas sistem.</p>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Aktivitas Sistem</CardTitle>
                </CardHeader>
                <CardContent>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>Waktu</TableHead>
                                <TableHead>Actor</TableHead>
                                <TableHead>Action</TableHead>
                                <TableHead>Target</TableHead>
                                <TableHead>Details</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {isLoading ? (
                                <TableRowsSkeleton columnCount={5} rowCount={10} />
                            ) : paginatedLogs?.map((log) => (
                                <TableRow key={log.id}>
                                    <TableCell className="whitespace-nowrap">
                                        {format(new Date(log.created_at), 'dd MMM HH:mm', { locale: id })}
                                    </TableCell>
                                    <TableCell>
                                        <div className="font-medium text-sm">
                                            {/* Access nested actor properly. The hook joins it. */}
                                            {/* @ts-ignore */}
                                            {log.actor?.full_name || 'Unknown'}
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        <Badge className={getActionColor(log.action)} variant="outline">
                                            {log.action}
                                        </Badge>
                                    </TableCell>
                                    <TableCell>
                                        <div className="flex flex-col">
                                            <span className="font-medium text-xs uppercase">{log.table_name}</span>
                                            <span className="text-xs text-muted-foreground">{log.record_id}</span>
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        <div className="max-w-xs truncate text-xs font-mono bg-muted p-1 rounded">
                                            {JSON.stringify(log.details)}
                                        </div>
                                    </TableCell>
                                </TableRow>
                            ))}
                            {logs?.length === 0 && (
                                <TableRow>
                                    <TableCell colSpan={5} className="text-center h-24 text-muted-foreground">
                                        Tidak ada aktivitas tercatat.
                                    </TableCell>
                                </TableRow>
                            )}
                        </TableBody>
                    </Table>

                    {/* Pagination Controls */}
                    {!isLoading && (logs?.length || 0) > 0 && (
                        <div className="flex items-center justify-end space-x-2 py-4">
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
                                Page {page + 1} of {totalPages}
                            </div>
                            <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
                                disabled={page >= totalPages - 1}
                            >
                                Next
                                <ChevronRight className="h-4 w-4" />
                            </Button>
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    )
}
