interface ExportData {
    headers: string[]
    rows: (string | number)[][]
    filename: string
    title?: string
}

export function exportToExcel({ headers, rows, filename }: ExportData) {
    void import('xlsx').then((XLSX) => {
        const worksheetData = [headers, ...rows]
        const worksheet = XLSX.utils.aoa_to_sheet(worksheetData)
        const workbook = XLSX.utils.book_new()
        XLSX.utils.book_append_sheet(workbook, worksheet, 'Data')

        // Auto-width columns
        const colWidths = headers.map((h, i) => {
            const maxLength = Math.max(
                h.length,
                ...rows.map(row => String(row[i] ?? '').length)
            )
            return { wch: Math.min(maxLength + 2, 50) }
        })
        worksheet['!cols'] = colWidths

        XLSX.writeFile(workbook, `${filename}.xlsx`)
    })
}

export function exportToPDF({ headers, rows, filename, title }: ExportData) {
    void Promise.all([import('jspdf'), import('jspdf-autotable')]).then(([jspdfModule, autoTableModule]) => {
        const doc = new jspdfModule.default()

        // Title
        if (title) {
            doc.setFontSize(16)
            doc.text(title, 14, 15)
        }

        // Date
        doc.setFontSize(10)
        doc.text(`Dicetak: ${new Date().toLocaleDateString('id-ID', {
            day: 'numeric',
            month: 'long',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        })}`, 14, title ? 23 : 15)

        // Table
        autoTableModule.default(doc, {
            head: [headers],
            body: rows,
            startY: title ? 28 : 20,
            styles: {
                fontSize: 9,
                cellPadding: 3,
            },
            headStyles: {
                fillColor: [50, 80, 80], // Slate color matching sidebar
                textColor: 255,
                fontStyle: 'bold',
            },
            alternateRowStyles: {
                fillColor: [245, 245, 245],
            },
        })

        doc.save(`${filename}.pdf`)
    })
}
