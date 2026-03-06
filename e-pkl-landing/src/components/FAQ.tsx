import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronDown } from 'lucide-react'

const faqs = [
    {
        question: 'Apakah data siswa aman?',
        answer:
            'Ya, sangat aman. Kami menggunakan Supabase (powered by PostgreSQL) dengan enkripsi end-to-end, Row Level Security, dan backup otomatis harian. Server berlokasi di Singapura untuk latensi rendah di Indonesia.',
    },
    {
        question: 'Bagaimana proses implementasi di sekolah kami?',
        answer:
            'Proses implementasi sangat mudah: 1) Kami setup akun admin sekolah, 2) Import data siswa via Excel, 3) Training online 1-2 jam untuk admin, 4) Siswa download aplikasi dan login. Total waktu: 1-3 hari kerja.',
    },
    {
        question: 'Apakah bisa custom logo dan nama sekolah?',
        answer:
            'Untuk paket Enterprise, kami menyediakan custom branding termasuk logo sekolah, nama aplikasi, dan warna tema. Untuk paket Starter dan Professional, branding menggunakan template standar E-PKL.',
    },
    {
        question: 'Bagaimana jika ada kendala teknis?',
        answer:
            'Tim support kami siap membantu via WhatsApp di jam kerja (08.00-17.00 WIB). Untuk paket Professional ke atas, Anda mendapat priority support dengan response time maksimal 2 jam.',
    },
    {
        question: 'Apakah bisa diakses offline?',
        answer:
            'Aplikasi siswa memiliki mode offline untuk mencatat jurnal. Data akan otomatis sync ke server saat koneksi internet tersedia. Absensi tetap memerlukan koneksi untuk validasi GPS.',
    },
    {
        question: 'Bagaimana sistem pembayarannya?',
        answer:
            'Pembayaran dilakukan per tahun ajaran di awal. Kami menerima transfer bank dan bisa menyesuaikan dengan mekanisme keuangan sekolah (SPP atau dana BOS jika memenuhi syarat).',
    },
]

export function FAQ() {
    const [openIndex, setOpenIndex] = useState<number | null>(0)

    return (
        <section id="faq" className="section bg-slate-50">
            <div className="container-custom max-w-3xl">
                {/* Section Header */}
                <div className="text-center mb-12">
                    <span className="inline-block px-4 py-2 rounded-full bg-emerald-100 border border-emerald-200 text-emerald-700 text-sm font-medium mb-4">
                        FAQ
                    </span>
                    <h2 className="text-3xl md:text-4xl font-bold mb-4 text-slate-800">
                        Pertanyaan yang <span className="gradient-text">Sering Diajukan</span>
                    </h2>
                </div>

                {/* FAQ Accordion */}
                <div className="space-y-4">
                    {faqs.map((faq, index) => (
                        <motion.div
                            key={index}
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            transition={{ delay: index * 0.05 }}
                            viewport={{ once: true }}
                            className="glass-card rounded-xl overflow-hidden"
                        >
                            <button
                                onClick={() => setOpenIndex(openIndex === index ? null : index)}
                                className="w-full px-6 py-4 flex items-center justify-between text-left"
                            >
                                <span className="font-medium pr-4 text-slate-800">{faq.question}</span>
                                <ChevronDown
                                    className={`w-5 h-5 text-slate-400 shrink-0 transition-transform ${openIndex === index ? 'rotate-180' : ''
                                        }`}
                                />
                            </button>
                            <AnimatePresence>
                                {openIndex === index && (
                                    <motion.div
                                        initial={{ height: 0, opacity: 0 }}
                                        animate={{ height: 'auto', opacity: 1 }}
                                        exit={{ height: 0, opacity: 0 }}
                                        transition={{ duration: 0.2 }}
                                        className="overflow-hidden"
                                    >
                                        <div className="px-6 pb-4 text-slate-500 text-sm leading-relaxed">
                                            {faq.answer}
                                        </div>
                                    </motion.div>
                                )}
                            </AnimatePresence>
                        </motion.div>
                    ))}
                </div>
            </div>
        </section>
    )
}
