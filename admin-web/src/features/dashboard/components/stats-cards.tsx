
import { Users, Clock, UserX, TrendingUp } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import {
    Card,
    CardDescription,
    CardFooter,
    CardHeader,
    CardTitle,
} from "@/components/ui/card"

interface StatsCardsProps {
    totalStudents: number
    stats?: Record<string, number>
}

export function StatsCards({ totalStudents, stats }: StatsCardsProps) {
    const hadir = stats?.Hadir || 0
    const terlambat = stats?.Terlambat || 0
    const tidakHadir = (stats?.Sakit || 0) + (stats?.Izin || 0) + (stats?.Alpa || 0) + (stats?.['Belum Hadir'] || 0)

    // Calculate percentages
    const hadirPercent = totalStudents > 0 ? ((hadir / totalStudents) * 100).toFixed(1) : "0"
    const terlambatPercent = totalStudents > 0 ? ((terlambat / totalStudents) * 100).toFixed(1) : "0"
    const tidakHadirPercent = totalStudents > 0 ? ((tidakHadir / totalStudents) * 100).toFixed(1) : "0"

    return (
        <div className="grid grid-cols-1 gap-4 *:data-[slot=card]:shadow-xs lg:grid-cols-2 xl:grid-cols-4">
            {/* Total Siswa */}
            <Card className="@container/card">
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardDescription>Total Siswa</CardDescription>
                    <Badge variant="outline" className="ml-auto">
                        <Users className="mr-1 size-3" />
                        100%
                    </Badge>
                </CardHeader>
                <CardHeader className="pt-0">
                    <CardTitle className="text-2xl font-semibold tabular-nums @[250px]/card:text-3xl">
                        {totalStudents}
                    </CardTitle>
                </CardHeader>
                <CardFooter className="flex-col items-start gap-1.5 text-sm">
                    <div className="line-clamp-1 flex gap-2 font-medium">
                        Terdaftar dalam sistem
                    </div>
                </CardFooter>
            </Card>

            {/* Hadir */}
            <Card className="@container/card">
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardDescription>Hadir</CardDescription>
                    <Badge variant="outline" className="ml-auto border-emerald-500 text-emerald-600 bg-emerald-50/50">
                        <TrendingUp className="mr-1 size-3" />
                        {hadirPercent}%
                    </Badge>
                </CardHeader>
                <CardHeader className="pt-0">
                    <CardTitle className="text-2xl font-semibold tabular-nums @[250px]/card:text-3xl">
                        {hadir}
                    </CardTitle>
                </CardHeader>
                <CardFooter className="flex-col items-start gap-1.5 text-sm">
                    <div className="line-clamp-1 flex gap-2 font-medium text-emerald-600">
                        Hadir tepat waktu
                    </div>
                </CardFooter>
            </Card>

            {/* Terlambat */}
            <Card className="@container/card">
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardDescription>Terlambat</CardDescription>
                    <Badge variant="outline" className="ml-auto border-amber-500 text-amber-600 bg-amber-50/50">
                        <Clock className="mr-1 size-3" />
                        {terlambatPercent}%
                    </Badge>
                </CardHeader>
                <CardHeader className="pt-0">
                    <CardTitle className="text-2xl font-semibold tabular-nums @[250px]/card:text-3xl">
                        {terlambat}
                    </CardTitle>
                </CardHeader>
                <CardFooter className="flex-col items-start gap-1.5 text-sm">
                    <div className="line-clamp-1 flex gap-2 font-medium text-amber-600">
                        Datang terlambat
                    </div>
                </CardFooter>
            </Card>

            {/* Tidak Hadir (Sakit/Izin/Alpha) */}
            <Card className="@container/card">
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardDescription>Tidak Hadir</CardDescription>
                    <Badge variant="outline" className="ml-auto border-red-500 text-red-600 bg-red-50/50">
                        <UserX className="mr-1 size-3" />
                        {tidakHadirPercent}%
                    </Badge>
                </CardHeader>
                <CardHeader className="pt-0">
                    <CardTitle className="text-2xl font-semibold tabular-nums @[250px]/card:text-3xl">
                        {tidakHadir}
                    </CardTitle>
                </CardHeader>
                <CardFooter className="flex-col items-start gap-1.5 text-sm">
                    <div className="line-clamp-1 flex gap-2 font-medium text-red-600">
                        Sakit, Izin, atau Alpha
                    </div>
                </CardFooter>
            </Card>
        </div>
    )
}
