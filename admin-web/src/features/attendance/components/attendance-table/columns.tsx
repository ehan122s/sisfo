import type { ColumnDef } from "@tanstack/react-table"
import { Badge } from "@/components/ui/badge"
import { Checkbox } from "@/components/ui/checkbox"
import { DataTableColumnHeader } from "@/components/ui/data-table/data-table-column-header"

export type AttendanceReportRow = {
    id: string
    full_name: string
    class_name: string
    company_name: string | null
    status: string
    check_in_time: string | null
    check_out_time: string | null
}

const getStatusColor = (status: string) => {
    switch (status) {
        case 'Hadir': return 'bg-green-50 text-green-700 border-green-200'
        case 'Terlambat': return 'bg-yellow-50 text-yellow-700 border-yellow-200'
        case 'Izin': return 'bg-blue-50 text-blue-700 border-blue-200'
        case 'Sakit': return 'bg-purple-50 text-purple-700 border-purple-200'
        case 'Alpa': return 'bg-red-50 text-red-700 border-red-200'
        default: return 'bg-gray-50 text-gray-700 border-gray-200'
    }
}

const formatTime = (time?: string | null) => {
    if (!time) return '-'
    return new Date(time).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
}

export const columns: ColumnDef<AttendanceReportRow>[] = [
    {
        id: "select",
        header: ({ table }) => (
            <Checkbox
                checked={table.getIsAllPageRowsSelected() || (table.getIsSomePageRowsSelected() && "indeterminate")}
                onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
                aria-label="Select all"
                className="translate-y-[2px]"
            />
        ),
        cell: ({ row }) => (
            <Checkbox
                checked={row.getIsSelected()}
                onCheckedChange={(value) => row.toggleSelected(!!value)}
                aria-label="Select row"
                className="translate-y-[2px]"
            />
        ),
        enableSorting: false,
        enableHiding: false,
    },
    {
        accessorKey: "full_name",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Nama Siswa" />
        ),
        cell: ({ row }) => {
            return (
                <div className="flex flex-col">
                    <span className="max-w-[500px] truncate font-medium">
                        {row.getValue("full_name")}
                    </span>
                    <span className="text-xs text-muted-foreground sm:hidden">
                        {row.original.class_name}
                    </span>
                </div>
            )
        },
    },
    {
        accessorKey: "class_name",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Kelas" />
        ),
        cell: ({ row }) => {
            return (
                <div className="w-[80px]">
                    {row.getValue("class_name")}
                </div>
            )
        },
        filterFn: (row, id, value) => {
            return value.includes(row.getValue(id))
        },
    },
    {
        accessorKey: "company_name",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="DUDI" />
        ),
        cell: ({ row }) => {
            return (
                <div className="flex items-center">
                    <span className="truncate" title={row.getValue("company_name") || ""}>
                        {row.getValue("company_name") || "-"}
                    </span>
                </div>
            )
        },
    },
    {
        accessorKey: "status",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Status" />
        ),
        cell: ({ row }) => {
            const status = row.getValue("status") as string
            return (
                <Badge className={getStatusColor(status)} variant="outline">
                    {status}
                </Badge>
            )
        },
        filterFn: (row, id, value) => {
            return value.includes(row.getValue(id))
        },
    },
    {
        accessorKey: "check_in_time",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Masuk" />
        ),
        cell: ({ row }) => {
            return (
                <div className="flex w-[80px] items-center">
                    {formatTime(row.getValue("check_in_time"))}
                </div>
            )
        },
    },
    {
        accessorKey: "check_out_time",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Pulang" />
        ),
        cell: ({ row }) => {
            return (
                <div className="flex w-[80px] items-center">
                    {formatTime(row.getValue("check_out_time"))}
                </div>
            )
        },
    },
]
