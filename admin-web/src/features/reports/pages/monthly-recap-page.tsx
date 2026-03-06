
import { useState, useMemo, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { format } from 'date-fns'
import { id } from 'date-fns/locale'

import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { getMonthlyAttendanceReport, getClassList, getYearlyAttendanceReport } from '../services/report-service'
import { Loader2, Download, ChevronLeft, ChevronRight, FileText, PlusCircle, Check, FileSpreadsheet, Building2, CalendarRange } from 'lucide-react'
import { toast } from 'sonner'
import { TableSkeleton } from '@/components/ui/table-skeleton'
import { EmptyState } from '@/components/ui/empty-state'
import { exportToExcel } from '@/lib/export'
import {
    Command,
    CommandEmpty,
    CommandGroup,
    CommandInput,
    CommandItem,
    CommandList,
    CommandSeparator,
} from '@/components/ui/command'
import {
    Popover,
    PopoverContent,
    PopoverTrigger,
} from '@/components/ui/popover'
import { cn } from '@/lib/utils'

export function MonthlyRecapPage() {
    const [activeTab, setActiveTab] = useState('per-kelas')
    const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth())
    const [selectedYear, setSelectedYear] = useState(new Date().getFullYear())
    const [selectedClasses, setSelectedClasses] = useState<string[]>([])
    const [openClassFilter, setOpenClassFilter] = useState(false)
    const [isGenerating, setIsGenerating] = useState(false)
    const [page, setPage] = useState(0)
    const pageSize = 45

    // Yearly tab state
    const [yearlySelectedYear, setYearlySelectedYear] = useState(new Date().getFullYear())
    const [yearlySelectedClass, setYearlySelectedClass] = useState('')
    const [yearlyPage, setYearlyPage] = useState(0)
    const [openYearlyClassFilter, setOpenYearlyClassFilter] = useState(false)

    // Derived state for query
    const monthName = format(new Date(selectedYear, selectedMonth), 'MMMM', { locale: id })

    const { data: classList = [] } = useQuery({
        queryKey: ['class-list'],
        queryFn: getClassList,
        staleTime: 1000 * 60 * 10,
    })

    // Auto-select first class when list loads
    useEffect(() => {
        if (classList.length > 0 && selectedClasses.length === 0) {
            setSelectedClasses([classList[0]])
        }
    }, [classList]) // eslint-disable-line react-hooks/exhaustive-deps

    const { data: reportData, isLoading, isError } = useQuery({
        queryKey: ['attendance-report', selectedMonth, selectedYear, [...selectedClasses].sort()],
        queryFn: async () => {
            const results = await Promise.all(
                selectedClasses.map(cls => getMonthlyAttendanceReport(selectedMonth, selectedYear, cls))
            )
            return results.flat()
        },
        enabled: selectedClasses.length > 0,
        staleTime: 1000 * 60 * 5,
    })

    // Pagination
    const totalCount = reportData?.length || 0
    const totalPages = Math.ceil(totalCount / pageSize)
    const paginatedData = reportData?.slice(page * pageSize, (page + 1) * pageSize) || []

    // Per DUDI grouping — aggregate students by company
    const dudiData = useMemo(() => {
        if (!reportData) return []
        const map = new Map<string, {
            companyName: string
            studentCount: number
            hadir: number
            terlambat: number
            sakit: number
            izin: number
            alpa: number
            totalDays: number
        }>()
        reportData.forEach(item => {
            const key = item.companyName || '-'
            const existing = map.get(key)
            if (existing) {
                existing.studentCount++
                existing.hadir += item.stats.hadir
                existing.terlambat += item.stats.terlambat
                existing.sakit += item.stats.sakit
                existing.izin += item.stats.izin
                existing.alpa += item.stats.alpa
                existing.totalDays += item.stats.totalDays
            } else {
                map.set(key, {
                    companyName: key,
                    studentCount: 1,
                    hadir: item.stats.hadir,
                    terlambat: item.stats.terlambat,
                    sakit: item.stats.sakit,
                    izin: item.stats.izin,
                    alpa: item.stats.alpa,
                    totalDays: item.stats.totalDays,
                })
            }
        })
        return Array.from(map.values()).sort((a, b) => a.companyName.localeCompare(b.companyName))
    }, [reportData])

    const handleDownloadDudiExcel = async () => {
        if (!dudiData.length) { toast.error('Tidak ada data untuk diunduh'); return }
        await exportToExcel({
            headers: ['No', 'DUDI/Perusahaan', 'Jml Siswa', 'H', 'T', 'S', 'I', 'A', '% Rata-rata'],
            rows: dudiData.map((d, i) => {
                const avgPct = d.totalDays > 0
                    ? Math.round(((d.hadir + d.terlambat) / d.totalDays) * 100)
                    : 0
                return [i + 1, d.companyName, d.studentCount, d.hadir, d.terlambat, d.sakit, d.izin, d.alpa, `${avgPct}%`]
            }),
            filename: `Rekap_DUDI_${monthName}_${selectedYear}`,
        })
        toast.success('File Excel berhasil diunduh')
    }

    // Yearly report query
    const { data: yearlyData, isLoading: isYearlyLoading } = useQuery({
        queryKey: ['yearly-report', yearlySelectedYear, yearlySelectedClass],
        queryFn: () => getYearlyAttendanceReport(yearlySelectedYear, yearlySelectedClass || undefined),
        staleTime: 1000 * 60 * 10,
    })

    const yearlyPageSize = 45
    const yearlyTotalPages = Math.ceil((yearlyData?.length || 0) / yearlyPageSize)
    const yearlyPaginatedData = yearlyData?.slice(yearlyPage * yearlyPageSize, (yearlyPage + 1) * yearlyPageSize) || []

    const handleDownloadYearlyExcel = async () => {
        if (!yearlyData?.length) { toast.error('Tidak ada data untuk diunduh'); return }
        const classLabel = yearlySelectedClass || 'Semua Kelas'
        await exportToExcel({
            headers: ['No', 'Nama Siswa', 'Kelas', 'DUDI', 'H', 'T', 'S', 'I', 'A', 'Total Hari', '%'],
            rows: yearlyData.map((s, i) => [
                i + 1, s.studentName, s.className, s.companyName,
                s.stats.hadir, s.stats.terlambat, s.stats.sakit, s.stats.izin, s.stats.alpa,
                s.stats.totalDays, `${s.stats.percentage}%`
            ]),
            filename: `Rekap_Tahunan_${classLabel}_${yearlySelectedYear}`,
        })
        toast.success('File Excel berhasil diunduh')
    }

    // Reset page when filters change
    const handleFilterChange = () => {
        setPage(0)
    }

    const handleDownloadPDF = async () => {
        if (!reportData || reportData.length === 0) {
            toast.error('Tidak ada data untuk diunduh')
            return
        }

        setIsGenerating(true)
        try {
            const [{ default: jsPDF }, { default: autoTable }] = await Promise.all([
                import('jspdf'),
                import('jspdf-autotable'),
            ])
            const doc = new jsPDF()

            // Header
            doc.setFontSize(18)
            doc.text('NAMA SMK ANDA', 105, 15, { align: 'center' })
            doc.setFontSize(14)
            doc.text('LAPORAN KEHADIRAN SISWA PKL', 105, 22, { align: 'center' })
            doc.setFontSize(12)
            doc.text(`Periode: ${monthName} ${selectedYear}`, 105, 28, { align: 'center' })

            if (selectedClasses.length > 0) {
                doc.text(`Kelas: ${selectedClasses.join(', ')}`, 14, 35)
            }

            // Show total working days
            const totalDays = reportData[0]?.stats.totalDays || 0
            const totalDaysY = selectedClasses.length > 0 ? 42 : 35
            doc.text(`Total Hari Kerja: ${totalDays} hari`, 14, totalDaysY)

            // Table
            const tableColumn = ["No", "Nama Siswa", "Kelas", "DUDI", "H", "T", "S", "I", "A", "%"]
            const tableRows: any[] = []

            reportData.forEach((student, index) => {
                const rowData = [
                    index + 1,
                    student.studentName,
                    student.className,
                    student.companyName,
                    student.stats.hadir,
                    student.stats.terlambat,
                    student.stats.sakit,
                    student.stats.izin,
                    student.stats.alpa,
                    `${student.stats.percentage}%`
                ]
                tableRows.push(rowData)
            })

            autoTable(doc, {
                head: [tableColumn],
                body: tableRows,
                startY: selectedClasses.length > 0 ? 47 : 42,
                theme: 'grid',
                headStyles: { fillColor: [16, 185, 129] }, // Emerald-500
                styles: { fontSize: 8, cellPadding: 2 },
                columnStyles: {
                    0: { cellWidth: 10 }, // No
                    1: { cellWidth: 35 }, // Nama
                    2: { cellWidth: 18 }, // Kelas
                    3: { cellWidth: 35 }, // DUDI
                    4: { cellWidth: 10, halign: 'center' }, // H
                    5: { cellWidth: 10, halign: 'center' }, // T
                    6: { cellWidth: 10, halign: 'center' }, // S
                    7: { cellWidth: 10, halign: 'center' }, // I
                    8: { cellWidth: 10, halign: 'center' }, // A
                    9: { cellWidth: 15, halign: 'center' }, // %
                }
            })

            // Footer / Signatures
            // @ts-ignore
            const finalY = doc.lastAutoTable.finalY || 150

            // Avoid page break inside signatures
            if (finalY > 250) {
                doc.addPage()
                const newY = 20
                doc.text(`Kota, ${format(new Date(), 'd MMMM yyyy', { locale: id })}`, 140, newY)
                doc.text("Mengetahui,", 140, newY + 7)
                doc.text("Kepala Program Keahlian", 140, newY + 14)
                doc.text("( ..................................... )", 140, newY + 40)
            } else {
                const signatureY = finalY + 15
                doc.text(`Kota, ${format(new Date(), 'd MMMM yyyy', { locale: id })}`, 140, signatureY)
                doc.text("Mengetahui,", 140, signatureY + 7)
                doc.text("Kepala Program Keahlian", 140, signatureY + 14)
                doc.text("( ..................................... )", 140, signatureY + 40)
            }

            const classLabel = selectedClasses.join('_') || 'Semua'
            doc.save(`Laporan_Absensi_${classLabel}_${monthName}_${selectedYear}.pdf`)
            toast.success('Laporan berhasil diunduh')
        } catch (error) {
            console.error(error)
            toast.error('Gagal membuat PDF')
        } finally {
            setIsGenerating(false)
        }
    }

    const handleDownloadExcel = () => {
        if (!reportData || reportData.length === 0) {
            toast.error('Tidak ada data untuk diunduh')
            return
        }
        const classLabel = selectedClasses.join('_') || 'Semua'
        exportToExcel({
            headers: ['No', 'Nama Siswa', 'Kelas', 'DUDI', 'Hadir', 'Terlambat', 'Sakit', 'Izin', 'Alpa', '% Kehadiran'],
            rows: reportData.map((s, i) => [
                i + 1,
                s.studentName,
                s.className,
                s.companyName,
                s.stats.hadir,
                s.stats.terlambat,
                s.stats.sakit,
                s.stats.izin,
                s.stats.alpa,
                `${s.stats.percentage}%`,
            ]),
            filename: `Laporan_Absensi_${classLabel}_${monthName}_${selectedYear}`,
        })
        toast.success('File Excel berhasil diunduh')
    }

    const months = [
        "Januari", "Februari", "Maret", "April", "Mei", "Juni",
        "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ]
    const years = [2024, 2025, 2026]

    // Helper for percentage badge
    const getPercentageBadge = (percentage: number) => {
        if (percentage >= 90) {
            return <Badge className="bg-green-100 text-green-700 border-green-200">{percentage}%</Badge>
        } else if (percentage >= 75) {
            return <Badge className="bg-yellow-100 text-yellow-700 border-yellow-200">{percentage}%</Badge>
        } else {
            return <Badge variant="destructive">{percentage}%</Badge>
        }
    }

    return (
        <div className="space-y-6">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Laporan Kehadiran</h1>
                    <p className="text-muted-foreground">
                        Rekap absensi bulanan per kelas atau per DUDI/Perusahaan.
                    </p>
                </div>
                {activeTab === 'per-kelas' && (
                    <div className="flex gap-2">
                        <Button variant="outline" onClick={handleDownloadExcel} disabled={isLoading || !reportData?.length}>
                            <FileSpreadsheet className="mr-2 h-4 w-4" />
                            Excel
                        </Button>
                        <Button onClick={handleDownloadPDF} disabled={isGenerating || isLoading || !reportData?.length}>
                            {isGenerating ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    Generating...
                                </>
                            ) : (
                                <>
                                    <Download className="mr-2 h-4 w-4" />
                                    Download PDF
                                </>
                            )}
                        </Button>
                    </div>
                )}
                {activeTab === 'per-dudi' && (
                    <Button variant="outline" onClick={handleDownloadDudiExcel} disabled={isLoading || !dudiData.length}>
                        <FileSpreadsheet className="mr-2 h-4 w-4" />
                        Excel DUDI
                    </Button>
                )}
                {activeTab === 'rekap-tahunan' && (
                    <Button variant="outline" onClick={handleDownloadYearlyExcel} disabled={isYearlyLoading || !yearlyData?.length}>
                        <FileSpreadsheet className="mr-2 h-4 w-4" />
                        Excel Tahunan
                    </Button>
                )}
            </div>

            <Card className={activeTab === 'rekap-tahunan' ? 'hidden' : ''}>
                <CardHeader>
                    <CardTitle>Filter Laporan</CardTitle>
                    <CardDescription>Pilih periode dan kelas untuk menampilkan data.</CardDescription>
                </CardHeader>
                <CardContent>
                    <div className="flex flex-col sm:flex-row gap-4">
                        <div className="w-full sm:w-[200px]">
                            <label className="text-sm font-medium mb-2 block">Bulan</label>
                            <Select
                                value={selectedMonth.toString()}
                                onValueChange={(v) => {
                                    setSelectedMonth(parseInt(v))
                                    handleFilterChange()
                                }}
                            >
                                <SelectTrigger>
                                    <SelectValue placeholder="Pilih Bulan" />
                                </SelectTrigger>
                                <SelectContent>
                                    {months.map((m, i) => (
                                        <SelectItem key={i} value={i.toString()}>{m}</SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>

                        <div className="w-full sm:w-[150px]">
                            <label className="text-sm font-medium mb-2 block">Tahun</label>
                            <Select
                                value={selectedYear.toString()}
                                onValueChange={(v) => {
                                    setSelectedYear(parseInt(v))
                                    handleFilterChange()
                                }}
                            >
                                <SelectTrigger>
                                    <SelectValue placeholder="Pilih Tahun" />
                                </SelectTrigger>
                                <SelectContent>
                                    {years.map((y) => (
                                        <SelectItem key={y} value={y.toString()}>{y}</SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>

                        <div className="w-full sm:w-auto">
                            <label className="text-sm font-medium mb-2 block">Kelas</label>
                            <Popover open={openClassFilter} onOpenChange={setOpenClassFilter}>
                                <PopoverTrigger asChild>
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        className="h-9 border-dashed"
                                    >
                                        <PlusCircle className="mr-2 h-4 w-4" />
                                        Kelas
                                        {selectedClasses.length > 0 && (
                                            <>
                                                <Separator orientation="vertical" className="mx-2 h-4" />
                                                <div className="hidden space-x-1 lg:flex">
                                                    {selectedClasses.length > 2 ? (
                                                        <Badge variant="secondary" className="rounded-sm px-1 font-normal">
                                                            {selectedClasses.length} dipilih
                                                        </Badge>
                                                    ) : (
                                                        selectedClasses.map((cls) => (
                                                            <Badge variant="secondary" key={cls} className="rounded-sm px-1 font-normal">
                                                                {cls}
                                                            </Badge>
                                                        ))
                                                    )}
                                                </div>
                                                <Badge variant="secondary" className="rounded-sm px-1 font-normal lg:hidden">
                                                    {selectedClasses.length}
                                                </Badge>
                                            </>
                                        )}
                                    </Button>
                                </PopoverTrigger>
                                <PopoverContent className="w-[200px] p-0" align="start">
                                    <Command>
                                        <CommandInput placeholder="Cari kelas..." />
                                        <CommandList>
                                            <CommandEmpty>Kelas tidak ditemukan.</CommandEmpty>
                                            <CommandGroup>
                                                {classList.map((cls) => {
                                                    const isSelected = selectedClasses.includes(cls)
                                                    return (
                                                        <CommandItem
                                                            key={cls}
                                                            value={cls}
                                                            onSelect={() => {
                                                                const next = isSelected
                                                                    ? selectedClasses.filter(c => c !== cls)
                                                                    : [...selectedClasses, cls]
                                                                setSelectedClasses(next)
                                                                handleFilterChange()
                                                            }}
                                                        >
                                                            <div
                                                                className={cn(
                                                                    "mr-2 flex h-4 w-4 items-center justify-center rounded-sm border border-primary",
                                                                    isSelected
                                                                        ? "bg-primary text-primary-foreground"
                                                                        : "opacity-50 [&_svg]:invisible"
                                                                )}
                                                            >
                                                                <Check className="h-4 w-4" />
                                                            </div>
                                                            {cls}
                                                        </CommandItem>
                                                    )
                                                })}
                                            </CommandGroup>
                                            {selectedClasses.length > 0 && (
                                                <>
                                                    <CommandSeparator />
                                                    <CommandGroup>
                                                        <CommandItem
                                                            onSelect={() => {
                                                                setSelectedClasses([])
                                                                handleFilterChange()
                                                            }}
                                                            className="justify-center text-center"
                                                        >
                                                            Hapus filter
                                                        </CommandItem>
                                                    </CommandGroup>
                                                </>
                                            )}
                                        </CommandList>
                                    </Command>
                                </PopoverContent>
                            </Popover>
                        </div>
                    </div>
                </CardContent>
            </Card>

            <Tabs value={activeTab} onValueChange={setActiveTab}>
                <TabsList>
                    <TabsTrigger value="per-kelas">Per Kelas</TabsTrigger>
                    <TabsTrigger value="per-dudi">
                        <Building2 className="mr-1.5 h-3.5 w-3.5" />
                        Per DUDI
                    </TabsTrigger>
                    <TabsTrigger value="rekap-tahunan">
                        <CalendarRange className="mr-1.5 h-3.5 w-3.5" />
                        Rekap Tahunan
                    </TabsTrigger>
                </TabsList>

                {/* TAB 1: Per Kelas */}
                <TabsContent value="per-kelas" className="mt-4">
                    <Card>
                        <CardHeader>
                            <div className="flex items-center justify-between">
                                <div>
                                    <CardTitle>Preview Data</CardTitle>
                                    <CardDescription>
                                        {reportData?.length || 0} siswa ditemukan untuk periode {monthName} {selectedYear}
                                        {reportData && reportData.length > 0 && (
                                            <> · Total Hari Kerja: <strong>{reportData[0]?.stats.totalDays || 0}</strong> hari</>
                                        )}
                                    </CardDescription>
                                </div>
                                {reportData && reportData.length > 0 && (
                                    <Badge variant="outline" className="text-sm">
                                        <FileText className="mr-1 h-3 w-3" />
                                        {totalCount} Total
                                    </Badge>
                                )}
                            </div>
                        </CardHeader>
                        <CardContent>
                            {isLoading ? (
                                <TableSkeleton columnCount={10} rowCount={5} />
                            ) : isError ? (
                                <EmptyState
                                    title="Gagal memuat data"
                                    description="Terjadi kesalahan saat memuat data. Silakan coba lagi."
                                />
                            ) : !reportData || reportData.length === 0 ? (
                                <EmptyState
                                    title="Tidak ada data"
                                    description="Tidak ada data absensi untuk periode ini."
                                />
                            ) : (
                                <>
                                    <div className="rounded-md border">
                                        <Table>
                                            <TableHeader>
                                                <TableRow>
                                                    <TableHead className="w-[50px]">No</TableHead>
                                                    <TableHead>Nama Siswa</TableHead>
                                                    <TableHead className="hidden sm:table-cell">Kelas</TableHead>
                                                    <TableHead className="hidden md:table-cell">DUDI</TableHead>
                                                    <TableHead className="text-center w-[50px]">H</TableHead>
                                                    <TableHead className="text-center w-[50px]">T</TableHead>
                                                    <TableHead className="text-center w-[50px]">S</TableHead>
                                                    <TableHead className="text-center w-[50px]">I</TableHead>
                                                    <TableHead className="text-center w-[50px]">A</TableHead>
                                                    <TableHead className="text-center">% Keh.</TableHead>
                                                </TableRow>
                                            </TableHeader>
                                            <TableBody>
                                                {paginatedData.map((student, index) => (
                                                    <TableRow key={student.studentId}>
                                                        <TableCell className="font-medium">{page * pageSize + index + 1}</TableCell>
                                                        <TableCell className="font-medium">{student.studentName}</TableCell>
                                                        <TableCell className="hidden sm:table-cell">
                                                            <Badge variant="outline">{student.className}</Badge>
                                                        </TableCell>
                                                        <TableCell className="hidden md:table-cell text-muted-foreground">
                                                            {student.companyName}
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            <span className="text-green-600 font-medium">{student.stats.hadir}</span>
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            <span className="text-orange-500 font-medium">{student.stats.terlambat}</span>
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            <span className="text-yellow-600 font-medium">{student.stats.sakit}</span>
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            <span className="text-blue-600 font-medium">{student.stats.izin}</span>
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            <span className="text-red-600 font-medium">{student.stats.alpa}</span>
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            {getPercentageBadge(student.stats.percentage)}
                                                        </TableCell>
                                                    </TableRow>
                                                ))}
                                            </TableBody>
                                        </Table>
                                    </div>

                                    {/* Pagination */}
                                    {totalPages > 1 && (
                                        <div className="mt-4 flex items-center justify-end space-x-2">
                                            <Button
                                                variant="outline"
                                                size="sm"
                                                onClick={() => setPage((p) => Math.max(0, p - 1))}
                                                disabled={page === 0}
                                            >
                                                <ChevronLeft className="h-4 w-4" />
                                                Previous
                                            </Button>
                                            <div className="text-sm text-muted-foreground">
                                                Page {page + 1} of {totalPages}
                                            </div>
                                            <Button
                                                variant="outline"
                                                size="sm"
                                                onClick={() => setPage((p) => p + 1)}
                                                disabled={page >= totalPages - 1}
                                            >
                                                Next
                                                <ChevronRight className="h-4 w-4" />
                                            </Button>
                                        </div>
                                    )}
                                </>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* TAB 2: Per DUDI */}
                <TabsContent value="per-dudi" className="mt-4">
                    <Card>
                        <CardHeader>
                            <div className="flex items-center justify-between">
                                <div>
                                    <CardTitle>Rekap per DUDI/Perusahaan</CardTitle>
                                    <CardDescription>
                                        {dudiData.length} DUDI · {reportData?.length || 0} siswa · {monthName} {selectedYear}
                                    </CardDescription>
                                </div>
                            </div>
                        </CardHeader>
                        <CardContent>
                            {isLoading ? (
                                <TableSkeleton columnCount={8} rowCount={5} />
                            ) : dudiData.length === 0 ? (
                                <EmptyState title="Tidak ada data" description="Pilih kelas terlebih dahulu untuk melihat data per DUDI." />
                            ) : (
                                <div className="rounded-md border">
                                    <Table>
                                        <TableHeader>
                                            <TableRow>
                                                <TableHead className="w-[50px]">No</TableHead>
                                                <TableHead>DUDI / Perusahaan</TableHead>
                                                <TableHead className="text-center">Siswa</TableHead>
                                                <TableHead className="text-center">H</TableHead>
                                                <TableHead className="text-center">T</TableHead>
                                                <TableHead className="text-center">S</TableHead>
                                                <TableHead className="text-center">I</TableHead>
                                                <TableHead className="text-center">A</TableHead>
                                                <TableHead className="text-center">% Rata-rata</TableHead>
                                            </TableRow>
                                        </TableHeader>
                                        <TableBody>
                                            {dudiData.map((dudi, i) => {
                                                const avgPct = dudi.totalDays > 0
                                                    ? Math.round(((dudi.hadir + dudi.terlambat) / dudi.totalDays) * 100)
                                                    : 0
                                                return (
                                                    <TableRow key={dudi.companyName}>
                                                        <TableCell className="font-medium">{i + 1}</TableCell>
                                                        <TableCell>
                                                            <div className="flex items-center gap-2">
                                                                <Building2 className="h-4 w-4 text-muted-foreground shrink-0" />
                                                                <span className="font-medium">{dudi.companyName}</span>
                                                            </div>
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            <Badge variant="secondary">{dudi.studentCount}</Badge>
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            <span className="text-green-600 font-medium">{dudi.hadir}</span>
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            <span className="text-orange-500 font-medium">{dudi.terlambat}</span>
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            <span className="text-yellow-600 font-medium">{dudi.sakit}</span>
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            <span className="text-blue-600 font-medium">{dudi.izin}</span>
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            <span className="text-red-600 font-medium">{dudi.alpa}</span>
                                                        </TableCell>
                                                        <TableCell className="text-center">
                                                            {getPercentageBadge(avgPct)}
                                                        </TableCell>
                                                    </TableRow>
                                                )
                                            })}
                                        </TableBody>
                                    </Table>
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>
                {/* TAB 3: Rekap Tahunan */}
                <TabsContent value="rekap-tahunan" className="mt-4">
                    <Card>
                        <CardHeader>
                            <CardTitle>Rekap Tahunan</CardTitle>
                            <CardDescription>Akumulasi kehadiran seluruh tahun per siswa.</CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            {/* Yearly filters */}
                            <div className="flex flex-col sm:flex-row gap-4">
                                <div className="w-full sm:w-[150px]">
                                    <label className="text-sm font-medium mb-2 block">Tahun</label>
                                    <Select
                                        value={yearlySelectedYear.toString()}
                                        onValueChange={(v) => { setYearlySelectedYear(parseInt(v)); setYearlyPage(0) }}
                                    >
                                        <SelectTrigger>
                                            <SelectValue />
                                        </SelectTrigger>
                                        <SelectContent>
                                            {years.map((y) => (
                                                <SelectItem key={y} value={y.toString()}>{y}</SelectItem>
                                            ))}
                                        </SelectContent>
                                    </Select>
                                </div>
                                <div className="w-full sm:w-[200px]">
                                    <label className="text-sm font-medium mb-2 block">Kelas</label>
                                    <Popover open={openYearlyClassFilter} onOpenChange={setOpenYearlyClassFilter}>
                                        <PopoverTrigger asChild>
                                            <Button variant="outline" role="combobox" className="w-full justify-between">
                                                {yearlySelectedClass || 'Semua Kelas'}
                                                <ChevronLeft className="ml-2 h-4 w-4 shrink-0 opacity-50 rotate-[-90deg]" />
                                            </Button>
                                        </PopoverTrigger>
                                        <PopoverContent className="w-[200px] p-0">
                                            <Command>
                                                <CommandInput placeholder="Cari kelas..." />
                                                <CommandList>
                                                    <CommandEmpty>Kelas tidak ditemukan.</CommandEmpty>
                                                    <CommandGroup>
                                                        <CommandItem value="all" onSelect={() => { setYearlySelectedClass(''); setYearlyPage(0); setOpenYearlyClassFilter(false) }}>
                                                            <Check className={cn('mr-2 h-4 w-4', !yearlySelectedClass ? 'opacity-100' : 'opacity-0')} />
                                                            Semua Kelas
                                                        </CommandItem>
                                                        {classList.map((cls) => (
                                                            <CommandItem key={cls} value={cls} onSelect={() => { setYearlySelectedClass(cls); setYearlyPage(0); setOpenYearlyClassFilter(false) }}>
                                                                <Check className={cn('mr-2 h-4 w-4', yearlySelectedClass === cls ? 'opacity-100' : 'opacity-0')} />
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
                                    <div className="flex items-end">
                                        <Badge variant="outline" className="h-9 px-3 text-sm">
                                            <FileText className="mr-1 h-3 w-3" />
                                            {yearlyData.length} siswa
                                        </Badge>
                                    </div>
                                )}
                            </div>

                            {isYearlyLoading ? (
                                <TableSkeleton columnCount={10} rowCount={5} />
                            ) : !yearlyData || yearlyData.length === 0 ? (
                                <EmptyState title="Tidak ada data" description="Tidak ada data kehadiran untuk tahun ini." />
                            ) : (
                                <>
                                    <div className="rounded-md border">
                                        <Table>
                                            <TableHeader>
                                                <TableRow>
                                                    <TableHead className="w-[50px]">No</TableHead>
                                                    <TableHead>Nama Siswa</TableHead>
                                                    <TableHead className="hidden sm:table-cell">Kelas</TableHead>
                                                    <TableHead className="hidden md:table-cell">DUDI</TableHead>
                                                    <TableHead className="text-center">H</TableHead>
                                                    <TableHead className="text-center">T</TableHead>
                                                    <TableHead className="text-center">S</TableHead>
                                                    <TableHead className="text-center">I</TableHead>
                                                    <TableHead className="text-center">A</TableHead>
                                                    <TableHead className="text-center">% Keh.</TableHead>
                                                </TableRow>
                                            </TableHeader>
                                            <TableBody>
                                                {yearlyPaginatedData.map((student, index) => (
                                                    <TableRow key={student.studentId}>
                                                        <TableCell>{yearlyPage * yearlyPageSize + index + 1}</TableCell>
                                                        <TableCell className="font-medium">{student.studentName}</TableCell>
                                                        <TableCell className="hidden sm:table-cell">
                                                            <Badge variant="outline">{student.className}</Badge>
                                                        </TableCell>
                                                        <TableCell className="hidden md:table-cell text-muted-foreground">{student.companyName}</TableCell>
                                                        <TableCell className="text-center"><span className="text-green-600 font-medium">{student.stats.hadir}</span></TableCell>
                                                        <TableCell className="text-center"><span className="text-orange-500 font-medium">{student.stats.terlambat}</span></TableCell>
                                                        <TableCell className="text-center"><span className="text-yellow-600 font-medium">{student.stats.sakit}</span></TableCell>
                                                        <TableCell className="text-center"><span className="text-blue-600 font-medium">{student.stats.izin}</span></TableCell>
                                                        <TableCell className="text-center"><span className="text-red-600 font-medium">{student.stats.alpa}</span></TableCell>
                                                        <TableCell className="text-center">{getPercentageBadge(student.stats.percentage)}</TableCell>
                                                    </TableRow>
                                                ))}
                                            </TableBody>
                                        </Table>
                                    </div>
                                    {yearlyTotalPages > 1 && (
                                        <div className="mt-4 flex items-center justify-end space-x-2">
                                            <Button variant="outline" size="sm" onClick={() => setYearlyPage(p => Math.max(0, p - 1))} disabled={yearlyPage === 0}>
                                                <ChevronLeft className="h-4 w-4" /> Previous
                                            </Button>
                                            <div className="text-sm text-muted-foreground">Page {yearlyPage + 1} of {yearlyTotalPages}</div>
                                            <Button variant="outline" size="sm" onClick={() => setYearlyPage(p => p + 1)} disabled={yearlyPage >= yearlyTotalPages - 1}>
                                                Next <ChevronRight className="h-4 w-4" />
                                            </Button>
                                        </div>
                                    )}
                                </>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>
            </Tabs>
        </div>
    )
}
