"use client"

import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { TrendingUp } from "lucide-react"
import { Pie, PieChart } from "recharts"

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
    ChartLegend,
    ChartLegendContent,
    ChartTooltip,
    ChartTooltipContent,
    type ChartConfig,
} from "@/components/ui/chart"
import { Skeleton } from '@/components/ui/skeleton'

// Green palette for the chart
const CHART_COLORS = [
    "hsl(142.1 76.2% 36.3%)", // Green 600
    "hsl(142.1 70.6% 45.3%)", // Green 500
    "hsl(142.1 76.2% 36.3%)", // Green 600 (reuse or vary?) -> Let's vary
    "#4ade80", // Green 400
    "#86efac", // Green 300
    "#bbf7d0", // Green 200
]

export function CityDistributionChart() {
    const { data: chartData = [], isLoading } = useQuery({
        queryKey: ['cityDistribution'],
        queryFn: async () => {
            // Get all students with placements and company addresses
            const { data: students } = await supabase
                .from('profiles')
                .select('id, placements(companies(address))')

            const cityCounts: Record<string, number> = {}
            const cityRegex = /\b(Kota|Kabupaten|Kab\.?)\s+([^,0-9]+)/i

            students?.forEach((student) => {
                const placements = student.placements as unknown as { companies: { address: string } | null }[] | null
                if (placements && placements.length > 0 && placements[0].companies?.address) {
                    const address = placements[0].companies.address
                    const match = cityRegex.exec(address)

                    if (match) {
                        let city = match[0].trim().replace(/[,\.]+$/, '')
                        // Normalize to Title Case
                        city = city.split(' ').map(word =>
                            word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
                        ).join(' ')
                        // Normalize "Kab" to "Kabupaten"
                        if (city.toLowerCase().startsWith('kab ') || city.toLowerCase().startsWith('kab. ')) {
                            city = city.replace(/Kab\.?\s+/i, 'Kabupaten ')
                        }
                        cityCounts[city] = (cityCounts[city] ?? 0) + 1
                    } else {
                        cityCounts['Lainnya'] = (cityCounts['Lainnya'] ?? 0) + 1
                    }
                }
            })

            // Sort by count descending
            const sorted = Object.entries(cityCounts)
                .sort((a, b) => b[1] - a[1])

            // Take top 5 and aggregate the rest
            const top5 = sorted.slice(0, 5)
            const others = sorted.slice(5)

            const finalData = top5.map(([city, count], index) => ({
                city: city,
                visitors: count,
                fill: CHART_COLORS[index % CHART_COLORS.length]
            }))

            if (others.length > 0) {
                const otherCount = others.reduce((acc, [, count]) => acc + count, 0)
                finalData.push({
                    city: "Lainnya",
                    visitors: otherCount,
                    fill: "#94a3b8" // slate-400 for 'Lainnya'
                })
            }

            return finalData
        },
    })

    const chartConfig = {
        visitors: {
            label: "Siswa",
        },
        // Since we use dynamic cities, we rely on 'city' key in data for labels
        // and 'fill' for colors. Use generic config or empty if not strictly needed for legend names
        // (Legend content usually falls back to nameKey)
    } satisfies ChartConfig

    if (isLoading) {
        return <Skeleton className="h-[300px] w-full" />
    }

    return (
        <Card className="flex flex-col">
            <CardHeader className="items-center pb-0">
                <CardTitle>Sebaran Lokasi Siswa</CardTitle>
                <CardDescription>Berdasarkan Kota/Kabupaten DUDI</CardDescription>
            </CardHeader>
            <CardContent className="flex-1 pb-0">
                <ChartContainer
                    config={chartConfig}
                    className="mx-auto aspect-square max-h-[300px]"
                >
                    <PieChart>
                        <Pie
                            data={chartData}
                            dataKey="visitors"
                            nameKey="city"
                        />
                        <ChartTooltip
                            cursor={false}
                            content={<ChartTooltipContent hideLabel />}
                        />
                        <ChartLegend
                            content={<ChartLegendContent nameKey="city" />}
                            className="-translate-y-2 flex-wrap gap-2 *:basis-1/4 *:justify-center"
                        />
                    </PieChart>
                </ChartContainer>
            </CardContent>
            <CardFooter className="flex-col gap-2 text-sm">
                <div className="flex items-center gap-2 leading-none font-medium">
                    Data Lokasi Terkini <TrendingUp className="h-4 w-4" />
                </div>
                <div className="text-muted-foreground leading-none">
                    Menampilkan distribusi wilayah siswa PKL
                </div>
            </CardFooter>
        </Card>
    )
}
