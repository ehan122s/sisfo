import { useState, useCallback } from 'react'
import { toast } from "sonner"
import { useDropzone } from 'react-dropzone'
import Papa from 'papaparse'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import {
    Dialog,
    DialogContent,
    DialogDescription,
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
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Progress } from '@/components/ui/progress'
import { Upload, FileSpreadsheet, CheckCircle, XCircle, AlertCircle, Loader2 } from 'lucide-react'

interface CompanyRow {
    name: string
    address?: string
    latitude?: string
    longitude?: string
    radius_meter?: string
}

interface ImportResult {
    success: boolean
    name: string
    error?: string
}

interface ImportCompanyDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
}

export function ImportCompanyDialog({ open, onOpenChange }: ImportCompanyDialogProps) {
    const [parsedData, setParsedData] = useState<CompanyRow[]>([])
    const [parseError, setParseError] = useState<string | null>(null)
    const [importResults, setImportResults] = useState<ImportResult[] | null>(null)
    const [progress, setProgress] = useState(0)
    const queryClient = useQueryClient()

    // Import mutation
    const importMutation = useMutation({
        mutationFn: async (companies: CompanyRow[]) => {
            const results: ImportResult[] = []
            let successCount = 0

            const total = companies.length

            for (let i = 0; i < total; i++) {
                const row = companies[i]
                setProgress(Math.round(((i + 1) / total) * 100))

                try {
                    const payload = {
                        name: row.name,
                        address: row.address || null,
                        latitude: row.latitude ? parseFloat(row.latitude) : null,
                        longitude: row.longitude ? parseFloat(row.longitude) : null,
                        radius_meter: row.radius_meter ? parseInt(row.radius_meter) : 100,
                    }

                    const { error } = await supabase.from('companies').insert(payload)

                    if (error) throw error

                    results.push({ success: true, name: row.name })
                    successCount++
                } catch (error) {
                    results.push({
                        success: false,
                        name: row.name,
                        error: error instanceof Error ? error.message : 'Gagal insert data'
                    })
                }
            }

            return { successCount, failureCount: total - successCount, results }
        },
        onSuccess: (data) => {
            setImportResults(data.results)
            queryClient.invalidateQueries({ queryKey: ['companies'] })
            toast.success(`Import selesai: ${data.successCount} berhasil, ${data.failureCount} gagal`)
        },
        onError: (error) => {
            console.error('Import error:', error)
            toast.error('Terjadi kesalahan fatal saat import')
        },
    })

    // Dropzone handler
    const onDrop = useCallback((acceptedFiles: File[]) => {
        const file = acceptedFiles[0]
        if (!file) return

        setParseError(null)
        setImportResults(null)
        setProgress(0)

        Papa.parse(file, {
            header: true,
            skipEmptyLines: true,
            complete: (results) => {
                const data = results.data as Record<string, string>[]

                const requiredColumns = ['name']
                const headers = Object.keys(data[0] || {})
                const missingColumns = requiredColumns.filter(col => !headers.includes(col))

                if (missingColumns.length > 0) {
                    setParseError(`Kolom wajib tidak ditemukan: ${missingColumns.join(', ')}`)
                    return
                }

                const parsed: CompanyRow[] = data.map(row => ({
                    name: row.name?.trim() || '',
                    address: row.address?.trim(),
                    latitude: row.latitude?.trim(),
                    longitude: row.longitude?.trim(),
                    radius_meter: row.radius_meter?.trim(),
                })).filter(row => row.name)

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
    }, [])

    const { getRootProps, getInputProps, isDragActive } = useDropzone({
        onDrop,
        accept: {
            'text/csv': ['.csv'],
        },
        maxFiles: 1,
    })

    const handleImport = () => {
        if (parsedData.length === 0) return
        importMutation.mutate(parsedData)
    }

    const handleReset = () => {
        setParsedData([])
        setParseError(null)
        setImportResults(null)
        setProgress(0)
        importMutation.reset()
    }

    const handleClose = () => {
        handleReset()
        onOpenChange(false)
    }

    const successCount = importResults?.filter(r => r.success).length ?? 0
    const failureCount = importResults?.filter(r => !r.success).length ?? 0

    return (
        <Dialog open={open} onOpenChange={handleClose}>
            <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                    <DialogTitle>Import DUDI dari CSV</DialogTitle>
                    <DialogDescription>
                        Format CSV: <code className="bg-muted px-1 rounded">name,address,latitude,longitude,radius_meter</code>
                    </DialogDescription>
                </DialogHeader>

                <div className="space-y-4">
                    {/* Upload Zone */}
                    {!importResults && parsedData.length === 0 && (
                        <div>
                            <div
                                {...getRootProps()}
                                className={`border-2 border-dashed rounded-lg p-6 text-center cursor-pointer transition-colors ${isDragActive ? 'border-primary bg-primary/5' : 'border-muted-foreground/25 hover:border-primary/50'
                                    }`}
                            >
                                <input {...getInputProps()} />
                                <Upload className="h-8 w-8 mx-auto mb-2 text-muted-foreground" />
                                {isDragActive ? (
                                    <p className="text-primary font-medium">Drop file CSV di sini...</p>
                                ) : (
                                    <div>
                                        <p className="font-medium">Drag & drop file CSV, atau klik untuk memilih</p>
                                        <p className="text-sm text-muted-foreground mt-1">Hanya file .csv yang diterima</p>
                                    </div>
                                )}
                            </div>

                            {parseError && (
                                <Alert variant="destructive" className="mt-4">
                                    <AlertCircle className="h-4 w-4" />
                                    <AlertTitle>Error</AlertTitle>
                                    <AlertDescription>{parseError}</AlertDescription>
                                </Alert>
                            )}
                        </div>
                    )}

                    {/* Preview Table */}
                    {parsedData.length > 0 && !importResults && (
                        <div className="space-y-3">
                            <div className="flex items-center gap-2">
                                <FileSpreadsheet className="h-5 w-5" />
                                <h3 className="font-medium">Preview ({parsedData.length} perusahaan)</h3>
                            </div>
                            <div className="rounded-md border max-h-[300px] overflow-auto">
                                <Table>
                                    <TableHeader>
                                        <TableRow>
                                            <TableHead>No</TableHead>
                                            <TableHead>Nama</TableHead>
                                            <TableHead>Alamat</TableHead>
                                            <TableHead>Lat, Long</TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {parsedData.slice(0, 10).map((row, index) => (
                                            <TableRow key={index}>
                                                <TableCell>{index + 1}</TableCell>
                                                <TableCell>{row.name}</TableCell>
                                                <TableCell className="max-w-xs truncate">{row.address || '-'}</TableCell>
                                                <TableCell>
                                                    {row.latitude && row.longitude
                                                        ? `${row.latitude}, ${row.longitude}`
                                                        : '-'}
                                                </TableCell>
                                            </TableRow>
                                        ))}
                                        {parsedData.length > 10 && (
                                            <TableRow>
                                                <TableCell colSpan={4} className="text-center text-muted-foreground">
                                                    ... dan {parsedData.length - 10} lainnya
                                                </TableCell>
                                            </TableRow>
                                        )}
                                    </TableBody>
                                </Table>
                            </div>

                            <div className="flex justify-end gap-3">
                                <Button variant="outline" onClick={handleReset}>
                                    Batal
                                </Button>
                                <Button onClick={handleImport} disabled={importMutation.isPending}>
                                    {importMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                    Import {parsedData.length} DUDI
                                </Button>
                            </div>
                        </div>
                    )}

                    {/* Import Progress */}
                    {importMutation.isPending && (
                        <div className="py-8 text-center">
                            <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4 text-primary" />
                            <p className="font-medium">Mengimport perusahaan... {progress}%</p>
                            <Progress value={progress} className="mt-4 max-w-md mx-auto" />
                        </div>
                    )}

                    {/* Import Results */}
                    {importResults && (
                        <div className="space-y-3">
                            <div>
                                <h3 className="font-medium mb-2">Hasil Import</h3>
                                <div className="text-sm">
                                    <span className="text-green-600 font-medium">{successCount} berhasil</span>
                                    {failureCount > 0 && (
                                        <span className="text-red-600 font-medium ml-3">{failureCount} gagal</span>
                                    )}
                                </div>
                            </div>
                            <div className="rounded-md border max-h-[300px] overflow-auto">
                                <Table>
                                    <TableHeader>
                                        <TableRow>
                                            <TableHead>Status</TableHead>
                                            <TableHead>Nama</TableHead>
                                            <TableHead>Keterangan</TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {importResults.map((result, index) => (
                                            <TableRow key={index}>
                                                <TableCell>
                                                    {result.success ? (
                                                        <Badge className="bg-green-100 text-green-800">
                                                            <CheckCircle className="h-3 w-3 mr-1" /> Berhasil
                                                        </Badge>
                                                    ) : (
                                                        <Badge variant="destructive">
                                                            <XCircle className="h-3 w-3 mr-1" /> Gagal
                                                        </Badge>
                                                    )}
                                                </TableCell>
                                                <TableCell>{result.name}</TableCell>
                                                <TableCell className="text-sm text-muted-foreground">
                                                    {result.error || '-'}
                                                </TableCell>
                                            </TableRow>
                                        ))}
                                    </TableBody>
                                </Table>
                            </div>

                            <div className="flex justify-end">
                                <Button onClick={handleClose}>
                                    Tutup
                                </Button>
                            </div>
                        </div>
                    )}
                </div>
            </DialogContent>
        </Dialog>
    )
}
