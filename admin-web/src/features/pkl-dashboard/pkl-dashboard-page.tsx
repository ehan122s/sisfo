import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Calendar } from '@/components/ui/calendar'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { 
    Users, Building2, MapPin, Calendar as CalendarIcon, 
    ArrowUpRight, FileText, PlusCircle, LayoutDashboard 
} from 'lucide-react'
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
    const queryDate = date ? format(date, 'yyyy-MM-dd') : format(new Date(), 'yyyy-MM-dd')

    const { data: stats, isLoading } = useQuery({
        queryKey: ['pkl-stats', queryDate],
        queryFn: async () => {
            const { count: totalStudents } = await supabase
                .from('profiles')
                .select('*', { count: 'exact', head: true })
                .eq('role', 'student')
                .eq('status', 'active')
                .like('class_name', 'XII%')

            const { count: totalCompanies } = await supabase
                .from('companies')
                .select('*', { count: 'exact', head: true })

            const { count: placedStudents } = await supabase
                .from('placements')
                .select('*, students:profiles!inner(class_name)', { count: 'exact', head: true })
                .eq('status', 'active')
                .like('students.class_name', 'XII%')

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
            </div>
        )
    }

    const statItems = [
        {
            title: "Total Siswa PKL",
            icon: Users,
            value: stats?.totalStudents ?? 0,
            description: "Siswa aktif kelas XII",
            gradient: "from-blue-600 to-indigo-600",
            progress: 100
        },
        {
            title: "Total DUDI",
            icon: Building2,
            value: stats?.totalCompanies ?? 0,
            description: "Mitra industri terdaftar",
            gradient: "from-blue-500 to-cyan-500",
            progress: 75
        },
        {
            title: "Siswa Ditempatkan",
            icon: MapPin,
            value: stats?.placedStudents ?? 0,
            description: `${Math.round(((stats?.placedStudents ?? 0) / (stats?.totalStudents ?? 1)) * 100)}% dari total siswa`,
            gradient: "from-indigo-500 to-purple-500",
            progress: ((stats?.placedStudents ?? 0) / (stats?.totalStudents ?? 1)) * 100
        },
        {
            title: "Jurnal Hari Ini",
            icon: CalendarIcon,
            value: stats?.journalsToday ?? 0,
            description: "Laporan aktivitas masuk",
            gradient: "from-sky-500 to-blue-600",
            progress: ((stats?.journalsToday ?? 0) / (stats?.placedStudents ?? 1)) * 100
        }
    ]

    return (
        <div className="space-y-8 pb-10">
            {/* Header dengan Quick Actions */}
            <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
                <div>
                    <div className="flex items-center gap-2 mb-1">
                        <LayoutDashboard className="w-5 h-5 text-blue-600" />
                        <span className="text-sm font-bold text-blue-600 uppercase tracking-widest">Overview</span>
                    </div>
                    <h1 className="text-4xl font-black tracking-tight text-slate-800">Dashboard PKL</h1>
                </div>

                <div className="flex flex-wrap items-center gap-3">
                    <Button variant="outline" className="rounded-xl border-blue-100 hover:bg-blue-50 text-blue-700 font-bold gap-2">
                        <FileText className="w-4 h-4" /> Cetak Laporan
                    </Button>
                    <Button className="rounded-xl bg-blue-600 hover:bg-blue-700 shadow-lg shadow-blue-200 gap-2 font-bold">
                        <PlusCircle className="w-4 h-4" /> Penempatan
                    </Button>
                    <div className="h-8 w-[1px] bg-slate-200 mx-2 hidden md:block" />
                    <Popover>
                        <PopoverTrigger asChild>
                            <Button variant="outline" className="w-[220px] justify-start rounded-xl border-slate-200 font-semibold shadow-sm">
                                <CalendarIcon className="mr-2 h-4 w-4 text-blue-500" />
                                {date ? format(date, "PPP", { locale: id }) : <span>Pilih tanggal</span>}
                            </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0 rounded-2xl shadow-2xl border-none" align="end">
                            <Calendar mode="single" selected={date} onSelect={setDate} locale={id} />
                        </PopoverContent>
                    </Popover>
                </div>
            </div>

            {/* Stat Cards yang diperbarui */}
            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
                {statItems.map((stat, index) => (
                    <Card key={index} className="border-none shadow-sm bg-white overflow-hidden group hover:shadow-xl hover:shadow-blue-500/5 transition-all duration-300">
                        <CardHeader className="flex flex-row items-center justify-between pb-2">
                            <CardTitle className="text-[11px] font-black uppercase tracking-[0.1em] text-slate-400">
                                {stat.title}
                            </CardTitle>
                            <div className={cn("p-2 rounded-xl bg-slate-50 group-hover:scale-110 transition-transform")}>
                                <stat.icon className="h-4 w-4 text-blue-600" />
                            </div>
                        </CardHeader>
                        <CardContent>
                            <div className="flex items-baseline gap-1">
                                <span className="text-3xl font-black text-slate-800">{stat.value}</span>
                                <ArrowUpRight className="w-4 h-4 text-blue-400 opacity-0 group-hover:opacity-100 transition-opacity" />
                            </div>
                            <p className="text-[11px] font-bold text-slate-400 mt-1 uppercase mb-4">
                                {stat.description}
                            </p>
                            {/* Progress Bar (Fitur Biar Gak Bosen) */}
                            <div className="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
                                <div 
                                    className={cn("h-full rounded-full bg-gradient-to-r transition-all duration-1000", stat.gradient)} 
                                    style={{ width: `${stat.progress}%` }}
                                />
                            </div>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {/* Distribusi Charts dengan container Biru */}
            <div className="grid gap-8 md:grid-cols-2">
                <Card className="border-none shadow-sm rounded-3xl overflow-hidden">
                    <CardHeader className="border-b border-slate-50 bg-slate-50/30">
                        <CardTitle className="text-sm font-bold text-slate-700">Distribusi Perusahaan</CardTitle>
                    </CardHeader>
                    <CardContent className="pt-6">
                        <CompanyDistributionChart />
                    </CardContent>
                </Card>
                <Card className="border-none shadow-sm rounded-3xl overflow-hidden">
                    <CardHeader className="border-b border-slate-50 bg-slate-50/30">
                        <CardTitle className="text-sm font-bold text-slate-700">Sebaran Kota PKL</CardTitle>
                    </CardHeader>
                    <CardContent className="pt-6">
                        <CityDistributionChart />
                    </CardContent>
                </Card>
            </div>

            {/* Live Monitoring Map (Tetap Seperti Aslinya) */}
            <div className="space-y-4">
                <div className="flex items-center gap-2 px-1">
                    <div className="w-2 h-2 rounded-full bg-red-500 animate-ping" />
                    <h2 className="text-sm font-bold text-slate-700 uppercase tracking-widest">Live Monitoring Map</h2>
                </div>
                <div className="rounded-[2.5rem] overflow-hidden border-8 border-white shadow-2xl">
                    <LiveMonitoringMap />
                </div>
            </div>
        </div>
    )
}