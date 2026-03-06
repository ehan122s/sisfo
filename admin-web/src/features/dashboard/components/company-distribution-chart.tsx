"use client"

import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { TrendingUp } from "lucide-react"
import { Bar, BarChart, XAxis, YAxis } from "recharts"

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
            // Get all students with placements
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

            // Sort by count descending and take top 10 for better visualization
            const sorted = Object.entries(companyCounts)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 10) // Limit to top 10
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
            color: "hsl(142.1 76.2% 36.3%)", // Green 600
        },
    } satisfies ChartConfig

    if (isLoading) {
        return <Skeleton className="h-[400px] w-full" />
    }

    return (
        <Card>
            <CardHeader>
                <CardTitle>Distribusi Siswa Per Dudi</CardTitle>
                <CardDescription>Top 10 Perusahaan dengan Siswa Terbanyak</CardDescription>
            </CardHeader>
            <CardContent>
                <ChartContainer config={chartConfig}>
                    <BarChart
                        accessibilityLayer
                        data={distribution}
                        layout="vertical"
                        margin={{
                            left: 0, // Adjusted from -20 to 0 to give slightly more space for long names if needed, or strictly -20 if labels are short.
                            // Recharts automatic layout usually handles YAxis width if not fixed.
                        }}
                    >
                        <XAxis type="number" dataKey="students" hide />
                        <YAxis
                            dataKey="company"
                            type="category"
                            tickLine={false}
                            tickMargin={10}
                            axisLine={false}
                            width={150} // Give enough fixed width for company names
                            tickFormatter={(value) => value.length > 20 ? `${value.slice(0, 20)}...` : value}
                        />
                        <ChartTooltip
                            cursor={false}
                            content={<ChartTooltipContent hideLabel />}
                        />
                        <Bar dataKey="students" fill="var(--color-students)" radius={5} />
                    </BarChart>
                </ChartContainer>
            </CardContent>
            <CardFooter className="flex-col items-start gap-2 text-sm">
                <div className="flex gap-2 leading-none font-medium">
                    Menampilkan top 10 DUDI terbanyak <TrendingUp className="h-4 w-4" />
                </div>
                <div className="text-muted-foreground leading-none">
                    Data berdasarkan penempatan siswa aktif saat ini
                </div>
            </CardFooter>
        </Card>
    )
}
