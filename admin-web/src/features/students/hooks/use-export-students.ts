import { useState } from 'react'
import { supabase } from '@/lib/supabase'
import { toast } from 'sonner'

export function useExportStudents() {
    const [isExporting, setIsExporting] = useState(false)

    const exportToExcel = async () => {
        setIsExporting(true)
        try {
            // Fetch all students with their placement data (paginated to bypass PostgREST max-rows limit)
            const PAGE_SIZE = 1000
            let data: any[] = []
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
                        email,
                        placements (
                            companies (name)
                        )
                    `)
                    .eq('role', 'student')
                    .order('full_name')
                    .range(from, from + PAGE_SIZE - 1)

                if (error) throw error
                data = data.concat(batch ?? [])
                hasMore = (batch?.length ?? 0) === PAGE_SIZE
                from += PAGE_SIZE
            }

            if (!data || data.length === 0) {
                toast.warning('Tidak ada data siswa untuk diexport')
                return
            }

            // Transform data for Excel
            const excelData = data.map((student: any, index: number) => ({
                'No': index + 1,
                'Nama Lengkap': student.full_name,
                'NISN': student.nisn || '-',
                'Kelas': student.class_name || '-',
                'Email': student.email,
                'Tempat PKL': student.placements?.[0]?.companies?.name || 'Belum Ada',
                'Status': student.status === 'active' ? 'Aktif' :
                    student.status === 'inactive' ? 'Non-aktif' :
                        student.status === 'completed' ? 'Selesai' :
                            student.status === 'suspended' ? 'Suspended' : 'Pending'
            }))

            // Create workbook and worksheet
            const XLSX = await import('xlsx')
            const wb = XLSX.utils.book_new()
            const ws = XLSX.utils.json_to_sheet(excelData)

            // Auto-width for columns
            const colWidths = [
                { wch: 5 },  // No
                { wch: 30 }, // Nama
                { wch: 15 }, // NISN
                { wch: 15 }, // Kelas
                { wch: 25 }, // Email
                { wch: 30 }, // Tempat PKL
                { wch: 15 }  // Status
            ]
            ws['!cols'] = colWidths

            XLSX.utils.book_append_sheet(wb, ws, 'Data Siswa')

            // Generate file
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
