import * as React from "react"
import {
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
  type ColumnDef,
  type SortingState,
} from "@tanstack/react-table"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

import { ChevronLeft, ChevronRight } from "lucide-react"

export type AttendanceRow = {
  id: string
  full_name: string
  class_name: string
  avatar_url?: string
  company_name?: string
  status?: string
  check_in_time?: string
  check_out_time?: string
}

type Props = {
  data?: AttendanceRow[]
  classList?: string[]
  columns?: unknown // supaya aman kalau parent masih kirim columns
}

function formatTime(value?: string) {
  if (!value) return "-"
  const date = new Date(value)

  if (isNaN(date.getTime())) return "-"

  return date.toLocaleTimeString("id-ID", {
    hour: "2-digit",
    minute: "2-digit",
  })
}

export function DataTable({
  data = [],
  classList = [],
}: Props) {
  const [sorting, setSorting] = React.useState<SortingState>([])
  const [search, setSearch] = React.useState("")
  const [selectedClass, setSelectedClass] = React.useState("Semua")

  const tableColumns = React.useMemo<ColumnDef<AttendanceRow>[]>(
    () => [
      {
        accessorKey: "full_name",
        header: "Nama",
      },
      {
        accessorKey: "class_name",
        header: "Kelas",
      },
      {
        accessorKey: "company_name",
        header: "DUDI",
        cell: ({ row }) => row.original.company_name || "-",
      },
      {
        accessorKey: "status",
        header: "Status",
        cell: ({ row }) => row.original.status || "Alpa",
      },
      {
        accessorKey: "check_in_time",
        header: "Check In",
        cell: ({ row }) => formatTime(row.original.check_in_time),
      },
      {
        accessorKey: "check_out_time",
        header: "Check Out",
        cell: ({ row }) => formatTime(row.original.check_out_time),
      },
    ],
    []
  )

  const filteredData = React.useMemo(() => {
    return data.filter((item) => {
      const matchSearch = (item.full_name || "")
        .toLowerCase()
        .includes(search.toLowerCase())

      const matchClass =
        selectedClass === "Semua"
          ? true
          : item.class_name === selectedClass

      return matchSearch && matchClass
    })
  }, [data, search, selectedClass])

  const table = useReactTable({
    data: filteredData,
    columns: tableColumns,
    state: {
      sorting,
    },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
  })

  return (
    <div className="space-y-4">
      {/* FILTER */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <Input
          placeholder="Cari siswa..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="sm:max-w-xs"
        />

        <Select
          value={selectedClass}
          onValueChange={setSelectedClass}
        >
          <SelectTrigger className="sm:w-48">
            <SelectValue placeholder="Pilih kelas" />
          </SelectTrigger>

          <SelectContent>
            <SelectItem value="Semua">Semua</SelectItem>

            {classList.map((kelas) => (
              <SelectItem key={kelas} value={kelas}>
                {kelas}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* TABLE */}
      <div className="overflow-hidden rounded-xl border">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((group) => (
              <TableRow key={group.id}>
                {group.headers.map((header) => (
                  <TableHead key={header.id}>
                    {header.isPlaceholder
                      ? null
                      : flexRender(
                          header.column.columnDef.header,
                          header.getContext()
                        )}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>

          <TableBody>
            {table.getRowModel().rows.length > 0 ? (
              table.getRowModel().rows.map((row) => (
                <TableRow key={row.id}>
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(
                        cell.column.columnDef.cell,
                        cell.getContext()
                      )}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={tableColumns.length}
                  className="h-24 text-center"
                >
                  Tidak ada data
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {/* PAGINATION */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          Page {table.getState().pagination.pageIndex + 1} of{" "}
          {table.getPageCount() || 1}
        </p>

        <div className="flex gap-2">
          <Button
            variant="outline"
            size="icon"
            onClick={() => table.previousPage()}
            disabled={!table.getCanPreviousPage()}
          >
            <ChevronLeft className="h-4 w-4" />
          </Button>

          <Button
            variant="outline"
            size="icon"
            onClick={() => table.nextPage()}
            disabled={!table.getCanNextPage()}
          >
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </div>
  )
}