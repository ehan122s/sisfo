import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom' 
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Calendar } from '@/components/ui/calendar'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { 
    Users, Building2, MapPin, Calendar as CalendarIcon, 
    FileText, PlusCircle 
} from 'lucide-react'
import { CompanyDistributionChart } from '../dashboard/components/company-distribution-chart'
import { CityDistributionChart } from '../dashboard/components/city-distribution-chart'
import { LiveMonitoringMap } from '../dashboard/components/live-monitoring-map'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Skeleton } from '@/components/ui/skeleton'
import { format, startOfDay, endOfDay } from 'date-fns'
import { id } from 'date-fns/locale'
import { cn } from '@/lib/utils'

export function PklDashboardPage() {
    const navigate = useNavigate()
    const [date, setDate] = useState<Date | undefined>(new Date())
    const [isMounted, setIsMounted] = useState(false)

    useEffect(() => {
        setIsMounted(true)
    }, [])

    const { data: stats, isLoading, refetch } = useQuery({
        queryKey: ['pkl-stats', date ? format(date, 'yyyy-MM-dd') : 'today'],
        queryFn: async () => {
            const { count: totalStudents } = await supabase
                .from('profiles')
                .select('*', { count: 'exact', head: true })
                .eq('role', 'student')

            const { count: totalCompanies } = await supabase
                .from('companies')
                .select('*', { count: 'exact', head: true })

            const { count: placedStudents } = await supabase
                .from('profiles')
                .select('*', { count: 'exact', head: true })
                .eq('role', 'student')
                .eq('status', 'active')

            const targetDate = date || new Date()
            const isoStart = startOfDay(targetDate).toISOString()
            const isoEnd = endOfDay(targetDate).toISOString()

            const { count: journalsToday } = await supabase
                .from('daily_journals')
                .select('*', { count: 'exact', head: true })
                .gte('created_at', isoStart)
                .lte('created_at', isoEnd)

            return {
                totalStudents: totalStudents || 0,
                totalCompanies: totalCompanies || 0,
                placedStudents: placedStudents || 0,
                journalsToday: journalsToday || 0,
            }
        },
    })

    useEffect(() => {
        refetch()
    }, [date, refetch])

    if (isLoading) {
        return (
            <div className="space-y-6 p-6">
                <div className="flex items-center justify-between">
                    <Skeleton className="h-12 w-64 rounded-xl bg-slate-200 dark:bg-slate-800" />
                    <Skeleton className="h-10 w-[240px] rounded-xl bg-slate-200 dark:bg-slate-800" />
                </div>
                <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
                    {[1, 2, 3, 4].map(i => <Skeleton key={i} className="h-32 rounded-2xl bg-slate-200 dark:bg-slate-800" />)}
                </div>
            </div>
        )
    }

    const statItems = [
        { 
            title: "Total Siswa PKL", 
            icon: Users, 
            value: stats?.totalStudents ?? 0, 
            description: "Siswa Terdaftar", 
            iconColor: 'text-blue-600 dark:text-blue-400',
            iconBg: 'bg-blue-500/10',
            barColor: 'bg-blue-500',
            borderColor: 'border-blue-200 hover:border-blue-400', 
            progress: 100, 
            path: '/students' 
        },
        { 
            title: "Total DUDI", 
            icon: Building2, 
            value: stats?.totalCompanies ?? 0, 
            description: "Mitra Industri Aktif", 
            iconColor: 'text-cyan-600 dark:text-cyan-400',
            iconBg: 'bg-cyan-500/10',
            barColor: 'bg-cyan-500',
            borderColor: 'border-cyan-200 hover:border-cyan-400', 
            progress: 100, 
            path: '/companies' 
        },
        { 
            title: "Siswa Ditempatkan", 
            icon: MapPin, 
            value: stats?.placedStudents ?? 0, 
            description: `${stats?.placedStudents ?? 0} Siswa Aktif PKL`, 
            iconColor: 'text-emerald-600 dark:text-emerald-400',
            iconBg: 'bg-emerald-500/10',
            barColor: 'bg-emerald-500',
            borderColor: 'border-emerald-200 hover:border-emerald-400', 
            path: '/students',
            progress: ((stats?.placedStudents ?? 0) / (stats?.totalStudents ?? 1)) * 100, 
        },
        { 
            title: "Jurnal Hari Ini", 
            icon: CalendarIcon, 
            value: stats?.journalsToday ?? 0, 
            description: "Laporan Masuk", 
            iconColor: 'text-orange-600 dark:text-orange-400',
            iconBg: 'bg-orange-500/10',
            barColor: 'bg-orange-400',
            borderColor: 'border-orange-200 hover:border-orange-400', 
            progress: stats?.placedStudents ? ((stats.journalsToday / stats.placedStudents) * 100) : 0, 
            path: '/journals' 
        }
    ]

    return (
        <div className={cn(
            "space-y-8 p-6 pb-16 transition-all duration-700 ease-in-out",
            isMounted ? "opacity-100 translate-y-0" : "opacity-0 translate-y-4"
        )}>
            
            {/* ── Header ── */}
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                <div className="space-y-1">
                    <div className="flex gap-1 mb-3">
                        <div className="h-1 w-8 rounded-full bg-blue-500" />
                        <div className="h-1 w-4 rounded-full bg-blue-800 dark:bg-blue-300" />
                    </div>
                    <h1 className="text-4xl md:text-5xl font-black italic tracking-tight text-slate-900 dark:text-white uppercase">
                        DASHBOARD{" "}
                        <span className="text-blue-600 dark:text-blue-400">PKL</span>
                    </h1>
                    <p className="text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
                        Pantau dan kelola seluruh aktivitas PKL siswa
                    </p>
                </div>

                {/* Tombol pembungkus dengan flex-row yang dipaksa sejajar di layar besar */}
                <div className="flex flex-row flex-wrap items-center gap-3 mt-2 md:mt-0">
                    <Button
                        onClick={() => navigate('/reports')}
                        variant="outline"
                        className="rounded-xl border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800/50 text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-white font-bold gap-2"
                    >
                        <FileText className="w-4 h-4" /> Cetak Laporan
                    </Button>
                    
                    {/* Urutan dikembalikan: Tanggal berada di tengah */}
                    <Popover>
                        <PopoverTrigger asChild>
                            <Button
                                variant="outline"
                                className="w-[200px] justify-start rounded-xl border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800/50 text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 hover:text-slate-900 dark:hover:text-white font-bold"
                            >
                                <CalendarIcon className="mr-2 h-4 w-4 text-slate-400 dark:text-slate-500" />
                                {date ? format(date, "PPP", { locale: id }) : <span>Pilih tanggal</span>}
                            </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0 rounded-2xl border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 shadow-2xl" align="end">
                            <Calendar mode="single" selected={date} onSelect={setDate} locale={id} className="rounded-2xl" />
                        </PopoverContent>
                    </Popover>

                    {/* Tombol Penempatan di paling kanan */}
                    <Button
                        onClick={() => navigate('/companies')}
                        className="rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-black uppercase tracking-wider text-xs shadow-none px-5 h-10"
                    >
                        <PlusCircle className="w-4 h-4 mr-2" /> Penempatan
                    </Button>
                </div>
            </div>

            {/* ── Stats Grid ── */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                {statItems.map((stat, index) => (
                    <Card 
                        key={index} 
                        onClick={() => navigate(stat.path)}
                        className={cn(
                            "bg-white dark:bg-slate-900/80 border rounded-2xl overflow-hidden cursor-pointer transition-all duration-200 hover:-translate-y-1 shadow-sm dark:shadow-none dark:border-slate-800 dark:hover:border-slate-600",
                            stat.borderColor
                        )}
                    >
                        <CardContent className="p-5">
                            <div className="flex items-start justify-between mb-4">
                                <div>
                                    <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-1">{stat.title}</p>
                                    <p className="text-4xl font-black text-slate-900 dark:text-white tracking-tight">{stat.value}</p>
                                </div>
                                <div className={cn("p-3 rounded-xl", stat.iconBg)}>
                                    <stat.icon className={cn("w-5 h-5", stat.iconColor)} />
                                </div>
                            </div>
                            <div className="h-1 w-full bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                                <div
                                    className={cn("h-full rounded-full transition-all duration-1000", stat.barColor)}
                                    style={{ width: `${Math.min(stat.progress, 100)}%` }}
                                />
                            </div>
                            <p className="text-xs text-slate-500 dark:text-slate-400 mt-2 font-medium">{stat.description}</p>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {/* ── Charts ── */}
            <div className="grid gap-6 md:grid-cols-2">
                <Card className="bg-white dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 rounded-2xl overflow-hidden shadow-sm dark:shadow-none">
                    <CardHeader className="border-b border-slate-100 dark:border-slate-800 px-6 py-4">
                        <CardTitle className="text-xs font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Distribusi Perusahaan</CardTitle>
                    </CardHeader>
                    <CardContent className="pt-6 px-6">
                        <CompanyDistributionChart />
                    </CardContent>
                </Card>
                
                <Card className="bg-white dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 rounded-2xl overflow-hidden shadow-sm dark:shadow-none">
                    <CardHeader className="border-b border-slate-100 dark:border-slate-800 px-6 py-4">
                        <CardTitle className="text-xs font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Sebaran Kota PKL</CardTitle>
                    </CardHeader>
                    <CardContent className="pt-6 px-6">
                        <CityDistributionChart />
                    </CardContent>
                </Card>
            </div>

            {/* ── Live Map ── */}
            <div className="space-y-4">
                <div className="flex items-center gap-3">
                    <span className="relative flex h-2.5 w-2.5">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-500 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
                    </span>
                    <h2 className="text-xs font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Live Monitoring Map</h2>
                </div>
                <div className="rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900">
                    <LiveMonitoringMap />
                </div>
            </div>  
        </div>
    )
}