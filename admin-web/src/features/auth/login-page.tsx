import { useState } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { useAuthContext } from '@/contexts/auth-context'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Loader2, Lock, Mail, ArrowRight } from 'lucide-react'

export function LoginPage() {
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [error, setError] = useState('')
    const [loading, setLoading] = useState(false)

    const { signIn } = useAuthContext()
    const navigate = useNavigate()
    const location = useLocation()

    const from = (location.state as { from?: { pathname: string } })?.from?.pathname || '/'

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setError('')
        setLoading(true)

        try {
            await signIn(email, password)
            navigate(from, { replace: true })
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Login gagal')
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="flex min-h-screen w-full overflow-hidden bg-slate-950 lg:grid lg:grid-cols-2">
            {/* Animated Background Section (Left/Top) */}
            <div className="relative hidden w-full flex-col justify-between overflow-hidden bg-slate-900 lg:flex px-10 py-12 text-white">
                {/* Abstract Tech SVG Pattern */}
                <div className="absolute inset-0 z-0 opacity-20">
                    <svg className="h-full w-full" xmlns="http://www.w3.org/2000/svg">
                        <defs>
                            <pattern id="grid-pattern" width="40" height="40" patternUnits="userSpaceOnUse">
                                <path d="M0 40L40 0H20L0 20M40 40V20L20 40" stroke="currentColor" strokeWidth="1" fill="none" className="text-emerald-500/30" />
                            </pattern>
                        </defs>
                        <rect width="100%" height="100%" fill="url(#grid-pattern)" />
                        <circle cx="20%" cy="30%" r="200" fill="url(#glow-1)" className="animate-pulse opacity-40" />
                        <circle cx="80%" cy="70%" r="300" fill="url(#glow-2)" className="animate-pulse opacity-30 delay-1000" />
                        <defs>
                            <radialGradient id="glow-1" cx="0.5" cy="0.5" r="0.5">
                                <stop offset="0%" stopColor="#10b981" />
                                <stop offset="100%" stopColor="transparent" />
                            </radialGradient>
                            <radialGradient id="glow-2" cx="0.5" cy="0.5" r="0.5">
                                <stop offset="0%" stopColor="#3b82f6" />
                                <stop offset="100%" stopColor="transparent" />
                            </radialGradient>
                        </defs>
                    </svg>
                </div>

                <div className="relative z-10">
                    <div className="flex items-center gap-2">
                        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-400 to-cyan-500 shadow-lg shadow-emerald-500/20">
                            <Lock className="h-5 w-5 text-white" />
                        </div>
                        <span className="text-xl font-bold tracking-tight text-white">E-PKL System</span>
                    </div>
                </div>

                <div className="relative z-10 max-w-lg">
                    <h1 className="text-4xl font-bold tracking-tight text-white sm:text-5xl lg:text-6xl">
                        Sistem Monitoring <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-cyan-400">Prakerin</span> Terpadu.
                    </h1>
                    <p className="mt-6 text-lg text-slate-400 leading-relaxed">
                        Kelola data siswa, absensi, dan jurnal kegiatan dalam satu platform modern yang aman dan efisien.
                    </p>
                </div>

                <div className="relative z-10 flex items-center gap-4 text-sm text-slate-500">
                    <span>&copy; 2024 E-PKL System System</span>
                    <div className="h-1 w-1 rounded-full bg-slate-700" />
                    <span>Nama SMK Anda</span>
                </div>
            </div>

            {/* Login Form Section (Right/Bottom) */}
            <div className="flex flex-1 items-center justify-center p-8 bg-slate-50 dark:bg-slate-950 relative">
                {/* Mobile Background Effect */}
                <div className="absolute inset-0 lg:hidden overflow-hidden">
                    <div className="absolute -top-[20%] -left-[20%] w-[140%] h-[140%] bg-gradient-to-br from-emerald-500/10 via-transparent to-cyan-500/10 rotate-12 blur-3xl" />
                </div>

                <div className="relative w-full max-w-sm space-y-8">
                    <div className="flex flex-col space-y-2 text-center lg:text-left">
                        <h2 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white">Selamat Datang</h2>
                        <p className="text-muted-foreground">Masuk untuk mengakses dashboard admin.</p>
                    </div>

                    <Card className="border-0 shadow-2xl bg-white/70 backdrop-blur-xl dark:bg-slate-900/70 border-t border-white/50 dark:border-slate-800/50">
                        <CardHeader className="space-y-1 pb-2">
                            <CardTitle className="text-xl">Akun Admin</CardTitle>
                            <CardDescription>Masukkan kredensial Anda untuk melanjutkan</CardDescription>
                        </CardHeader>
                        <CardContent>
                            <form onSubmit={handleSubmit} className="space-y-4">
                                {error && (
                                    <div className="flex items-center gap-2 rounded-lg bg-red-50 p-3 text-sm text-red-600 dark:bg-red-900/20 dark:text-red-400 border border-red-100 dark:border-red-900/50 animate-in fade-in slide-in-from-top-2">
                                        <Lock className="h-4 w-4 shrink-0" />
                                        <span>{error}</span>
                                    </div>
                                )}
                                <div className="space-y-4">
                                    <div className="space-y-2">
                                        <div className="relative">
                                            <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                                            <Input
                                                id="email"
                                                type="email"
                                                placeholder="nama@sekolah.sch.id"
                                                value={email}
                                                onChange={(e) => setEmail(e.target.value)}
                                                className="pl-9 h-11 bg-white/50 dark:bg-slate-950/50 border-slate-200 dark:border-slate-800 focus:border-emerald-500 focus:ring-emerald-500 transition-all"
                                                required
                                            />
                                        </div>
                                    </div>
                                    <div className="space-y-2">
                                        <div className="relative">
                                            <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                                            <Input
                                                id="password"
                                                type="password"
                                                placeholder="••••••••"
                                                value={password}
                                                onChange={(e) => setPassword(e.target.value)}
                                                className="pl-9 h-11 bg-white/50 dark:bg-slate-950/50 border-slate-200 dark:border-slate-800 focus:border-emerald-500 focus:ring-emerald-500 transition-all"
                                                required
                                            />
                                        </div>
                                    </div>
                                </div>
                                <Button
                                    type="submit"
                                    className="w-full h-11 bg-gradient-to-r from-emerald-600 to-cyan-600 hover:from-emerald-700 hover:to-cyan-700 text-white shadow-lg shadow-emerald-500/20 transition-all duration-300 transform hover:scale-[1.02] active:scale-[0.98]"
                                    disabled={loading}
                                >
                                    {loading ? (
                                        <>
                                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                            Memverifikasi...
                                        </>
                                    ) : (
                                        <>
                                            Masuk Dashboard
                                            <ArrowRight className="ml-2 h-4 w-4 opacity-70" />
                                        </>
                                    )}
                                </Button>
                            </form>
                        </CardContent>
                    </Card>

                    <p className="px-8 text-center text-sm text-muted-foreground">
                        Lupa password? <a href="#" className="underline underline-offset-4 hover:text-emerald-600 transition-colors">Hubungi IT Support</a>
                    </p>
                </div>
            </div>
        </div>
    )
}
