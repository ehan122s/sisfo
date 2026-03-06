import { useState, useEffect } from 'react'
import { Menu, X, Lock } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'

const navLinks = [
    { name: 'Fitur', href: '#features' },
    { name: 'Keuntungan', href: '#benefits' },
    { name: 'Harga', href: '#pricing' },
    { name: 'FAQ', href: '#faq' },
]

export function Navbar() {
    const [isOpen, setIsOpen] = useState(false)
    const [isScrolled, setIsScrolled] = useState(false)

    useEffect(() => {
        const handleScroll = () => {
            setIsScrolled(window.scrollY > 50)
        }
        window.addEventListener('scroll', handleScroll)
        return () => window.removeEventListener('scroll', handleScroll)
    }, [])

    return (
        <nav
            className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${isScrolled
                    ? 'bg-white/90 backdrop-blur-lg border-b border-slate-200 shadow-sm'
                    : 'bg-transparent'
                }`}
        >
            <div className="container-custom">
                <div className="flex items-center justify-between h-16">
                    {/* Logo */}
                    <a href="#" className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-cyan-500 flex items-center justify-center">
                            <Lock className="w-4 h-4 text-white" />
                        </div>
                        <span className="font-bold text-lg text-slate-800">E-PKL</span>
                    </a>

                    {/* Desktop Nav */}
                    <div className="hidden md:flex items-center gap-8">
                        {navLinks.map((link) => (
                            <a
                                key={link.name}
                                href={link.href}
                                className="text-sm text-slate-600 hover:text-emerald-600 transition-colors"
                            >
                                {link.name}
                            </a>
                        ))}
                        <a
                            href="#contact"
                            className="btn-gradient px-5 py-2 rounded-lg text-sm font-medium"
                        >
                            Hubungi Kami
                        </a>
                    </div>

                    {/* Mobile Menu Button */}
                    <button
                        onClick={() => setIsOpen(!isOpen)}
                        className="md:hidden p-2 text-slate-700"
                    >
                        {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
                    </button>
                </div>

                {/* Mobile Nav */}
                <AnimatePresence>
                    {isOpen && (
                        <motion.div
                            initial={{ opacity: 0, height: 0 }}
                            animate={{ opacity: 1, height: 'auto' }}
                            exit={{ opacity: 0, height: 0 }}
                            className="md:hidden overflow-hidden bg-white"
                        >
                            <div className="py-4 space-y-4">
                                {navLinks.map((link) => (
                                    <a
                                        key={link.name}
                                        href={link.href}
                                        onClick={() => setIsOpen(false)}
                                        className="block text-slate-600 hover:text-emerald-600 transition-colors"
                                    >
                                        {link.name}
                                    </a>
                                ))}
                                <a
                                    href="#contact"
                                    onClick={() => setIsOpen(false)}
                                    className="block btn-gradient px-5 py-2 rounded-lg text-sm font-medium text-center"
                                >
                                    Hubungi Kami
                                </a>
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>
            </div>
        </nav>
    )
}
