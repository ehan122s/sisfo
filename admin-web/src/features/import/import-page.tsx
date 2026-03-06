import { useState, useCallback } from 'react'
import { useDropzone } from 'react-dropzone'
import Papa from 'papaparse'
import { useMutation, useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
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
import { Upload, FileSpreadsheet, CheckCircle, XCircle, AlertCircle, Loader2 } from 'lucide-react'
import type { Company } from '@/types'

interface StudentRow {
    nama: string
    nisn: string
    kelas: string
    password?: string
    company_id?: number
}

interface ImportResult {
    success: boolean
    nisn: string
    nama: string
    error?: string
}

export function ImportPage() {
    const [parsedData, setParsedData] = useState<StudentRow[]>([])
    const [parseError, setParseError] = useState<string | null>(null)
    const [selectedCompanyId, setSelectedCompanyId] = useState<number | null>(null)
    const [importResults, setImportResults] = useState<ImportResult[] | null>(null)

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

    // Import mutation
    const importMutation = useMutation({
        mutationFn: async (students: StudentRow[]) => {
            // Get current session
            const { data: { session }, error: sessionError } = await supabase.auth.getSession()

            if (sessionError || !session) {
                console.error('Session error:', sessionError)
                throw new Error('Anda belum login atau session telah expired. Silakan refresh halaman dan login kembali.')
            }

            console.log('Invoking Edge Function with', students.length, 'students')

            // Invoke Edge Function
            const response = await supabase.functions.invoke('import-students', {
                body: { students },
                headers: {
                    Authorization: `Bearer ${session.access_token}`,
                },
            })

            console.log('Edge Function response:', response)

            if (response.error) {
                console.error('Edge Function error:', response.error)
                throw new Error(response.error.message || 'Import gagal')
            }

            return response.data as { successCount: number; failureCount: number; results: ImportResult[] }
        },
        onSuccess: (data) => {
            setImportResults(data.results)
        },
        onError: (error) => {
            console.error('Import mutation error:', error)
        },
    })

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

                // Validate required columns
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

    // Handle company selection change
    const handleCompanyChange = (value: string) => {
        const companyId = value === 'none' ? null : parseInt(value, 10)
        setSelectedCompanyId(companyId)
        // Update parsed data with new company_id
        if (parsedData.length > 0) {
            setParsedData(prev => prev.map(row => ({
                ...row,
                company_id: companyId || undefined,
            })))
        }
    }

    // Handle import
    const handleImport = () => {
        if (parsedData.length === 0) return
        importMutation.mutate(parsedData)
    }

    // Reset all
    const handleReset = () => {
        setParsedData([])
        setParseError(null)
        setImportResults(null)
        importMutation.reset()
    }

    const successCount = importResults?.filter(r => r.success).length ?? 0
    const failureCount = importResults?.filter(r => !r.success).length ?? 0

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold">Import Siswa</h1>
            </div>

            {/* Instructions */}
            <Card>
                <CardHeader>
                    <CardTitle>Petunjuk Import</CardTitle>
                    <CardDescription>
                        Upload file CSV dengan format kolom: <code className="bg-muted px-1 rounded">nama, nisn, kelas, password (opsional)</code>
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-4 md:grid-cols-2">
                        <div>
                            <h4 className="font-medium mb-2">Format CSV</h4>
                            <pre className="bg-muted p-3 rounded text-sm overflow-x-auto">
                                {`nama,nisn,kelas,password
AHMAD ZAKI,0012345678,XI TEI 1,siswapkl2026
BUDI SANTOSO,0012345679,XI TEI 1,`}
                            </pre>
                        </div>
                        <div>
                            <h4 className="font-medium mb-2">Keterangan</h4>
                            <ul className="text-sm text-muted-foreground space-y-1">
                                <li>• Email otomatis: <code className="bg-muted px-1 rounded">NISN@pkl.com</code></li>
                                <li>• Password default: <code className="bg-muted px-1 rounded">siswapkl2026</code></li>
                                <li>• DUDI bisa dipilih setelah upload</li>
                            </ul>
                        </div>
                    </div>
                </CardContent>
            </Card>

            {/* Company Selection */}
            <Card>
                <CardHeader>
                    <CardTitle>Pilih DUDI (Opsional)</CardTitle>
                    <CardDescription>Semua siswa yang diimport akan ditempatkan di DUDI ini</CardDescription>
                </CardHeader>
                <CardContent>
                    <Select value={selectedCompanyId?.toString() ?? 'none'} onValueChange={handleCompanyChange}>
                        <SelectTrigger className="w-full md:w-[300px]">
                            <SelectValue placeholder="Pilih DUDI..." />
                        </SelectTrigger>
                        <SelectContent>
                            <SelectItem value="none">Tidak ada penempatan</SelectItem>
                            {companies.map((company) => (
                                <SelectItem key={company.id} value={company.id.toString()}>
                                    {company.name}
                                </SelectItem>
                            ))}
                        </SelectContent>
                    </Select>
                </CardContent>
            </Card>

            {/* Upload Zone */}
            {!importResults && (
                <Card>
                    <CardHeader>
                        <CardTitle>Upload File</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div
                            {...getRootProps()}
                            className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors ${isDragActive ? 'border-primary bg-primary/5' : 'border-muted-foreground/25 hover:border-primary/50'
                                }`}
                        >
                            <input {...getInputProps()} />
                            <Upload className="h-10 w-10 mx-auto mb-4 text-muted-foreground" />
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
                    </CardContent>
                </Card>
            )}

            {/* Preview Table */}
            {parsedData.length > 0 && !importResults && (
                <Card>
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <FileSpreadsheet className="h-5 w-5" />
                            Preview Data ({parsedData.length} siswa)
                        </CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="rounded-md border max-h-[400px] overflow-auto">
                            <Table>
                                <TableHeader>
                                    <TableRow>
                                        <TableHead>No</TableHead>
                                        <TableHead>Nama</TableHead>
                                        <TableHead>NISN</TableHead>
                                        <TableHead>Kelas</TableHead>
                                        <TableHead>Email</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {parsedData.map((row, index) => (
                                        <TableRow key={index}>
                                            <TableCell>{index + 1}</TableCell>
                                            <TableCell className="font-medium">{row.nama}</TableCell>
                                            <TableCell>{row.nisn}</TableCell>
                                            <TableCell>{row.kelas}</TableCell>
                                            <TableCell className="text-muted-foreground">{row.nisn}@pkl.com</TableCell>
                                        </TableRow>
                                    ))}
                                </TableBody>
                            </Table>
                        </div>

                        <div className="flex justify-end gap-3 mt-4">
                            <Button variant="outline" onClick={handleReset}>
                                Batal
                            </Button>
                            <Button onClick={handleImport} disabled={importMutation.isPending}>
                                {importMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                Import {parsedData.length} Siswa
                            </Button>
                        </div>
                    </CardContent>
                </Card>
            )}

            {/* Import Progress */}
            {importMutation.isPending && (
                <Card>
                    <CardContent className="py-8">
                        <div className="text-center">
                            <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4 text-primary" />
                            <p className="font-medium">Mengimport data siswa...</p>
                            <p className="text-sm text-muted-foreground">Mohon tunggu, proses ini mungkin memakan waktu beberapa saat</p>
                            <Progress value={50} className="mt-4 max-w-md mx-auto" />
                        </div>
                    </CardContent>
                </Card>
            )}

            {/* Import Results */}
            {importResults && (
                <Card>
                    <CardHeader>
                        <CardTitle>Hasil Import</CardTitle>
                        <CardDescription>
                            <span className="text-green-600 font-medium">{successCount} berhasil</span>
                            {failureCount > 0 && (
                                <span className="text-red-600 font-medium ml-3">{failureCount} gagal</span>
                            )}
                        </CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="rounded-md border max-h-[400px] overflow-auto">
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

                        <div className="flex justify-end mt-4">
                            <Button onClick={handleReset}>
                                Import Lagi
                            </Button>
                        </div>
                    </CardContent>
                </Card>
            )}
        </div>
    )
}
