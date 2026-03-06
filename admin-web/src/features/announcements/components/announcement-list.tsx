import { format } from "date-fns"
import { id } from "date-fns/locale"
import { MoreHorizontal, Trash2 } from 'lucide-react'
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { supabase } from "@/lib/supabase"
import { toast } from "sonner"

export interface Announcement {
    id: string
    title: string
    content: string
    target_role: 'all' | 'student' | 'teacher'
    created_at: string
    is_active: boolean
    author_id: string
}

interface AnnouncementListProps {
    data: Announcement[]
    onRefresh: () => void
}

export function AnnouncementList({ data, onRefresh }: AnnouncementListProps) {

    async function handleDelete(id: string) {
        if (!confirm("Apakah Anda yakin ingin menghapus pengumuman ini?")) return

        const { error } = await supabase
            .from("announcements")
            .delete()
            .eq("id", id)

        if (error) {
            toast.error("Gagal menghapus pengumuman")
        } else {
            toast.success("Pengumuman dihapus")
            onRefresh()
        }
    }

    async function handleToggleStatus(item: Announcement) {
        const { error } = await supabase
            .from("announcements")
            .update({ is_active: !item.is_active })
            .eq("id", item.id)

        if (error) {
            toast.error("Gagal mengubah status")
        } else {
            toast.success("Status berhasil diubah")
            onRefresh()
        }
    }

    if (data.length === 0) {
        return (
            <div className="text-center py-12 border rounded-lg bg-slate-50">
                <p className="text-slate-500">Belum ada pengumuman</p>
            </div>
        )
    }

    return (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {data.map((item) => (
                <div
                    key={item.id}
                    className={`p-4 rounded-lg border bg-white shadow-sm flex flex-col ${!item.is_active ? 'opacity-60 bg-slate-50' : ''}`}
                >
                    <div className="flex justify-between items-start mb-2">
                        <div className="flex gap-2 items-center">
                            <Badge variant={item.is_active ? "default" : "secondary"}>
                                {item.is_active ? "Aktif" : "Nonaktif"}
                            </Badge>
                            <Badge variant="outline" className="capitalize">
                                {item.target_role === 'all' ? 'Semua' : item.target_role}
                            </Badge>
                        </div>
                        <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                                <Button variant="ghost" size="icon" className="h-8 w-8">
                                    <MoreHorizontal className="h-4 w-4" />
                                </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                                <DropdownMenuItem onClick={() => handleToggleStatus(item)}>
                                    {item.is_active ? "Nonaktifkan" : "Aktifkan"}
                                </DropdownMenuItem>
                                <DropdownMenuItem
                                    className="text-red-600 focus:text-red-600"
                                    onClick={() => handleDelete(item.id)}
                                >
                                    <Trash2 className="mr-2 h-4 w-4" />
                                    Hapus
                                </DropdownMenuItem>
                            </DropdownMenuContent>
                        </DropdownMenu>
                    </div>

                    <h3 className="font-semibold text-lg mb-1">{item.title}</h3>
                    <p className="text-slate-600 text-sm mb-4 line-clamp-3 flex-1">
                        {item.content}
                    </p>

                    <div className="text-xs text-slate-400 mt-auto pt-2 border-t">
                        Diposting: {format(new Date(item.created_at), "d MMM yyyy, HH:mm", { locale: id })}
                    </div>
                </div>
            ))}
        </div>
    )
}
