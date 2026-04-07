import * as React from "react"
import { useQuery } from "@tanstack/react-query"
import { format, getDaysInMonth } from "date-fns"
import { id } from "date-fns/locale"
import { Printer, Loader2, FileDown, ArrowLeft, Info } from "lucide-react"
import { useParams, useNavigate } from "react-router-dom"
import { supabase } from "@/lib/supabase"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { type Student } from "@/types"
import { toast } from "sonner"
import { getHomeroomByClass } from "@/features/homeroom/services/homeroom-service"

// Standard Hex Colors for reporting
const COLORS = {
    white: '#ffffff',
    black: '#000000',
    gray50: '#f9fafb',
    gray100: '#f3f4f6',
    gray200: '#e5e7eb',
    gray300: '#d1d5db',
    gray400: '#9ca3af',
    gray500: '#6b7280',
    gray600: '#4b5563',
    green50: '#f0fdf4',
    green100: '#dcfce7',
    green600: '#16a34a',
    green700: '#15803d',
    green800: '#166534',
    green900: '#14532d',
    green950: '#052e16',
    yellow50: '#fefce8',
    yellow100: '#fef9c3',
    yellow600: '#ca8a04',
    yellow700: '#a16207',
    yellow800: '#854d0e',
    yellow900: '#713f12',
    yellow950: '#422006',
    blue50: '#eff6ff',
    blue100: '#dbeafe',
    blue600: '#2563eb',
    blue700: '#1d4ed8',
    blue800: '#1e40af',
    blue900: '#1e3a8a',
    blue950: '#172554',
    red50: '#fef2f2',
    red100: '#fee2e2',
    red600: '#dc2626',
    red700: '#b91c1c',
    red800: '#991b1b',
    red900: '#7f1d1d',
    red950: '#450a0a',
}

export function StudentReportPage() {
    const { studentId, year: yearParam } = useParams()
    const navigate = useNavigate()
    const year = parseInt(yearParam || new Date().getFullYear().toString())
    const [isExporting, setIsExporting] = React.useState(false)
    const reportRef = React.useRef<HTMLDivElement>(null)

    // Fetch Student Info
    const { data: student, isLoading: isLoadingStudent } = useQuery({
        queryKey: ['student', studentId],
        queryFn: async () => {
            if (!studentId) return null
            const { data, error } = await supabase
                .from('profiles')
                .select('*, placements(companies(name))')
                .eq('id', studentId)
                .single()
            if (error) throw error
            return data as Student
        }
    })

    // Fetch wali kelas dari tabel class_homeroom_teachers
    const { data: homeroomData } = useQuery({
        queryKey: ['homeroom-by-class', student?.class_name],
        queryFn: () => student?.class_name ? getHomeroomByClass(student.class_name) : null,
        enabled: Boolean(student?.class_name),
        staleTime: 1000 * 60 * 5,
    })

    // Fetch Yearly Logs
    const { data: logs = [], isLoading: isLoadingLogs } = useQuery({
        queryKey: ['yearly-attendance', studentId, year],
        queryFn: async () => {
            if (!studentId) return []
            const start = new Date(year, 0, 1).toISOString()
            const end = new Date(year, 11, 31, 23, 59, 59).toISOString()
            const { data, error } = await supabase
                .from('attendance_logs')
                .select('id, status, created_at')
                .eq('student_id', studentId)
                .gte('created_at', start)
                .lte('created_at', end)
                .order('created_at', { ascending: false })
            if (error) throw error
            return data
        }
    })

    const months = Array.from({ length: 12 }, (_, i) => i)
    const days = Array.from({ length: 31 }, (_, i) => i + 1)

    // Returns true if the given date (month 0-11, day 1-31) is Saturday or Sunday
    // new Date(year, m, d).getDay() is always accurate per the JS calendar
    const isWeekendDate = (m: number, d: number): boolean => {
        const dow = new Date(year, m, d).getDay()
        return dow === 0 || dow === 6  // 0=Sunday, 6=Saturday
    }

    const attendanceMatrix = React.useMemo(() => {
        const matrix: Record<string, string> = {}
        const priority: Record<string, number> = { "-": 0, A: 1, I: 2, S: 2, H: 3 }
        logs.forEach(log => {
            const date = new Date(log.created_at)
            if (Number.isNaN(date.getTime())) return
            const m = date.getMonth()
            const d = date.getDate()
            const key = `${m}-${d}`
            
            let code = '-'
            const status = log.status?.trim().toLowerCase()
            if (status === 'hadir' || status === 'terlambat' || status === 'telat' || status === 'present' || status === 'late') code = 'H'
            else if (status === 'sakit') code = 'S'
            else if (status === 'izin' || status === 'permission') code = 'I'
            else if (status === 'alpa' || status === 'belum hadir' || status === 'alpha' || status === 'absent') code = 'A'

            const current = matrix[key] || "-"
            if (priority[code] > priority[current]) {
                matrix[key] = code
            }
        })
        return matrix
    }, [logs])

    const recap = React.useMemo(() => {
        const totals = { H: 0, S: 0, I: 0, A: 0 }
        Object.values(attendanceMatrix).forEach(code => {
            if (code === 'H') totals.H++
            else if (code === 'S') totals.S++
            else if (code === 'I') totals.I++
            else if (code === 'A') totals.A++
        })
        return totals
    }, [attendanceMatrix])

    const handlePrint = () => {
        window.print()
    }

    const handleDownloadPDF = async () => {
        if (!reportRef.current) return
        setIsExporting(true)
        try {
            const [{ default: html2canvas }, { default: jsPDF }] = await Promise.all([
                import("html2canvas"),
                import("jspdf"),
            ])
            const canvas = await html2canvas(reportRef.current, {
                scale: 2,
                useCORS: true,
                logging: false,
                backgroundColor: COLORS.white,
                width: 1122,
                height: 794,
            })
            const imgData = canvas.toDataURL('image/png', 1.0)
            const pdf = new jsPDF({
                orientation: 'landscape',
                unit: 'mm',
                format: 'a4',
                compress: true
            })
            pdf.addImage(imgData, 'PNG', 0, 0, 297, 210, undefined, 'FAST')
            pdf.save(`Laporan_Tahunan_${student?.full_name.replace(/\s+/g, '_')}_${year}.pdf`)
            toast.success("PDF berhasil diunduh")
        } catch (error) {
            console.error("PDF Error:", error)
            toast.error("Gagal membuat PDF. Gunakan fitur Print (Ctrl+P) sebagai alternatif.")
        } finally {
            setIsExporting(false)
        }
    }

    if (isLoadingStudent || isLoadingLogs) {
        return (
            <div className="flex flex-col items-center justify-center min-h-screen gap-4">
                <Loader2 className="h-10 w-10 animate-spin text-primary" />
                <p className="font-medium text-muted-foreground">Menyiapkan laporan tahunan...</p>
            </div>
        )
    }

    if (!student) {
        return (
            <div className="flex flex-col items-center justify-center min-h-screen gap-4">
                <h1 className="text-xl font-bold">Data tidak ditemukan</h1>
                <Button onClick={() => navigate(-1)}>Kembali</Button>
            </div>
        )
    }

    return (
        <div className="min-h-screen bg-background flex flex-col">
            {/* Action Bar (Hidden during print) */}
            <header className="sticky top-0 z-50 border-b bg-background/95 px-6 py-3 backdrop-blur supports-[backdrop-filter]:bg-background/80 no-print">
                <div className="flex items-center justify-between gap-4">
                <div className="flex items-center gap-4">
                    <Button variant="ghost" size="sm" onClick={() => navigate(-1)} className="gap-2">
                        <ArrowLeft className="h-4 w-4" /> Kembali
                    </Button>
                    <div className="h-6 w-px bg-border" />
                    <div>
                        <h1 className="text-sm font-bold truncate max-w-[200px] md:max-w-none">{student.full_name}</h1>
                        <div className="mt-1">
                            <Badge variant="secondary" className="uppercase text-[10px] tracking-wide">Laporan Tahunan {year}</Badge>
                        </div>
                    </div>
                </div>
                <div className="flex items-center gap-2">
                    <Button size="sm" onClick={handlePrint} disabled={isExporting} className="gap-2">
                        <Printer className="h-4 w-4" /> Cetak (A4)
                    </Button>
                    <Button variant="outline" size="sm" onClick={handleDownloadPDF} disabled={isExporting} className="gap-2">
                        {isExporting ? <Loader2 className="h-4 w-4 animate-spin" /> : <FileDown className="h-4 w-4" />}
                        Simpan PDF
                    </Button>
                </div>
                </div>
            </header>

            {/* Document Content */}
            <div className="flex-1 overflow-auto p-4 md:p-12 flex justify-center custom-scrollbar">
                <div className="w-full max-w-[32cm] space-y-4">
                    <Alert className="no-print">
                        <Info className="h-4 w-4" />
                        <AlertDescription>
                            Tampilan dokumen dipertahankan formal untuk kebutuhan cetak, sementara kontrol aksi menggunakan pola komponen shadcnUI.
                        </AlertDescription>
                    </Alert>
                <div 
                    ref={reportRef}
                    id="printable-report"
                    className="bg-white p-[1.2cm] w-[29.7cm] min-h-[21cm] mx-auto text-black shadow-lg print:shadow-none print:p-0 print:m-0 print:block"
                    style={{ 
                        boxSizing: 'border-box',
                        fontFamily: "'Times New Roman', Times, serif",
                        backgroundColor: '#ffffff',
                        color: '#000000'
                    }}
                >
                    {/* Kop Lembaga */}
                    <div className="flex items-center justify-between border-b-[3px] border-black pb-3 mb-6 relative">
                        <img src="/logo_jawa_barat.svg" alt="Logo Jawa Barat" className="w-20 h-20 object-contain" />
                        <div className="flex-1 text-center px-6">
                            <h2 className="text-base font-bold uppercase leading-tight">Pemerintah Provinsi Jawa Barat</h2>
                            <h2 className="text-sm font-bold uppercase leading-tight">Dinas Pendidikan</h2>
                            <h1 className="text-2xl font-black uppercase leading-none tracking-tighter my-1">SMKN 1 Garut</h1>
                            <p className="text-[9px] italic font-sans font-medium">
                                Jl. Alamat Sekolah No. 123, Kota, Provinsi 00000 <br />
                                Telp: (0xxx) xxxxxx | Website: www.smkanda.sch.id | Email: info@smkanda.sch.id
                            </p>
                        </div>
                        <img src="/logo-sekolah.png" alt="Logo Sekolah" className="w-20 h-20 object-contain" />
                        <div className="absolute bottom-[-6px] left-0 w-full h-[1px] bg-black"></div>
                    </div>

                    <div className="text-center mb-6">
                        <h3 className="text-lg font-bold underline underline-offset-4 uppercase tracking-tight">Laporan Kehadiran Siswa</h3>
                        <p className="font-sans font-bold mt-1 text-xs">Tahun Pelajaran {year} / {year+1}</p>
                    </div>

                    {/* Identitas Siswa */}
                    <div className="grid grid-cols-2 gap-x-16 gap-y-1 mb-6 text-[10px] font-sans">
                        <div className="grid grid-cols-[120px_8px_1fr] items-baseline text-left">
                            <span className="uppercase font-semibold text-slate-600">Nama Lengkap</span>
                            <span>:</span>
                            <span className="font-bold border-b border-dotted border-slate-400 pb-0.5 uppercase">{student.full_name}</span>
                        </div>
                        <div className="grid grid-cols-[120px_8px_1fr] items-baseline text-left">
                            <span className="uppercase font-semibold text-slate-600">Instansi / DUDI</span>
                            <span>:</span>
                            <span className="font-bold border-b border-dotted border-slate-400 pb-0.5 truncate">{student.placements?.[0]?.companies?.name || '-'}</span>
                        </div>
                        <div className="grid grid-cols-[120px_8px_1fr] items-baseline text-left">
                            <span className="uppercase font-semibold text-slate-600">NISN / NIPD</span>
                            <span>:</span>
                            <span className="font-medium border-b border-dotted border-slate-400 pb-0.5">{student.nisn || '-'} / {student.nipd || '-'}</span>
                        </div>
                        <div className="grid grid-cols-[120px_8px_1fr] items-baseline text-left">
                            <span className="uppercase font-semibold text-slate-600">Wali Kelas / Pembimbing</span>
                            <span>:</span>
                            <span className="font-medium border-b border-dotted border-slate-400 pb-0.5">
                                {homeroomData?.teacher_name ?? '......................................................'}
                            </span>
                        </div>
                        <div className="grid grid-cols-[120px_8px_1fr] items-baseline text-left">
                            <span className="uppercase font-semibold text-slate-600">Kelas / Kompetensi</span>
                            <span>:</span>
                            <span className="font-medium border-b border-dotted border-slate-400 pb-0.5">{student.class_name || '-'}</span>
                        </div>
                        <div className="grid grid-cols-[120px_8px_1fr] items-baseline text-left">
                            <span className="uppercase font-semibold text-slate-600">Periode Laporan</span>
                            <span>:</span>
                            <span className="font-medium border-b border-dotted border-slate-400 pb-0.5">Januari - Desember {year}</span>
                        </div>
                    </div>

                    {/* Matrix Table */}
                    <div className="w-full">
                        <table className="w-full border-collapse border-[1.5px] border-black text-[8px] leading-tight font-sans table-fixed">
                            <thead style={{ backgroundColor: COLORS.gray100 }}>
                                <tr className="font-bold text-center">
                                    <th rowSpan={2} className="border border-black p-1 w-[70px]">BULAN</th>
                                    <th colSpan={31} className="border border-black p-0.5 tracking-[0.1em]">TANGGAL</th>
                                    <th colSpan={4} className="border border-black p-0.5">REKAP</th>
                                </tr>
                                <tr className="font-bold text-center text-[7px]">
                                    {days.map(d => (
                                        <th key={d} className="border border-black p-0 w-[21px] h-5">{d}</th>
                                    ))}
                                    <th className="border border-black p-0 w-[21px]" style={{ backgroundColor: COLORS.green100 }}>H</th>
                                    <th className="border border-black p-0 w-[21px]" style={{ backgroundColor: COLORS.yellow100 }}>S</th>
                                    <th className="border border-black p-0 w-[21px]" style={{ backgroundColor: COLORS.blue100 }}>I</th>
                                    <th className="border border-black p-0 w-[21px]" style={{ backgroundColor: COLORS.red100 }}>A</th>
                                </tr>
                            </thead>
                            <tbody>
                                {months.map(m => {
                                    const monthName = format(new Date(year, m), 'MMMM', { locale: id })
                                    const daysInMonth = getDaysInMonth(new Date(year, m))
                                    let mH = 0, mS = 0, mI = 0, mA = 0

                                    return (
                                        <tr key={m} className="h-5">
                                            <td className="border border-black px-1 font-bold uppercase text-[7.5px] text-left truncate bg-gray-50/50" style={{ backgroundColor: COLORS.gray50 }}>{monthName}</td>
                                            {days.map(d => {
                                                const code = attendanceMatrix[`${m}-${d}`] || '-'
                                                const isInvalidDay = d > daysInMonth
                                                const isWeekend = !isInvalidDay && isWeekendDate(m, d)
                                                if (!isInvalidDay && !isWeekend) {
                                                    if (code === 'H') mH++
                                                    else if (code === 'S') mS++
                                                    else if (code === 'I') mI++
                                                    else if (code === 'A') mA++
                                                }
                                                const cellStyle: React.CSSProperties = {
                                                    backgroundColor: isInvalidDay ? COLORS.gray200 : 
                                                        code === 'H' ? COLORS.green50 : 
                                                        code === 'S' ? COLORS.yellow50 : 
                                                        code === 'I' ? COLORS.blue50 : 
                                                        code === 'A' ? COLORS.red50 :
                                                        isWeekend ? COLORS.gray300 : 'transparent',
                                                    color: 
                                                        code === 'H' ? COLORS.green600 : 
                                                        code === 'S' ? COLORS.yellow600 : 
                                                        code === 'I' ? COLORS.blue600 : 
                                                        code === 'A' ? COLORS.red600 : COLORS.black
                                                }
                                                return (
                                                    <td key={d} className="border border-black text-center p-0 font-bold" style={cellStyle}>
                                                        {isInvalidDay ? '' : (code === '-' ? '' : code)}
                                                    </td>
                                                )
                                            })}
                                            <td className="border border-black text-center font-black text-[8px]" style={{ backgroundColor: COLORS.green50 }}>{mH || ''}</td>
                                            <td className="border border-black text-center font-black text-[8px]" style={{ backgroundColor: COLORS.yellow50 }}>{mS || ''}</td>
                                            <td className="border border-black text-center font-black text-[8px]" style={{ backgroundColor: COLORS.blue50 }}>{mI || ''}</td>
                                            <td className="border border-black text-center font-black text-[8px]" style={{ backgroundColor: COLORS.red50 }}>{mA || ''}</td>
                                        </tr>
                                    )
                                })}
                            </tbody>
                            <tfoot className="font-black text-[8px] uppercase text-center">
                                <tr className="h-7" style={{ backgroundColor: COLORS.gray100 }}>
                                    <td colSpan={32} className="border border-black px-4 text-right text-[7px]">TOTAL AKUMULASI :</td>
                                    <td className="border border-black text-center" style={{ backgroundColor: COLORS.green100 }}>{recap.H}</td>
                                    <td className="border border-black text-center" style={{ backgroundColor: COLORS.yellow100 }}>{recap.S}</td>
                                    <td className="border border-black text-center" style={{ backgroundColor: COLORS.blue100 }}>{recap.I}</td>
                                    <td className="border border-black text-center" style={{ backgroundColor: COLORS.red100 }}>{recap.A}</td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>

                    <div className="mt-4 text-[8px] font-sans font-bold flex gap-6 italic">
                        <span className="text-slate-700 font-black">Keterangan:</span>
                        <div className="flex gap-4">
                            <span className="flex items-center gap-1">H = HADIR / TERLAMBAT</span>
                            <span className="flex items-center gap-1">S = SAKIT</span>
                            <span className="flex items-center gap-1">I = IZIN</span>
                            <span className="flex items-center gap-1">A = ALPA (TANPA KETERANGAN)</span>
                            <span className="flex items-center gap-1" style={{ color: COLORS.gray600 }}>■ = LIBUR (SABTU / MINGGU)</span>
                        </div>
                    </div>
                    <p className="mt-1 text-[8px] font-sans text-slate-600 italic">Catatan: tanggal kosong berarti belum ada catatan kehadiran (bukan otomatis Alpa).</p>

                    {/* Signatures */}
                    <div className="mt-10 grid grid-cols-3 gap-12 text-center text-[10px] font-sans">
                        <div className="flex flex-col justify-between h-32">
                            <p className="font-semibold">Orang Tua / Wali Siswa,</p>
                            <div className="space-y-1">
                                <p className="font-bold border-b border-black w-4/5 mx-auto pb-1"></p>
                                <p className="font-medium">{student.father_name || student.mother_name || ''}</p>
                                <p className="text-[8px] text-slate-500 italic">Tanda tangan & Nama Terang</p>
                            </div>
                        </div>
                        <div className="flex flex-col justify-between h-32">
                            <p className="font-semibold">Wali Kelas / Pembimbing,</p>
                            <div className="space-y-1">
                                <p className="font-bold border-b border-black w-4/5 mx-auto pb-1"></p>
                                <p className="font-medium">{homeroomData?.teacher_name ?? ''}</p>
                                <p className="text-[8px] text-slate-500 italic">NIP / NUPTK</p>
                            </div>
                        </div>
                        <div className="flex flex-col justify-between h-32">
                            <div className="space-y-0.5">
                                <p className="font-medium text-[9px]">Kota, {format(new Date(), 'dd MMMM yyyy', { locale: id })}</p>
                                <p className="font-semibold">Kepala Sekolah,</p>
                            </div>
                            <div className="space-y-1">
                                <p className="font-bold border-b border-black w-4/5 mx-auto pb-1"></p>
                                <p className="text-[8px] text-slate-500 italic">NIP / NUPTK</p>
                            </div>
                        </div>
                    </div>

                    <div className="mt-10 pt-4 border-t border-dotted border-slate-300 flex justify-between items-center opacity-40 font-sans text-[7px] font-bold uppercase tracking-widest">
                        <p>Sistem E-PKL - Dokumen Resmi Akademik</p>
                        <p>Dicetak pada: {format(new Date(), 'Pp', { locale: id })}</p>
                    </div>
                </div>
                </div>
            </div>

            <style>{`
                @media print {
                    @page { 
                        size: A4 landscape;
                        margin: 0;
                    }
                    body {
                        visibility: hidden !important;
                        margin: 0 !important;
                        padding: 0 !important;
                        background: white !important;
                    }
                    .no-print {
                        display: none !important;
                    }
                    #printable-report {
                        visibility: visible !important;
                        position: absolute !important;
                        left: 0 !important;
                        top: 0 !important;
                        width: 297mm !important;
                        height: 210mm !important;
                        padding: 12mm !important;
                        margin: 0 !important;
                        border: none !important;
                        box-shadow: none !important;
                        z-index: 99999 !important;
                        background: white !important;
                        display: block !important;
                    }
                    #printable-report * {
                        visibility: visible !important;
                    }
                    * {
                        -webkit-print-color-adjust: exact !important;
                        print-color-adjust: exact !important;
                    }
                }
                .custom-scrollbar::-webkit-scrollbar {
                    width: 8px;
                    height: 8px;
                }
                .custom-scrollbar::-webkit-scrollbar-track {
                    background: rgba(0,0,0,0.05);
                }
                .custom-scrollbar::-webkit-scrollbar-thumb {
                    background: rgba(0,0,0,0.2);
                    border-radius: 10px;
                }
            `}</style>
        </div>
    )
}
