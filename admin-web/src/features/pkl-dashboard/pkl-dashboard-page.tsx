import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom' 
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Calendar } from '@/components/ui/calendar'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { 
    Users, Building2, MapPin, Calendar as CalendarIcon, 
    ArrowUpRight, FileText, PlusCircle 
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
    const [displayText, setDisplayText] = useState("")
    const fullText = "Dashboard"

    useEffect(() => {
        setIsMounted(true)
        let i = 0
        setDisplayText("") 
        const timer = setInterval(() => {
            if (i < fullText.length) {
                setDisplayText((prev) => fullText.slice(0, i + 1))
                i++
            } else {
                clearInterval(timer)
            }
        }, 150)
        return () => clearInterval(timer)
    }, [])

    const { data: stats, isLoading, refetch } = useQuery({
        queryKey: ['pkl-stats', date ? format(date, 'yyyy-MM-dd') : 'today'],
        queryFn: async () => {
            // 1. TOTAL SISWA (11 Siswa Terdaftar)
            const { count: totalStudents } = await supabase
                .from('profiles')
                .select('*', { count: 'exact', head: true })
                .eq('role', 'student')

            // 2. TOTAL DUDI (3 Mitra Industri)
            const { count: totalCompanies } = await supabase
                .from('companies')
                .select('*', { count: 'exact', head: true })

            // 3. SISWA DITEMPATKAN (Status Aktif)
            const { count: placedStudents } = await supabase
                .from('profiles')
                .select('*', { count: 'exact', head: true })
                .eq('role', 'student')
                .eq('status', 'active')

            // 4. JURNAL HARI INI
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
                    <Skeleton className="h-12 w-64 rounded-xl" />
                    <Skeleton className="h-10 w-[240px] rounded-xl" />
                </div>
                <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
                    {[1, 2, 3, 4].map(i => <Skeleton key={i} className="h-32 rounded-2xl" />)}
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
            gradient: "from-blue-600 to-indigo-600", 
            progress: 100, 
            path: '/students' 
        },
        { 
            title: "Total DUDI", 
            icon: Building2, 
            value: stats?.totalCompanies ?? 0, 
            description: "Mitra Industri Aktif", 
            gradient: "from-cyan-500 to-blue-600", 
            progress: 100, 
            path: '/companies' 
        },
        { 
            title: "Siswa Ditempatkan", 
            icon: MapPin, 
            value: stats?.placedStudents ?? 0, 
            description: `${stats?.placedStudents ?? 0} SISWA AKTIF PKL`, 
            gradient: "from-blue-700 to-blue-500", 
            path: '/students', // Diarahkan ke Manajemen Siswa
            progress: ((stats?.placedStudents ?? 0) / (stats?.totalStudents ?? 1)) * 100, 
        },
        { 
            title: "Jurnal Hari Ini", 
            icon: CalendarIcon, 
            value: stats?.journalsToday ?? 0, 
            description: "Laporan Masuk", 
            gradient: "from-sky-400 to-blue-600", 
            progress: stats?.placedStudents ? ((stats.journalsToday / stats.placedStudents) * 100) : 0, 
            path: '/journals' 
        }
    ]

    return (
        <div className={cn(
            "space-y-10 p-6 pb-16 transition-all duration-700 ease-in-out",
            isMounted ? "opacity-100 translate-y-0" : "opacity-0 translate-y-4"
        )}>
            
            {/* Header */}
            <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
                <div className="space-y-1">
                    <div className="flex items-center gap-2 mb-2">
                        <div className="h-1.5 w-12 bg-blue-600 rounded-full animate-pulse" />
                        <span className="text-xs font-black text-blue-600 uppercase tracking-[0.4em]">System Monitoring</span>
                    </div>
                    <h1 className="text-4xl md:text-5xl font-black tracking-tighter text-slate-900 dark:text-white min-h-[60px]">
                        {displayText}<span className="text-blue-600"> PKL</span>
                        <span className="ml-1 inline-block w-1 h-10 bg-blue-600 animate-pulse align-middle"></span>
                    </h1>
                </div>

                <div className="flex flex-wrap items-center gap-3">
                    <Button onClick={() => navigate('/reports')} variant="outline" className="rounded-xl border-blue-400 dark:border-blue-800 font-bold gap-2">
                        <FileText className="w-4 h-4 text-blue-600" /> Cetak Laporan
                    </Button>
                    
                    <Popover>
                        <PopoverTrigger asChild>
                            <Button variant="outline" className="w-[220px] justify-start rounded-xl border-blue-400 dark:border-blue-800 font-bold">
                                <CalendarIcon className="mr-2 h-4 w-4 text-blue-500" />
                                {date ? format(date, "PPP", { locale: id }) : <span>Pilih tanggal</span>}
                            </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0 rounded-2xl border-none shadow-2xl" align="end">
                            <Calendar mode="single" selected={date} onSelect={setDate} locale={id} className="rounded-2xl" />
                        </PopoverContent>
                    </Popover>

                    <Button onClick={() => navigate('/companies')} className="rounded-xl bg-blue-600 hover:bg-blue-700 shadow-xl font-bold transition-all duration-300 hover:scale-105 active:scale-95 text-white">
                        <PlusCircle className="w-4 h-4" /> Penempatan
                    </Button>
                </div>
            </div>

            {/* Stats Grid */}
            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
                {statItems.map((stat, index) => (
                    <Card 
                        key={index} 
                        onClick={() => navigate(stat.path)}
                        className="relative border-2 border-blue-400 dark:border-blue-800/60 bg-white dark:bg-slate-900/90 overflow-hidden cursor-pointer rounded-2xl transition-all duration-500 hover:-translate-y-2 hover:shadow-2xl group"
                    >
                        <CardHeader className="flex flex-row items-center justify-between pb-2 border-b border-blue-100 dark:border-blue-900/30">
                            <CardTitle className="text-[11px] font-black uppercase tracking-widest text-blue-700 dark:text-blue-100">{stat.title}</CardTitle>
                            <div className="p-2 rounded-lg bg-blue-600 text-white shadow-lg group-hover:rotate-12 transition-transform">
                                <stat.icon className="h-4 w-4" />
                            </div>
                        </CardHeader>
                        <CardContent className="pt-5">
                            <div className="flex items-baseline justify-between">
                                <span className="text-4xl font-black text-slate-900 dark:text-white tracking-tight leading-none">{stat.value}</span>
                                <ArrowUpRight className="w-5 h-5 text-blue-500 opacity-50" />
                            </div>
                            <p className="text-[11px] font-bold text-blue-600/70 dark:text-blue-300/70 mt-2 uppercase mb-4">{stat.description}</p>
                            <div className="h-2 w-full bg-blue-50 dark:bg-slate-800 rounded-full overflow-hidden border border-blue-100 dark:border-slate-700/50">
                                <div className={cn("h-full rounded-full bg-gradient-to-r transition-all duration-1000", stat.gradient)} style={{ width: `${stat.progress}%` }} />
                            </div>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {/* Charts */}
            <div className="grid gap-8 md:grid-cols-2">
                <Card className="border-2 border-blue-400 dark:border-blue-900/40 shadow-xl rounded-[2.5rem] overflow-hidden bg-white dark:bg-slate-900">
                    <CardHeader className="border-b-2 border-blue-100 dark:border-blue-900/50 bg-blue-50/30 dark:bg-blue-950/20 px-8 py-5">
                        <CardTitle className="text-sm font-black text-blue-800 dark:text-slate-100 uppercase tracking-[0.2em]">Distribusi Perusahaan</CardTitle>
                    </CardHeader>
                    <CardContent className="pt-8 px-6">
                        <CompanyDistributionChart />
                    </CardContent>
                </Card>
                
                <Card className="border-2 border-blue-400 dark:border-blue-900/40 shadow-xl rounded-[2.5rem] overflow-hidden bg-white dark:bg-slate-900">
                    <CardHeader className="border-b-2 border-blue-100 dark:border-blue-900/50 bg-blue-50/30 dark:bg-blue-950/20 px-8 py-5">
                        <CardTitle className="text-sm font-black text-blue-800 dark:text-slate-100 uppercase tracking-[0.2em]">Sebaran Kota PKL</CardTitle>
                    </CardHeader>
                    <CardContent className="pt-8 px-6">
                        <CityDistributionChart />
                    </CardContent>
                </Card>
            </div>

            {/* Map */}
            <div className="space-y-6 pt-4">
                <div className="flex items-center gap-3 px-2">
                    <div className="relative flex h-3 w-3">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-3 w-3 bg-red-500"></span>
                    </div>
                    <h2 className="text-sm font-black text-slate-800 dark:text-slate-100 uppercase tracking-[0.3em]">Live Monitoring Map</h2>
                </div>
                <div className="rounded-[3rem] overflow-hidden border-[8px] border-blue-400 dark:border-slate-800 shadow-[0_0_50px_rgba(59,130,246,0.2)] bg-slate-100 dark:bg-slate-900 min-h-[400px]">
                    <LiveMonitoringMap />
                </div>
            </div>
        </div>
    )
}