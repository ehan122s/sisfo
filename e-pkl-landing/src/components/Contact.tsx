import { motion } from 'framer-motion'
import { Send, MessageCircle, Mail, Phone } from 'lucide-react'

export function Contact() {
    return (
        <section id="contact" className="section">
            <div className="container-custom">
                <div className="grid lg:grid-cols-2 gap-12 items-start">
                    {/* Left - Info */}
                    <motion.div
                        initial={{ opacity: 0, x: -30 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                    >
                        <span className="inline-block px-4 py-2 rounded-full bg-emerald-100 border border-emerald-200 text-emerald-700 text-sm font-medium mb-4">
                            Hubungi Kami
                        </span>
                        <h2 className="text-3xl md:text-4xl font-bold mb-4 text-slate-800">
                            Tertarik? <span className="gradient-text">Mari Berdiskusi</span>
                        </h2>
                        <p className="text-slate-500 mb-8">
                            Kami siap menjawab pertanyaan Anda dan memberikan demo langsung.
                            Silakan isi form atau hubungi kami melalui WhatsApp.
                        </p>

                        {/* Contact Methods */}
                        <div className="space-y-4 mb-8">
                            <a
                                href="https://wa.me/6282318490567?text=Halo,%20saya%20tertarik%20dengan%20platform%20E-PKL"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex items-center gap-4 p-4 glass-card rounded-xl hover:border-green-300 transition-all group"
                            >
                                <div className="w-12 h-12 rounded-lg bg-green-100 flex items-center justify-center">
                                    <MessageCircle className="w-6 h-6 text-green-600" />
                                </div>
                                <div>
                                    <div className="font-medium group-hover:text-emerald-600 transition-colors text-slate-800">
                                        WhatsApp
                                    </div>
                                    <div className="text-slate-500 text-sm">+62 823-1849-0567</div>
                                </div>
                            </a>
                            <div className="flex items-center gap-4 p-4 glass-card rounded-xl">
                                <div className="w-12 h-12 rounded-lg bg-blue-100 flex items-center justify-center">
                                    <Mail className="w-6 h-6 text-blue-600" />
                                </div>
                                <div>
                                    <div className="font-medium text-slate-800">Email</div>
                                    <div className="text-slate-500 text-sm">epkl.support@gmail.com</div>
                                </div>
                            </div>
                            <div className="flex items-center gap-4 p-4 glass-card rounded-xl">
                                <div className="w-12 h-12 rounded-lg bg-purple-100 flex items-center justify-center">
                                    <Phone className="w-6 h-6 text-purple-600" />
                                </div>
                                <div>
                                    <div className="font-medium text-slate-800">Telepon</div>
                                    <div className="text-slate-500 text-sm">+62 823-1849-0567</div>
                                </div>
                            </div>
                        </div>
                    </motion.div>

                    {/* Right - Form */}
                    <motion.div
                        initial={{ opacity: 0, x: 30 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        className="glass-card rounded-2xl p-8"
                    >
                        <h3 className="text-xl font-semibold mb-6 text-slate-800">Kirim Pesan</h3>
                        <form className="space-y-4">
                            <div>
                                <label className="block text-sm text-slate-500 mb-2">
                                    Nama Lengkap
                                </label>
                                <input
                                    type="text"
                                    placeholder="Nama Anda"
                                    className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:border-emerald-500 focus:outline-none transition-colors text-slate-800 placeholder-slate-400"
                                />
                            </div>
                            <div>
                                <label className="block text-sm text-slate-500 mb-2">
                                    Nama Sekolah
                                </label>
                                <input
                                    type="text"
                                    placeholder="SMK Contoh"
                                    className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:border-emerald-500 focus:outline-none transition-colors text-slate-800 placeholder-slate-400"
                                />
                            </div>
                            <div className="grid sm:grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm text-slate-500 mb-2">
                                        Email
                                    </label>
                                    <input
                                        type="email"
                                        placeholder="email@sekolah.sch.id"
                                        className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:border-emerald-500 focus:outline-none transition-colors text-slate-800 placeholder-slate-400"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm text-slate-500 mb-2">
                                        No. WhatsApp
                                    </label>
                                    <input
                                        type="tel"
                                        placeholder="08123456789"
                                        className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:border-emerald-500 focus:outline-none transition-colors text-slate-800 placeholder-slate-400"
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm text-slate-500 mb-2">
                                    Pesan (Opsional)
                                </label>
                                <textarea
                                    rows={4}
                                    placeholder="Ceritakan kebutuhan Anda..."
                                    className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:border-emerald-500 focus:outline-none transition-colors resize-none text-slate-800 placeholder-slate-400"
                                />
                            </div>
                            <button
                                type="submit"
                                className="w-full btn-gradient py-4 rounded-xl font-semibold inline-flex items-center justify-center gap-2"
                            >
                                <Send className="w-5 h-5" />
                                Kirim Pesan
                            </button>
                        </form>
                    </motion.div>
                </div>
            </div>
        </section>
    )
}
