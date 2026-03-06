import { Lock } from 'lucide-react'

export function Footer() {
    const currentYear = new Date().getFullYear()

    return (
        <footer className="border-t border-slate-200 py-8 bg-slate-50">
            <div className="container-custom">
                <div className="flex flex-col md:flex-row items-center justify-between gap-4">
                    {/* Logo */}
                    <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-cyan-500 flex items-center justify-center">
                            <Lock className="w-4 h-4 text-white" />
                        </div>
                        <span className="font-bold text-lg text-slate-800">E-PKL</span>
                    </div>

                    {/* Links */}
                    <nav className="flex items-center gap-6 text-sm text-slate-500">
                        <a href="#features" className="hover:text-emerald-600 transition-colors">
                            Fitur
                        </a>
                        <a href="#pricing" className="hover:text-emerald-600 transition-colors">
                            Harga
                        </a>
                        <a href="#faq" className="hover:text-emerald-600 transition-colors">
                            FAQ
                        </a>
                        <a href="#contact" className="hover:text-emerald-600 transition-colors">
                            Kontak
                        </a>
                    </nav>

                    {/* Copyright */}
                    <div className="text-sm text-slate-400">
                        &copy; {currentYear} E-PKL. Dibuat oleh{' '}
                        <span className="text-slate-600">E-PKL Open Source</span>
                    </div>
                </div>
            </div>
        </footer>
    )
}
