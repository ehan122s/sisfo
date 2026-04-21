import { useEffect, useState } from "react"
import { Loader2, Megaphone, CheckCircle, Users, Search } from 'lucide-react'
import { AnnouncementList, type Announcement } from "./components/announcement-list"
import { CreateAnnouncementDialog } from "./components/create-announcement-dialog"
import { supabase } from "@/lib/supabase"
import { Input } from "@/components/ui/input"
import { cn } from "@/lib/utils"

export function AnnouncementsPage() {
    const [data, setData] = useState<Announcement[]>([])
    const [loading, setLoading] = useState(true)
    const [searchQuery, setSearchQuery] = useState("")
    const [activeFilter, setActiveFilter] = useState<string>("all")

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
            setLoading(false)
        }
    }

    useEffect(() => {
        fetchData()
    }, [])

    const filteredData = data.filter(item => {
        const title = item.title?.toLowerCase() || ""
        const content = item.content?.toLowerCase() || ""
        const search = searchQuery.toLowerCase()
        
        const matchesSearch = title.includes(search) || content.includes(search)
        const matchesFilter = activeFilter === "all" || item.target_role === activeFilter
        
        return matchesSearch && matchesFilter
    })

    const stats = [
        { 
            label: 'Total', 
            value: data.length.toString(), 
            icon: Megaphone, 
            gradient: 'from-blue-700 to-blue-400'
        },
        { 
            label: 'Aktif', 
            value: data.filter(d => d.is_active).length.toString(), 
            icon: CheckCircle, 
            gradient: 'from-cyan-600 to-blue-500'
        },
        { 
            label: 'Users', 
            value: 'Semua', 
            icon: Users, 
            gradient: 'from-indigo-600 to-blue-500'
        },
    ]

    return (
        <div className="space-y-8">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-foreground">Pengumuman</h1>
                    {/* Teks deskripsi sudah dihapus di sini */}
                </div>
                <CreateAnnouncementDialog onSuccess={fetchData} />
            </div>

            {/* Statistik Ringkas */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {stats.map((stat, i) => (
                    <div 
                        key={i} 
                        className={cn(
                            "p-4 rounded-xl border border-border bg-card flex items-center gap-4 transition-all hover:shadow-md hover:scale-[1.01]",
                            "bg-gradient-to-br from-white to-blue-50/30 dark:from-card dark:to-blue-950/10"
                        )}
                    >
                        <div className={cn(
                            "p-3 rounded-lg shadow-sm text-white bg-gradient-to-tr",
                            stat.gradient
                        )}>
                            <stat.icon className="w-5 h-5" />
                        </div>
                        <div>
                            <p className="text-xs text-muted-foreground font-medium">{stat.label}</p>
                            <p className="text-xl font-bold text-foreground">{stat.value}</p>
                        </div>
                    </div>
                ))}
            </div>

            {/* Filter Target & Search */}
            <div className="flex flex-col md:flex-row gap-4 items-start md:items-center justify-between py-4 border-y border-border/50">
                <div className="flex items-center gap-2 overflow-x-auto w-full md:w-auto pb-2 md:pb-0">
                    {filters.map((f) => (
                        <button
                            key={f.value}
                            onClick={() => setActiveFilter(f.value)}
                            className={cn(
                                "px-5 py-2 rounded-full text-xs font-bold transition-all border whitespace-nowrap shadow-sm",
                                activeFilter === f.value 
                                    ? "bg-gradient-to-r from-blue-700 to-blue-500 text-white border-transparent" 
                                    : "bg-background text-muted-foreground border-border hover:border-blue-400 hover:text-blue-600"
                            )}
                        >
                            {f.label}
                        </button>
                    ))}
                </div>
                <div className="relative w-full md:w-72">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                    <Input 
                        placeholder="Cari judul atau isi..." 
                        className="pl-9 bg-background focus-visible:ring-blue-500/20 border-border hover:border-blue-300 transition-colors"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />
                </div>
            </div>

            {loading ? (
                <div className="flex flex-col items-center justify-center py-20 gap-3">
                    <Loader2 className="h-10 w-10 animate-spin text-blue-600" />
                    <p className="text-sm text-muted-foreground animate-pulse">Menghubungkan ke database...</p>
                </div>
            ) : (
                <div className="min-h-[300px]">
                    {filteredData.length === 0 ? (
                        <div className="flex flex-col items-center justify-center py-20 border-2 border-dashed rounded-2xl border-border/60">
                            <Megaphone className="h-12 w-12 text-muted-foreground/20 mb-4" />
                            <p className="text-muted-foreground font-medium">Tidak ada pengumuman ditemukan.</p>
                        </div>
                    ) : (
                        <AnnouncementList data={filteredData} onRefresh={fetchData} />
                    )}
                </div>
            )}
        </div>
    )
}