import { useEffect, useState } from "react"
import { Loader2, Megaphone, CheckCircle, Users, Search, BellOff } from 'lucide-react'
import { AnnouncementList, type Announcement } from "./components/announcement-list"
import { CreateAnnouncementDialog } from "./components/create-announcement-dialog"
import { supabase } from "@/lib/supabase"
import { Input } from "@/components/ui/input"
import { cn } from "@/lib/utils"
import { Card, CardContent } from '@/components/ui/card'

export function AnnouncementsPage() {
    const [data, setData] = useState<Announcement[]>([])
    const [loading, setLoading] = useState(true)
    const [searchQuery, setSearchQuery] = useState("")
    const [activeFilter, setActiveFilter] = useState<string>("all")
    const [isMounted, setIsMounted] = useState(false)

    const filters = [
        { label: "Semua", value: "all" },
        { label: "Siswa", value: "student" },
        { label: "Guru", value: "teacher" }
    ]

    async function fetchData() {
        setLoading(true)
        try {
            const { data: result, error } = await supabase
                .from("announcements")
                .select("*")
                .order("created_at", { ascending: false })

            if (!error && result) {
                setData(result as Announcement[])
            }
        } catch (err) {
            console.error("Error fetching announcements:", err)
        } finally {
            setTimeout(() => setLoading(false), 500)
        }
    }

    useEffect(() => {
        fetchData()
        setIsMounted(true)
    }, [])

    const filteredData = data.filter(item => {
        const title = item.title?.toLowerCase() || ""
        const content = item.content?.toLowerCase() || ""
        const search = searchQuery.toLowerCase()
        return (title.includes(search) || content.includes(search)) &&
            (activeFilter === "all" || item.target_role === activeFilter)
    })

    const stats = [
        {
            label: 'TOTAL PENGUMUMAN',
            value: data.length,
            icon: Megaphone,
            iconColor: 'text-blue-500 dark:text-blue-400',
            iconBg: 'bg-blue-500/10',
            barColor: 'bg-blue-500',
            percent: 100,
            sub: '100% dari total',
        },
        {
            label: 'AKTIF',
            value: data.filter(d => d.is_active).length,
            icon: CheckCircle,
            iconColor: 'text-green-500 dark:text-green-400',
            iconBg: 'bg-green-500/10',
            barColor: 'bg-green-500',
            percent: data.length > 0 ? Math.round((data.filter(d => d.is_active).length / data.length) * 100) : 0,
            sub: `${data.length > 0 ? Math.round((data.filter(d => d.is_active).length / data.length) * 100) : 0}% dari total`,
        },
        {
            label: 'TARGET AUDIENS',
            value: 'Semua',
            icon: Users,
            iconColor: 'text-orange-500 dark:text-orange-400',
            iconBg: 'bg-orange-500/10',
            barColor: 'bg-orange-400',
            percent: 11,
            sub: 'Siswa & Guru',
        },
    ]

    return (
        <div className={cn(
            "space-y-8 p-4 pb-16 min-h-screen bg-slate-50/50 dark:bg-transparent transition-all duration-700 ease-out",
            isMounted ? "opacity-100 translate-y-0" : "opacity-0 translate-y-6"
        )}>

            {/* --- HEADER --- */}
            <div className="flex flex-col gap-4 md:flex-row md:items-start justify-between">
                <div className="space-y-1">
                    <div className="flex gap-1 mb-3">
                        <div className="h-1 w-8 rounded-full bg-blue-500" />
                        <div className="h-1 w-4 rounded-full bg-blue-800" />
                    </div>
                    <h1 className="text-4xl md:text-5xl font-black italic tracking-tight text-slate-900 dark:text-white uppercase">
                        MANAJEMEN{" "}
                        <span className="text-blue-600 dark:text-blue-400">PENGUMUMAN</span>
                    </h1>
                    <p className="text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
                        Kelola dan broadcast pengumuman untuk siswa & guru
                    </p>
                </div>
                <div className="flex items-center gap-3 mt-2 md:mt-1">
                    <CreateAnnouncementDialog onSuccess={fetchData} />
                </div>
            </div>

            {/* --- STATS --- */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
                {stats.map((stat, i) => (
                    <Card
                        key={i}
                        className="bg-white dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 rounded-2xl overflow-hidden shadow-sm transition-all duration-300"
                    >
                        <CardContent className="p-5">
                            <div className="flex items-start justify-between mb-4">
                                <div>
                                    <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-1">{stat.label}</p>
                                    <p className="text-4xl font-black text-slate-900 dark:text-white tracking-tight">{stat.value}</p>
                                </div>
                                <div className={cn("p-3 rounded-xl", stat.iconBg)}>
                                    <stat.icon className={cn("w-6 h-6", stat.iconColor)} />
                                </div>
                            </div>
                           
                            <div className="h-1 w-full bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                                <div
                                    className={cn("h-full rounded-full transition-all duration-1000", stat.barColor)}
                                    style={{ width: `${stat.percent}%` }}
                                />
                            </div>
                            <p className="text-xs text-slate-400 dark:text-slate-500 mt-2 font-medium">{stat.sub}</p>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {/* --- FILTER & SEARCH --- */}
            <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
                {/* Filter Tabs */}
            
                <div className="flex bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 p-1 rounded-xl w-full md:w-auto shadow-sm">
                    {filters.map((f) => (
                        <button
                            key={f.value}
                            onClick={() => setActiveFilter(f.value)}
                            className={cn(
                                "flex-1 md:flex-none px-6 py-2 rounded-lg text-xs font-black transition-all duration-200 uppercase tracking-widest",
                                activeFilter === f.value
                                    ? "bg-blue-600 text-white shadow-md shadow-blue-500/20"
                                    : "text-slate-400 dark:text-slate-500 hover:text-slate-800 dark:hover:text-white"
                            )}
                        >
                            {f.label}
                        </button>
                    ))}
                </div>

                {/* Search */}
                <div className="relative w-full md:w-72">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                   
                    <Input
                        placeholder="Cari pengumuman..."
                        className="pl-10 h-10 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 placeholder:text-slate-400 dark:placeholder:text-slate-500 focus-visible:ring-1 focus-visible:ring-blue-500 focus-visible:border-blue-500 text-sm font-medium shadow-sm transition-colors"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />
                </div>
            </div>

            {/* --- CONTENT --- */}
            <div className="relative min-h-[400px]">
                {loading ? (
                    <div className="absolute inset-0 flex flex-col items-center justify-center gap-4">
                        <Loader2 className="h-10 w-10 animate-spin text-blue-500" />
                        <p className="text-xs font-black text-slate-400 dark:text-slate-500 tracking-[0.4em] uppercase">Memuat Data...</p>
                    </div>
                ) : (
                    <div className="animate-in fade-in slide-in-from-bottom-6 duration-500">
                        {filteredData.length === 0 ? (
                            
                            <Card className="border border-dashed border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900/50 rounded-2xl min-h-[400px] flex flex-col items-center justify-center text-center p-12 shadow-sm">
                                <div className="bg-slate-100 dark:bg-slate-800 p-8 rounded-full mb-6">
                                    <BellOff className="w-14 h-14 text-slate-400 dark:text-slate-600" />
                                </div>
                                <h3 className="text-2xl font-black text-slate-800 dark:text-white mb-2 uppercase">Data Kosong</h3>
                                <p className="text-slate-400 dark:text-slate-500 font-medium max-w-xs leading-relaxed text-sm">
                                    Belum ada pengumuman. Coba filter lain atau buat pengumuman baru.
                                </p>
                            </Card>
                        ) : (
                            <AnnouncementList data={filteredData} onRefresh={fetchData} />
                        )}
                    </div>
                )}
            </div>
        </div>
    )
}