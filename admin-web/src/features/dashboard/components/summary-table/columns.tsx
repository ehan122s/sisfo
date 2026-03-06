import type { ColumnDef } from "@tanstack/react-table"
import { Badge } from "@/components/ui/badge"
import { DataTableColumnHeader } from "@/components/ui/data-table/data-table-column-header"

export type ClassAttendanceSummary = {
    class_name: string
    hadir: number
    terlambat: number
    sakit: number
    izin: number
    alpa: number
    total: number
}

export const columns: ColumnDef<ClassAttendanceSummary>[] = [
    {
        accessorKey: "class_name",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Kelas" />
        ),
        cell: ({ row }) => <div className="font-medium">{row.getValue("class_name")}</div>,
        footer: () => <div className="font-bold">TOTAL</div>
    },
    {
        accessorKey: "hadir",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Hadir" />
        ),
        cell: ({ row }) => (
            <div className="text-center">
                <Badge variant="outline" className="text-green-700 border-green-200 bg-green-50">
                    {row.getValue("hadir")}
                </Badge>
            </div>
        ),
        footer: ({ table }) => {
            const total = table.getFilteredRowModel().rows.reduce((sum, row) => sum + (row.getValue("hadir") as number), 0)
            return <div className="text-center font-bold">{total}</div>
        }
    },
    {
        accessorKey: "terlambat",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Terlambat" />
        ),
        cell: ({ row }) => (
            <div className="text-center">
                <Badge variant="outline" className="text-yellow-700 border-yellow-200 bg-yellow-50">
                    {row.getValue("terlambat")}
                </Badge>
            </div>
        ),
        footer: ({ table }) => {
            const total = table.getFilteredRowModel().rows.reduce((sum, row) => sum + (row.getValue("terlambat") as number), 0)
            return <div className="text-center font-bold">{total}</div>
        }
    },
    {
        accessorKey: "sakit",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Sakit" />
        ),
        cell: ({ row }) => (
            <div className="text-center">
                <Badge variant="outline" className="text-purple-700 border-purple-200 bg-purple-50">
                    {row.getValue("sakit")}
                </Badge>
            </div>
        ),
        footer: ({ table }) => {
            const total = table.getFilteredRowModel().rows.reduce((sum, row) => sum + (row.getValue("sakit") as number), 0)
            return <div className="text-center font-bold">{total}</div>
        }
    },
    {
        accessorKey: "izin",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Izin" />
        ),
        cell: ({ row }) => (
            <div className="text-center">
                <Badge variant="outline" className="text-blue-700 border-blue-200 bg-blue-50">
                    {row.getValue("izin")}
                </Badge>
            </div>
        ),
        footer: ({ table }) => {
            const total = table.getFilteredRowModel().rows.reduce((sum, row) => sum + (row.getValue("izin") as number), 0)
            return <div className="text-center font-bold">{total}</div>
        }
    },
    {
        accessorKey: "alpa",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Alpa" />
        ),
        cell: ({ row }) => (
            <div className="text-center">
                <Badge variant="outline" className="text-red-700 border-red-200 bg-red-50">
                    {row.getValue("alpa")}
                </Badge>
            </div>
        ),
        footer: ({ table }) => {
            const total = table.getFilteredRowModel().rows.reduce((sum, row) => sum + (row.getValue("alpa") as number), 0)
            return <div className="text-center font-bold">{total}</div>
        }
    },
    {
        accessorKey: "total",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Total" />
        ),
        cell: ({ row }) => (
            <div className="text-center font-bold">
                {row.getValue("total")}
            </div>
        ),
        footer: ({ table }) => {
            const total = table.getFilteredRowModel().rows.reduce((sum, row) => sum + (row.getValue("total") as number), 0)
            return <div className="text-center font-bold">{total}</div>
        }
    },
]
