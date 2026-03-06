import { useState } from 'react'

import { Input } from '@/components/ui/input'

import { Calendar } from 'lucide-react'
import { ChartAreaInteractive } from '@/components/ui/chart-area-interactive'
import { StatsCards } from './components/stats-cards'
import { AttendanceSummaryTable } from './components/attendance-summary-table'
import { useDashboardAnalytics } from './hooks/use-dashboard-analytics'
import { Skeleton } from '@/components/ui/skeleton'

import { format } from 'date-fns'
import { id as idLocale } from 'date-fns/locale'

export function DashboardPage() {
    const [selectedDate, setSelectedDate] = useState<string>(new Date().toISOString().split('T')[0])
    const { totalStudents, attendanceStats, weeklyTrend, isLoading } = useDashboardAnalytics(selectedDate)




    if (isLoading) {
        return <div className="space-y-6">
            <div className="flex items-center justify-between">
                <Skeleton className="h-10 w-48" />
                <Skeleton className="h-10 w-40" />
            </div>
            <div className="grid gap-4 grid-cols-2 md:grid-cols-4">
                {[1, 2, 3, 4].map(i => <Skeleton key={i} className="h-32" />)}
            </div>
            <div className="grid gap-4 md:grid-cols-2">
                <Skeleton className="h-[350px]" />
                <Skeleton className="h-[350px]" />
            </div>
        </div>
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                    <h1 className="text-2xl font-bold tracking-tight">Dashboard Absensi</h1>
                    <p className="text-muted-foreground">
                        {format(new Date(selectedDate), 'EEEE, dd MMMM yyyy', { locale: idLocale })}
                    </p>
                </div>
                <div className="flex items-center gap-2">
                    <Calendar className="h-4 w-4 text-muted-foreground" />
                    <Input
                        type="date"
                        value={selectedDate}
                        onChange={(e) => setSelectedDate(e.target.value)}
                        className="w-40"
                    />
                </div>
            </div>

            {/* Stat Cards - 4 columns */}
            {/* Stat Cards - Section Cards Style */}
            <StatsCards totalStudents={totalStudents} stats={attendanceStats} />

            {/* Main Overview Chart */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
                <div className="col-span-full">
                    <ChartAreaInteractive
                        data={(weeklyTrend || []).map(item => ({
                            ...item,
                            date: item.dateStr || '' // Ensure ISO date is passed
                        }))}
                    />
                </div>
            </div>

            {/* Attendance Summary Table */}
            <AttendanceSummaryTable selectedDate={selectedDate} />
        </div>
    )
}

