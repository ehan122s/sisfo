import { ArrowRight, Play } from 'lucide-react'
import { motion } from 'framer-motion'

export function Hero() {
    return (
        <section className="min-h-screen flex items-center relative overflow-hidden bg-gradient-to-br from-slate-50 to-emerald-50">
            {/* Background Effects */}
            <div className="absolute inset-0 z-0">
                <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-emerald-200/40 rounded-full blur-3xl" />
                <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-cyan-200/40 rounded-full blur-3xl" />
            </div>

            <div className="container-custom relative z-10 pt-20">
                <div className="grid lg:grid-cols-2 gap-12 items-center">
                    {/* Left Content */}
                    <motion.div
                        initial={{ opacity: 0, x: -50 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ duration: 0.8 }}
                    >
                        <span className="inline-block px-4 py-2 rounded-full bg-emerald-100 border border-emerald-200 text-emerald-700 text-sm font-medium mb-6">
                            ✨ Platform Prakerin Modern
                        </span>
                        <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold leading-tight mb-6 text-slate-800">
                            Digitalisasi <span className="gradient-text">Prakerin SMK</span>,
                            <br />Semudah Satu Klik
                        </h1>
                        <p className="text-lg text-slate-600 mb-8 max-w-xl">
                            Sistem monitoring PKL modern berbasis mobile & web untuk efisiensi
                            administrasi sekolah. Hemat waktu, tingkatkan akurasi, dan pantau
                            siswa secara real-time.
                        </p>
                        <div className="flex flex-wrap gap-4">
                            <a
                                href="#contact"
                                className="btn-gradient px-8 py-4 rounded-xl font-semibold inline-flex items-center gap-2"
                            >
                                Hubungi Kami
                                <ArrowRight className="w-5 h-5" />
                            </a>
                            <a
                                href="#features"
                                className="px-8 py-4 rounded-xl font-semibold border border-slate-300 hover:border-emerald-500 hover:text-emerald-600 transition-colors inline-flex items-center gap-2 text-slate-700"
                            >
                                <Play className="w-5 h-5" />
                                Lihat Fitur
                            </a>
                        </div>

                        {/* Stats */}
                        <div className="flex gap-8 mt-12 pt-8 border-t border-slate-200">
                            <div>
                                <div className="text-3xl font-bold gradient-text">300+</div>
                                <div className="text-slate-500 text-sm">Siswa Terdaftar</div>
                            </div>
                            <div>
                                <div className="text-3xl font-bold gradient-text">15+</div>
                                <div className="text-slate-500 text-sm">DUDI Partner</div>
                            </div>
                            <div>
                                <div className="text-3xl font-bold gradient-text">99%</div>
                                <div className="text-slate-500 text-sm">Uptime Server</div>
                            </div>
                        </div>
                    </motion.div>

                    {/* Right - Mockup */}
                    <motion.div
                        initial={{ opacity: 0, x: 50 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ duration: 0.8, delay: 0.2 }}
                        className="relative"
                    >
                        <div className="relative z-10">
                            <div className="glass-card rounded-3xl p-2 shadow-2xl relative overflow-hidden">
                                {/* Use the Dashboard screenshot as Hero Image */}
                                <div className="bg-slate-100 rounded-2xl overflow-hidden aspect-video relative group">
                                    <img
                                        src="/screenshoot/web admin dashboard 1.png"
                                        alt="Dashboard Preview"
                                        className="w-full h-full object-cover object-left-top"
                                    />
                                </div>
                            </div>
                        </div>
                        {/* Decorative Elements */}
                        <div className="absolute -top-4 -right-4 w-24 h-24 bg-emerald-200/50 rounded-full blur-2xl" />
                        <div className="absolute -bottom-4 -left-4 w-32 h-32 bg-cyan-200/50 rounded-full blur-2xl" />
                    </motion.div>
                </div>
            </div>
        </section>
    )
}
