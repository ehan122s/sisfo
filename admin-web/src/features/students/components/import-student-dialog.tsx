import { useState, useCallback } from 'react'
import { AuditLogService } from '@/features/audit-logs/services/audit-log-service'
import { toast } from "sonner"
import { useDropzone } from 'react-dropzone'
import Papa from 'papaparse'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table'
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Progress } from '@/components/ui/progress'
import { Upload, FileSpreadsheet, CheckCircle, XCircle, AlertCircle, Loader2, Download, ChevronDown, ChevronUp, Info } from 'lucide-react'
import type { Company } from '@/types'

interface StudentRow {
    nama: string
    nisn: string
    kelas: string
    password?: string
    company_id?: number
    phone_number?: string
    parent_phone_number?: string
    nipd?: string
    gender?: "L" | "P"
    birth_place?: string
    birth_date?: string
    nik?: string
    religion?: string
    address?: string
    father_name?: string
    mother_name?: string
}

interface ImportResult {
    success: boolean
    nisn: string
    nama: string
    error?: string
}

interface ImportStudentDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
}

export function ImportStudentDialog({ open, onOpenChange }: ImportStudentDialogProps) {
    const [parsedData, setParsedData] = useState<StudentRow[]>([])
    const [parseError, setParseError] = useState<string | null>(null)
    const [selectedCompanyId, setSelectedCompanyId] = useState<number | null>(null)
    const [importResults, setImportResults] = useState<ImportResult[] | null>(null)
    const [importProgress, setImportProgress] = useState(0)
    const [isImporting, setIsImporting] = useState(false)
    const [showFormatDetails, setShowFormatDetails] = useState(false)
    const queryClient = useQueryClient()

    // Fetch companies for dropdown
    const { data: companies = [] } = useQuery({
        queryKey: ['companies'],
        queryFn: async () => {
            const { data } = await supabase
                .from('companies')
                .select('*')
                .order('name')
            return (data ?? []) as Company[]
        },
    })

    // Import mutation (single batch)
    const importBatchMutation = useMutation({
        mutationFn: async (students: StudentRow[]) => {
            const { data: { session }, error: sessionError } = await supabase.auth.getSession()

            if (sessionError || !session) {
                throw new Error('Anda belum login atau session telah expired.')
            }

            const response = await supabase.functions.invoke('import-students', {
                body: { students },
                headers: {
                    Authorization: `Bearer ${session.access_token}`,
                },
            })

            if (response.error) {
                throw new Error(response.error.message || 'Import gagal')
            }

            return response.data as { successCount: number; failureCount: number; results: ImportResult[] }
        }
    })

    // Download Template Handler
    const handleDownloadTemplate = () => {
        const headers = "nama,nisn,kelas,password,no_hp,nipd,nik,gender,tempat_lahir,tanggal_lahir,agama,alamat,nama_ayah,nama_ibu,no_hp_ortu";
        const example = "Siswa Contoh,0012345678,X RPL 1,,08123456789,12345,3205000000000001,L,Kota Contoh,2008-01-01,Islam,Jl. Merdeka No 1,Ayah Contoh,Ibu Contoh,081987654321";
        const csvContent = `${headers}\n${example}`;

        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', 'template_import_siswa.csv');
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };

    // Dropzone handler
    const onDrop = useCallback((acceptedFiles: File[]) => {
        const file = acceptedFiles[0]
        if (!file) return

        setParseError(null)
        setImportResults(null)

        Papa.parse(file, {
            header: true,
            skipEmptyLines: true,
            complete: (results) => {
                const data = results.data as Record<string, string>[]

                const requiredColumns = ['nama', 'nisn', 'kelas']
                const headers = Object.keys(data[0] || {})
                const missingColumns = requiredColumns.filter(col => !headers.includes(col))

                if (missingColumns.length > 0) {
                    setParseError(`Kolom wajib tidak ditemukan: ${missingColumns.join(', ')}`)
                    return
                }

                const parsed: StudentRow[] = data.map(row => ({
                    nama: row.nama?.trim() || '',
                    nisn: row.nisn?.trim() || '',
                    kelas: row.kelas?.trim() || '',
                    password: row.password?.trim() || undefined,
                    company_id: selectedCompanyId || undefined,
                    phone_number: row.no_hp?.trim() || undefined,
                    parent_phone_number: row.no_hp_ortu?.trim() || undefined,
                    nipd: row.nipd?.trim() || undefined,
                    gender: (row.gender?.trim() === 'L' || row.gender?.trim() === 'P') ? row.gender.trim() as "L" | "P" : undefined,
                    birth_place: row.tempat_lahir?.trim() || undefined,
                    birth_date: row.tanggal_lahir?.trim() || undefined, // Expected format YYYY-MM-DD
                    nik: row.nik?.trim() || undefined,
                    religion: row.agama?.trim() || undefined,
                    address: row.alamat?.trim() || undefined,
                    father_name: row.nama_ayah?.trim() || undefined,
                    mother_name: row.nama_ibu?.trim() || undefined,
                })).filter(row => row.nama && row.nisn && row.kelas)

                if (parsed.length === 0) {
                    setParseError('Tidak ada data valid ditemukan dalam file')
                    return
                }

                setParsedData(parsed)
            },
            error: () => {
                setParseError('Gagal membaca file CSV')
            },
        })
    }, [selectedCompanyId])

    const { getRootProps, getInputProps, isDragActive } = useDropzone({
        onDrop,
        accept: {
            'text/csv': ['.csv'],
        },
        maxFiles: 1,
    })

    const handleCompanyChange = (value: string) => {
        const companyId = value === 'none' ? null : parseInt(value, 10)
        setSelectedCompanyId(companyId)
        if (parsedData.length > 0) {
            setParsedData(prev => prev.map(row => ({
                ...row,
                company_id: companyId || undefined,
            })))
        }
    }

    const handleImport = async () => {
        if (parsedData.length === 0) return

        setIsImporting(true)
        setImportProgress(0)
        setImportResults(null)

        const BATCH_SIZE = 20
        const totalBatches = Math.ceil(parsedData.length / BATCH_SIZE)
        let allResults: ImportResult[] = []
        let successTotal = 0
        let failureTotal = 0

        try {
            for (let i = 0; i < totalBatches; i++) {
                const start = i * BATCH_SIZE
                const end = Math.min(start + BATCH_SIZE, parsedData.length)
                const batch = parsedData.slice(start, end)

                try {
                    const result = await importBatchMutation.mutateAsync(batch)
                    allResults = [...allResults, ...result.results]
                    successTotal += result.successCount
                    failureTotal += result.failureCount
                } catch (error) {
                    console.error(`Batch ${i + 1} failed:`, error)
                    // Add failed results for this batch manually so user knows
                    const failedBatchResults = batch.map(s => ({
                        success: false,
                        nisn: s.nisn,
                        nama: s.nama,
                        error: error instanceof Error ? error.message : 'Batch failed'
                    }))
                    allResults = [...allResults, ...failedBatchResults]
                    failureTotal += batch.length
                }

                // Update progress
                const progress = Math.round(((i + 1) / totalBatches) * 100)
                setImportProgress(progress)
            }

            // Finalize
            setImportResults(allResults)
            queryClient.invalidateQueries({ queryKey: ['students'] })
            toast.success(`Import selesai. ${successTotal} berhasil, ${failureTotal} gagal.`)

            // Log audit log for whole operation
            if (successTotal > 0) {
                await AuditLogService.logAction(
                    'BULK_IMPORT_STUDENTS',
                    'profiles',
                    'multiple',
                    {
                        success_count: successTotal,
                        failure_count: failureTotal,
                        company_id: parsedData[0].company_id
                    }
                )
            }

        } catch (error) {
            console.error('Critical import error:', error)
            toast.error('Terjadi kesalahan fatal saat import')
        } finally {
            setIsImporting(false)
        }
    }

    const handleReset = () => {
        setParsedData([])
        setParseError(null)
        setImportResults(null)
        importBatchMutation.reset()
        setImportProgress(0)
        setIsImporting(false)
    }

    const handleClose = () => {
        handleReset()
        onOpenChange(false)
    }

    const successCount = importResults?.filter(r => r.success).length ?? 0
    const failureCount = importResults?.filter(r => !r.success).length ?? 0

    return (
        <Dialog open={open} onOpenChange={handleClose}>
            <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <Upload className="h-5 w-5" />
                        Import Siswa dari CSV
                    </DialogTitle>
                    <div className="pt-2">
                        <div className="flex items-start gap-3 text-sm text-muted-foreground bg-muted/50 p-3 rounded-md">
                            <Info className="h-5 w-5 shrink-0 mt-0.5 text-blue-500" />
                            <div className="space-y-1">
                                <p>Pastikan file CSV Anda menggunakan format yang benar.</p>
                                <p className="text-xs">
                                    Email otomatis: <code className="font-mono bg-background px-1 rounded">NISN@siswa.com</code>.
                                    Password default: <code className="font-mono bg-background px-1 rounded">NISN</code> (jika kosong).
                                </p>
                            </div>
                        </div>

                        <div className="mt-3 flex items-center gap-2">
                            <Button size="sm" variant="outline" onClick={handleDownloadTemplate} className="gap-2 h-8">
                                <Download className="h-3.5 w-3.5" />
                                Download Template CSV
                            </Button>

                            <Button
                                size="sm"
                                variant="ghost"
                                onClick={() => setShowFormatDetails(!showFormatDetails)}
                                className="gap-2 h-8 text-muted-foreground hover:text-foreground"
                            >
                                {showFormatDetails ? <ChevronUp className="h-3.5 w-3.5" /> : <ChevronDown className="h-3.5 w-3.5" />}
                                {showFormatDetails ? 'Sembunyikan Referensi Format' : 'Lihat Referensi Format'}
                            </Button>
                        </div>

                        {showFormatDetails && (
                            <div className="mt-3 p-3 text-xs bg-muted/30 rounded border animate-in slide-in-from-top-2">
                                <p className="font-semibold mb-1">Kolom Wajib:</p>
                                <code className="block bg-background p-1.5 rounded border mb-2 text-primary font-mono select-all">nama,nisn,kelas</code>

                                <p className="font-semibold mb-1">Kolom Opsional:</p>
                                <code className="block bg-background p-1.5 rounded border text-muted-foreground font-mono break-all select-all">
                                    password,no_hp,nipd,nik,gender,tempat_lahir,tanggal_lahir,agama,alamat,nama_ayah,nama_ibu,no_hp_ortu
                                </code>
                            </div>
                        )}
                    </div>
                </DialogHeader>

                <div className="space-y-6 py-2">
                    {/* Company Selection */}
                    {!importResults && (
                        <div className="space-y-2">
                            <label className="text-sm font-medium">DUDI (Opsional)</label>
                            <Select value={selectedCompanyId?.toString() ?? 'none'} onValueChange={handleCompanyChange}>
                                <SelectTrigger>
                                    <SelectValue placeholder="Pilih DUDI..." />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="none">Tanpa DUDI</SelectItem>
                                    {companies.map((company) => (
                                        <SelectItem key={company.id} value={company.id.toString()}>
                                            {company.name}
                                        </SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                            <p className="text-[10px] text-muted-foreground">Jika dipilih, semua siswa yang diimport akan ditempatkan di DUDI ini.</p>
                        </div>
                    )}

                    {/* Upload Zone */}
                    {!importResults && parsedData.length === 0 && (
                        <div>
                            <div
                                {...getRootProps()}
                                className={`border-2 border-dashed rounded-lg p-10 text-center cursor-pointer transition-colors ${isDragActive ? 'border-primary bg-primary/5' : 'border-muted-foreground/25 hover:border-primary/50'
                                    }`}
                            >
                                <input {...getInputProps()} />
                                <div className="bg-primary/10 w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-4">
                                    <Upload className="h-6 w-6 text-primary" />
                                </div>
                                {isDragActive ? (
                                    <p className="text-primary font-medium">Drop file CSV di sini...</p>
                                ) : (
                                    <div className="space-y-1">
                                        <p className="font-medium">Klik untuk upload atau drag & drop file CSV</p>
                                        <p className="text-sm text-muted-foreground">Hanya file .csv yang diterima</p>
                                    </div>
                                )}
                            </div>

                            {parseError && (
                                <Alert variant="destructive" className="mt-4">
                                    <AlertCircle className="h-4 w-4" />
                                    <AlertTitle>Gagal Membaca File</AlertTitle>
                                    <AlertDescription>{parseError}</AlertDescription>
                                </Alert>
                            )}
                        </div>
                    )}

                    {/* Preview Table */}
                    {parsedData.length > 0 && !importResults && (
                        <div className="space-y-4">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                    <div className="bg-green-100 p-1.5 rounded">
                                        <FileSpreadsheet className="h-4 w-4 text-green-700" />
                                    </div>
                                    <div>
                                        <h3 className="font-medium text-sm">Preview Data</h3>
                                        <p className="text-xs text-muted-foreground">{parsedData.length} siswa akan diimport</p>
                                    </div>
                                </div>
                                <Button variant="ghost" size="sm" onClick={handleReset} className="text-red-500 hover:text-red-600 hover:bg-red-50">
                                    Hapus File
                                </Button>
                            </div>

                            <div className="rounded-md border max-h-[250px] overflow-auto relative">
                                <Table>
                                    <TableHeader className="bg-muted/50 sticky top-0 z-10">
                                        <TableRow>
                                            <TableHead className="w-[50px]">No</TableHead>
                                            <TableHead>Nama</TableHead>
                                            <TableHead>NISN</TableHead>
                                            <TableHead>Kelas</TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {parsedData.slice(0, 10).map((row, index) => (
                                            <TableRow key={index}>
                                                <TableCell>{index + 1}</TableCell>
                                                <TableCell className="font-medium">{row.nama}</TableCell>
                                                <TableCell>{row.nisn}</TableCell>
                                                <TableCell>{row.kelas}</TableCell>
                                            </TableRow>
                                        ))}
                                        {parsedData.length > 10 && (
                                            <TableRow>
                                                <TableCell colSpan={4} className="text-center text-xs text-muted-foreground py-4">
                                                    ... dan {parsedData.length - 10} siswa lainnya
                                                </TableCell>
                                            </TableRow>
                                        )}
                                    </TableBody>
                                </Table>
                            </div>

                            <div className="flex justify-end pt-2">
                                <Button onClick={handleImport} disabled={isImporting} className="w-full sm:w-auto">
                                    {isImporting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                    Lanjut Import Data
                                </Button>
                            </div>
                        </div>
                    )}

                    {/* Import Progress */}
                    {isImporting && (
                        <div className="py-8 text-center space-y-4">
                            <div className="relative w-16 h-16 mx-auto">
                                <Loader2 className="w-full h-full animate-spin text-primary/20" />
                                <div className="absolute inset-0 flex items-center justify-center text-xs font-bold">
                                    {importProgress}%
                                </div>
                            </div>
                            <div>
                                <h3 className="font-medium animate-pulse">Sedang memproses data...</h3>
                                <p className="text-sm text-muted-foreground">Mohon jangan tutup jendela ini.</p>
                            </div>
                            <Progress value={importProgress} className="h-2 max-w-md mx-auto" />
                        </div>
                    )}

                    {/* Import Results */}
                    {importResults && (
                        <div className="space-y-4 animate-in fade-in zoom-in-95 duration-300">
                            <div className="flex items-center justify-between p-4 bg-muted/40 rounded-lg border">
                                <div>
                                    <h3 className="font-semibold mb-1">Proses Selesai</h3>
                                    <div className="text-sm flex gap-4">
                                        <div className="flex items-center gap-1.5 text-green-600">
                                            <CheckCircle className="h-4 w-4" />
                                            <span className="font-bold">{successCount}</span> Berhasil
                                        </div>
                                        {failureCount > 0 && (
                                            <div className="flex items-center gap-1.5 text-red-600">
                                                <XCircle className="h-4 w-4" />
                                                <span className="font-bold">{failureCount}</span> Gagal
                                            </div>
                                        )}
                                    </div>
                                </div>
                                <Button onClick={handleClose}>
                                    Tutup
                                </Button>
                            </div>

                            <div className="rounded-md border max-h-[300px] overflow-auto">
                                <Table>
                                    <TableHeader>
                                        <TableRow>
                                            <TableHead>Status</TableHead>
                                            <TableHead>Nama</TableHead>
                                            <TableHead>NISN</TableHead>
                                            <TableHead>Keterangan</TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {importResults.map((result, index) => (
                                            <TableRow key={index} className={!result.success ? "bg-red-50/50" : ""}>
                                                <TableCell>
                                                    {result.success ? (
                                                        <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">
                                                            Berhasil
                                                        </Badge>
                                                    ) : (
                                                        <Badge variant="destructive">
                                                            Gagal
                                                        </Badge>
                                                    )}
                                                </TableCell>
                                                <TableCell className="font-medium">{result.nama}</TableCell>
                                                <TableCell>{result.nisn}</TableCell>
                                                <TableCell className="text-sm text-muted-foreground">
                                                    {result.error || '-'}
                                                </TableCell>
                                            </TableRow>
                                        ))}
                                    </TableBody>
                                </Table>
                            </div>
                        </div>
                    )}
                </div>
            </DialogContent>
        </Dialog>
    )
}
