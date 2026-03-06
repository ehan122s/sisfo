import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Calendar } from '@/components/ui/calendar'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { Users, Building2, MapPin, Calendar as CalendarIcon } from 'lucide-react'
import { CompanyDistributionChart } from '../dashboard/components/company-distribution-chart'
import { CityDistributionChart } from '../dashboard/components/city-distribution-chart'
import { LiveMonitoringMap } from '../dashboard/components/live-monitoring-map'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Skeleton } from '@/components/ui/skeleton'
import { format } from 'date-fns'
import { id } from 'date-fns/locale'
import { cn } from '@/lib/utils'

export function PklDashboardPage() {
    const [date, setDate] = useState<Date | undefined>(new Date())

    // Helper to format date for database queries
    const queryDate = date ? format(date, 'yyyy-MM-dd') : format(new Date(), 'yyyy-MM-dd')

    // Fetch PKL-specific stats
    const { data: stats, isLoading } = useQuery({
        queryKey: ['pkl-stats', queryDate],
        queryFn: async () => {
            // Total active students in PKL (XII only)
            const { count: totalStudents } = await supabase
                .from('profiles')
                .select('*', { count: 'exact', head: true })
                .eq('role', 'student')
                .eq('status', 'active')
                .like('class_name', 'XII%') // Only XII grade

            // Total companies (DUDI)
            const { count: totalCompanies } = await supabase
                .from('companies')
                .select('*', { count: 'exact', head: true })

            // Students with placements (XII only)
            const { count: placedStudents } = await supabase
                .from('placements')
                .select('*, students:profiles!inner(class_name)', { count: 'exact', head: true })
                .eq('status', 'active')
                .like('students.class_name', 'XII%')

            // Total journals for the selected date (XII only)
            const startOfDay = `${queryDate}T00:00:00`
            const endOfDay = `${queryDate}T23:59:59`

            const { count: journalsToday } = await supabase
                .from('journals')
                .select('*, student:profiles!inner(class_name)', { count: 'exact', head: true })
                .gte('created_at', startOfDay)
                .lte('created_at', endOfDay)
                .like('student.class_name', 'XII%')

            return {
                totalStudents: totalStudents || 0,
                totalCompanies: totalCompanies || 0,
                placedStudents: placedStudents || 0,
                journalsToday: journalsToday || 0,
            }
        },
    })

    if (isLoading) {
        return (
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <Skeleton className="h-9 w-48" />
                    <Skeleton className="h-9 w-[240px]" />
                </div>
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                    {[1, 2, 3, 4].map(i => <Skeleton key={i} className="h-[120px]" />)}
                </div>
                <div className="grid gap-4 md:grid-cols-2">
                    <Skeleton className="h-[400px]" />
                    <Skeleton className="h-[400px]" />
                </div>
                <Skeleton className="h-[400px] w-full" />
            </div>
        )
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                <h1 className="text-3xl font-bold tracking-tight">Dashboard PKL</h1>
                <div className="flex items-center gap-2">
                    <Popover>
                        <PopoverTrigger asChild>
                            <Button
                                variant={"outline"}
                                className={cn(
                                    "w-[240px] justify-start text-left font-normal",
                                    !date && "text-muted-foreground"
                                )}
                            >
                                <CalendarIcon className="mr-2 h-4 w-4" />
                                {date ? format(date, "PPP", { locale: id }) : <span>Pilih tanggal</span>}
                            </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0" align="end">
                            <Calendar
                                mode="single"
                                selected={date}
                                onSelect={setDate}
                                initialFocus
                                locale={id}
                            />
                        </PopoverContent>
                    </Popover>
                </div>
            </div>

            {/* Stat Cards */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                {[
                    {
                        title: "Total Siswa PKL",
                        icon: Users,
                        value: stats?.totalStudents ?? 0,
                        description: "Siswa aktif kelas XII",
                    },
                    {
                        title: "Total DUDI",
                        icon: Building2,
                        value: stats?.totalCompanies ?? 0,
                        description: "Mitra industri terdaftar",
                    },
                    {
                        title: "Siswa Ditempatkan",
                        icon: MapPin,
                        value: stats?.placedStudents ?? 0,
                        description: "Sedang menjalani PKL",
                    },
                    {
                        title: "Jurnal Hari Ini",
                        icon: CalendarIcon,
                        value: stats?.journalsToday ?? 0,
                        description: format(new Date(queryDate), "dd MMMM yyyy", { locale: id }),
                    }
                ].map((stat, index) => (
                    <Card key={index}>
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium">
                                {stat.title}
                            </CardTitle>
                            <stat.icon className="h-4 w-4 text-muted-foreground" />
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold">{stat.value}</div>
                            <p className="text-xs text-muted-foreground">
                                {stat.description}
                            </p>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {/* Distribution Charts */}
            <div className="grid gap-4 md:grid-cols-2">
                <CompanyDistributionChart />
                <CityDistributionChart />
            </div>

            {/* Live Monitoring Map */}
            <LiveMonitoringMap />
        </div>
    )
}
