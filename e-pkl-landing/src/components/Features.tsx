import { motion } from 'framer-motion'
import {
    MapPin,
    BookOpen,
    BarChart3,
    Users,
    Eye,
    FileSpreadsheet,
} from 'lucide-react'

const features = [
    {
        icon: MapPin,
        title: 'Absensi Geofencing',
        description:
            'Siswa hanya bisa absen dalam radius lokasi DUDI. Anti titip absen dengan validasi GPS.',
        color: 'from-emerald-500 to-green-500',
    },
    {
        icon: BookOpen,
        title: 'Jurnal Digital',
        description:
            'Submit jurnal harian dengan foto bukti kegiatan langsung dari smartphone.',
        color: 'from-cyan-500 to-blue-500',
    },
    {
        icon: BarChart3,
        title: 'Dashboard Real-time',
        description:
            'Statistik kehadiran, distribusi siswa, dan visualisasi data yang informatif.',
        color: 'from-purple-500 to-pink-500',
    },
    {
        icon: Users,
        title: 'Multi-Role Access',
        description:
            'Akun terpisah untuk Siswa, Guru Pembimbing, dan Admin sekolah dengan hak akses berbeda.',
        color: 'from-orange-500 to-red-500',
    },
    {
        icon: Eye,
        title: 'Monitoring Live',
        description:
            'Pantau status kehadiran siswa secara real-time. Notifikasi jika ada ketidakhadiran.',
        color: 'from-teal-500 to-emerald-500',
    },
    {
        icon: FileSpreadsheet,
        title: 'Export Laporan',
        description:
            'Rekap bulanan dalam format Excel & PDF, siap cetak untuk dokumentasi sekolah.',
        color: 'from-indigo-500 to-purple-500',
    },
]

const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
        opacity: 1,
        transition: {
            staggerChildren: 0.1,
        },
    },
}

const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { opacity: 1, y: 0 },
}

export function Features() {
    return (
        <section id="features" className="section">
            <div className="container-custom">
                {/* Section Header */}
                <div className="text-center max-w-2xl mx-auto mb-16">
                    <span className="inline-block px-4 py-2 rounded-full bg-emerald-100 border border-emerald-200 text-emerald-700 text-sm font-medium mb-4">
                        Fitur Unggulan
                    </span>
                    <h2 className="text-3xl md:text-4xl font-bold mb-4 text-slate-800">
                        Semua yang Anda Butuhkan dalam{' '}
                        <span className="gradient-text">Satu Platform</span>
                    </h2>
                    <p className="text-slate-500">
                        Solusi lengkap untuk manajemen Prakerin/PKL yang efisien, modern,
                        dan mudah digunakan.
                    </p>
                </div>

                {/* Features Grid */}
                <motion.div
                    className="grid md:grid-cols-2 lg:grid-cols-3 gap-6"
                    variants={containerVariants}
                    initial="hidden"
                    whileInView="visible"
                    viewport={{ once: true, margin: '-100px' }}
                >
                    {features.map((feature) => (
                        <motion.div
                            key={feature.title}
                            className="glass-card rounded-2xl p-6 hover:border-emerald-300 transition-all duration-300 group"
                            variants={itemVariants}
                        >
                            <div
                                className={`w-12 h-12 rounded-xl bg-gradient-to-br ${feature.color} flex items-center justify-center mb-4 group-hover:scale-110 transition-transform shadow-lg`}
                            >
                                <feature.icon className="w-6 h-6 text-white" />
                            </div>
                            <h3 className="text-xl font-semibold mb-2 text-slate-800">{feature.title}</h3>
                            <p className="text-slate-500 text-sm leading-relaxed">
                                {feature.description}
                            </p>
                        </motion.div>
                    ))}
                </motion.div>
            </div>
        </section>
    )
}
