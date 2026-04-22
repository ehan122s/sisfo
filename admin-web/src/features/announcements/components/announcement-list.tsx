import { format } from "date-fns"
import { id } from "date-fns/locale"
import { MoreHorizontal, Trash2, Eye, Calendar, Megaphone } from 'lucide-react'
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { supabase } from "@/lib/supabase"
import { toast } from "sonner"
import { cn } from "@/lib/utils"

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
            <div className="flex flex-col items-center justify-center py-20 border-2 border-dashed rounded-2xl border-border/60 bg-muted/5">
                <Megaphone className="h-10 w-10 text-muted-foreground/20 mb-3" />
                <p className="text-muted-foreground font-medium text-sm">Belum ada pengumuman yang sesuai.</p>
            </div>
        )
    }

    return (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {data.map((item) => (
                <div
                    key={item.id}
                    className={cn(
                        "group relative p-5 rounded-2xl border bg-card text-card-foreground shadow-sm flex flex-col transition-all duration-300",
                        "hover:shadow-xl hover:shadow-blue-500/10 hover:-translate-y-1 hover:border-blue-400/50",
                        !item.is_active && 'opacity-70 grayscale-[0.5] bg-muted/30'
                    )}
                >
                    {/* Garis Aksen Gradasi di atas saat Hover */}
                    <div className="absolute top-0 left-0 w-full h-1.5 bg-gradient-to-r from-blue-700 via-blue-500 to-blue-400 rounded-t-2xl opacity-0 group-hover:opacity-100 transition-opacity" />

                    <div className="flex justify-between items-start mb-4">
                        <div className="flex gap-2 items-center">
                            <Badge 
                                className={cn(
                                    "border-none px-3 py-0.5 font-bold shadow-sm",
                                    item.is_active 
                                    ? "bg-gradient-to-r from-blue-600 to-blue-400 text-white" 
                                    : "bg-slate-500 text-white"
                                )}
                            >
                                {item.is_active ? "Aktif" : "Nonaktif"}
                            </Badge>
                            
                            <Badge 
                                variant="outline" 
                                className={cn(
                                    "capitalize font-bold border-2",
                                    item.target_role === 'student' && "text-blue-500 border-blue-100 bg-blue-50/50 dark:bg-blue-900/20",
                                    item.target_role === 'teacher' && "text-purple-500 border-purple-100 bg-purple-50/50 dark:bg-purple-900/20",
                                    item.target_role === 'all' && "text-emerald-500 border-emerald-100 bg-emerald-50/50 dark:bg-emerald-900/20"
                                )}
                            >
                                {item.target_role === 'all' ? 'Semua' : item.target_role}
                            </Badge>
                        </div>

                        <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                                <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/30">
                                    <MoreHorizontal className="h-4 w-4" />
                                </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end" className="w-48 rounded-xl shadow-xl">
                                <DropdownMenuItem onClick={() => handleToggleStatus(item)} className="cursor-pointer font-medium">
                                    {item.is_active ? "Nonaktifkan" : "Aktifkan"}
                                </DropdownMenuItem>
                                <DropdownMenuItem
                                    className="text-red-600 focus:text-red-600 dark:focus:bg-red-900/20 cursor-pointer font-medium"
                                    onClick={() => handleDelete(item.id)}
                                >
                                    <Trash2 className="mr-2 h-4 w-4" />
                                    Hapus
                                </DropdownMenuItem>
                            </DropdownMenuContent>
                        </DropdownMenu>
                    </div>

                    <h3 className="font-bold text-xl mb-2 group-hover:text-blue-600 transition-colors line-clamp-1">
                        {item.title}
                    </h3>
                    
                    <p className="text-muted-foreground text-sm mb-6 line-clamp-3 flex-1 leading-relaxed">
                        {item.content}
                    </p>

                    <div className="flex items-center justify-between mt-auto pt-4 border-t border-border/50">
                        <div className="flex flex-col gap-1">
                            <div className="flex items-center gap-1.5 text-muted-foreground/60">
                                <Calendar className="w-3 h-3" />
                                <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground/40">Dibuat</span>
                            </div>
                            <span className="text-[11px] font-semibold text-muted-foreground">
                                {format(new Date(item.created_at), "d MMMM yyyy", { locale: id })}
                            </span>
                        </div>
                        
                        {/* FITUR DETAIL DENGAN DIALOG */}
                        <Dialog>
                            <DialogTrigger asChild>
                                <Button 
                                    variant="secondary"
                                    size="sm" 
                                    className="h-8 px-4 rounded-full bg-gradient-to-r from-blue-700 to-blue-500 hover:from-blue-800 hover:to-blue-600 text-white border-none shadow-md shadow-blue-500/20 transition-all hover:translate-x-0.5 active:scale-95"
                                >
                                    <Eye className="w-3.5 h-3.5 mr-1.5" />
                                    <span className="text-[11px] font-bold">Detail</span>
                                </Button>
                            </DialogTrigger>
                            <DialogContent className="sm:max-w-[525px] rounded-2xl border-none bg-gradient-to-b from-white to-blue-50 dark:from-card dark:to-blue-950/10">
                                <DialogHeader>
                                    <div className="flex items-center gap-2 mb-3">
                                        <Badge className="bg-blue-600 hover:bg-blue-600">{item.target_role}</Badge>
                                        <span className="text-[11px] font-medium text-muted-foreground italic">
                                            {format(new Date(item.created_at), "EEEE, d MMMM yyyy", { locale: id })}
                                        </span>
                                    </div>
                                    <DialogTitle className="text-2xl font-black text-blue-800 dark:text-blue-400 leading-tight">
                                        {item.title}
                                    </DialogTitle>
                                </DialogHeader>
                                <div className="py-6 text-sm md:text-base text-foreground/80 leading-relaxed whitespace-pre-wrap border-t border-blue-100 dark:border-blue-900/50 mt-2">
                                    {item.content}
                                </div>
                                <div className="flex justify-end pt-2">
                                    <p className="text-[10px] text-muted-foreground font-bold tracking-widest uppercase italic">
                                        SIP SMEA Official Announcement
                                    </p>
                                </div>
                            </DialogContent>
                        </Dialog>
                    </div>
                </div>
            ))}
        </div>
    )
}