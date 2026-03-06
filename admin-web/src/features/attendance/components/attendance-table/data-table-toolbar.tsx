import type { Table } from "@tanstack/react-table"
import { X } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

import { DataTableFacetedFilter } from "@/components/ui/data-table/data-table-faceted-filter"

const STATUS_OPTIONS = [
    { label: 'Hadir', value: 'Hadir' },
    { label: 'Terlambat', value: 'Terlambat' },
    { label: 'Izin', value: 'Izin' },
    { label: 'Sakit', value: 'Sakit' },
    { label: 'Alpa', value: 'Alpa' },
]

interface DataTableToolbarProps<TData> {
    table: Table<TData>
    classList: string[]
}

export function DataTableToolbar<TData>({
    table,
    classList,
}: DataTableToolbarProps<TData>) {
    const isFiltered = table.getState().columnFilters.length > 0

    return (
        <div className="flex items-center justify-between">
            <div className="flex flex-1 items-center space-x-2">
                <Input
                    placeholder="Filter nama siswa..."
                    value={(table.getColumn("full_name")?.getFilterValue() as string) ?? ""}
                    onChange={(event) =>
                        table.getColumn("full_name")?.setFilterValue(event.target.value)
                    }
                    className="h-8 w-[150px] lg:w-[250px]"
                />
                
                {table.getColumn("class_name") && (
                    <DataTableFacetedFilter
                        column={table.getColumn("class_name")}
                        title="Kelas"
                        options={classList.map(c => ({ label: c, value: c }))}
                    />
                )}

                {table.getColumn("status") && (
                    <DataTableFacetedFilter
                        column={table.getColumn("status")}
                        title="Status"
                        options={STATUS_OPTIONS}
                    />
                )}

                {isFiltered && (
                    <Button
                        variant="ghost"
                        onClick={() => table.resetColumnFilters()}
                        className="h-8 px-2 lg:px-3"
                    >
                        Reset
                        <X className="ml-2 h-4 w-4" />
                    </Button>
                )}
            </div>
            {/* <DataTableViewOptions table={table} /> // Optional */}
        </div>
    )
}
