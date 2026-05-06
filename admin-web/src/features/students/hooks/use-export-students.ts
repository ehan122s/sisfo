import { useState } from 'react'
import { supabase } from '@/lib/supabase'
import { toast } from 'sonner'
import * as XLSX from 'xlsx'

interface StudentRow {
    id: string
    full_name: string | null
    nisn: string | null
    class_name: string | null
    status: string | null
    placements: {
        companies: {
            name: string
        } | null
    }[]
}

export function useExportStudents() {
    const [isExporting, setIsExporting] = useState(false)

    const exportToExcel = async () => {
        setIsExporting(true)
        try {
            const PAGE_SIZE = 1000
            let data: StudentRow[] = []
            let from = 0
            let hasMore = true

            while (hasMore) {
                const { data: batch, error } = await supabase
                    .from('profiles')
                    .select(`
                        id,
                        full_name,
                        nisn,
                        class_name,
                        status,
                        placements (
                            companies (name)
                        )
                    `)
                    .eq('role', 'student')
                    .order('full_name')
                    .range(from, from + PAGE_SIZE - 1)

               if (error) throw error
               data = [...data, ...((batch as unknown as StudentRow[]) ?? [])]
               hasMore = (batch?.length ?? 0) === PAGE_SIZE
               from += PAGE_SIZE
            }

            if (data.length === 0) {
                toast.warning('Tidak ada data siswa untuk diexport')
                return
            }

            const excelData = data.map((student: StudentRow, index: number) => ({
                'No': index + 1,
                'Nama Lengkap': student.full_name ?? '-',
                'NISN': student.nisn ?? '-',
                'Kelas': student.class_name ?? '-',
                'Tempat PKL': student.placements?.[0]?.companies?.name ?? 'Belum Ada',
                'Status':
                    student.status === 'active' ? 'Aktif' :
                    student.status === 'inactive' ? 'Non-aktif' :
                    student.status === 'completed' ? 'Selesai' :
                    student.status === 'suspended' ? 'Suspended' : 'Pending'
            }))

            const wb = XLSX.utils.book_new()
            const ws = XLSX.utils.json_to_sheet(excelData)

            ws['!cols'] = [
                { wch: 5 },
                { wch: 30 },
                { wch: 15 },
                { wch: 15 },
                { wch: 30 },
                { wch: 15 },
            ]

            XLSX.utils.book_append_sheet(wb, ws, 'Data Siswa')
            XLSX.writeFile(wb, `Data_Siswa_PKL_${new Date().toISOString().split('T')[0]}.xlsx`)

            toast.success('Export data berhasil')
        } catch (error) {
            console.error('Export failed:', error)
            toast.error('Gagal mengexport data')
        } finally {
            setIsExporting(false)
        }
    }

    return { exportToExcel, isExporting }
}