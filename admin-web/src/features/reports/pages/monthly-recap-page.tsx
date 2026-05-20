import { useState, useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { format } from 'date-fns'
import { id } from 'date-fns/locale'

import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { getMonthlyAttendanceReport, getClassList, getYearlyAttendanceReport } from '../services/report-service'
import {
    Loader2, Download, ChevronLeft, ChevronRight, FileText,
    FileSpreadsheet, Building2, CalendarRange, Users, CalendarX2,
} from 'lucide-react'
import { toast } from 'sonner'
import { TableSkeleton } from '@/components/ui/table-skeleton'
import { EmptyState } from '@/components/ui/empty-state'
import { exportToExcel } from '@/lib/export'
import {
    Command, CommandEmpty, CommandGroup, CommandInput,
    CommandItem, CommandList,
} from '@/components/ui/command'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { cn } from '@/lib/utils'

/* ─── design tokens ───────────────────────────────────────────────────────── */
const TH = 'px-4 py-3 text-left text-[10px] font-bold uppercase tracking-[0.1em] text-gray-400 dark:text-gray-500'
const TD = 'px-4 py-3.5 text-sm'
const SEL = 'h-9 rounded-xl text-sm font-medium bg-white dark:bg-white/[0.05] border-gray-200 dark:border-white/10 text-gray-800 dark:text-gray-200'

const MONTHS = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember']
const YEARS = [2024, 2025, 2026]

/* ─── atoms ───────────────────────────────────────────────────────────────── */
function PctBadge({ pct }: { pct: number }) {
    return (
        <span className={cn(
            'inline-flex items-center justify-center px-2.5 py-0.5 rounded-full text-[11px] font-extrabold tabular-nums border',
            pct >= 90
                ? 'bg-emerald-50 text-emerald-600 border-emerald-200 dark:bg-emerald-400/10 dark:text-emerald-400 dark:border-emerald-400/20'
                : pct >= 75
                    ? 'bg-amber-50 text-amber-600 border-amber-200 dark:bg-amber-400/10 dark:text-amber-400 dark:border-amber-400/20'
                    : 'bg-red-50 text-red-600 border-red-200 dark:bg-red-400/10 dark:text-red-400 dark:border-red-400/20'
        )}>
            {pct}%
        </span>
    )
}

function ClassPill({ name }: { name: string }) {
    return (
        <span className="inline-flex px-2 py-0.5 rounded-md text-[11px] font-bold
            bg-blue-50 text-blue-600 border border-blue-100
            dark:bg-blue-500/10 dark:text-blue-400 dark:border-blue-400/20">
            {name}
        </span>
    )
}

function PagBtn({ onClick, disabled, children }: {
    onClick: () => void; disabled: boolean; children: React.ReactNode
}) {
    return (
        <button onClick={onClick} disabled={disabled}
            className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold
                border border-gray-200 dark:border-white/10
                bg-white dark:bg-white/5 text-gray-600 dark:text-gray-400
                hover:bg-gray-50 dark:hover:bg-white/10
                disabled:opacity-30 disabled:cursor-not-allowed transition-all">
            {children}
        </button>
    )
}

function StatTH() {
    return (
        <>
            <th className={cn(TH, 'text-center w-12 text-emerald-500')}>H</th>
            <th className={cn(TH, 'text-center w-12 text-amber-500')}>T</th>
            <th className={cn(TH, 'text-center w-12 text-yellow-500')}>S</th>
            <th className={cn(TH, 'text-center w-12 text-blue-500')}>I</th>
            <th className={cn(TH, 'text-center w-12 text-red-500')}>A</th>
            <th className={cn(TH, 'text-center')}>% Keh.</th>
        </>
    )
}

function TableWrap({ children }: { children: React.ReactNode }) {
    return (
        <div className="rounded-xl overflow-hidden border border-gray-100 dark:border-white/[0.06]">
            <table className="w-full border-collapse">{children}</table>
        </div>
    )
}

function THead({ children }: { children: React.ReactNode }) {
    return (
        <thead>
            <tr className="bg-gray-50/80 dark:bg-[#0d0d1a] border-b border-gray-100 dark:border-white/[0.06]">
                {children}
            </tr>
        </thead>
    )
}

function Card({ children, blue }: { children: React.ReactNode; blue?: boolean }) {
    return (
        <div className={cn(
            'rounded-2xl overflow-hidden bg-white dark:bg-[#111120]',
            'border border-gray-100 dark:border-white/[0.07]',
            blue
                ? 'shadow-[0_2px_16px_rgba(59,130,246,0.06)] dark:shadow-[0_4px_30px_rgba(0,0,0,0.4)]'
                : 'shadow-[0_1px_6px_rgba(0,0,0,0.04)] dark:shadow-none',
        )}>
            {children}
        </div>
    )
}

function CardHead({ title, desc, badge }: { title: string; desc?: string; badge?: React.ReactNode }) {
    return (
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 dark:border-white/[0.06]">
            <div>
                <h2 className="text-sm font-bold text-gray-900 dark:text-white tracking-tight">{title}</h2>
                {desc && <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5 font-medium">{desc}</p>}
            </div>
            {badge}
        </div>
    )
}

function StatCells({ stats }: { stats: { hadir: number; terlambat: number; sakit: number; izin: number; alpa: number; percentage: number } }) {
    return (<>
        <td className={cn(TD, 'text-center font-extrabold text-emerald-500 tabular-nums')}>{stats.hadir}</td>
        <td className={cn(TD, 'text-center font-extrabold text-amber-500 tabular-nums')}>{stats.terlambat}</td>
        <td className={cn(TD, 'text-center font-extrabold text-yellow-500 tabular-nums')}>{stats.sakit}</td>
        <td className={cn(TD, 'text-center font-extrabold text-blue-500 tabular-nums')}>{stats.izin}</td>
        <td className={cn(TD, 'text-center font-extrabold text-red-500 tabular-nums')}>{stats.alpa}</td>
        <td className={cn(TD, 'text-center')}><PctBadge pct={stats.percentage} /></td>
    </>)
}

/* ─── Empty state khusus "tidak ada data bulan ini" ──────────────────────── */
function NoDataForMonth({ monthName, year, className }: { monthName: string; year: number; className?: string }) {
    return (
        <div className="flex flex-col items-center justify-center py-16 px-6 text-center">
            <div className="w-14 h-14 rounded-2xl flex items-center justify-center mb-4
                bg-gray-100 dark:bg-white/[0.05]
                border border-gray-200 dark:border-white/10">
                <CalendarX2 className="h-6 w-6 text-gray-400 dark:text-gray-500" />
            </div>
            <p className="text-sm font-bold text-gray-700 dark:text-gray-300 mb-1">
                Tidak ada data absensi
            </p>
            <p className="text-xs text-gray-400 dark:text-gray-500 max-w-xs leading-relaxed">
                Belum ada catatan kehadiran untuk bulan{' '}
                <span className="font-bold text-blue-500">{monthName} {year}</span>
                {className ? (
                    <> · kelas <span className="font-bold text-blue-500">{className}</span></>
                ) : null}.
                Pastikan data sudah diinput atau coba pilih bulan lain.
            </p>
        </div>
    )
}

/* ─── main ────────────────────────────────────────────────────────────────── */
export function MonthlyRecapPage() {
    const [activeTab, setActiveTab] = useState('per-kelas')
    const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth())
    const [selectedYear, setSelectedYear] = useState(new Date().getFullYear())

    const [selectedClass, setSelectedClass] = useState<string>('')
    const [openClassFilter, setOpenClassFilter] = useState(false)

    const [isGenerating, setIsGenerating] = useState(false)
    const [page, setPage] = useState(0)
    const pageSize = 45

    const [yearlySelectedYear, setYearlySelectedYear] = useState(new Date().getFullYear())
    const [yearlySelectedClass, setYearlySelectedClass] = useState('')
    const [yearlyPage, setYearlyPage] = useState(0)
    const [openYearlyClassFilter, setOpenYearlyClassFilter] = useState(false)

    const monthName = MONTHS[selectedMonth]

    const { data: classList = [] } = useQuery({
        queryKey: ['class-list'],
        queryFn: getClassList,
        staleTime: 1000 * 60 * 10,
    })

    // ── Reset page ke 0 setiap kali filter berubah ──
    const handleMonthChange = (val: string) => {
        setSelectedMonth(parseInt(val))
        setPage(0)
    }

    const handleYearChange = (val: string) => {
        setSelectedYear(parseInt(val))
        setPage(0)
    }

    const handleClassChange = (cls: string) => {
        setSelectedClass(cls)
        setPage(0)
        setOpenClassFilter(false)
    }

    // ── Report query ──
    // queryKey menyertakan semua variabel filter supaya react-query
    // refetch otomatis setiap kali salah satu berubah
    const { data: reportData, isLoading, isFetching, isError, error } = useQuery({
        queryKey: ['attendance-report', selectedMonth, selectedYear, selectedClass],
        queryFn: async () => {
            const result = await getMonthlyAttendanceReport(
                selectedMonth,
                selectedYear,
                selectedClass || undefined
            )
            // Deduplicate by studentId
            const seen = new Set<string>()
            return result.filter(s => {
                if (seen.has(s.studentId)) return false
                seen.add(s.studentId)
                return true
            })
        },
        enabled: classList.length > 0,
        // Turunkan staleTime supaya saat pindah bulan data tidak di-serve dari cache lama
        staleTime: 1000 * 60 * 2,
        refetchOnMount: true,
        retry: 1,
    })

    const isLoadingData = isLoading || isFetching

    const totalCount = reportData?.length || 0
    const totalPages = Math.ceil(totalCount / pageSize)
    const paginatedData = reportData?.slice(page * pageSize, (page + 1) * pageSize) || []

    const dudiData = useMemo(() => {
        if (!reportData) return []
        const map = new Map<string, {
            companyName: string; studentCount: number; hadir: number; terlambat: number
            sakit: number; izin: number; alpa: number; totalDays: number
        }>()
        reportData.forEach(item => {
            const key = item.companyName && item.companyName !== '-' ? item.companyName : '-'
            const ex = map.get(key)
            if (ex) {
                ex.studentCount++
                ex.hadir += item.stats.hadir
                ex.terlambat += item.stats.terlambat
                ex.sakit += item.stats.sakit
                ex.izin += item.stats.izin
                ex.alpa += item.stats.alpa
                ex.totalDays += item.stats.totalDays
            } else {
                map.set(key, {
                    companyName: key, studentCount: 1,
                    hadir: item.stats.hadir, terlambat: item.stats.terlambat,
                    sakit: item.stats.sakit, izin: item.stats.izin,
                    alpa: item.stats.alpa, totalDays: item.stats.totalDays,
                })
            }
        })
        return Array.from(map.values()).sort((a, b) => {
            if (a.companyName === '-') return 1
            if (b.companyName === '-') return -1
            return a.companyName.localeCompare(b.companyName)
        })
    }, [reportData])

    const { data: yearlyData, isLoading: isYearlyLoading } = useQuery({
        queryKey: ['yearly-report', yearlySelectedYear, yearlySelectedClass],
        queryFn: () => getYearlyAttendanceReport(yearlySelectedYear, yearlySelectedClass || undefined),
        staleTime: 1000 * 60 * 10,
        retry: 1,
    })

    const yearlyPageSize = 45
    const yearlyTotalPages = Math.ceil((yearlyData?.length || 0) / yearlyPageSize)
    const yearlyPaginatedData = yearlyData?.slice(yearlyPage * yearlyPageSize, (yearlyPage + 1) * yearlyPageSize) || []

    const handleDownloadDudiExcel = async () => {
        if (!dudiData.length) { toast.error('Tidak ada data untuk diunduh'); return }
        await exportToExcel({
            headers: ['No', 'DUDI/Perusahaan', 'Jml Siswa', 'H', 'T', 'S', 'I', 'A', '% Rata-rata'],
            rows: dudiData.map((d, i) => {
                const avgPct = d.totalDays > 0 ? Math.round(((d.hadir + d.terlambat) / d.totalDays) * 100) : 0
                return [i + 1, d.companyName, d.studentCount, d.hadir, d.terlambat, d.sakit, d.izin, d.alpa, `${avgPct}%`]
            }),
            filename: `Rekap_DUDI_${monthName}_${selectedYear}`,
        })
        toast.success('File Excel berhasil diunduh')
    }

    const handleDownloadYearlyExcel = async () => {
        if (!yearlyData?.length) { toast.error('Tidak ada data untuk diunduh'); return }
        await exportToExcel({
            headers: ['No', 'Nama Siswa', 'Kelas', 'DUDI', 'H', 'T', 'S', 'I', 'A', 'Total Hari', '%'],
            rows: yearlyData.map((s, i) => [
                i + 1, s.studentName, s.className, s.companyName,
                s.stats.hadir, s.stats.terlambat, s.stats.sakit, s.stats.izin, s.stats.alpa,
                s.stats.totalDays, `${s.stats.percentage}%`
            ]),
            filename: `Rekap_Tahunan_${yearlySelectedClass || 'Semua Kelas'}_${yearlySelectedYear}`,
        })
        toast.success('File Excel berhasil diunduh')
    }

    const handleDownloadPDF = async () => {
        if (!reportData?.length) { toast.error('Tidak ada data untuk diunduh'); return }
        setIsGenerating(true)
        try {
            const [{ default: jsPDF }, { default: autoTable }] = await Promise.all([
                import('jspdf'), import('jspdf-autotable'),
            ])
            const doc = new jsPDF()
            doc.setFontSize(18)
            doc.text('SMKN 1 GARUT', 105, 15, { align: 'center' })
            doc.setFontSize(14)
            doc.text('LAPORAN KEHADIRAN SISWA PKL', 105, 22, { align: 'center' })
            doc.setFontSize(12)
            doc.text(`Periode: ${monthName} ${selectedYear}`, 105, 28, { align: 'center' })
            const kelasLabel = selectedClass || 'Semua Kelas'
            doc.text(`Kelas: ${kelasLabel}`, 14, 35)
            const totalDays = reportData[0]?.stats.totalDays || 0
            doc.text(`Total Hari Kerja: ${totalDays} hari`, 14, 42)
            const tableRows: (string | number)[][] = reportData.map((s, i) => [
                i + 1, s.studentName, s.className, s.companyName,
                s.stats.hadir, s.stats.terlambat, s.stats.sakit, s.stats.izin, s.stats.alpa, `${s.stats.percentage}%`
            ])
            autoTable(doc, {
                head: [['No', 'Nama Siswa', 'Kelas', 'DUDI', 'H', 'T', 'S', 'I', 'A', '%']],
                body: tableRows,
                startY: 47,
                theme: 'grid',
                headStyles: { fillColor: [16, 185, 129] },
                styles: { fontSize: 8, cellPadding: 2 },
                columnStyles: {
                    0: { cellWidth: 10 }, 1: { cellWidth: 35 }, 2: { cellWidth: 18 },
                    3: { cellWidth: 35 }, 4: { cellWidth: 10, halign: 'center' },
                    5: { cellWidth: 10, halign: 'center' }, 6: { cellWidth: 10, halign: 'center' },
                    7: { cellWidth: 10, halign: 'center' }, 8: { cellWidth: 10, halign: 'center' },
                    9: { cellWidth: 15, halign: 'center' },
                }
            })
            const finalY = (doc as InstanceType<typeof jsPDF> & { lastAutoTable: { finalY: number } }).lastAutoTable.finalY || 150
            const signatureY = finalY > 250 ? (doc.addPage(), 20) : finalY + 15
            doc.text(`Garut, ${format(new Date(), 'd MMMM yyyy', { locale: id })}`, 140, signatureY)
            doc.text('Mengetahui,', 140, signatureY + 7)
            doc.text('Kepala Program Keahlian', 140, signatureY + 14)
            doc.text('( ..................................... )', 140, signatureY + 40)
            doc.save(`Laporan_Absensi_${kelasLabel.replace(/,\s*/g, '_')}_${monthName}_${selectedYear}.pdf`)
            toast.success('Laporan berhasil diunduh')
        } catch (err) {
            console.error(err)
            toast.error('Gagal membuat PDF')
        } finally {
            setIsGenerating(false)
        }
    }

    const handleDownloadExcel = () => {
        if (!reportData?.length) { toast.error('Tidak ada data untuk diunduh'); return }
        exportToExcel({
            headers: ['No', 'Nama Siswa', 'Kelas', 'DUDI', 'Hadir', 'Terlambat', 'Sakit', 'Izin', 'Alpa', '% Kehadiran'],
            rows: reportData.map((s, i) => [
                i + 1, s.studentName, s.className, s.companyName,
                s.stats.hadir, s.stats.terlambat, s.stats.sakit, s.stats.izin, s.stats.alpa, `${s.stats.percentage}%`,
            ]),
            filename: `Laporan_Absensi_${selectedClass || 'Semua'}_${monthName}_${selectedYear}`,
        })
        toast.success('File Excel berhasil diunduh')
    }

    const tabs = [
        { id: 'per-kelas', label: 'Per Kelas', icon: <FileText className="h-3.5 w-3.5" /> },
        { id: 'per-dudi', label: 'Per DUDI', icon: <Building2 className="h-3.5 w-3.5" /> },
        { id: 'rekap-tahunan', label: 'Rekap Tahunan', icon: <CalendarRange className="h-3.5 w-3.5" /> },
    ]

    const btnSecondary = 'flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold transition-all duration-150 border border-gray-200 dark:border-white/10 bg-white dark:bg-white/[0.06] text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/10 shadow-sm dark:shadow-none disabled:opacity-40 disabled:cursor-not-allowed'
    const btnPrimary = 'flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold transition-all duration-150 bg-blue-500 hover:bg-blue-600 active:scale-[0.98] text-white shadow-lg shadow-blue-500/25 hover:shadow-blue-500/35 disabled:opacity-40 disabled:cursor-not-allowed'

    return (
        <div className="space-y-6">

            {/* ══ HEADER ═══════════════════════════════════════════════════ */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div>
                    <div className="flex items-center gap-1 mb-2.5">
                        <span className="w-7 h-[3px] rounded-full bg-blue-500" />
                        <span className="w-2.5 h-[3px] rounded-full bg-blue-400/40" />
                    </div>
                    <h1 className="text-[2rem] font-black italic tracking-tight leading-none text-gray-900 dark:text-white">
                        LAPORAN <span className="text-blue-500">KEHADIRAN</span>
                    </h1>
                    <p className="text-sm text-gray-500 dark:text-gray-400 mt-1.5 font-medium">
                        Rekap absensi bulanan per kelas atau per DUDI/Perusahaan.
                    </p>
                </div>

                <div className="flex gap-2 shrink-0">
                    {activeTab === 'per-kelas' && (<>
                        <button onClick={handleDownloadExcel} disabled={isLoadingData || !reportData?.length} className={btnSecondary}>
                            <FileSpreadsheet className="h-4 w-4 text-emerald-500" />
                            Export Excel
                        </button>
                        <button onClick={handleDownloadPDF} disabled={isGenerating || isLoadingData || !reportData?.length} className={btnPrimary}>
                            {isGenerating
                                ? <><Loader2 className="h-4 w-4 animate-spin" /> Generating...</>
                                : <><Download className="h-4 w-4" /> Download PDF</>}
                        </button>
                    </>)}
                    {activeTab === 'per-dudi' && (
                        <button onClick={handleDownloadDudiExcel} disabled={isLoadingData || !dudiData.length} className={btnSecondary}>
                            <FileSpreadsheet className="h-4 w-4 text-emerald-500" /> Excel DUDI
                        </button>
                    )}
                    {activeTab === 'rekap-tahunan' && (
                        <button onClick={handleDownloadYearlyExcel} disabled={isYearlyLoading || !yearlyData?.length} className={btnSecondary}>
                            <FileSpreadsheet className="h-4 w-4 text-emerald-500" /> Excel Tahunan
                        </button>
                    )}
                </div>
            </div>

            {/* ══ FILTER PANEL ══════════════════════════════════════════════ */}
            {activeTab !== 'rekap-tahunan' && (
                <Card>
                    <div className="px-6 py-5">
                        <p className="text-[10px] font-bold uppercase tracking-[0.15em] text-gray-400 dark:text-gray-500 mb-4">
                            Filter Laporan
                        </p>
                        <div className="flex flex-wrap gap-3 items-end">

                            {/* Bulan */}
                            <div className="min-w-[9rem]">
                                <label className="text-[10px] font-bold uppercase tracking-widest text-gray-400 dark:text-gray-500 mb-1.5 block">Bulan</label>
                                <Select
                                    value={selectedMonth.toString()}
                                    onValueChange={handleMonthChange}
                                >
                                    <SelectTrigger className={SEL}><SelectValue /></SelectTrigger>
                                    <SelectContent>
                                        {MONTHS.map((m, i) => (
                                            <SelectItem key={i} value={i.toString()}>{m}</SelectItem>
                                        ))}
                                    </SelectContent>
                                </Select>
                            </div>

                            {/* Tahun */}
                            <div className="w-28">
                                <label className="text-[10px] font-bold uppercase tracking-widest text-gray-400 dark:text-gray-500 mb-1.5 block">Tahun</label>
                                <Select
                                    value={selectedYear.toString()}
                                    onValueChange={handleYearChange}
                                >
                                    <SelectTrigger className={SEL}><SelectValue /></SelectTrigger>
                                    <SelectContent>
                                        {YEARS.map(y => <SelectItem key={y} value={y.toString()}>{y}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            </div>

                            {/* Kelas */}
                            <div>
                                <label className="text-[10px] font-bold uppercase tracking-widest text-gray-400 dark:text-gray-500 mb-1.5 block">Kelas</label>
                                <Popover open={openClassFilter} onOpenChange={setOpenClassFilter}>
                                    <PopoverTrigger asChild>
                                        <button className="flex items-center gap-2 h-9 px-3 rounded-xl text-sm font-semibold
                                            border border-dashed border-gray-300 dark:border-white/20
                                            bg-white dark:bg-white/[0.04]
                                            text-gray-600 dark:text-gray-300
                                            hover:border-blue-400 dark:hover:border-blue-500/50
                                            hover:bg-blue-50 dark:hover:bg-blue-500/[0.06]
                                            hover:text-blue-600 dark:hover:text-blue-400
                                            transition-all duration-150">
                                            {!selectedClass ? (
                                                <span className="px-1.5 py-0.5 rounded-md text-[11px] font-bold
                                                    bg-emerald-50 text-emerald-600 border border-emerald-100
                                                    dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-400/20">
                                                    Semua Kelas
                                                </span>
                                            ) : (
                                                <span className="px-1.5 py-0.5 rounded-md text-[11px] font-bold
                                                    bg-blue-50 text-blue-600 border border-blue-100
                                                    dark:bg-blue-500/10 dark:text-blue-400 dark:border-blue-400/20">
                                                    {selectedClass}
                                                </span>
                                            )}
                                            <ChevronRight className="h-3.5 w-3.5 opacity-40 rotate-90" />
                                        </button>
                                    </PopoverTrigger>
                                    <PopoverContent
                                        className="w-52 p-0 rounded-xl bg-white dark:bg-[#1a1a2e] border-gray-200 dark:border-white/10 shadow-xl"
                                        align="start">
                                        <Command>
                                            <CommandInput placeholder="Cari kelas..." className="h-9 text-sm" />
                                            <CommandList>
                                                <CommandEmpty className="py-4 text-center text-xs text-gray-400">Kelas tidak ditemukan.</CommandEmpty>
                                                <CommandGroup>
                                                    <CommandItem
                                                        value="__semua__"
                                                        onSelect={() => handleClassChange('')}
                                                        className="font-semibold">
                                                        <div className={cn(
                                                            'mr-2 flex h-4 w-4 items-center justify-center rounded border transition-colors',
                                                            !selectedClass
                                                                ? 'bg-emerald-500 border-emerald-500 text-white'
                                                                : 'border-gray-300 dark:border-gray-600'
                                                        )}>
                                                            {!selectedClass && (
                                                                <svg className="h-3 w-3" viewBox="0 0 12 12" fill="none">
                                                                    <path d="M2 6l3 3 5-5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                                                                </svg>
                                                            )}
                                                        </div>
                                                        <span className={!selectedClass ? 'text-emerald-600 dark:text-emerald-400' : ''}>
                                                            Semua Kelas
                                                        </span>
                                                    </CommandItem>

                                                    {classList.map(cls => (
                                                        <CommandItem
                                                            key={cls}
                                                            value={cls}
                                                            onSelect={() => handleClassChange(selectedClass === cls ? '' : cls)}>
                                                            <div className={cn(
                                                                'mr-2 flex h-4 w-4 items-center justify-center rounded border transition-colors',
                                                                selectedClass === cls
                                                                    ? 'bg-blue-500 border-blue-500 text-white'
                                                                    : 'border-gray-300 dark:border-gray-600'
                                                            )}>
                                                                {selectedClass === cls && (
                                                                    <svg className="h-3 w-3" viewBox="0 0 12 12" fill="none">
                                                                        <path d="M2 6l3 3 5-5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                                                                    </svg>
                                                                )}
                                                            </div>
                                                            {cls}
                                                        </CommandItem>
                                                    ))}
                                                </CommandGroup>
                                            </CommandList>
                                        </Command>
                                    </PopoverContent>
                                </Popover>
                            </div>

                            {/* Badge jumlah siswa — hanya tampil kalau ada data */}
                            {!isLoadingData && reportData && reportData.length > 0 && (
                                <div className="ml-auto flex items-end">
                                    <div className="flex items-center gap-2.5 px-4 py-2 rounded-xl
                                        bg-blue-50 dark:bg-blue-500/10
                                        border border-blue-100 dark:border-blue-400/20">
                                        <Users className="h-4 w-4 text-blue-400 shrink-0" />
                                        <div className="text-center">
                                            <p className="text-[9px] font-bold uppercase tracking-widest text-blue-400">Siswa</p>
                                            <p className="text-xl font-black text-blue-600 dark:text-blue-400 tabular-nums leading-tight mt-0.5">{totalCount}</p>
                                        </div>
                                    </div>
                                </div>
                            )}
                        </div>
                    </div>
                </Card>
            )}

            {/* ══ TABS ══════════════════════════════════════════════════════ */}
            <div>
                <div className="flex gap-1 p-1 w-fit rounded-2xl mb-5
                    bg-gray-100/70 dark:bg-white/[0.04]
                    border border-gray-200/60 dark:border-white/[0.07]">
                    {tabs.map(tab => (
                        <button key={tab.id} onClick={() => setActiveTab(tab.id)}
                            className={cn(
                                'flex items-center gap-2 px-5 py-2 rounded-xl text-sm font-semibold transition-all duration-150',
                                activeTab === tab.id
                                    ? 'bg-white dark:bg-[#1e1e35] text-gray-900 dark:text-white shadow-sm border border-gray-200/80 dark:border-white/10'
                                    : 'text-gray-500 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200 hover:bg-white/60 dark:hover:bg-white/[0.04]'
                            )}>
                            <span className={activeTab === tab.id ? 'text-blue-500' : 'text-gray-400 dark:text-gray-500'}>{tab.icon}</span>
                            {tab.label}
                        </button>
                    ))}
                </div>

                {/* ── TAB 1: Per Kelas ─────────────────────────────────── */}
                {activeTab === 'per-kelas' && (
                    <Card blue>
                        <CardHead
                            title="Preview Data"
                            desc={
                                isLoadingData
                                    ? `Memuat data ${monthName} ${selectedYear}...`
                                    : `${totalCount} siswa · periode ${monthName} ${selectedYear}`
                            }
                            badge={!isLoadingData && totalCount > 0
                                ? <span className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold
                                    bg-blue-50 text-blue-600 border border-blue-100
                                    dark:bg-blue-500/10 dark:text-blue-400 dark:border-blue-400/20">
                                    <FileText className="h-3 w-3" /> {totalCount} Total
                                  </span>
                                : undefined}
                        />
                        <div className="p-5">
                            {/* Loading state — termasuk saat isFetching (background refetch) */}
                            {isLoadingData
                                ? <TableSkeleton columnCount={10} rowCount={5} />
                                : isError
                                    ? (
                                        <EmptyState
                                            title="Gagal memuat data"
                                            description={`Terjadi kesalahan saat memuat data. ${(error as Error)?.message || ''}`}
                                        />
                                    )
                                    : !reportData?.length
                                        // ← Empty state informatif dengan bulan & kelas yang dipilih
                                        ? <NoDataForMonth
                                            monthName={monthName}
                                            year={selectedYear}
                                            className={selectedClass || undefined}
                                          />
                                        : (<>
                                            <TableWrap>
                                                <THead>
                                                    <th className={cn(TH, 'w-12')}>No</th>
                                                    <th className={TH}>Nama Siswa</th>
                                                    <th className={cn(TH, 'hidden sm:table-cell')}>Kelas</th>
                                                    <th className={cn(TH, 'hidden md:table-cell')}>DUDI</th>
                                                    <StatTH />
                                                </THead>
                                                <tbody>
                                                    {paginatedData.map((s, i) => (
                                                        <tr key={s.studentId}
                                                            className="border-b border-gray-50 dark:border-white/[0.04] last:border-0
                                                                hover:bg-blue-50/40 dark:hover:bg-white/[0.025] transition-colors duration-100">
                                                            <td className={cn(TD, 'text-gray-300 dark:text-gray-600 font-mono text-xs w-12')}>{page * pageSize + i + 1}</td>
                                                            <td className={cn(TD, 'font-bold text-gray-900 dark:text-white')}>{s.studentName}</td>
                                                            <td className={cn(TD, 'hidden sm:table-cell')}><ClassPill name={s.className} /></td>
                                                            <td className={cn(TD, 'hidden md:table-cell text-xs text-gray-400 dark:text-gray-500 max-w-[10rem] truncate')}>{s.companyName}</td>
                                                            <StatCells stats={s.stats} />
                                                        </tr>
                                                    ))}
                                                </tbody>
                                            </TableWrap>
                                            {totalPages > 1 && (
                                                <div className="mt-4 flex items-center justify-between">
                                                    <p className="text-xs text-gray-400 font-medium">
                                                        Menampilkan {page * pageSize + 1}–{Math.min((page + 1) * pageSize, totalCount)} dari {totalCount}
                                                    </p>
                                                    <div className="flex items-center gap-2">
                                                        <PagBtn onClick={() => setPage(p => Math.max(0, p - 1))} disabled={page === 0}>
                                                            <ChevronLeft className="h-3 w-3" /> Prev
                                                        </PagBtn>
                                                        <span className="text-xs font-semibold text-gray-400 tabular-nums">{page + 1} / {totalPages}</span>
                                                        <PagBtn onClick={() => setPage(p => p + 1)} disabled={page >= totalPages - 1}>
                                                            Next <ChevronRight className="h-3 w-3" />
                                                        </PagBtn>
                                                    </div>
                                                </div>
                                            )}
                                        </>)}
                        </div>
                    </Card>
                )}

                {/* ── TAB 2: Per DUDI ──────────────────────────────────── */}
                {activeTab === 'per-dudi' && (
                    <Card>
                        <CardHead
                            title="Rekap per DUDI / Perusahaan"
                            desc={`${dudiData.filter(d => d.companyName !== '-').length} perusahaan · ${reportData?.length || 0} siswa · ${monthName} ${selectedYear}`}
                        />
                        <div className="p-5">
                            {isLoadingData
                                ? <TableSkeleton columnCount={9} rowCount={5} />
                                : !dudiData.length
                                    ? <NoDataForMonth
                                        monthName={monthName}
                                        year={selectedYear}
                                        className={selectedClass || undefined}
                                      />
                                    : (
                                        <TableWrap>
                                            <THead>
                                                <th className={cn(TH, 'w-12')}>No</th>
                                                <th className={TH}>DUDI / Perusahaan</th>
                                                <th className={cn(TH, 'text-center')}>Siswa</th>
                                                <th className={cn(TH, 'text-center text-emerald-500')}>H</th>
                                                <th className={cn(TH, 'text-center text-amber-500')}>T</th>
                                                <th className={cn(TH, 'text-center text-yellow-500')}>S</th>
                                                <th className={cn(TH, 'text-center text-blue-500')}>I</th>
                                                <th className={cn(TH, 'text-center text-red-500')}>A</th>
                                                <th className={cn(TH, 'text-center')}>% Rata-rata</th>
                                            </THead>
                                            <tbody>
                                                {dudiData.map((d, i) => {
                                                    const avgPct = d.totalDays > 0
                                                        ? Math.round(((d.hadir + d.terlambat) / d.totalDays) * 100) : 0
                                                    return (
                                                        <tr key={d.companyName}
                                                            className={cn(
                                                                'border-b border-gray-50 dark:border-white/[0.04] last:border-0 transition-colors',
                                                                d.companyName === '-'
                                                                    ? 'bg-gray-50/50 dark:bg-white/[0.01] hover:bg-gray-50 dark:hover:bg-white/[0.02]'
                                                                    : 'hover:bg-blue-50/40 dark:hover:bg-white/[0.025]'
                                                            )}>
                                                            <td className={cn(TD, 'text-gray-300 dark:text-gray-600 font-mono text-xs')}>{i + 1}</td>
                                                            <td className={TD}>
                                                                <div className="flex items-center gap-3">
                                                                    <div className={cn(
                                                                        'flex-shrink-0 w-8 h-8 rounded-xl flex items-center justify-center border',
                                                                        d.companyName === '-'
                                                                            ? 'bg-gray-100 dark:bg-white/[0.04] border-gray-200 dark:border-white/10'
                                                                            : 'bg-gray-100 dark:bg-white/[0.07] border-gray-200 dark:border-white/10'
                                                                    )}>
                                                                        <Building2 className={cn('h-4 w-4', d.companyName === '-' ? 'text-gray-300' : 'text-gray-400')} />
                                                                    </div>
                                                                    <span className={cn(
                                                                        'font-bold text-sm',
                                                                        d.companyName === '-'
                                                                            ? 'text-gray-400 dark:text-gray-500 italic'
                                                                            : 'text-gray-900 dark:text-white'
                                                                    )}>
                                                                        {d.companyName === '-' ? 'Belum ada DUDI' : d.companyName}
                                                                    </span>
                                                                </div>
                                                            </td>
                                                            <td className={cn(TD, 'text-center')}>
                                                                <span className="inline-flex items-center justify-center w-7 h-7 rounded-lg text-xs font-extrabold
                                                                    bg-gray-100 dark:bg-white/[0.07] text-gray-500 dark:text-gray-300">
                                                                    {d.studentCount}
                                                                </span>
                                                            </td>
                                                            <td className={cn(TD, 'text-center font-extrabold text-emerald-500 tabular-nums')}>{d.hadir}</td>
                                                            <td className={cn(TD, 'text-center font-extrabold text-amber-500 tabular-nums')}>{d.terlambat}</td>
                                                            <td className={cn(TD, 'text-center font-extrabold text-yellow-500 tabular-nums')}>{d.sakit}</td>
                                                            <td className={cn(TD, 'text-center font-extrabold text-blue-500 tabular-nums')}>{d.izin}</td>
                                                            <td className={cn(TD, 'text-center font-extrabold text-red-500 tabular-nums')}>{d.alpa}</td>
                                                            <td className={cn(TD, 'text-center')}><PctBadge pct={avgPct} /></td>
                                                        </tr>
                                                    )
                                                })}
                                            </tbody>
                                        </TableWrap>
                                    )}
                        </div>
                    </Card>
                )}

                {/* ── TAB 3: Rekap Tahunan ─────────────────────────────── */}
                {activeTab === 'rekap-tahunan' && (
                    <Card>
                        <CardHead title="Rekap Tahunan" desc="Akumulasi kehadiran seluruh tahun per siswa." />
                        <div className="p-5 space-y-5">
                            <div className="flex flex-wrap gap-3 items-end">
                                <div className="w-28">
                                    <label className="text-[10px] font-bold uppercase tracking-widest text-gray-400 dark:text-gray-500 mb-1.5 block">Tahun</label>
                                    <Select value={yearlySelectedYear.toString()} onValueChange={v => { setYearlySelectedYear(parseInt(v)); setYearlyPage(0) }}>
                                        <SelectTrigger className={SEL}><SelectValue /></SelectTrigger>
                                        <SelectContent>
                                            {YEARS.map(y => <SelectItem key={y} value={y.toString()}>{y}</SelectItem>)}
                                        </SelectContent>
                                    </Select>
                                </div>
                                <div className="min-w-[11rem]">
                                    <label className="text-[10px] font-bold uppercase tracking-widest text-gray-400 dark:text-gray-500 mb-1.5 block">Kelas</label>
                                    <Popover open={openYearlyClassFilter} onOpenChange={setOpenYearlyClassFilter}>
                                        <PopoverTrigger asChild>
                                            <button className="flex items-center justify-between w-full h-9 px-3 rounded-xl text-sm font-semibold
                                                border border-gray-200 dark:border-white/10
                                                bg-white dark:bg-white/[0.04] text-gray-700 dark:text-gray-300
                                                hover:bg-gray-50 dark:hover:bg-white/10 transition-all duration-150">
                                                {yearlySelectedClass || 'Semua Kelas'}
                                                <ChevronLeft className="h-4 w-4 opacity-40 -rotate-90 ml-2 shrink-0" />
                                            </button>
                                        </PopoverTrigger>
                                        <PopoverContent className="w-48 p-0 rounded-xl bg-white dark:bg-[#1a1a2e] border-gray-200 dark:border-white/10 shadow-xl">
                                            <Command>
                                                <CommandInput placeholder="Cari kelas..." className="h-9" />
                                                <CommandList>
                                                    <CommandEmpty className="py-4 text-center text-xs text-gray-400">Kelas tidak ditemukan.</CommandEmpty>
                                                    <CommandGroup>
                                                        <CommandItem value="all" onSelect={() => { setYearlySelectedClass(''); setYearlyPage(0); setOpenYearlyClassFilter(false) }}>
                                                            <svg className={cn('mr-2 h-4 w-4', !yearlySelectedClass ? 'text-blue-500' : 'opacity-0')} viewBox="0 0 12 12" fill="none">
                                                                <path d="M2 6l3 3 5-5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                                                            </svg>
                                                            Semua Kelas
                                                        </CommandItem>
                                                        {classList.map(cls => (
                                                            <CommandItem key={cls} value={cls}
                                                                onSelect={() => { setYearlySelectedClass(cls); setYearlyPage(0); setOpenYearlyClassFilter(false) }}>
                                                                <svg className={cn('mr-2 h-4 w-4', yearlySelectedClass === cls ? 'text-blue-500' : 'opacity-0')} viewBox="0 0 12 12" fill="none">
                                                                    <path d="M2 6l3 3 5-5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                                                                </svg>
                                                                {cls}
                                                            </CommandItem>
                                                        ))}
                                                    </CommandGroup>
                                                </CommandList>
                                            </Command>
                                        </PopoverContent>
                                    </Popover>
                                </div>
                                {yearlyData && (
                                    <span className="flex items-center gap-1.5 h-9 px-3 rounded-xl text-xs font-bold
                                        border border-gray-200 dark:border-white/10
                                        text-gray-500 dark:text-gray-400 bg-white dark:bg-white/5">
                                        <FileText className="h-3 w-3" /> {yearlyData.length} siswa
                                    </span>
                                )}
                            </div>

                            {isYearlyLoading ? <TableSkeleton columnCount={10} rowCount={5} />
                                : !yearlyData?.length
                                    ? <EmptyState title="Tidak ada data" description={`Tidak ada data kehadiran untuk tahun ${yearlySelectedYear}${yearlySelectedClass ? ` · kelas ${yearlySelectedClass}` : ''}.`} />
                                    : (<>
                                        <TableWrap>
                                            <THead>
                                                <th className={cn(TH, 'w-12')}>No</th>
                                                <th className={TH}>Nama Siswa</th>
                                                <th className={cn(TH, 'hidden sm:table-cell')}>Kelas</th>
                                                <th className={cn(TH, 'hidden md:table-cell')}>DUDI</th>
                                                <StatTH />
                                            </THead>
                                            <tbody>
                                                {yearlyPaginatedData.map((s, i) => (
                                                    <tr key={s.studentId}
                                                        className="border-b border-gray-50 dark:border-white/[0.04] last:border-0
                                                            hover:bg-blue-50/40 dark:hover:bg-white/[0.025] transition-colors">
                                                        <td className={cn(TD, 'text-gray-300 dark:text-gray-600 font-mono text-xs')}>{yearlyPage * yearlyPageSize + i + 1}</td>
                                                        <td className={cn(TD, 'font-bold text-gray-900 dark:text-white')}>{s.studentName}</td>
                                                        <td className={cn(TD, 'hidden sm:table-cell')}><ClassPill name={s.className} /></td>
                                                        <td className={cn(TD, 'hidden md:table-cell text-xs text-gray-400 dark:text-gray-500')}>{s.companyName}</td>
                                                        <StatCells stats={s.stats} />
                                                    </tr>
                                                ))}
                                            </tbody>
                                        </TableWrap>
                                        {yearlyTotalPages > 1 && (
                                            <div className="flex items-center justify-between">
                                                <p className="text-xs text-gray-400 font-medium">
                                                    Menampilkan {yearlyPage * yearlyPageSize + 1}–{Math.min((yearlyPage + 1) * yearlyPageSize, yearlyData.length)} dari {yearlyData.length}
                                                </p>
                                                <div className="flex items-center gap-2">
                                                    <PagBtn onClick={() => setYearlyPage(p => Math.max(0, p - 1))} disabled={yearlyPage === 0}>
                                                        <ChevronLeft className="h-3 w-3" /> Prev
                                                    </PagBtn>
                                                    <span className="text-xs font-semibold text-gray-400 tabular-nums">{yearlyPage + 1} / {yearlyTotalPages}</span>
                                                    <PagBtn onClick={() => setYearlyPage(p => p + 1)} disabled={yearlyPage >= yearlyTotalPages - 1}>
                                                        Next <ChevronRight className="h-3 w-3" />
                                                    </PagBtn>
                                                </div>
                                            </div>
                                        )}
                                    </>)}
                        </div>
                    </Card>
                )}
            </div>
        </div>
    )
}