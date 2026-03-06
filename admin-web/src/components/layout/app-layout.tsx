import { Outlet } from 'react-router-dom'
import { SidebarProvider, SidebarInset } from '@/components/ui/sidebar'
import { AppSidebar } from '@/components/app-sidebar'
import { SiteHeader } from '@/components/site-header'
import { useKeyboardShortcuts } from '@/hooks/use-keyboard-shortcuts'
import { MobileNav } from '@/components/layout/mobile-nav'
import { SessionTimeoutProvider } from '@/components/session-timeout-provider'

export function AppLayout() {
    useKeyboardShortcuts()

    return (
        <SessionTimeoutProvider>
            <SidebarProvider>
                <AppSidebar variant="inset" />
                <SidebarInset>
                    <SiteHeader />
                    <main className="flex-1 overflow-auto p-4 lg:p-6 pb-20 md:pb-6">
                        <Outlet />
                    </main>
                    <MobileNav />
                </SidebarInset>
            </SidebarProvider>
        </SessionTimeoutProvider>
    )
}
