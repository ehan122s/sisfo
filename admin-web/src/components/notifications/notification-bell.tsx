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

// Simple time ago formatter
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
                <Button variant="ghost" size="icon" className="relative text-slate-500 hover:text-slate-900">
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
            <DropdownMenuContent className="w-80 md:w-96" align="end" forceMount>
                <div className="flex items-center justify-between px-4 py-2 border-b bg-slate-50/50">
                    <h4 className="text-sm font-semibold text-slate-900">Notifikasi</h4>
                    <div className="flex gap-1">
                        <Button
                            variant="outline"
                            size="sm"
                            className="h-7 px-2 text-xs gap-1 border-slate-200 text-slate-600 hover:text-slate-900 hover:bg-slate-100"
                            onClick={async () => {
                                // Trigger violation check manually
                                await supabase.rpc('check_attendance_violations')
                                // Optional: give feedback
                            }}
                            title="Cek Pelanggaran Manual"
                        >
                            <CheckCheck className="w-3.5 h-3.5" />
                            <span>Scan</span>
                        </Button>
                        {unreadCount > 0 && (
                            <Button
                                variant="ghost"
                                size="sm"
                                className="h-auto px-2 text-xs text-blue-600 hover:text-blue-700 hover:bg-blue-50"
                                onClick={() => markAllAsRead()}
                            >
                                Tandai dibaca
                            </Button>
                        )}
                    </div>
                </div>

                {/* Notification List Container */}
                <div className="max-h-[70vh] overflow-y-auto">
                    {notifications.length === 0 ? (
                        <div className="py-8 text-center text-slate-500 text-sm">
                            Belum ada notifikasi
                        </div>
                    ) : (
                        <div className="grid">
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

    // Determine icon based on type (could be enhanced later)
    const isAlert = item.type === 'alert' || item.type === 'warning'

    return (
        <div
            onClick={handleClick}
            className={cn(
                "flex gap-3 px-4 py-3 hover:bg-slate-50 transition-colors cursor-pointer border-b last:border-0 relative group",
                !item.is_read && "bg-blue-50/40 hover:bg-blue-50/60"
            )}
        >
            {!item.is_read && (
                <div className="absolute left-0 top-0 bottom-0 w-1 bg-blue-500" />
            )}

            <div className={cn(
                "mt-0.5 w-2 h-2 rounded-full flex-shrink-0",
                isAlert ? "bg-red-500" : "bg-blue-500",
                item.is_read && "bg-slate-300"
            )} />

            <div className="flex-1 space-y-1">
                <div className="flex items-start justify-between gap-2">
                    <p className={cn("text-sm font-medium leading-none", !item.is_read ? "text-slate-900" : "text-slate-600")}>
                        {item.title}
                    </p>
                    <span className="text-[10px] text-slate-400 whitespace-nowrap">
                        {timeAgo(item.created_at)}
                    </span>
                </div>
                <p className="text-xs text-slate-500 line-clamp-2">
                    {item.message}
                </p>
                {item.action_link && (
                    <Link
                        to={item.action_link}
                        className="inline-block mt-1 text-xs font-medium text-blue-600 hover:underline"
                        onClick={(e) => { e.stopPropagation(); handleClick(); }}
                    >
                        Lihat Detail
                    </Link>
                )}
            </div>
        </div>
    )
}
