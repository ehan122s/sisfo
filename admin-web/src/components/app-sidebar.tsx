import * as React from "react"
import { Link, useLocation } from "react-router-dom"
import {
  IconDashboard,
  IconUsers,
  IconBuilding,
  IconCalendarCheck,
  IconNotebook,
  IconSettings,
  IconHelp,
  IconSchool,
  IconReportAnalytics,
  IconUserCog,
  IconHistory,
  IconMap,
  IconBroadcast,
  IconBell,
  IconUserCheck,
  IconLayoutDashboard,
  IconChalkboard,
} from "@tabler/icons-react"
import { NavMain } from "@/components/nav-main"
import { NavSecondary } from "@/components/nav-secondary"
import { NavUser } from "@/components/nav-user"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "@/components/ui/sidebar"
import { useAuthContext } from "@/contexts/auth-context"

const navMain = [
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
    title: "Guru",
    url: "/teachers",
    icon: IconUserCog,
  },
  {
    title: "Wali Kelas",
    url: "/wali-kelas",
    icon: IconChalkboard,
  },
  {
    title: "Absensi Siswa",
    url: "/attendance",
    icon: IconCalendarCheck,
  },
  {
    title: "Absensi Guru",
    url: "/teacher-attendance",
    icon: IconUserCheck,
  },
  {
    title: "PKL",
    url: "#", // Dummy URL for collapse trigger
    icon: IconSchool,
    items: [
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
        title: "Monitoring Siswa",
        url: "/monitoring",
        icon: IconUsers,
      },
      {
        title: "Live Map",
        url: "/live-map",
        icon: IconMap,
      },
    ]
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
]

const navSecondary = [
  {
    title: "Notifikasi",
    url: "/notifications",
    icon: IconBell,
  },
  {
    title: "Pengaturan",
    url: "/settings",
    icon: IconSettings,
  },
  {
    title: "Bantuan",
    url: "/help",
    icon: IconHelp,
  },
]

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const { user, signOut } = useAuthContext()
  const location = useLocation()

  const userData = {
    name: user?.email?.split('@')[0] || 'Admin',
    email: user?.email || '',
    avatar: '',
  }

  // Mark active items
  const navMainWithActive = navMain.map(item => ({
    ...item,
    isActive: location.pathname === item.url,
  }))

  return (
    <Sidebar collapsible="offcanvas" {...props}>
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton
              asChild
              className="data-[slot=sidebar-menu-button]:!p-1.5"
            >
              <Link to="/">
                <IconSchool className="!size-5" />
                <span className="text-base font-semibold">
                  E-PKL
                </span>
              </Link>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>
      <SidebarContent>
        <NavMain items={navMainWithActive} />
        <NavSecondary items={navSecondary} className="mt-auto" />
      </SidebarContent>
      <SidebarFooter>
        <NavUser user={userData} onSignOut={signOut} />
      </SidebarFooter>
    </Sidebar>
  )
}
