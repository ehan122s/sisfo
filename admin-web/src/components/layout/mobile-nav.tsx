
import { Link, useLocation } from "react-router-dom"
import {
    IconDashboard,
    IconUsers,
    IconCalendarCheck,
    IconMenu2,
    IconSchool,
    IconUserCheck,
    IconBuilding,
    IconUserCog,
    IconReportAnalytics,
    IconHistory,
    IconSettings,
    IconNotebook,
    IconMap,
    IconBroadcast,
    IconLayoutDashboard,
} from "@tabler/icons-react"
import { cn } from "@/lib/utils"
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuSub,
    DropdownMenuSubTrigger,
    DropdownMenuSubContent,
} from "@/components/ui/dropdown-menu"

export function MobileNav() {
    const location = useLocation()
    const pathname = location.pathname

    // Main bottom nav items (4 items + more)
    const navItems = [
        {
            title: "Dashboard",
            url: "/",
            icon: IconDashboard,
        },
        {
            title: "Siswa",
            url: "/students",
            icon: IconUsers,
        },
        {
            title: "Absen",
            url: "/attendance",
            icon: IconCalendarCheck,
        },
        {
            title: "Guru",
            url: "/teacher-attendance",
            icon: IconUserCheck,
        },
    ]

    // PKL sub-menu items (grouped)
    const pklItems = [
        {
            title: "Dashboard",
            url: "/pkl-dashboard",
            icon: IconLayoutDashboard,
        },
        {
            title: "DUDI",
            url: "/companies",
            icon: IconBuilding,
        },
        {
            title: "Jurnal",
            url: "/journals",
            icon: IconNotebook,
        },
        {
            title: "Monitoring",
            url: "/monitoring",
            icon: IconSchool,
        },
        {
            title: "Live Map",
            url: "/live-map",
            icon: IconMap,
        },
    ]

    // Other menu items
    const otherItems = [
        {
            title: "Guru / Pembimbing",
            url: "/teachers",
            icon: IconUserCog,
        },
        {
            title: "Laporan",
            url: "/reports",
            icon: IconReportAnalytics,
        },
        {
            title: "Pengumuman",
            url: "/announcements",
            icon: IconBroadcast,
        },
        {
            title: "Audit Logs",
            url: "/audit-logs",
            icon: IconHistory,
        },
        {
            title: "Pengaturan",
            url: "/settings",
            icon: IconSettings,
        },
    ]

    return (
        <div className="fixed bottom-0 left-0 right-0 z-50 flex h-16 items-center justify-around border-t bg-background px-4 pb-safe pt-2 md:hidden">
            {navItems.map((item) => {
                const isActive = pathname === item.url
                return (
                    <Link
                        key={item.url}
                        to={item.url}
                        className={cn(
                            "flex flex-col items-center justify-center gap-1 text-xs font-medium transition-colors hover:text-primary",
                            isActive ? "text-primary" : "text-muted-foreground"
                        )}
                    >
                        <item.icon className={cn("h-5 w-5", isActive && "fill-current")} />
                        <span>{item.title}</span>
                    </Link>
                )
            })}

            <DropdownMenu>
                <DropdownMenuTrigger asChild>
                    <div
                        className={cn(
                            "flex flex-col items-center justify-center gap-1 text-xs font-medium transition-colors hover:text-primary cursor-pointer text-muted-foreground"
                        )}
                    >
                        <IconMenu2 className="h-5 w-5" />
                        <span>Lainnya</span>
                    </div>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-56 mb-2">
                    <DropdownMenuLabel>Menu Lainnya</DropdownMenuLabel>
                    <DropdownMenuSeparator />

                    {/* PKL Submenu */}
                    <DropdownMenuSub>
                        <DropdownMenuSubTrigger className="flex items-center gap-2">
                            <IconSchool className="h-4 w-4" />
                            <span>PKL</span>
                        </DropdownMenuSubTrigger>
                        <DropdownMenuSubContent>
                            {pklItems.map((item) => (
                                <DropdownMenuItem key={item.url} asChild>
                                    <Link to={item.url} className="flex items-center gap-2 cursor-pointer">
                                        <item.icon className="h-4 w-4" />
                                        <span>{item.title}</span>
                                    </Link>
                                </DropdownMenuItem>
                            ))}
                        </DropdownMenuSubContent>
                    </DropdownMenuSub>

                    <DropdownMenuSeparator />

                    {/* Other menu items */}
                    {otherItems.map((item) => (
                        <DropdownMenuItem key={item.url} asChild>
                            <Link to={item.url} className="flex items-center gap-2 cursor-pointer">
                                <item.icon className="h-4 w-4" />
                                <span>{item.title}</span>
                            </Link>
                        </DropdownMenuItem>
                    ))}
                </DropdownMenuContent>
            </DropdownMenu>
        </div>
    )
}
