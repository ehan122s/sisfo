import { useState } from "react"
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table"
import { Input } from "@/components/ui/input"
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select"
import { Button } from "@/components/ui/button"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Search, MapPin, Eye, ChevronLeft, ChevronRight } from "lucide-react"
import { useNavigate } from "react-router-dom"
import { TableRowsSkeleton } from '@/components/ui/table-skeleton'

interface StudentsTableProps { }

export function StudentsTable({ }: StudentsTableProps) {
    const navigate = useNavigate()
    const [search, setSearch] = useState("")
    const [selectedClass, setSelectedClass] = useState<string>("all")
    const [selectedCompany, setSelectedCompany] = useState<string>("all")

    // Fetch Unique Classes
    const { data: classes = [] } = useQuery({
        queryKey: ['classes'],
        queryFn: async () => {
            const { data } = await supabase
                .from('profiles')
                .select('class_name')
                .not('class_name', 'is', null)
                .order('class_name')

            // Extract unique class names
            const uniqueClasses = Array.from(new Set(data?.map(item => item.class_name) || []))
            return uniqueClasses
        }
    })

    // Fetch Companies
    const { data: companies = [] } = useQuery({
        queryKey: ['companies'],
        queryFn: async () => {
            const { data } = await supabase
                .from('companies')
                .select('id, name')
                .order('name')
            return data
        }
    })

    // Fetch Students with Filters
    const { data: students, isLoading } = useQuery({
        queryKey: ['students-report', search, selectedClass, selectedCompany],
        queryFn: async () => {
            let query = supabase
                .from('profiles')
                .select('*, placements(companies(id, name))')
                .eq('role', 'student')
                .order('full_name')

            if (search) {
                query = query.ilike('full_name', `%${search}%`)
            }

            if (selectedClass !== 'all') {
                query = query.eq('class_name', selectedClass)
            }

            // Filtering by company is tricky because it's in a joined table.
            // For now, we'll filter on client side if company is selected, or try to use !inner join if needed.
            // Using !inner on placements would filter out students without placements. 
            // Let's fetch and filter for simplicity for now as dataset isn't huge yet.

            const { data, error } = await query

            if (error) throw error

            let filteredData = data

            if (selectedCompany !== 'all') {
                filteredData = data?.filter(student =>
                    student.placements?.[0]?.companies?.id?.toString() === selectedCompany
                ) || []
            }

            return filteredData
        }
    })

    const handleDetailClick = (studentId: string) => {
        navigate(`/monitoring/${studentId}`)
    }

    const [page, setPage] = useState(0)
    const pageSize = 10



    // Improved handlers to reset page
    const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setSearch(e.target.value)
        setPage(0)
    }

    const handleClassChange = (value: string) => {
        setSelectedClass(value)
        setPage(0)
    }

    const handleCompanyChange = (value: string) => {
        setSelectedCompany(value)
        setPage(0)
    }

    // Paginate logic
    const filteredStudents = students || []
    const totalPages = Math.ceil(filteredStudents.length / pageSize)
    const paginatedStudents = filteredStudents.slice(page * pageSize, (page + 1) * pageSize)

    return (
        <div className="space-y-4">
            {/* Filters */}
            <div className="flex flex-col md:flex-row gap-4">
                <div className="relative flex-1">
                    <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                    <Input
                        placeholder="Cari siswa..."
                        value={search}
                        onChange={handleSearchChange}
                        className="pl-9"
                    />
                </div>
                <Select value={selectedClass} onValueChange={handleClassChange}>
                    <SelectTrigger className="w-full md:w-[200px]">
                        <SelectValue placeholder="Semua Kelas" />
                    </SelectTrigger>
                    <SelectContent>
                        <SelectItem value="all">Semua Kelas</SelectItem>
                        {classes.map((cls) => (
                            <SelectItem key={cls} value={cls}>{cls}</SelectItem>
                        ))}
                    </SelectContent>
                </Select>
                <Select value={selectedCompany} onValueChange={handleCompanyChange}>
                    <SelectTrigger className="w-full md:w-[250px]">
                        <SelectValue placeholder="Semua DUDI" />
                    </SelectTrigger>
                    <SelectContent>
                        <SelectItem value="all">Semua DUDI</SelectItem>
                        {companies?.map((company) => (
                            <SelectItem key={company.id} value={company.id.toString()}>
                                {company.name}
                            </SelectItem>
                        ))}
                    </SelectContent>
                </Select>
            </div>

            {/* Table */}
            <div className="rounded-md border bg-white">
                <Table>
                    <TableHeader>
                        <TableRow>
                            <TableHead>Nama Siswa</TableHead>
                            <TableHead>Kelas</TableHead>
                            <TableHead>Tempat PKL (DUDI)</TableHead>
                            <TableHead>Status</TableHead>
                            <TableHead className="text-right">Aksi</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {isLoading ? (
                            <TableRowsSkeleton columnCount={5} rowCount={5} />
                        ) : filteredStudents.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={5} className="h-24 text-center text-muted-foreground">
                                    Tidak ada data siswa ditemukan.
                                </TableCell>
                            </TableRow>
                        ) : (
                            paginatedStudents.map((student) => (
                                <TableRow key={student.id}>
                                    <TableCell>
                                        <div className="flex items-center gap-3">
                                            <Avatar className="h-9 w-9">
                                                <AvatarImage src={student.avatar_url} />
                                                <AvatarFallback>{student.full_name?.substring(0, 2).toUpperCase()}</AvatarFallback>
                                            </Avatar>
                                            <div className="font-medium">{student.full_name}</div>
                                        </div>
                                    </TableCell>
                                    <TableCell>{student.class_name || '-'}</TableCell>
                                    <TableCell>
                                        <div className="flex items-center gap-2">
                                            <MapPin className="h-3 w-3 text-muted-foreground" />
                                            {student.placements?.[0]?.companies?.name || <span className="text-muted-foreground italic">Belum ditempatkan</span>}
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        <Badge variant={student.status === 'active' ? 'default' : 'secondary'}>
                                            {student.status === 'active' ? 'Aktif' : 'Non-Aktif'}
                                        </Badge>
                                    </TableCell>
                                    <TableCell className="text-right">
                                        <Button
                                            variant="ghost"
                                            size="sm"
                                            onClick={() => handleDetailClick(student.id)}
                                        >
                                            <Eye className="h-4 w-4 mr-2" />
                                            Detail
                                        </Button>
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </div>

            {/* Pagination Controls */}
            {!isLoading && filteredStudents.length > 0 && (
                <div className="flex items-center justify-end space-x-2 py-4">
                    <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPage((p) => Math.max(0, p - 1))}
                        disabled={page === 0}
                    >
                        <ChevronLeft className="h-4 w-4" />
                        Previous
                    </Button>
                    <div className="text-sm text-muted-foreground">
                        Page {page + 1} of {totalPages}
                    </div>
                    <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
                        disabled={page >= totalPages - 1}
                    >
                        Next
                        <ChevronRight className="h-4 w-4" />
                    </Button>
                </div>
            )}
        </div>
    )
}
