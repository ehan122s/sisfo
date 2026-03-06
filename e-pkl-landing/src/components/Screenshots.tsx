import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Smartphone, Monitor, ChevronRight, ChevronLeft } from 'lucide-react'

// Real image paths from public/screenshoot directory
const screenshots = {
    mobile: [
        {
            id: 1,
            title: 'Absensi Mudah',
            desc: 'Cukup satu klik untuk absen masuk dan pulang',
            image: '/screenshoot/Halaman Absen Masuk.jpg',
        },
        {
            id: 2,
            title: 'Validasi Lokasi',
            desc: 'Sistem Geofencing memastikan siswa berada di lokasi PKL',
            image: '/screenshoot/Halaman Geofacing.jpg',
        },
        {
            id: 3,
            title: 'Jurnal Harian',
            desc: 'Isi kegiatan harian dengan mudah beserta foto bukti',
            image: '/screenshoot/Jurnal harian.jpg',
        },
        {
            id: 4,
            title: 'Tambah Jurnal',
            desc: 'Form input jurnal dengan fitur upload foto kegiatan',
            image: '/screenshoot/Tambah Jurnal harian.jpg',
        },
        {
            id: 5,
            title: 'Riwayat Kehadiran',
            desc: 'Pantau rekap kehadiran bulanan secara transparan',
            image: '/screenshoot/Riwayat Kehadiran.jpg',
        }
    ],
    web: [
        {
            id: 1,
            title: 'Dashboard Utama',
            desc: 'Overview statistik siswa dan kehadiran real-time',
            image: '/screenshoot/web admin dashboard 1.png',
        },
        {
            id: 2,
            title: 'Statistik Detail',
            desc: 'Visualisasi data kehadiran dengan chart interaktif',
            image: '/screenshoot/web admin dashboard 2.png',
        },
        {
            id: 3,
            title: 'Live Monitoring',
            desc: 'Pantau sebaran lokasi siswa di peta secara langsung',
            image: '/screenshoot/web admin dashboard - Peta sebaran PKL live monitoring.png',
        },
        {
            id: 4,
            title: 'Laporan Bulanan',
            desc: 'Rekap absensi bulanan otomatis siap cetak',
            image: '/screenshoot/web admin laporan absensi bulanan.png',
        }
    ]
}

export function Screenshots() {
    const [activeTab, setActiveTab] = useState<'mobile' | 'web'>('mobile')
    const [currentIndex, setCurrentIndex] = useState(0)

    const items = screenshots[activeTab]

    const nextSlide = () => {
        setCurrentIndex((prev) => (prev + 1) % items.length)
    }

    const prevSlide = () => {
        setCurrentIndex((prev) => (prev - 1 + items.length) % items.length)
    }

    return (
        <section id="screenshots" className="section bg-slate-50 overflow-hidden">
            <div className="container-custom">
                {/* Header */}
                <div className="text-center max-w-3xl mx-auto mb-12">
                    <span className="inline-block px-4 py-2 rounded-full bg-emerald-100 border border-emerald-200 text-emerald-700 text-sm font-medium mb-4">
                        Galeri Aplikasi
                    </span>
                    <h2 className="text-3xl md:text-4xl font-bold mb-4 text-slate-800">
                        Tampilan <span className="gradient-text">E-PKL</span> di Berbagai Platform
                    </h2>
                    <p className="text-slate-500">
                        Desain antarmuka yang intuitif dan mudah digunakan, baik di smartphone maupun desktop.
                    </p>
                </div>

                {/* Tabs */}
                <div className="flex justify-center gap-4 mb-12">
                    <button
                        onClick={() => { setActiveTab('mobile'); setCurrentIndex(0); }}
                        className={`flex items-center gap-2 px-6 py-3 rounded-full font-medium transition-all ${activeTab === 'mobile'
                            ? 'bg-emerald-600 text-white shadow-lg shadow-emerald-200'
                            : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
                            }`}
                    >
                        <Smartphone className="w-5 h-5" />
                        Aplikasi Android
                    </button>
                    <button
                        onClick={() => { setActiveTab('web'); setCurrentIndex(0); }}
                        className={`flex items-center gap-2 px-6 py-3 rounded-full font-medium transition-all ${activeTab === 'web'
                            ? 'bg-emerald-600 text-white shadow-lg shadow-emerald-200'
                            : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
                            }`}
                    >
                        <Monitor className="w-5 h-5" />
                        Admin Web
                    </button>
                </div>

                {/* Showcase Area */}
                <div className="relative max-w-5xl mx-auto">
                    {/* Navigation Buttons */}
                    <button
                        onClick={prevSlide}
                        className="absolute left-0 top-1/2 -translate-y-1/2 -translate-x-4 md:-translate-x-12 z-10 w-10 h-10 rounded-full bg-white shadow-lg border border-slate-100 flex items-center justify-center hover:scale-110 transition-transform text-slate-700"
                    >
                        <ChevronLeft className="w-6 h-6" />
                    </button>
                    <button
                        onClick={nextSlide}
                        className="absolute right-0 top-1/2 -translate-y-1/2 translate-x-4 md:translate-x-12 z-10 w-10 h-10 rounded-full bg-white shadow-lg border border-slate-100 flex items-center justify-center hover:scale-110 transition-transform text-slate-700"
                    >
                        <ChevronRight className="w-6 h-6" />
                    </button>

                    {/* Slider */}
                    <div className="overflow-hidden py-4 px-4">
                        <motion.div
                            key={activeTab} // Reset animation when tab changes
                            className="flex justify-center"
                        >
                            <div className="relative">
                                {/* Mockup Frame based on device type */}
                                {activeTab === 'mobile' ? (
                                    // Mobile Mockup
                                    <div className="flex flex-col items-center">
                                        <motion.div
                                            initial={{ opacity: 0, scale: 0.9 }}
                                            animate={{ opacity: 1, scale: 1 }}
                                            transition={{ duration: 0.5 }}
                                            className="w-[280px] md:w-[320px] h-[580px] md:h-[650px] bg-slate-900 rounded-[3rem] border-8 border-slate-900 shadow-2xl relative overflow-hidden"
                                        >
                                            {/* Notch */}
                                            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-slate-900 rounded-b-xl z-20"></div>

                                            {/* Content */}
                                            <AnimatePresence mode="wait">
                                                <motion.div
                                                    key={currentIndex}
                                                    initial={{ opacity: 0, x: 100 }}
                                                    animate={{ opacity: 1, x: 0 }}
                                                    exit={{ opacity: 0, x: -100 }}
                                                    transition={{ duration: 0.3 }}
                                                    className="w-full h-full relative bg-slate-100"
                                                >
                                                    <img
                                                        src={items[currentIndex].image}
                                                        alt={items[currentIndex].title}
                                                        className="w-full h-full object-cover"
                                                    />
                                                </motion.div>
                                            </AnimatePresence>
                                        </motion.div>

                                        {/* Description Outside */}
                                        <AnimatePresence mode="wait">
                                            <motion.div
                                                key={currentIndex}
                                                initial={{ opacity: 0, y: 20 }}
                                                animate={{ opacity: 1, y: 0 }}
                                                exit={{ opacity: 0, y: -20 }}
                                                transition={{ duration: 0.3 }}
                                                className="mt-8 text-center max-w-md"
                                            >
                                                <h3 className="text-2xl font-bold text-slate-800 mb-2">{items[currentIndex].title}</h3>
                                                <p className="text-slate-600">{items[currentIndex].desc}</p>
                                            </motion.div>
                                        </AnimatePresence>
                                    </div>
                                ) : (
                                    // Laptop/Web Mockup
                                    <motion.div
                                        initial={{ opacity: 0, scale: 0.95 }}
                                        animate={{ opacity: 1, scale: 1 }}
                                        transition={{ duration: 0.5 }}
                                        className="w-[90vw] max-w-[800px] aspect-[16/9] bg-slate-900 rounded-xl shadow-2xl relative border-b-[20px] border-slate-800"
                                    >
                                        {/* Browser Header */}
                                        <div className="h-8 bg-slate-800 rounded-t-xl flex items-center px-4 gap-2">
                                            <div className="w-3 h-3 rounded-full bg-red-400"></div>
                                            <div className="w-3 h-3 rounded-full bg-amber-400"></div>
                                            <div className="w-3 h-3 rounded-full bg-green-400"></div>
                                        </div>

                                        {/* Content */}
                                        <div className="w-full h-[calc(100%-2rem)] bg-white overflow-hidden relative group">
                                            <AnimatePresence mode="wait">
                                                <motion.div
                                                    key={currentIndex}
                                                    initial={{ opacity: 0 }}
                                                    animate={{ opacity: 1 }}
                                                    exit={{ opacity: 0 }}
                                                    transition={{ duration: 0.3 }}
                                                    className="w-full h-full relative"
                                                >
                                                    <img
                                                        src={items[currentIndex].image}
                                                        alt={items[currentIndex].title}
                                                        className="w-full h-full object-cover object-top"
                                                    />

                                                    {/* Overlay Info */}
                                                    <div className="absolute bottom-0 left-0 right-0 bg-black/70 backdrop-blur-sm p-4 text-white translate-y-full group-hover:translate-y-0 transition-transform duration-300">
                                                        <h3 className="text-xl font-bold mb-1">{items[currentIndex].title}</h3>
                                                        <p className="text-white/80">{items[currentIndex].desc}</p>
                                                    </div>
                                                </motion.div>
                                            </AnimatePresence>
                                        </div>
                                    </motion.div>
                                )}
                            </div>
                        </motion.div>
                    </div>

                    {/* Dots Indicator */}
                    <div className="flex justify-center gap-2 mt-8">
                        {items.map((_, idx) => (
                            <button
                                key={idx}
                                onClick={() => setCurrentIndex(idx)}
                                className={`w-2.5 h-2.5 rounded-full transition-all ${currentIndex === idx ? 'bg-emerald-500 w-8' : 'bg-slate-300'
                                    }`}
                            />
                        ))}
                    </div>
                </div>
            </div>
        </section>
    )
}
