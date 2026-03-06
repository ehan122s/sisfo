import { type ColumnDef } from "@tanstack/react-table"
import { Badge } from "@/components/ui/badge"
import { Checkbox } from "@/components/ui/checkbox"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
    MoreHorizontal,
    Pencil,
    Trash2,
    Building2,
    List,
    Check,
    X,
    CheckCircle,
    MinusCircle,
    AlertCircle,
    Clock
} from "lucide-react"
import { type Student } from "@/types"
import { getInitials } from "@/lib/utils"
import { DataTableColumnHeader } from "@/components/ui/data-table/data-table-column-header"

interface StudentColumnProps {
    onEdit: (student: Student) => void
    onDelete: (student: Student) => void
    onAssign: (student: Student) => void
    onUpdateStatus: (id: string, status: string) => void
}

export const getStatusBadge = (status: string) => {
    switch (status) {
        case 'active':
            return (
                <Badge className="bg-green-100 text-green-700 hover:bg-green-200 border-green-200 flex w-fit items-center gap-1">
                    <CheckCircle className="h-3 w-3" />
                    Aktif
                </Badge>
            )
        case 'inactive':
            return (
                <Badge variant="secondary" className="bg-gray-100 text-gray-700 hover:bg-gray-200 flex w-fit items-center gap-1">
                    <MinusCircle className="h-3 w-3" />
                    Non-aktif
                </Badge>
            )
        case 'completed':
            return (
                <Badge className="bg-blue-100 text-blue-700 hover:bg-blue-200 border-blue-200 flex w-fit items-center gap-1">
                    <CheckCircle className="h-3 w-3" />
                    Selesai
                </Badge>
            )
        case 'suspended':
            return (
                <Badge variant="destructive" className="flex w-fit items-center gap-1">
                    <AlertCircle className="h-3 w-3" />
                    Suspended
                </Badge>
            )
        default:
            return (
                <Badge variant="outline" className="text-yellow-600 border-yellow-300 bg-yellow-50 flex w-fit items-center gap-1">
                    <Clock className="h-3 w-3" />
                    Pending
                </Badge>
            )
    }
}

export const getColumns = ({
    onEdit,
    onDelete,
    onAssign,
    onUpdateStatus
}: StudentColumnProps): ColumnDef<Student>[] => [
    {
        id: "select",
        header: ({ table }) => (
            <Checkbox
                checked={table.getIsAllPageRowsSelected()}
                onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
                aria-label="Select all"
            />
        ),
        cell: ({ row }) => (
            <Checkbox
                checked={row.getIsSelected()}
                onCheckedChange={(value) => row.toggleSelected(!!value)}
                aria-label="Select row"
            />
        ),
        enableSorting: false,
        enableHiding: false,
    },
    {
        accessorKey: "full_name",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Siswa" />
        ),
        cell: ({ row }) => {
            const student = row.original
            return (
                <div className="flex items-center gap-3">
                    <Avatar className="h-9 w-9">
                        <AvatarImage src={student.avatar_url || undefined} alt={student.full_name} />
                        <AvatarFallback className="bg-primary/10 text-primary text-xs">
                            {getInitials(student.full_name)}
                        </AvatarFallback>
                    </Avatar>
                    <div className="flex flex-col">
                        <span className="font-medium text-sm line-clamp-1">{student.full_name}</span>
                        <span className="text-xs text-muted-foreground line-clamp-1">{student.email}</span>
                    </div>
                </div>
            )
        },
    },
    {
        accessorKey: "nisn",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="NISN" />
        ),
        cell: ({ row }) => <span className="text-sm font-mono">{row.original.nisn || '-'}</span>,
    },
    {
        accessorKey: "class_name",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Kelas" />
        ),
        cell: ({ row }) => (
            <Badge variant="outline" className="font-normal shrink-0">
                {row.original.class_name || '-'}
            </Badge>
        ),
        filterFn: (row, id, value) => {
            return value.includes(row.getValue(id))
        },
    },
    {
        id: "placement",
        header: "Tempat PKL",
        accessorFn: (row) => row.placements?.[0]?.companies?.name,
        cell: ({ row }) => {
            const companyName = row.getValue("placement") as string

            return companyName ? (
                <div className="flex items-center gap-1.5 text-sm max-w-[200px]">
                    <Building2 className="h-3.5 w-3.5 text-muted-foreground shrink-0" />
                    <span className="truncate">{companyName}</span>
                </div>
            ) : (
                <span className="text-muted-foreground text-sm italic">Belum ada</span>
            )
        },
        filterFn: (row, id, value) => {
            return value.includes(row.getValue(id))
        },
    },
    {
        accessorKey: "status",
        header: ({ column }) => (
            <DataTableColumnHeader column={column} title="Status" />
        ),
        cell: ({ row }) => getStatusBadge(row.original.status),
        filterFn: (row, id, value) => {
            return value.includes(row.getValue(id))
        },
    },
    {
        id: "actions",
        cell: ({ row }) => {
            const student = row.original

            return (
                <div className="text-right">
                    <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                            <Button variant="ghost" className="h-8 w-8 p-0">
                                <span className="sr-only">Open menu</span>
                                <MoreHorizontal className="h-4 w-4" />
                            </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                            <DropdownMenuLabel>Aksi</DropdownMenuLabel>
                            <DropdownMenuItem
                                onClick={() => window.location.href = `/monitoring/${student.id}`}
                            >
                                <List className="mr-2 h-4 w-4" />
                                Lihat Detail
                            </DropdownMenuItem>

                            <DropdownMenuSeparator />
                            {student.status === 'pending' && (
                                <>
                                    <DropdownMenuItem
                                        onClick={() => onUpdateStatus(student.id, 'active')}
                                    >
                                        <Check className="mr-2 h-4 w-4 text-green-600" />
                                        Set Aktif
                                    </DropdownMenuItem>
                                    <DropdownMenuItem
                                        onClick={() => onUpdateStatus(student.id, 'inactive')}
                                    >
                                        <X className="mr-2 h-4 w-4 text-red-600" />
                                        Set Non-aktif
                                    </DropdownMenuItem>
                                    <DropdownMenuSeparator />
                                </>
                            )}
                            <DropdownMenuItem
                                onClick={() => onAssign(student)}
                            >
                                <Building2 className="mr-2 h-4 w-4" />
                                Assign DUDI
                            </DropdownMenuItem>
                            <DropdownMenuItem
                                onClick={() => onEdit(student)}
                            >
                                <Pencil className="mr-2 h-4 w-4" />
                                Edit Siswa
                            </DropdownMenuItem>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem
                                className="text-red-600 focus:text-red-600 focus:bg-red-50"
                                onClick={() => onDelete(student)}
                            >
                                <Trash2 className="mr-2 h-4 w-4" />
                                Hapus Siswa
                            </DropdownMenuItem>
                        </DropdownMenuContent>
                    </DropdownMenu>
                </div>
            )
        },
    },
]
