import { Bell, CheckCheck } from 'lucide-react'
import { Link } from 'react-router-dom'
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Button } from '@/components/ui/button'
import { useNotifications, type Notification } from '@/hooks/use-notifications'
import { supabase } from '@/lib/supabase'
import { cn } from '@/lib/utils'

// Formatter waktu biar lebih rapi
function timeAgo(dateString: string) {
    const date = new Date(dateString)
    const now = new Date()
    const seconds = Math.floor((now.getTime() - date.getTime()) / 1000)

    if (seconds < 60) return 'Baru saja'
    const minutes = Math.floor(seconds / 60)
    if (minutes < 60) return `${minutes}m yang lalu`
    const hours = Math.floor(minutes / 60)
    if (hours < 24) return `${hours}j yang lalu`
    const days = Math.floor(hours / 24)
    if (days < 30) return `${days}h yang lalu`
    return date.toLocaleDateString('id-ID')
}

export function NotificationBell() {
    const { notifications, unreadCount, markAsRead, markAllAsRead } = useNotifications()

    return (
        <DropdownMenu>
            <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="relative text-muted-foreground hover:text-foreground">
                    <Bell className="h-5 w-5" />
                    {unreadCount > 0 && (
                        <span className="absolute top-1.5 right-1.5 flex h-2.5 w-2.5">
                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                            <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-red-500"></span>
                        </span>
                    )}
                    <span className="sr-only">Notifikasi</span>
                </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent className="w-80 md:w-96 p-0 overflow-hidden" align="end">
                {/* Header Dropdown - Sekarang adaptif dark mode */}
                <div className="flex items-center justify-between px-4 py-2.5 border-b bg-muted/30">
                    <h4 className="text-sm font-bold text-foreground">Notifikasi</h4>
                    <div className="flex gap-2">
                        <Button
                            variant="outline"
                            size="sm"
                            className="h-7 px-2 text-[10px] gap-1 border-border bg-background hover:bg-muted"
                            onClick={async () => {
                                await supabase.rpc('check_attendance_violations')
                            }}
                            title="Cek Pelanggaran Manual"
                        >
                            <CheckCheck className="w-3 h-3 text-primary" />
                            <span>Scan</span>
                        </Button>
                        {unreadCount > 0 && (
                            <Button
                                variant="ghost"
                                size="sm"
                                className="h-7 px-2 text-[10px] text-primary hover:bg-primary/10"
                                onClick={() => markAllAsRead()}
                            >
                                Tandai dibaca
                            </Button>
                        )}
                    </div>
                </div>

                {/* List Notifikasi */}
                <div className="max-h-[70vh] overflow-y-auto">
                    {notifications.length === 0 ? (
                        <div className="py-10 text-center text-muted-foreground text-sm">
                            Belum ada notifikasi
                        </div>
                    ) : (
                        <div className="flex flex-col">
                            {notifications.map((item) => (
                                <NotificationItem
                                    key={item.id}
                                    item={item}
                                    onRead={() => markAsRead(item.id)}
                                />
                            ))}
                        </div>
                    )}
                </div>
            </DropdownMenuContent>
        </DropdownMenu>
    )
}

function NotificationItem({ item, onRead }: { item: Notification; onRead: () => void }) {
    const handleClick = () => {
        if (!item.is_read) onRead()
    }

    const isAlert = item.type === 'alert' || item.type === 'warning'

    return (
        <div
            onClick={handleClick}
            className={cn(
                "flex gap-3 px-4 py-3 transition-all cursor-pointer border-b border-border last:border-0 relative group",
                "hover:bg-slate-50 dark:hover:bg-slate-900/80",
                // Warna background kalau belum dibaca (biru tipis transparan)
                !item.is_read && "bg-primary/[0.04] dark:bg-primary/[0.08]"
            )}
        >
            {/* Indikator garis vertikal biru di kiri */}
            {!item.is_read && (
                <div className="absolute left-0 top-0 bottom-0 w-1 bg-primary" />
            )}

            {/* Titik Status (Biru/Merah/Abu) */}
            <div className={cn(
                "mt-1.5 w-2 h-2 rounded-full flex-shrink-0 transition-all",
                isAlert ? "bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.4)]" : "bg-primary shadow-[0_0_8px_rgba(59,130,246,0.4)]",
                item.is_read && "bg-slate-300 dark:bg-slate-700 shadow-none"
            )} />

            <div className="flex-1 space-y-1">
                <div className="flex items-start justify-between gap-2">
                    <p className={cn(
                        "text-sm font-semibold leading-tight",
                        !item.is_read ? "text-foreground" : "text-muted-foreground"
                    )}>
                        {item.title}
                    </p>
                    <span className="text-[10px] text-muted-foreground/70 whitespace-nowrap">
                        {timeAgo(item.created_at)}
                    </span>
                </div>
                
                {/* Isi Pesan */}
                <p className={cn(
                    "text-xs line-clamp-2 leading-relaxed",
                    !item.is_read ? "text-muted-foreground font-medium" : "text-muted-foreground/60"
                )}>
                    {item.message}
                </p>

                {item.action_link && (
                    <Link
                        to={item.action_link}
                        className="inline-block mt-1 text-[11px] font-bold text-primary hover:underline underline-offset-4 decoration-2"
                        onClick={(e) => { e.stopPropagation(); handleClick(); }}
                    >
                        Lihat Detail
                    </Link>
                )}
            </div>
        </div>
    )
}