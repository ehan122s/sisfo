import * as React from "react"
import { useQuery } from "@tanstack/react-query"
import { format, getDaysInMonth } from "date-fns"
import { id } from "date-fns/locale"
import { Printer, Loader2, FileDown } from "lucide-react"
import { 
    Dialog, 
    DialogContent, 
    DialogHeader, 
    DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { getStudentYearlyAttendance } from "../services/report-service"
import { type Student } from "@/types"
import { toast } from "sonner"

interface StudentYearlyReportProps {
    student: Student
    year: number
    isOpen: boolean
    onOpenChange: (open: boolean) => void
}

// Fixed Hex Colors for html2canvas compatibility
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

export function StudentYearlyReport({
    student,
    year,
    isOpen,
    onOpenChange
}: StudentYearlyReportProps) {
    const [isExporting, setIsExporting] = React.useState(false)
    const reportRef = React.useRef<HTMLDivElement>(null)
    
    const { data: logs = [], isLoading } = useQuery({
        queryKey: ['yearly-attendance', student.id, year],
        queryFn: () => getStudentYearlyAttendance(student.id, year),
        enabled: isOpen
    })

    const months = Array.from({ length: 12 }, (_, i) => i)
    const days = Array.from({ length: 31 }, (_, i) => i + 1)

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
            // High reliability capture: Scroll to top and wait
            window.scrollTo(0, 0)
            await new Promise(resolve => setTimeout(resolve, 500))

            // Increase scale for better resolution (3 = 288 DPI approx)
            const scale = 3 
            
            // A4 Landscape dimensions in mm
            const a4WidthMm = 297
            const a4HeightMm = 210
            
            // Convert to pixels (approx 96 DPI screen base)
            // 1 mm = 3.7795 px
            const mmToPx = 3.7795
            const widthPx = Math.floor(a4WidthMm * mmToPx)
            const heightPx = Math.floor(a4HeightMm * mmToPx)

            const canvas = await html2canvas(reportRef.current, {
                scale: scale,
                useCORS: true,
                logging: false,
                backgroundColor: COLORS.white,
                width: widthPx,
                height: heightPx,
                windowWidth: widthPx,
                windowHeight: heightPx,
                x: 0,
                y: 0,
                scrollX: 0,
                scrollY: 0,
                onclone: (clonedDoc) => {
                    const el = clonedDoc.getElementById('printable-report')
                    if (el) {
                        el.style.position = 'relative'
                        el.style.display = 'block'
                        el.style.margin = '0'
                        // Ensure padding matches print style (15mm)
                        el.style.padding = '15mm' 
                        el.style.boxShadow = 'none'
                        el.style.visibility = 'visible'
                        // Force exact dimensions
                        el.style.width = `${a4WidthMm}mm`
                        el.style.minHeight = `${a4HeightMm}mm`
                        el.style.boxSizing = 'border-box'
                    }
                }
            })
            
            const imgData = canvas.toDataURL('image/png', 1.0)
            const pdf = new jsPDF({
                orientation: 'landscape',
                unit: 'mm',
                format: 'a4',
                compress: true
            })

            pdf.addImage(imgData, 'PNG', 0, 0, a4WidthMm, a4HeightMm, undefined, 'FAST')
            pdf.save(`Laporan_Tahunan_${student.full_name.replace(/\s+/g, '_')}_${year}.pdf`)
            toast.success("PDF berhasil diunduh")
        } catch (error) {
            console.error("PDF Error:", error)
            toast.error("Gagal membuat PDF")
        } finally {
            setIsExporting(false)
        }
    }

    return (
        <Dialog open={isOpen} onOpenChange={onOpenChange}>
            <DialogContent className="max-w-[98vw] w-full h-[95vh] flex flex-col p-0 overflow-hidden border-none shadow-2xl bg-white">
                <DialogHeader className="p-4 border-b flex flex-row items-center justify-between space-y-0 bg-white z-[100] no-print">
                    <div className="flex flex-col text-left">
                        <DialogTitle className="text-lg font-bold">Pratinjau Laporan Kehadiran Tahunan</DialogTitle>
                        <p className="text-xs text-slate-500 font-medium">Dokumen resmi - Format A4 Landscape</p>
                    </div>
                    <div className="flex items-center gap-3 pr-10">
                        <Button variant="default" size="sm" onClick={handlePrint} disabled={isLoading || isExporting} className="shadow-sm">
                            <Printer className="mr-2 h-4 w-4" /> Cetak (A4)
                        </Button>
                        <Button variant="outline" size="sm" onClick={handleDownloadPDF} disabled={isLoading || isExporting}>
                            {isExporting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <FileDown className="mr-2 h-4 w-4" />}
                            Simpan PDF
                        </Button>
                    </div>
                </DialogHeader>

                <div className="flex-1 overflow-auto bg-slate-100 p-4 md:p-12 flex justify-center custom-scrollbar no-print">
                    {isLoading ? (
                        <div className="flex flex-col items-center justify-center h-64 gap-4">
                            <Loader2 className="h-10 w-10 animate-spin text-blue-600" />
                            <p className="text-slate-500 animate-pulse font-semibold">Menyusun dokumen laporan...</p>
                        </div>
                    ) : (
                        <div 
                            ref={reportRef}
                            id="printable-report"
                            className="bg-white mx-auto text-black shadow-2xl relative print:shadow-none print:m-0 print:block"
                            style={{ 
                                boxSizing: 'border-box',
                                fontFamily: "'Times New Roman', Times, serif",
                                backgroundColor: '#ffffff',
                                color: '#000000',
                                width: '297mm',
                                minHeight: '210mm',
                                padding: '15mm'
                            }}
                        >
                            {/* Kop Lembaga */}
                            <div className="flex items-center justify-between border-b-[3px] border-black pb-3 mb-4 relative">
                                <div className="w-20 h-20 flex items-center justify-center border border-slate-200 rounded-lg bg-slate-50 text-[8px] font-bold text-center px-2">
                                    LOGO PROVINSI
                                </div>
                                <div className="flex-1 text-center px-4">
                                    <h2 className="text-lg font-bold uppercase leading-tight">Pemerintah Provinsi Jawa Barat</h2>
                                    <h2 className="text-md font-bold uppercase leading-tight">Dinas Pendidikan</h2>
                                    <h1 className="text-2xl font-black uppercase leading-none tracking-tighter my-1">NAMA SMK ANDA</h1>
                                    <p className="text-[10px] italic font-sans font-medium">
                                        Jl. Alamat Sekolah No. 123, Kota, Provinsi 00000 <br />
                                        Telp: (0xxx) xxxxxx | Website: www.smkanda.sch.id | Email: info@smkanda.sch.id
                                    </p>
                                </div>
                                <div className="w-20 h-20 flex items-center justify-center border border-slate-200 rounded-lg bg-slate-50 text-[8px] font-bold text-center px-2">
                                    LOGO SEKOLAH
                                </div>
                                <div className="absolute bottom-[-6px] left-0 w-full h-[1px] bg-black"></div>
                            </div>

                            <div className="text-center mb-4">
                                <h3 className="text-xl font-bold underline underline-offset-4 uppercase tracking-tight">Laporan Kehadiran Siswa PKL</h3>
                                <p className="font-sans font-bold mt-1 text-sm">Tahun Pelajaran {year} / {year+1}</p>
                            </div>

                            {/* Identitas Siswa */}
                            <div className="grid grid-cols-2 gap-x-12 gap-y-1 mb-4 text-[10px] font-sans">
                                <div className="grid grid-cols-[110px_6px_1fr] items-baseline text-left">
                                    <span className="uppercase font-semibold text-slate-600">Nama Lengkap</span>
                                    <span>:</span>
                                    <span className="font-bold border-b border-dotted border-slate-400 pb-0.5">{student.full_name}</span>
                                </div>
                                <div className="grid grid-cols-[110px_6px_1fr] items-baseline text-left">
                                    <span className="uppercase font-semibold text-slate-600">Instansi / DUDI</span>
                                    <span>:</span>
                                    <span className="font-bold border-b border-dotted border-slate-400 pb-0.5 truncate">{student.placements?.[0]?.companies?.name || '-'}</span>
                                </div>
                                <div className="grid grid-cols-[110px_6px_1fr] items-baseline text-left">
                                    <span className="uppercase font-semibold text-slate-600">NISN / NIPD</span>
                                    <span>:</span>
                                    <span className="font-medium border-b border-dotted border-slate-400 pb-0.5">{student.nisn || '-'} / {student.nipd || '-'}</span>
                                </div>
                                <div className="grid grid-cols-[110px_6px_1fr] items-baseline text-left">
                                    <span className="uppercase font-semibold text-slate-600">Guru Pembimbing</span>
                                    <span>:</span>
                                    <span className="font-medium border-b border-dotted border-slate-400 pb-0.5">......................................................</span>
                                </div>
                                <div className="grid grid-cols-[110px_6px_1fr] items-baseline text-left">
                                    <span className="uppercase font-semibold text-slate-600">Kelas / Kompetensi</span>
                                    <span>:</span>
                                    <span className="font-medium border-b border-dotted border-slate-400 pb-0.5">{student.class_name || '-'}</span>
                                </div>
                                <div className="grid grid-cols-[110px_6px_1fr] items-baseline text-left">
                                    <span className="uppercase font-semibold text-slate-600">Periode Laporan</span>
                                    <span>:</span>
                                    <span className="font-medium border-b border-dotted border-slate-400 pb-0.5">Januari - Desember {year}</span>
                                </div>
                            </div>

                            {/* Matrix Table */}
                            <div className="w-full">
                                <table className="w-full border-collapse border-[1.5px] border-black text-[8px] leading-tight font-sans">
                                    <thead style={{ backgroundColor: COLORS.gray100 }}>
                                        <tr className="font-bold text-center">
                                            <th rowSpan={2} className="border border-black p-0.5 w-[70px]">BULAN</th>
                                            <th colSpan={31} className="border border-black p-0.5 tracking-widest">TANGGAL</th>
                                            <th colSpan={4} className="border border-black p-0.5">REKAPITULASI</th>
                                        </tr>
                                        <tr className="font-bold text-center">
                                            {days.map(d => (
                                                <th key={d} className="border border-black p-0 w-[20px] h-5">{d}</th>
                                            ))}
                                            <th className="border border-black p-0 w-[20px]" style={{ backgroundColor: COLORS.green100, color: COLORS.green900 }}>H</th>
                                            <th className="border border-black p-0 w-[20px]" style={{ backgroundColor: COLORS.yellow100, color: COLORS.yellow900 }}>S</th>
                                            <th className="border border-black p-0 w-[20px]" style={{ backgroundColor: COLORS.blue100, color: COLORS.blue900 }}>I</th>
                                            <th className="border border-black p-0 w-[20px]" style={{ backgroundColor: COLORS.red100, color: COLORS.red900 }}>A</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {months.map(m => {
                                            const monthName = format(new Date(year, m), 'MMMM', { locale: id })
                                            const daysInMonth = getDaysInMonth(new Date(year, m))
                                            
                                            let mH = 0, mS = 0, mI = 0, mA = 0

                                            return (
                                                <tr key={m} className="h-5">
                                                    <td className="border border-black px-1.5 font-bold uppercase text-[8px] text-left" style={{ backgroundColor: COLORS.gray50 }}>{monthName}</td>
                                                    {days.map(d => {
                                                        const code = attendanceMatrix[`${m}-${d}`] || '-'
                                                        const isInvalidDay = d > daysInMonth
                                                        
                                                        if (!isInvalidDay) {
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
                                                                code === 'A' ? COLORS.red50 : 'transparent',
                                                            color: 
                                                                code === 'H' ? COLORS.green600 : 
                                                                code === 'S' ? COLORS.yellow600 : 
                                                                code === 'I' ? COLORS.blue600 : 
                                                                code === 'A' ? COLORS.red600 : COLORS.black
                                                        }

                                                        return (
                                                            <td 
                                                                key={d} 
                                                                className="border border-black text-center p-0 font-bold"
                                                                style={cellStyle}
                                                            >
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
                                        <tr className="h-6" style={{ backgroundColor: COLORS.gray100 }}>
                                            <td colSpan={32} className="border border-black px-2 text-right">TOTAL AKUMULASI KEHADIRAN PER TAHUN :</td>
                                            <td className="border border-black text-center font-black" style={{ backgroundColor: COLORS.green100, color: COLORS.green950 }}>{recap.H}</td>
                                            <td className="border border-black text-center font-black" style={{ backgroundColor: COLORS.yellow100, color: COLORS.yellow950 }}>{recap.S}</td>
                                            <td className="border border-black text-center font-black" style={{ backgroundColor: COLORS.blue100, color: COLORS.blue950 }}>{recap.I}</td>
                                            <td className="border border-black text-center font-black" style={{ backgroundColor: COLORS.red100, color: COLORS.red950 }}>{recap.A}</td>
                                        </tr>
                                    </tfoot>
                                </table>
                            </div>

                            <div className="mt-2 text-[8px] font-sans font-bold flex gap-6 italic">
                                <span className="text-slate-700">Keterangan Singkatan:</span>
                                <div className="flex gap-4">
                                    <span className="flex items-center gap-1"><div className="w-2 h-2 rounded-full" style={{ backgroundColor: COLORS.green600 }}></div> H = HADIR / TERLAMBAT</span>
                                    <span className="flex items-center gap-1"><div className="w-2 h-2 rounded-full" style={{ backgroundColor: COLORS.yellow600 }}></div> S = SAKIT</span>
                                    <span className="flex items-center gap-1"><div className="w-2 h-2 rounded-full" style={{ backgroundColor: COLORS.blue600 }}></div> I = IZIN</span>
                                    <span className="flex items-center gap-1"><div className="w-2 h-2 rounded-full" style={{ backgroundColor: COLORS.red600 }}></div> A = ALPA (TANPA KETERANGAN)</span>
                                </div>
                            </div>
                            <p className="mt-1 text-[8px] font-sans text-slate-600 italic">Catatan: tanggal kosong berarti belum ada catatan kehadiran (bukan otomatis Alpa).</p>

                            {/* Signatures */}
                            <div className="mt-6 grid grid-cols-3 gap-8 text-center text-[10px] font-sans">
                                <div className="flex flex-col justify-between h-28">
                                    <p className="font-semibold">Orang Tua / Wali Siswa,</p>
                                    <div className="space-y-1">
                                        <p className="font-bold border-b border-black w-4/5 mx-auto pb-1"></p>
                                        <p className="text-[8px] text-slate-500 italic">Tanda tangan & Nama Terang</p>
                                    </div>
                                </div>
                                <div className="flex flex-col justify-between h-28">
                                    <p className="font-semibold">Pembimbing Industri,</p>
                                    <div className="space-y-1">
                                        <p className="font-bold border-b border-black w-4/5 mx-auto pb-1"></p>
                                        <p className="text-[8px] text-slate-500 italic">Cap Perusahaan & Nama Terang</p>
                                    </div>
                                </div>
                                <div className="flex flex-col justify-between h-28">
                                    <div className="space-y-0.5">
                                        <p className="font-medium text-[9px]">Kota, {format(new Date(), 'dd MMMM yyyy', { locale: id })}</p>
                                        <p className="font-semibold">Pembimbing Sekolah,</p>
                                    </div>
                                    <div className="space-y-1">
                                        <p className="font-bold border-b border-black w-4/5 mx-auto pb-1"></p>
                                        <p className="text-[8px] text-slate-500 italic">NIP / NUPTK</p>
                                    </div>
                                </div>
                            </div>

                            <div className="mt-6 pt-2 border-t border-dotted border-slate-300 flex justify-between items-center opacity-40 font-sans text-[7px] font-bold uppercase tracking-widest">
                                <p>Sistem E-PKL - Dokumen Resmi Akademik</p>
                                <p>Dicetak pada: {format(new Date(), 'Pp', { locale: id })}</p>
                            </div>
                        </div>
                    )}
                </div>

                <style>{`
                    @media print {
                        @page { 
                            size: 297mm 210mm;
                            margin: 0;
                        }
                        body {
                            visibility: hidden !important;
                            margin: 0 !important;
                            padding: 0 !important;
                            height: 100vh !important;
                            overflow: hidden !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                            background: white !important;
                        }
                        .no-print {
                            display: none !important;
                        }
                        /* Reset default browser print styles */
                        html, body {
                            height: 100%;
                            width: 100%;
                        }
                        
                        /* Main Report Container - Force Exact A4 */
                        #printable-report {
                            visibility: visible !important;
                            position: fixed !important;
                            left: 0 !important;
                            top: 0 !important;
                            width: 297mm !important;
                            height: 210mm !important;
                            padding: 15mm !important; /* Safe Margin */
                            margin: 0 !important;
                            border: none !important;
                            box-shadow: none !important;
                            z-index: 9999999 !important;
                            background: white !important;
                            display: block !important;
                            box-sizing: border-box !important;
                            
                            /* Ensure text is sharp */
                            text-rendering: optimizeLegibility;
                            -webkit-font-smoothing: antialiased;
                            
                            /* Scaling logic to ensure fit */
                            transform-origin: top left;
                        }

                        /* Ensure all children are visible */
                        #printable-report * {
                            visibility: visible !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }

                        /* Hide browser default header/footer if possible (standard practice) */
                        @page {
                            margin: 0; 
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
                    .custom-scrollbar::-webkit-scrollbar-thumb:hover {
                        background: rgba(0,0,0,0.3);
                    }
                `}</style>
            </DialogContent>
        </Dialog>
    )
}
