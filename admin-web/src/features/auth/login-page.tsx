import { useState } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { useAuthContext } from '@/contexts/auth-context'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Loader2, Lock, Mail, ArrowRight, GraduationCap, ShieldCheck, BarChart3, Users } from 'lucide-react'

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

    const features = [
        { icon: Users, text: 'Manajemen data siswa PKL' },
        { icon: ShieldCheck, text: 'Absensi GPS & verifikasi foto' },
        { icon: BarChart3, text: 'Laporan & monitoring real-time' },
    ]

    return (
        <div className="flex min-h-screen w-full overflow-hidden" style={{ fontFamily: "'Plus Jakarta Sans', sans-serif" }}>
            <style>{`
                @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

                @keyframes float {
                    0%, 100% { transform: translateY(0px) rotate(0deg); }
                    50% { transform: translateY(-20px) rotate(3deg); }
                }
                @keyframes float2 {
                    0%, 100% { transform: translateY(0px) rotate(0deg); }
                    50% { transform: translateY(-14px) rotate(-2deg); }
                }
                @keyframes shimmer {
                    0% { background-position: -200% center; }
                    100% { background-position: 200% center; }
                }
                @keyframes fadeUp {
                    from { opacity: 0; transform: translateY(24px); }
                    to { opacity: 1; transform: translateY(0); }
                }
                @keyframes pulse-ring {
                    0% { transform: scale(1); opacity: 0.4; }
                    100% { transform: scale(1.8); opacity: 0; }
                }
                .animate-float { animation: float 6s ease-in-out infinite; }
                .animate-float2 { animation: float2 8s ease-in-out infinite; }
                .animate-fade-up { animation: fadeUp 0.6s ease-out forwards; }
                .animate-fade-up-delay-1 { animation: fadeUp 0.6s ease-out 0.1s forwards; opacity: 0; }
                .animate-fade-up-delay-2 { animation: fadeUp 0.6s ease-out 0.2s forwards; opacity: 0; }
                .animate-fade-up-delay-3 { animation: fadeUp 0.6s ease-out 0.3s forwards; opacity: 0; }
                .shimmer-text {
                    background: linear-gradient(90deg, #fff 0%, #93c5fd 40%, #fff 60%, #93c5fd 100%);
                    background-size: 200% auto;
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                    animation: shimmer 4s linear infinite;
                }
                .input-blue:focus {
                    border-color: #1d4ed8 !important;
                    box-shadow: 0 0 0 3px rgba(29,78,216,0.15) !important;
                    outline: none !important;
                }
                .btn-blue {
                    background: linear-gradient(135deg, #1565C0, #1E88E5);
                    transition: all 0.3s ease;
                }
                .btn-blue:hover:not(:disabled) {
                    background: linear-gradient(135deg, #0D47A1, #1565C0);
                    transform: translateY(-1px);
                    box-shadow: 0 8px 25px rgba(21,101,192,0.4);
                }
                .btn-blue:active:not(:disabled) {
                    transform: translateY(0px);
                }
                .card-login {
                    background: rgba(255,255,255,0.95);
                    backdrop-filter: blur(20px);
                    border: 1px solid rgba(255,255,255,0.8);
                    box-shadow: 0 32px 64px rgba(13,71,161,0.12), 0 0 0 1px rgba(255,255,255,0.5);
                }
            `}</style>

            {/* ── Left Panel ── */}
            <div
                className="hidden lg:flex flex-col justify-between w-[52%] relative overflow-hidden px-16 py-14"
                style={{ background: 'linear-gradient(145deg, #0D47A1 0%, #1565C0 40%, #1976D2 70%, #1E88E5 100%)' }}
            >
                {/* Background shapes */}
                <div className="absolute inset-0 overflow-hidden pointer-events-none">
                    <div className="animate-float absolute top-[10%] right-[8%] w-72 h-72 rounded-full opacity-10"
                        style={{ background: 'radial-gradient(circle, #90CAF9, transparent)' }} />
                    <div className="animate-float2 absolute bottom-[15%] left-[5%] w-96 h-96 rounded-full opacity-10"
                        style={{ background: 'radial-gradient(circle, #BBDEFB, transparent)' }} />
                    {/* Grid dots */}
                    <svg className="absolute inset-0 w-full h-full opacity-[0.06]" xmlns="http://www.w3.org/2000/svg">
                        <defs>
                            <pattern id="dots" width="32" height="32" patternUnits="userSpaceOnUse">
                                <circle cx="2" cy="2" r="1.5" fill="white" />
                            </pattern>
                        </defs>
                        <rect width="100%" height="100%" fill="url(#dots)" />
                    </svg>
                    {/* Decorative rings */}
                    <div className="absolute top-[30%] left-[60%] w-48 h-48 rounded-full border border-white/10" />
                    <div className="absolute top-[28%] left-[58%] w-64 h-64 rounded-full border border-white/5" />
                </div>

                {/* Logo */}
                <div className="relative z-10 animate-fade-up flex items-center gap-3">
                    <div className="flex h-11 w-11 items-center justify-center rounded-2xl shadow-lg"
                        style={{ background: 'rgba(255,255,255,0.2)', border: '1px solid rgba(255,255,255,0.3)' }}>
                        <GraduationCap className="h-6 w-6 text-white" />
                    </div>
                    <div>
                        <p className="text-white font-bold text-lg leading-none">E-PKL System</p>
                        <p className="text-blue-200 text-xs mt-0.5">SMKN 1 Garut</p>
                    </div>
                </div>

                {/* Hero text */}
                <div className="relative z-10 space-y-8">
                    <div className="space-y-4">
                        <div className="animate-fade-up-delay-1">
                            <span className="inline-block px-3 py-1 rounded-full text-xs font-semibold text-blue-100 mb-4"
                                style={{ background: 'rgba(255,255,255,0.15)', border: '1px solid rgba(255,255,255,0.2)' }}>
                                Platform Monitoring PKL
                            </span>
                        </div>
                        <h1 className="animate-fade-up-delay-1 text-5xl font-extrabold leading-tight tracking-tight text-white">
                            Sistem Monitoring<br />
                            <span className="shimmer-text">Prakerin</span>{' '}
                            <span className="text-white">Terpadu.</span>
                        </h1>
                        <p className="animate-fade-up-delay-2 text-blue-100 text-lg leading-relaxed max-w-md">
                            Kelola data siswa, absensi GPS, dan jurnal kegiatan dalam satu platform modern yang aman dan efisien.
                        </p>
                    </div>

                    {/* Feature list */}
                    <div className="animate-fade-up-delay-3 space-y-3">
                        {features.map((f, i) => (
                            <div key={i} className="flex items-center gap-3">
                                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl"
                                    style={{ background: 'rgba(255,255,255,0.15)' }}>
                                    <f.icon className="h-4 w-4 text-white" />
                                </div>
                                <span className="text-blue-100 text-sm">{f.text}</span>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Footer */}
                <div className="relative z-10 animate-fade-up-delay-3 flex items-center gap-3 text-blue-300 text-xs">
                    <span>© 2024 E-PKL System</span>
                    <span className="w-1 h-1 rounded-full bg-blue-400" />
                    <span>SMKN 1 Garut</span>
                </div>
            </div>

            {/* ── Right Panel (Form) ── */}
            <div className="flex flex-1 items-center justify-center p-8 relative"
                style={{ background: 'linear-gradient(160deg, #EFF6FF 0%, #F0F5FF 50%, #E8F0FE 100%)' }}>

                {/* Mobile bg */}
                <div className="absolute inset-0 lg:hidden overflow-hidden pointer-events-none">
                    <div className="absolute -top-32 -right-32 w-96 h-96 rounded-full opacity-30"
                        style={{ background: 'radial-gradient(circle, #BBDEFB, transparent)' }} />
                </div>

                <div className="relative w-full max-w-sm">
                    {/* Mobile logo */}
                    <div className="lg:hidden flex items-center gap-2 mb-8 justify-center">
                        <div className="flex h-10 w-10 items-center justify-center rounded-2xl"
                            style={{ background: 'linear-gradient(135deg, #1565C0, #1E88E5)' }}>
                            <GraduationCap className="h-5 w-5 text-white" />
                        </div>
                        <span className="text-xl font-bold text-slate-800">E-PKL System</span>
                    </div>

                    {/* Heading */}
                    <div className="mb-8 animate-fade-up">
                        <h2 className="text-3xl font-extrabold text-slate-800 tracking-tight">Selamat Datang</h2>
                        <p className="text-slate-500 mt-1 text-sm">Masuk untuk mengakses dashboard admin.</p>
                    </div>

                    {/* Card */}
                    <div className="card-login rounded-3xl p-8 animate-fade-up-delay-1">
                        <div className="mb-6">
                            <p className="font-bold text-slate-800 text-lg">Akun Admin</p>
                            <p className="text-slate-400 text-sm mt-0.5">Masukkan kredensial Anda untuk melanjutkan</p>
                        </div>

                        <form onSubmit={handleSubmit} className="space-y-4">
                            {error && (
                                <div className="flex items-center gap-2 rounded-xl p-3 text-sm text-red-600 border border-red-100 animate-fade-up"
                                    style={{ background: '#FFF5F5' }}>
                                    <Lock className="h-4 w-4 shrink-0" />
                                    <span>{error}</span>
                                </div>
                            )}

                            <div className="space-y-3">
                                <div className="relative">
                                    <Mail className="absolute left-3.5 top-3.5 h-4 w-4 text-slate-400" />
                                    <Input
                                        type="email"
                                        placeholder="nama@sekolah.sch.id"
                                        value={email}
                                        onChange={(e) => setEmail(e.target.value)}
                                        className="input-blue pl-10 h-12 rounded-xl border-slate-200 bg-slate-50 text-slate-800 placeholder:text-slate-400"
                                        required
                                    />
                                </div>
                                <div className="relative">
                                    <Lock className="absolute left-3.5 top-3.5 h-4 w-4 text-slate-400" />
                                    <Input
                                        type="password"
                                        placeholder="••••••••"
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                        className="input-blue pl-10 h-12 rounded-xl border-slate-200 bg-slate-50 text-slate-800"
                                        required
                                    />
                                </div>
                            </div>

                            <button
                                type="submit"
                                disabled={loading}
                                className="btn-blue w-full h-12 rounded-xl text-white font-semibold flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed mt-2"
                            >
                                {loading ? (
                                    <>
                                        <Loader2 className="h-4 w-4 animate-spin" />
                                        Memverifikasi...
                                    </>
                                ) : (
                                    <>
                                        Masuk Dashboard
                                        <ArrowRight className="h-4 w-4" />
                                    </>
                                )}
                            </button>
                        </form>
                    </div>

                    <p className="mt-6 text-center text-sm text-slate-400 animate-fade-up-delay-2">
                        Lupa password?{' '}
                        <a href="#" className="font-semibold text-blue-600 hover:text-blue-700 transition-colors">
                            Hubungi IT Support
                        </a>
                    </p>
                </div>
            </div>
        </div>
    )
}