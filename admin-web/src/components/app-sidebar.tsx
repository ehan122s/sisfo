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
} from "@/components/ui/sidebar"
import { useAuthContext } from "@/contexts/auth-context"

const navMain = [
  { title: "Dashboard", url: "/", icon: IconDashboard },
  { title: "Siswa", url: "/students", icon: IconUsers },
  { title: "Guru", url: "/teachers", icon: IconUserCog },
  { title: "Wali Kelas", url: "/wali-kelas", icon: IconChalkboard },
  { title: "Absensi Siswa", url: "/attendance", icon: IconCalendarCheck },
  { title: "Absensi Guru", url: "/teacher-attendance", icon: IconUserCheck },
  {
    title: "PKL",
    url: "#",
    icon: IconSchool,
    items: [
      { title: "Dashboard", url: "/pkl-dashboard", icon: IconLayoutDashboard },
      { title: "DUDI", url: "/companies", icon: IconBuilding },
      { title: "Jurnal", url: "/journals", icon: IconNotebook },
      { title: "Monitoring Siswa", url: "/monitoring", icon: IconUsers },
      { title: "Live Map", url: "/live-map", icon: IconMap },
    ],
  },
  { title: "Laporan", url: "/reports", icon: IconReportAnalytics },
  { title: "Pengumuman", url: "/announcements", icon: IconBroadcast },
  { title: "Audit Logs", url: "/audit-logs", icon: IconHistory },
]

const navSecondary = [
  { title: "Notifikasi", url: "/notifications", icon: IconBell },
  { title: "Pengaturan", url: "/settings", icon: IconSettings },
  { title: "Bantuan", url: "/help", icon: IconHelp },
]

// ─── EPKLLogo ─────────────────────────────────────────────────────────────────
function EPKLLogo() {
  const letters = ["E", "-", "P", "K", "L"]

  return (
    <div style={{ display: "flex", alignItems: "center", gap: "10px", padding: "4px 2px" }}>
      <style>{`
        @keyframes epkl-bounce {
          0%, 100% { transform: translateY(0px) rotate(-2deg); }
          50% { transform: translateY(-5px) rotate(2deg); }
        }
        @keyframes epkl-orbit {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        @keyframes epkl-twinkle-1 {
          0%, 100% { opacity: 0; transform: scale(0.5); }
          50% { opacity: 1; transform: scale(1.2); }
        }
        @keyframes epkl-twinkle-2 {
          0%, 100% { opacity: 0; transform: scale(0.5); }
          40% { opacity: 1; transform: scale(1.2); }
        }
        @keyframes epkl-twinkle-3 {
          0%, 100% { opacity: 0; transform: scale(0.5); }
          60% { opacity: 1; transform: scale(1.1); }
        }
        @keyframes epkl-wave {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-4px); }
        }
        @keyframes epkl-shimmer {
          0% { background-position: -200% center; }
          100% { background-position: 200% center; }
        }
        @keyframes epkl-glow-pulse {
          0%, 100% { box-shadow: 0 0 8px rgba(59,130,246,0.4); }
          50% { box-shadow: 0 0 18px rgba(59,130,246,0.85), 0 0 30px rgba(99,179,237,0.3); }
        }
      `}</style>

      {/* Graduation cap with orbit + bounce + glow */}
      <div style={{ position: "relative", width: "40px", height: "40px", flexShrink: 0 }}>
        {/* Orbit ring */}
        <div style={{
          position: "absolute", inset: "-4px", borderRadius: "50%",
          border: "1.5px solid transparent",
          borderTopColor: "#3b82f6",
          borderRightColor: "rgba(59,130,246,0.3)",
          animation: "epkl-orbit 2.4s linear infinite",
        }} />

        {/* Icon circle */}
        <div style={{
          width: "40px", height: "40px", borderRadius: "50%",
          background: "linear-gradient(135deg, #1d4ed8 0%, #3b82f6 60%, #60a5fa 100%)",
          display: "flex", alignItems: "center", justifyContent: "center",
          animation: "epkl-bounce 2.8s ease-in-out infinite, epkl-glow-pulse 2.8s ease-in-out infinite",
        }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
            <polygon points="12,3 22,8 12,13 2,8" fill="white" opacity="0.95" />
            <path d="M6 10.5v5.5c0 1.5 2.7 3 6 3s6-1.5 6-3v-5.5" fill="white" opacity="0.75" />
            <line x1="22" y1="8" x2="22" y2="14" stroke="white" strokeWidth="1.8" strokeLinecap="round" opacity="0.85" />
            <circle cx="22" cy="14.5" r="1.2" fill="white" opacity="0.85" />
          </svg>
        </div>

        {/* Twinkle stars */}
        <div style={{ position: "absolute", top: "0px", right: "-2px", width: "6px", height: "6px", borderRadius: "50%", background: "#facc15", animation: "epkl-twinkle-1 2s ease-in-out infinite" }} />
        <div style={{ position: "absolute", bottom: "2px", left: "-3px", width: "5px", height: "5px", borderRadius: "50%", background: "#60a5fa", animation: "epkl-twinkle-2 2.4s ease-in-out infinite 0.4s" }} />
        <div style={{ position: "absolute", top: "4px", left: "-1px", width: "4px", height: "4px", borderRadius: "50%", background: "#a78bfa", animation: "epkl-twinkle-3 1.8s ease-in-out infinite 0.8s" }} />
      </div>

      {/* E-PKL text wave + shimmer */}
      <div style={{ display: "flex", alignItems: "center" }}>
        {letters.map((char, i) => (
          <span key={i} style={{
            display: "inline-block",
            fontSize: "18px",
            fontWeight: 800,
            background: "linear-gradient(90deg, #1d4ed8, #3b82f6, #60a5fa, #93c5fd, #3b82f6, #1d4ed8)",
            backgroundSize: "200% auto",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            backgroundClip: "text",
            animation: `epkl-wave 1.8s ease-in-out infinite, epkl-shimmer 3s linear infinite`,
            animationDelay: `${i * 0.12}s, 0s`,
          }}>
            {char}
          </span>
        ))}
      </div>
    </div>
  )
}
// ─────────────────────────────────────────────────────────────────────────────

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const { user, signOut } = useAuthContext()
  const location = useLocation()

  const userData = {
    name: user?.email?.split("@")[0] || "Admin",
    email: user?.email || "",
    avatar: "",
  }

  const navMainWithActive = navMain.map((item) => ({
    ...item,
    isActive: location.pathname === item.url,
  }))

  return (
    <Sidebar collapsible="offcanvas" {...props}>
      <SidebarHeader>
        <EPKLLogo />
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