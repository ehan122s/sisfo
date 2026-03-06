import { useEffect, useState } from "react"
import { Loader2 } from 'lucide-react'
import { AnnouncementList, type Announcement } from "./components/announcement-list"
import { CreateAnnouncementDialog } from "./components/create-announcement-dialog"
import { supabase } from "@/lib/supabase"

export function AnnouncementsPage() {
    const [data, setData] = useState<Announcement[]>([])
    const [loading, setLoading] = useState(true)

    async function fetchData() {
        setLoading(true)
        const { data: result, error } = await supabase
            .from("announcements")
            .select("*")
            .order("created_at", { ascending: false })

        if (!error && result) {
            // Cast because Types setup is pending
            setData(result as unknown as Announcement[])
        }
        setLoading(false)
    }

    useEffect(() => {
        fetchData()
    }, [])

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Pengumuman</h1>
                    <p className="text-muted-foreground">
                        Kelola pengumuman untuk siswa dan guru.
                    </p>
                </div>
                <CreateAnnouncementDialog onSuccess={fetchData} />
            </div>

            {loading ? (
                <div className="flex justify-center py-12">
                    <Loader2 className="h-8 w-8 animate-spin text-slate-400" />
                </div>
            ) : (
                <AnnouncementList data={data} onRefresh={fetchData} />
            )}
        </div>
    )
}
