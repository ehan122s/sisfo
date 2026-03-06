import { motion } from 'framer-motion'
import { CheckCircle2, Clock, Shield, Smartphone, Cloud, Headphones } from 'lucide-react'

const benefits = [
    {
        icon: Clock,
        title: 'Hemat Waktu 80%',
        description: 'Tidak perlu lagi rekap manual jurnal dan absensi di akhir bulan.',
    },
    {
        icon: Shield,
        title: 'Anti Titip Absen',
        description: 'Teknologi GPS Geofencing memastikan siswa benar-benar di lokasi.',
    },
    {
        icon: Cloud,
        title: 'Akses dari Mana Saja',
        description: 'Cloud-based, bisa diakses kapan saja dan dari perangkat apapun.',
    },
    {
        icon: Smartphone,
        title: 'Mudah Digunakan',
        description: 'Interface modern dan intuitif, tidak perlu training khusus.',
    },
    {
        icon: CheckCircle2,
        title: 'Data Akurat',
        description: 'Validasi otomatis menghilangkan human error dalam pencatatan.',
    },
    {
        icon: Headphones,
        title: 'Support Responsif',
        description: 'Tim support siap membantu via WhatsApp di jam kerja.',
    },
]

export function Benefits() {
    return (
        <section id="benefits" className="section bg-slate-50">
            <div className="container-custom">
                <div className="grid lg:grid-cols-2 gap-16 items-center">
                    {/* Left - Image/Visual */}
                    <motion.div
                        initial={{ opacity: 0, x: -30 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        className="relative"
                    >
                        <div className="glass-card rounded-3xl p-8">
                            <div className="bg-gradient-to-br from-emerald-100 to-cyan-100 rounded-2xl aspect-square flex items-center justify-center">
                                <div className="text-center">
                                    <div className="text-6xl font-bold gradient-text mb-4">80%</div>
                                    <p className="text-slate-700 text-xl font-medium">Lebih Efisien</p>
                                    <p className="text-slate-500 text-sm mt-2">
                                        Dibanding rekap manual tradisional
                                    </p>
                                </div>
                            </div>
                        </div>
                        {/* Decorative */}
                        <div className="absolute -bottom-4 -right-4 w-32 h-32 bg-emerald-200/50 rounded-full blur-2xl" />
                    </motion.div>

                    {/* Right - Benefits List */}
                    <div>
                        <span className="inline-block px-4 py-2 rounded-full bg-emerald-100 border border-emerald-200 text-emerald-700 text-sm font-medium mb-4">
                            Mengapa E-PKL?
                        </span>
                        <h2 className="text-3xl md:text-4xl font-bold mb-8 text-slate-800">
                            Keuntungan Menggunakan{' '}
                            <span className="gradient-text">Platform Kami</span>
                        </h2>

                        <div className="grid sm:grid-cols-2 gap-6">
                            {benefits.map((benefit, index) => (
                                <motion.div
                                    key={benefit.title}
                                    initial={{ opacity: 0, y: 20 }}
                                    whileInView={{ opacity: 1, y: 0 }}
                                    transition={{ delay: index * 0.1 }}
                                    viewport={{ once: true }}
                                    className="flex gap-4"
                                >
                                    <div className="w-10 h-10 rounded-lg bg-emerald-100 flex items-center justify-center shrink-0">
                                        <benefit.icon className="w-5 h-5 text-emerald-600" />
                                    </div>
                                    <div>
                                        <h3 className="font-semibold mb-1 text-slate-800">{benefit.title}</h3>
                                        <p className="text-slate-500 text-sm">{benefit.description}</p>
                                    </div>
                                </motion.div>
                            ))}
                        </div>
                    </div>
                </div>
            </div>
        </section>
    )
}
