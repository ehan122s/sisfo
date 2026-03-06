import { Navigate, useLocation } from 'react-router-dom'
import { useAuthContext } from '@/contexts/auth-context'

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
    const { user, role, loading, signOut } = useAuthContext()
    const location = useLocation()

    if (loading) {
        return (
            <div className="flex h-screen items-center justify-center">
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
            </div>
        )
    }

    if (!user) {
        return <Navigate to="/login" state={{ from: location }} replace />
    }

    // Role check - now works instantly with Custom Claims
    if (role !== 'admin') {
        return (
            <div className="flex h-screen w-full flex-col items-center justify-center gap-2">
                <h1 className="text-2xl font-bold">Akses Ditolak</h1>
                <p className="text-muted-foreground">Anda tidak memiliki izin untuk mengakses halaman ini.</p>
                <div className="mt-4 rounded bg-slate-100 p-4 text-left text-xs font-mono dark:bg-slate-900">
                    <p>User ID: {user.id}</p>
                    <p>Detected Role: {role || 'none'}</p>
                </div>
                <button
                    onClick={() => signOut()}
                    className="mt-4 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90"
                >
                    Keluar
                </button>
            </div>
        )
    }

    return children
}
