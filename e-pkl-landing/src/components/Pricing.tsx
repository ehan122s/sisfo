import { motion } from 'framer-motion'
import { Check, Sparkles, Building2, Crown, MessageCircle } from 'lucide-react'

const WA_NUMBER = '6281382767491'
const createWaLink = (planName: string) => {
    const text = encodeURIComponent(`Halo, saya tertarik dengan paket ${planName} E-PKL`)
    return `https://wa.me/${WA_NUMBER}?text=${text}`
}

const plans = [
    {
        name: 'Starter',
        icon: Sparkles,
        period: '/tahun',
        description: 'Cocok untuk sekolah kecil atau uji coba awal',
        features: [
            'Maksimal 100 siswa PKL',
            '5 akun guru pembimbing',
            'Aplikasi Android siswa',
            'Dashboard admin web',
            'Support email',
        ],
        popular: false,
        buttonText: 'Hubungi via WhatsApp',
    },
    {
        name: 'Professional',
        icon: Building2,
        period: '/tahun',
        description: 'Paling populer untuk SMK menengah',
        features: [
            'Maksimal 300 siswa PKL',
            'Unlimited guru pembimbing',
            'Aplikasi Android siswa',
            'Dashboard admin web',
            'Export laporan Excel & PDF',
            'Priority support WhatsApp',
            'Training online 2 sesi',
        ],
        popular: true,
        buttonText: 'Hubungi via WhatsApp',
    },
    {
        name: 'Enterprise',
        icon: Crown,
        period: '',
        description: 'Untuk sekolah besar atau multi-cabang',
        features: [
            'Unlimited siswa PKL',
            'Unlimited guru pembimbing',
            'Semua fitur Professional',
            'Custom branding logo',
            'Dedicated server (opsional)',
            'On-site training',
            'SLA 99.9% uptime',
        ],
        popular: false,
        buttonText: 'Hubungi via WhatsApp',
    },
]

export function Pricing() {
    return (
        <section id="pricing" className="section">
            <div className="container-custom">
                {/* Section Header */}
                <div className="text-center max-w-2xl mx-auto mb-16">
                    <span className="inline-block px-4 py-2 rounded-full bg-emerald-100 border border-emerald-200 text-emerald-700 text-sm font-medium mb-4">
                        Penawaran Spesial
                    </span>
                    <h2 className="text-3xl md:text-4xl font-bold mb-4 text-slate-800">
                        Pilih Paket yang{' '}
                        <span className="gradient-text">Sesuai Kebutuhan</span>
                    </h2>
                    <p className="text-slate-500">
                        Diskusikan kebutuhan sekolah Anda dengan tim kami untuk mendapatkan penawaran terbaik.
                    </p>
                </div>

                {/* Pricing Cards */}
                <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
                    {plans.map((plan, index) => (
                        <motion.div
                            key={plan.name}
                            initial={{ opacity: 0, y: 30 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            transition={{ delay: index * 0.1 }}
                            viewport={{ once: true }}
                            className={`glass-card rounded-2xl p-8 relative flex flex-col ${plan.popular
                                    ? 'border-emerald-400 scale-105 z-10 shadow-xl shadow-emerald-100'
                                    : 'border-slate-200'
                                }`}
                        >
                            {plan.popular && (
                                <div className="absolute -top-4 left-1/2 -translate-x-1/2 px-4 py-1 rounded-full bg-gradient-to-r from-emerald-500 to-cyan-500 text-sm font-medium text-white shadow-lg">
                                    Paling Populer
                                </div>
                            )}

                            <div className="flex items-center gap-3 mb-6">
                                <div
                                    className={`w-12 h-12 rounded-xl flex items-center justify-center ${plan.popular
                                            ? 'bg-gradient-to-br from-emerald-500 to-cyan-500'
                                            : 'bg-slate-100'
                                        }`}
                                >
                                    <plan.icon className={`w-6 h-6 ${plan.popular ? 'text-white' : 'text-slate-600'}`} />
                                </div>
                                <div>
                                    <h3 className="text-xl font-bold text-slate-800">{plan.name}</h3>
                                    <div className="text-xs text-slate-500">Paket Sekolah</div>
                                </div>
                            </div>

                            {/* Removed Price Display */}

                            <p className="text-slate-500 text-sm mb-6 min-h-[40px]">{plan.description}</p>

                            <div className="flex-grow">
                                <ul className="space-y-3 mb-8">
                                    {plan.features.map((feature) => (
                                        <li key={feature} className="flex items-start gap-2 text-sm text-slate-600">
                                            <Check className="w-5 h-5 text-emerald-500 shrink-0 mt-0.5" />
                                            <span>{feature}</span>
                                        </li>
                                    ))}
                                </ul>
                            </div>

                            <a
                                href={createWaLink(plan.name)}
                                target="_blank"
                                rel="noopener noreferrer"
                                className={`block text-center py-3 rounded-xl font-semibold transition-all flex items-center justify-center gap-2 ${plan.popular
                                        ? 'btn-gradient shadow-lg shadow-emerald-200'
                                        : 'bg-slate-800 text-white hover:bg-slate-700'
                                    }`}
                            >
                                <MessageCircle className="w-4 h-4" />
                                {plan.buttonText}
                            </a>
                        </motion.div>
                    ))}
                </div>
            </div>
        </section>
    )
}
