import { useLocation, Link } from 'react-router-dom'
import { ChevronRight } from 'lucide-react'
import { cn } from '@/lib/utils'

export function Breadcrumbs() {
    const location = useLocation()
    const pathnames = location.pathname.split('/').filter((x) => x)

    // Map common routes to readable names
    const routeNameMap: Record<string, string> = {
        'dashboard': 'Dashboard',
        'students': 'Siswa',
        'companies': 'DUDI',
        'attendance': 'Absensi',
        'journals': 'Jurnal',
        'reports': 'Laporan',
        'audit-logs': 'Audit Logs',
        'teachers': 'Pembimbing',
        'add': 'Tambah',
        'edit': 'Edit',
    }

    const getRouteName = (value: string) => {
        // Check map first
        if (routeNameMap[value]) return routeNameMap[value]

        // If it looks like an ID (alphanumeric mixed, long), truncate or show generic
        if (value.length > 20 || /\d/.test(value)) return 'Detail'

        // Fallback: Capitalize
        return value.charAt(0).toUpperCase() + value.slice(1)
    }

    return (
        <nav aria-label="Breadcrumb" className="mb-4 flex items-center space-x-2 text-sm text-muted-foreground">
            <Link
                to="/"
                className={cn(
                    "hover:text-foreground transition-colors font-medium",
                    pathnames.length === 0 && "text-foreground"
                )}
            >
                E-PKL
            </Link>

            {pathnames.map((value, index) => {
                const to = `/${pathnames.slice(0, index + 1).join('/')}`
                const isLast = index === pathnames.length - 1
                const name = getRouteName(value)

                return (
                    <div key={to} className="flex items-center">
                        <ChevronRight className="h-4 w-4 mx-1" />
                        {isLast ? (
                            <span className="font-medium text-foreground">{name}</span>
                        ) : (
                            <Link to={to} className="hover:text-foreground transition-colors">
                                {name}
                            </Link>
                        )}
                    </div>
                )
            })}
        </nav>
    )
}
