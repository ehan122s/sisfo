import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Loader2 } from 'lucide-react'

import { columns } from './summary-table/columns'
import { DataTable } from './summary-table/data-table'

interface AttendanceSummaryTableProps {
    selectedDate: string
}

interface ClassAttendance {
    class_name: string
    hadir: number
    terlambat: number
    sakit: number
    izin: number
    alpa: number
    total: number
}

export function AttendanceSummaryTable({ selectedDate }: AttendanceSummaryTableProps) {
    const { data: classAttendance, isLoading } = useQuery({
        queryKey: ['classAttendanceSummary', selectedDate],
        queryFn: async () => {
            const { data, error } = await supabase.rpc('get_class_attendance_summary', {
                target_date: selectedDate
            })

            if (error) throw error

            return data as ClassAttendance[]
        }
    })

    if (isLoading) {
        return (
            <div>
                <Card className="@container/card">
                    <CardHeader>
                        <CardTitle>Rekap Kehadiran Per Kelas</CardTitle>
                        <CardDescription>Ringkasan kehadiran siswa semua kelas</CardDescription>
                    </CardHeader>
                    <CardContent className="flex justify-center py-8">
                        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                    </CardContent>
                </Card>
            </div>
        )
    }

    return (
        <div>
            <div className="flex flex-col gap-4">
                <div className="flex flex-col gap-1.5">
                    <h2 className="text-lg font-semibold tracking-tight">Rekap Kehadiran Per Kelas</h2>
                    <p className="text-sm text-muted-foreground">
                        Ringkasan kehadiran siswa semua kelas untuk {classAttendance?.length || 0} kelas
                    </p>
                </div>
                
                <DataTable columns={columns} data={classAttendance || []} />
            </div>
        </div>
    )
}
