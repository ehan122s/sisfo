"use client"

import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { TrendingUp, Building2 } from "lucide-react"
import { Bar, BarChart, XAxis, YAxis, CartesianGrid } from "recharts"

import {
    Card,
    CardContent,
    CardDescription,
    CardFooter,
    CardHeader,
    CardTitle,
} from "@/components/ui/card"
import {
    ChartContainer,
    ChartTooltip,
    ChartTooltipContent,
    type ChartConfig,
} from "@/components/ui/chart"
import { Skeleton } from '@/components/ui/skeleton'

export function CompanyDistributionChart() {
    const { data: distribution = [], isLoading } = useQuery({
        queryKey: ['companyDistribution'],
        queryFn: async () => {
            const { data: students } = await supabase
                .from('profiles')
                .select('id, placements(company_id, companies(name))')

            const companyCounts: Record<string, number> = {}

            students?.forEach((student) => {
                const placements = student.placements as unknown as { companies: { name: string } | null }[] | null
                if (placements && placements.length > 0 && placements[0].companies) {
                    const companyName = placements[0].companies.name
                    companyCounts[companyName] = (companyCounts[companyName] ?? 0) + 1
                } else {
                    companyCounts['Belum Ada DUDI'] = (companyCounts['Belum Ada DUDI'] ?? 0) + 1
                }
            })

            const sorted = Object.entries(companyCounts)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 10)
                .map(([name, count]) => ({
                    company: name,
                    students: count
                }))

            return sorted
        },
    })

    const chartConfig = {
        students: {
            label: "Siswa",
            color: "#2563eb", 
        },
    } satisfies ChartConfig

    if (isLoading) {
        return <Skeleton className="h-[400px] w-full rounded-3xl" />
    }

    return (
        <Card className="border-none shadow-none bg-transparent">
            <CardHeader className="px-0 pt-0">
                <div className="flex items-center gap-2 mb-1">
                    <Building2 className="w-4 h-4 text-blue-600" />
                    <CardTitle className="text-lg font-bold text-slate-800">Distribusi Siswa Per Dudi</CardTitle>
                </div>
                <CardDescription>Top 10 Perusahaan dengan penempatan terbanyak</CardDescription>
            </CardHeader>
            <CardContent className="px-0">
                <ChartContainer config={chartConfig} className="min-h-[300px] w-full">
                    <BarChart
                        accessibilityLayer
                        data={distribution}
                        layout="vertical"
                        margin={{ left: 10, right: 20 }}
                    >
                        {/* 1. Definisi Gradasi Warna */}
                        <defs>
                            <linearGradient id="colorBlue" x1="0" y1="0" x2="1" y2="0">
                                <stop offset="5%" stopColor="#2563eb" stopOpacity={0.9}/>
                                <stop offset="95%" stopColor="#60a5fa" stopOpacity={0.8}/>
                            </linearGradient>
                        </defs>

                        <CartesianGrid horizontal={false} strokeDasharray="3 3" stroke="#f1f5f9" />
                        <XAxis type="number" dataKey="students" hide />
                        <YAxis
                            dataKey="company"
                            type="category"
                            tickLine={false}
                            tickMargin={10}
                            axisLine={false}
                            width={130}
                            className="text-[10px] font-bold text-slate-500 uppercase"
                            tickFormatter={(value) => value.length > 15 ? `${value.slice(0, 15)}...` : value}
                        />
                        <ChartTooltip
                            cursor={{ fill: '#f1f5f9', opacity: 0.4 }}
                            content={<ChartTooltipContent hideLabel />}
                        />
                        
                        {/* 2. Panggil ID Gradasi di fill */}
                        <Bar 
                            dataKey="students" 
                            fill="url(#colorBlue)" 
                            radius={[0, 6, 6, 0]} 
                            barSize={22}
                        />
                    </BarChart>
                </ChartContainer>
            </CardContent>
            <CardFooter className="flex-col items-start gap-2 text-sm px-0 pb-0">
                <div className="flex gap-2 leading-none font-bold text-blue-600">
                    Analisis Penempatan <TrendingUp className="h-4 w-4" />
                </div>
                <div className="text-[11px] text-slate-400 font-medium">
                    Data sinkron otomatis dengan database Supabase
                </div>
            </CardFooter>
        </Card>
    )
}