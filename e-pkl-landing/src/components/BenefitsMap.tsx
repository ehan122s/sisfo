import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
    Zap, Eye, Shield,
    Smartphone, BookOpen, Award,
    Briefcase, TrendingUp, ClipboardCheck
} from 'lucide-react'

export function BenefitsMap() {
    const [activeTab, setActiveTab] = useState<'school' | 'student' | 'industry'>('school')

    const benefitsData = {
        school: [
            {
                icon: <Zap className="w-7 h-7" />,
                title: "Efisiensi Administrasi",
                desc: "Laporan kehadiran yang lengkap, jurnal harian, dan rekap nilai menghemat waktu guru pembimbing hingga 70%.",
                color: "emerald"
            },
            {
                icon: <Eye className="w-7 h-7" />,
                title: "Transparansi Monitoring",
                desc: "Pantau kehadiran dan lokasi siswa secara real-time dengan teknologi geofencing yang akurat dan anti-spoofing.",
                color: "emerald",
                active: true
            },
            {
                icon: <Shield className="w-7 h-7" />,
                title: "Kepatuhan Regulasi",
                desc: "Format penilaian dan pelaporan disesuaikan dengan kurikulum Merdeka dan standar industri terkini.",
                color: "emerald"
            }
        ],
        student: [
            {
                icon: <Smartphone className="w-7 h-7" />,
                title: "Absensi Mobile Mudah",
                desc: "Check-in kehadiran cukup dari HP dengan validasi lokasi GPS dan foto selfie. Tidak perlu antre absen manual.",
                color: "blue"
            },
            {
                icon: <BookOpen className="w-7 h-7" />,
                title: "Jurnal Digital Praktis",
                desc: "Isi laporan kegiatan harian langsung di aplikasi. Upload foto kegiatan dan minta validasi pembimbing dengan sekali klik.",
                color: "blue"
            },
            {
                icon: <Award className="w-7 h-7" />,
                title: "Rekam Jejak Keahlian",
                desc: "Simpan portofolio pekerjaan dan dapatkan sertifikat penilaian digital yang valid untuk menunjang karir.",
                color: "blue"
            }
        ],
        industry: [
            {
                icon: <Briefcase className="w-7 h-7" />,
                title: "Talent Scouting",
                desc: "Identifikasi dan rekrut talenta terbaik dari siswa magang berprestasi untuk kebutuhan SDM perusahaan masa depan.",
                color: "purple"
            },
            {
                icon: <TrendingUp className="w-7 h-7" />,
                title: "Efisiensi Bimbingan",
                desc: "Monitoring kehadiran dan aktivitas siswa magang tanpa mengganggu produktivitas kerja mentor industri.",
                color: "purple"
            },
            {
                icon: <ClipboardCheck className="w-7 h-7" />,
                title: "Penilaian Terintegrasi",
                desc: "Input nilai sikap dan keterampilan siswa secara online, langsung terhubung dan sinkron dengan sistem rapor sekolah.",
                color: "purple"
            }
        ]
    }
    return (
        <section id="benefits-map" className="section bg-slate-50">
            <div className="container-custom">
                {/* Section Header */}
                <div className="text-center max-w-3xl mx-auto mb-10">
                    <span className="inline-block px-4 py-2 rounded-full bg-emerald-100 border border-emerald-200 text-emerald-700 text-sm font-medium mb-4">
                        Keunggulan Sistem
                    </span>
                    <h2 className="text-3xl md:text-4xl font-bold mb-4 text-slate-800">
                        Mengapa Memilih <span className="gradient-text">E-PKL</span>?
                    </h2>
                    <p className="text-slate-500 text-base lg:text-lg">
                        Platform manajemen PKL modern yang dirancang untuk kebutuhan Sekolah, Siswa, dan Industri dalam satu ekosistem terintegrasi.
                    </p>
                </div>

                {/* Tabs */}
                <div className="w-full max-w-4xl mx-auto mb-12">
                    <div className="flex border-b border-slate-200 justify-center gap-4 sm:gap-8">
                        <button
                            onClick={() => setActiveTab('school')}
                            className={`group relative px-4 pb-4 text-sm font-bold transition-colors ${activeTab === 'school' ? 'text-emerald-600' : 'text-slate-400 hover:text-emerald-600'}`}
                        >
                            Untuk Sekolah
                            <span className={`absolute bottom-0 left-0 h-0.5 w-full rounded-t-full transition-all ${activeTab === 'school' ? 'bg-emerald-600' : 'bg-transparent group-hover:bg-emerald-200'}`}></span>
                        </button>
                        <button
                            onClick={() => setActiveTab('student')}
                            className={`group relative px-4 pb-4 text-sm font-bold transition-colors ${activeTab === 'student' ? 'text-blue-600' : 'text-slate-400 hover:text-blue-600'}`}
                        >
                            Untuk Siswa
                            <span className={`absolute bottom-0 left-0 h-0.5 w-full rounded-t-full transition-all ${activeTab === 'student' ? 'bg-blue-600' : 'bg-transparent group-hover:bg-blue-200'}`}></span>
                        </button>
                        <button
                            onClick={() => setActiveTab('industry')}
                            className={`group relative px-4 pb-4 text-sm font-bold transition-colors ${activeTab === 'industry' ? 'text-purple-600' : 'text-slate-400 hover:text-purple-600'}`}
                        >
                            Untuk Industri (DUDI)
                            <span className={`absolute bottom-0 left-0 h-0.5 w-full rounded-t-full transition-all ${activeTab === 'industry' ? 'bg-purple-600' : 'bg-transparent group-hover:bg-purple-200'}`}></span>
                        </button>
                    </div>
                </div>

                {/* Split Layout: Benefits & Interactive Map */}
                <div className="w-full max-w-[1200px] mx-auto grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-12 items-start">
                    {/* Left Column: Benefits Cards */}

                    <div className="lg:col-span-5 order-2 lg:order-1 min-h-[400px]">
                        <AnimatePresence mode="wait">
                            <motion.div
                                key={activeTab}
                                initial={{ opacity: 0, x: -20 }}
                                animate={{ opacity: 1, x: 0 }}
                                exit={{ opacity: 0, x: 20 }}
                                transition={{ duration: 0.3 }}
                                className="flex flex-col gap-5"
                            >
                                {benefitsData[activeTab].map((benefit, idx) => (
                                    <div
                                        key={idx}
                                        className={`group flex flex-col sm:flex-row gap-5 p-6 rounded-2xl bg-white border shadow-sm transition-all duration-300
                                            ${(benefit as any).active
                                                ? `border-${benefit.color}-400 ring-1 ring-${benefit.color}-100 shadow-md shadow-${benefit.color}-100/50`
                                                : `border-slate-200 hover:shadow-md hover:border-${benefit.color}-300`
                                            }
                                        `}
                                    >
                                        <div className={`shrink-0 flex items-center justify-center size-12 rounded-full transition-colors
                                            ${(benefit as any).active
                                                ? `bg-${benefit.color}-600 text-white`
                                                : `bg-${benefit.color}-50 text-${benefit.color}-600 group-hover:bg-${benefit.color}-600 group-hover:text-white`
                                            }
                                        `}>
                                            {benefit.icon}
                                        </div>
                                        <div className="flex flex-col gap-2">
                                            <h3 className="text-lg font-bold text-slate-800">{benefit.title}</h3>
                                            <p className="text-sm text-slate-600 leading-relaxed">
                                                {benefit.desc}
                                            </p>
                                            {(benefit as any).active && (
                                                <div className={`mt-1 flex items-center gap-1 text-${benefit.color}-600 text-xs font-bold`}>
                                                    <span>→</span>
                                                    Lihat simulasi di samping
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                ))}
                            </motion.div>
                        </AnimatePresence>
                    </div>

                    {/* Right Column: Interactive Live Map */}
                    <motion.div
                        initial={{ opacity: 0, x: 30 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.6, delay: 0.2 }}
                        className="lg:col-span-7 w-full order-1 lg:order-2"
                    >
                        <div className="relative w-full rounded-3xl overflow-hidden border border-slate-200 shadow-xl bg-white">
                            {/* Header Bar of the Mockup */}
                            <div className="flex items-center justify-between px-5 py-3 border-b border-slate-100 bg-white z-10 relative">
                                <div className="flex items-center gap-3">
                                    <div className="flex items-center justify-center size-8 rounded-full bg-red-100 text-red-600">
                                        <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                                            <circle cx="12" cy="12" r="2" />
                                            <circle cx="12" cy="12" r="6" opacity="0.3" />
                                            <circle cx="12" cy="12" r="10" opacity="0.15" />
                                        </svg>
                                    </div>
                                    <div>
                                        <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">Live Monitoring</h4>
                                        <p className="text-sm font-bold text-slate-800">SMK Negeri 1 Digital</p>
                                    </div>
                                </div>
                                <div className="flex items-center gap-2">
                                    <span className="relative flex h-2.5 w-2.5">
                                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-500 opacity-75"></span>
                                        <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
                                    </span>
                                    <span className="text-xs font-bold text-emerald-600">Live Update</span>
                                </div>
                            </div>

                            {/* Map Area */}
                            <div className="relative h-[400px] w-full bg-emerald-50 group cursor-default overflow-hidden">
                                {/* Simplified Map Background Grid */}
                                <div
                                    className="absolute inset-0 opacity-20"
                                    style={{
                                        backgroundImage: 'linear-gradient(#10b981 1px, transparent 1px), linear-gradient(90deg, #10b981 1px, transparent 1px)',
                                        backgroundSize: '40px 40px'
                                    }}
                                />

                                {/* Map Roads (CSS Shapes) */}
                                <div className="absolute top-1/2 left-0 w-full h-3 bg-white/60 -translate-y-1/2" />
                                <div className="absolute top-0 left-1/3 w-3 h-full bg-white/60" />
                                <div className="absolute top-1/4 right-1/4 w-32 h-32 border-4 border-white/40 rounded-full" />

                                {/* Geofence Zone (Circle) */}
                                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 size-64 rounded-full bg-emerald-500/5 border-2 border-emerald-500/20 flex items-center justify-center">
                                    <div className="absolute -top-6 left-1/2 -translate-x-1/2 bg-white px-2 py-1 rounded text-[10px] font-bold text-emerald-600 shadow-sm border border-emerald-200 whitespace-nowrap">
                                        Zone: PT. Teknologi Maju
                                    </div>
                                </div>

                                {/* Student Pins (Animated) */}
                                {/* Pin 1 */}
                                <div className="absolute top-[40%] left-[45%] flex flex-col items-center group/pin z-20 hover:z-30 transition-all">
                                    <div className="relative flex items-center justify-center">
                                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-500 opacity-20 delay-100"></span>
                                        <div className="size-3 rounded-full bg-emerald-500 border-2 border-white shadow-sm"></div>
                                    </div>
                                    <div className="absolute bottom-4 opacity-0 group-hover/pin:opacity-100 transition-opacity bg-white p-2 rounded-lg shadow-lg border border-slate-200 flex items-center gap-2 whitespace-nowrap">
                                        <div className="size-6 rounded-full bg-slate-200 flex items-center justify-center text-xs font-bold text-slate-600">BS</div>
                                        <div>
                                            <p className="text-[10px] font-bold text-slate-800">Budi Santoso</p>
                                            <p className="text-[8px] text-emerald-600 font-bold">Check-in: 07:55</p>
                                        </div>
                                    </div>
                                </div>

                                {/* Pin 2 */}
                                <div className="absolute top-[55%] left-[52%] flex flex-col items-center group/pin z-20 hover:z-30 transition-all">
                                    <div className="relative flex items-center justify-center">
                                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-500 opacity-20 delay-300"></span>
                                        <div className="size-3 rounded-full bg-emerald-500 border-2 border-white shadow-sm"></div>
                                    </div>
                                </div>

                                {/* Pin 3 (Warning) */}
                                <div className="absolute top-[20%] right-[20%] flex flex-col items-center group/pin z-20 hover:z-30 transition-all">
                                    <div className="relative flex items-center justify-center">
                                        <span className="animate-pulse absolute inline-flex h-full w-full rounded-full bg-amber-500 opacity-20"></span>
                                        <div className="size-3 rounded-full bg-amber-500 border-2 border-white shadow-sm"></div>
                                    </div>
                                    <div className="absolute bottom-4 opacity-100 bg-white p-2 rounded-lg shadow-lg border border-amber-200 flex items-center gap-2 whitespace-nowrap z-50 animate-bounce">
                                        <span className="text-amber-500 text-sm">⚠</span>
                                        <div>
                                            <p className="text-[10px] font-bold text-slate-800">Siti Aminah</p>
                                            <p className="text-[8px] text-amber-500 font-bold">Diluar Zona</p>
                                        </div>
                                    </div>
                                </div>

                                {/* Sidebar Overlay inside Map */}
                                <div className="absolute top-4 right-4 w-48 bg-white/90 backdrop-blur-sm rounded-xl shadow-lg border border-slate-200 p-3 hidden sm:block">
                                    <h5 className="text-xs font-bold text-slate-800 mb-2 flex justify-between">
                                        Kehadiran Hari Ini
                                        <span className="text-emerald-600">98%</span>
                                    </h5>
                                    <div className="flex flex-col gap-2 max-h-[140px] overflow-y-auto pr-1">
                                        <div className="flex items-center gap-2 p-1.5 rounded-lg bg-green-50 border border-green-100">
                                            <div className="size-2 rounded-full bg-emerald-500"></div>
                                            <div className="flex-1">
                                                <p className="text-[10px] font-bold text-slate-800">Rizky F.</p>
                                                <p className="text-[8px] text-slate-500">SMK A • TKR</p>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-2 p-1.5 rounded-lg bg-green-50 border border-green-100">
                                            <div className="size-2 rounded-full bg-emerald-500"></div>
                                            <div className="flex-1">
                                                <p className="text-[10px] font-bold text-slate-800">Dewi L.</p>
                                                <p className="text-[8px] text-slate-500">SMK B • TKJ</p>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-2 p-1.5 rounded-lg bg-amber-50 border border-amber-100">
                                            <div className="size-2 rounded-full bg-amber-500"></div>
                                            <div className="flex-1">
                                                <p className="text-[10px] font-bold text-slate-800">Ahmad D.</p>
                                                <p className="text-[8px] text-amber-600">Terlambat</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Bottom Stats Bar */}
                            <div className="grid grid-cols-3 divide-x divide-slate-100 bg-white">
                                <div className="p-4 flex flex-col items-center">
                                    <span className="text-xs text-slate-500">Total Siswa</span>
                                    <span className="text-lg font-bold text-slate-800">1,240</span>
                                </div>
                                <div className="p-4 flex flex-col items-center">
                                    <span className="text-xs text-slate-500">Industri Aktif</span>
                                    <span className="text-lg font-bold text-emerald-600">85</span>
                                </div>
                                <div className="p-4 flex flex-col items-center">
                                    <span className="text-xs text-slate-500">Jurnal Masuk</span>
                                    <span className="text-lg font-bold text-slate-800">892</span>
                                </div>
                            </div>
                        </div>
                    </motion.div>
                </div>

                {/* Trust / Logo Wall Section */}
                <div className="w-full max-w-5xl mx-auto mt-20 pt-10 border-t border-slate-200">
                    <p className="text-center text-sm font-bold text-slate-400 uppercase tracking-widest mb-8">
                        Dipercaya oleh 500+ SMK dan Industri
                    </p>
                    <div className="flex flex-wrap justify-center items-center gap-8 lg:gap-16 opacity-60 grayscale hover:grayscale-0 transition-all duration-500">
                        {['AstraTech', 'Telkom School', 'Tokopedia', 'SMK Bisa', 'Disdik Jabar'].map((partner, idx) => (
                            <div key={idx} className="flex items-center gap-2 group cursor-pointer">
                                <div className="size-8 bg-slate-300 rounded-full group-hover:bg-emerald-600 transition-colors" />
                                <span className="text-lg font-bold text-slate-400 group-hover:text-slate-800 transition-colors">{partner}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </section>
    )
}
