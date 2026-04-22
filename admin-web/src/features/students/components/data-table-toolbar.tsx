import { type Table } from "@tanstack/react-table"
import { X, Building2, CheckCircle2, Clock, Ban, GraduationCap } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { DataTableFacetedFilter } from "@/components/ui/data-table/data-table-faceted-filter"
import { useQuery } from "@tanstack/react-query"
import { supabase } from "@/lib/supabase"
import { type Company } from "@/types"
import { getClassList } from "@/features/reports/services/report-service"

interface DataTableToolbarProps<TData> {
    table: Table<TData>
}

export function DataTableToolbar<TData>({
    table,
}: DataTableToolbarProps<TData>) {
    const isFiltered = table.getState().columnFilters.length > 0

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

    const { data: classList = [] } = useQuery({
        queryKey: ['class-list'],
        queryFn: getClassList,
        staleTime: 0,
    })

    const classOptions = classList.map((cls) => ({
        label: cls,
        value: cls,
        icon: GraduationCap,
    }))

    const companyOptions = companies.map((company) => ({
        label: company.name,
        value: company.name, // The student object has placements[0].companies.name
        icon: Building2,
    }))

    const statusOptions = [
        { label: "Aktif", value: "active", icon: CheckCircle2 },
        { label: "Pending", value: "pending", icon: Clock },
        { label: "Suspended", value: "suspended", icon: Ban },
    ]

    return (
        <div className="flex items-center justify-between">
            <div className="flex flex-1 items-center space-x-2">
                <Input
                    placeholder="Filter siswa..."
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
                        options={classOptions}
                    />
                )}
                {table.getColumn("status") && (
                    <DataTableFacetedFilter
                        column={table.getColumn("status")}
                        title="Status"
                        options={statusOptions}
                    />
                )}
                {table.getColumn("placement") && (
                    <DataTableFacetedFilter
                        column={table.getColumn("placement")}
                        title="DUDI"
                        options={companyOptions}
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
        </div>
    )
}
