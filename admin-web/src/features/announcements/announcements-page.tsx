import { useEffect, useState } from "react"
import { Loader2, Megaphone, CheckCircle, Users, Search, Sparkles, BellOff, ArrowUpRight } from 'lucide-react'
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
    const [displayText, setDisplayText] = useState("")
    const fullText = "Pengumuman"

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
        let i = 0
        const timer = setInterval(() => {
            if (i < fullText.length) {
                setDisplayText(fullText.slice(0, i + 1))
                i++
            } else {
                clearInterval(timer)
            }
        }, 100)
        return () => clearInterval(timer)
    }, [])

    const filteredData = data.filter(item => {
        const title = item.title?.toLowerCase() || ""
        const content = item.content?.toLowerCase() || ""
        const search = searchQuery.toLowerCase()
        return (title.includes(search) || content.includes(search)) && 
               (activeFilter === "all" || item.target_role === activeFilter)
    })

    const stats = [
        { label: 'Total', value: data.length.toString(), icon: Megaphone, gradient: 'from-blue-700 to-blue-500', shadow: 'shadow-blue-500/40' },
        { label: 'Aktif', value: data.filter(d => d.is_active).length.toString(), icon: CheckCircle, gradient: 'from-cyan-600 to-blue-500', shadow: 'shadow-cyan-500/40' },
        { label: 'Target', value: 'Semua', icon: Users, gradient: 'from-indigo-600 to-blue-600', shadow: 'shadow-indigo-500/40' },
    ]

    return (
        <div className={cn(
            "space-y-10 p-4 pb-16 transition-all duration-1000 ease-out",
            isMounted ? "opacity-100 translate-y-0" : "opacity-0 translate-y-10"
        )}>
            
            {/* --- HEADER --- */}
            <div className="flex flex-col gap-6 md:flex-row md:items-center justify-between">
                <div className="space-y-1">
                    <div className="flex items-center gap-2 mb-2">
                        <Sparkles className="w-5 h-5 text-blue-600 drop-shadow-[0_0_10px_rgba(37,99,235,0.8)] animate-pulse" />
                        <span className="text-xs font-black text-blue-700 dark:text-blue-400 uppercase tracking-[0.4em]">Broadcast Center</span>
                    </div>
                    <h1 className="text-4xl md:text-5xl font-black tracking-tighter text-slate-900 dark:text-white min-h-[60px]">
                        {displayText}<span className="ml-1 inline-block w-2 h-10 bg-blue-600 animate-pulse align-middle rounded-full"></span>
                    </h1>
                </div>
                <div className="animate-in fade-in zoom-in duration-700 delay-300">
                    <CreateAnnouncementDialog onSuccess={fetchData} />
                </div>
            </div>

            {/* --- STATS (BIRU MENYALA) --- */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {stats.map((stat, i) => (
                    <Card 
                        key={i} 
                        className={cn(
                            "relative border-2 border-blue-100 dark:border-slate-800 bg-white dark:bg-slate-900/50 overflow-hidden rounded-2xl group transition-all duration-500",
                            "hover:-translate-y-2 hover:border-blue-500",
                            "shadow-[0_10px_20px_-10px_rgba(59,130,246,0.3)] hover:shadow-[0_20px_40px_-15px_rgba(59,130,246,0.5)]",
                            "animate-in fade-in slide-in-from-bottom-8 fill-mode-both"
                        )}
                        style={{ animationDelay: `${(i + 1) * 150}ms` }}
                    >
                        <CardContent className="p-6 flex items-center gap-5">
                            <div className={cn(
                                "p-4 rounded-2xl text-white shadow-xl transition-all duration-500 group-hover:rotate-12 bg-gradient-to-tr",
                                stat.gradient, stat.shadow
                            )}>
                                <stat.icon className="h-7 w-7" />
                            </div>
                            <div className="space-y-1">
                                <p className="text-[10px] font-black text-blue-700 uppercase tracking-widest">{stat.label}</p>
                                <div className="flex items-baseline gap-2">
                                    <span className="text-3xl font-black text-slate-900 dark:text-white tracking-tight">{stat.value}</span>
                                    <ArrowUpRight className="w-5 h-5 text-blue-600 transition-all opacity-0 group-hover:opacity-100 group-hover:translate-x-1 group-hover:-translate-y-1" />
                                </div>
                            </div>
                        </CardContent>
                        {/* Glow Line Under Card */}
                        <div className="absolute bottom-0 left-0 h-1.5 w-0 bg-blue-600 shadow-[0_-5px_15px_rgba(37,99,235,0.6)] transition-all duration-700 group-hover:w-full" />
                    </Card>
                ))}
            </div>

            {/* --- FILTER & SEARCH (NON-PUCET) --- */}
            <div className="flex flex-col md:flex-row gap-6 items-center justify-between p-5 border-2 border-blue-100 dark:border-slate-800 rounded-[2.5rem] bg-gradient-to-r from-blue-50/50 to-white dark:from-slate-900/50 dark:to-slate-900 animate-in fade-in duration-1000 delay-500 shadow-sm">
                <div className="flex bg-white dark:bg-slate-800 p-1.5 rounded-2xl shadow-[0_4px_10px_rgba(0,0,0,0.05)] border border-blue-100 dark:border-slate-700 w-full md:w-auto">
                    {filters.map((f) => (
                        <button
                            key={f.value}
                            onClick={() => setActiveFilter(f.value)}
                            className={cn(
                                "flex-1 md:flex-none px-8 py-2.5 rounded-xl text-xs font-black transition-all duration-300 uppercase tracking-widest",
                                activeFilter === f.value 
                                    ? "bg-blue-600 text-white shadow-[0_10px_20px_-5px_rgba(37,99,235,0.5)] scale-[1.05]" 
                                    : "text-slate-400 hover:text-blue-600 hover:bg-blue-50/50"
                            )}
                        >
                            {f.label}
                        </button>
                    ))}
                </div>

                <div className="relative w-full md:w-80 group">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-blue-400 group-focus-within:text-blue-600 transition-colors" />
                    <Input 
                        placeholder="Cari pengumuman..." 
                        className="pl-12 h-14 rounded-2xl border-2 border-blue-100 dark:border-slate-800 focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 transition-all bg-white dark:bg-slate-900/50 font-bold text-slate-700 shadow-inner"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />
                </div>
            </div>

            {/* --- CONTENT --- */}
            <div className="relative min-h-[400px]">
                {loading ? (
                    <div className="absolute inset-0 flex flex-col items-center justify-center gap-6">
                        <div className="relative">
                            <Loader2 className="h-16 w-16 animate-spin text-blue-600" />
                            <div className="absolute inset-0 blur-3xl bg-blue-500/40 animate-pulse" />
                        </div>
                        <p className="text-sm font-black text-blue-600 animate-pulse tracking-[0.6em] uppercase">Loading Data</p>
                    </div>
                ) : (
                    <div className="animate-in fade-in slide-in-from-bottom-10 duration-700">
                        {filteredData.length === 0 ? (
                            <Card className="border-4 border-dashed border-blue-100 bg-blue-50/20 rounded-[3rem] min-h-[400px] flex flex-col items-center justify-center text-center p-12">
                                <div className="bg-white p-10 rounded-full border-2 border-blue-50 shadow-[0_20px_40px_rgba(0,0,0,0.05)] mb-8">
                                    <BellOff className="w-20 h-20 text-blue-200" />
                                </div>
                                <h3 className="text-3xl font-black text-slate-900 mb-2">Data Kosong</h3>
                                <p className="text-slate-500 font-bold max-w-xs leading-relaxed">Gak ada pengumuman nih. Coba cari yang lain atau buat baru!</p>
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