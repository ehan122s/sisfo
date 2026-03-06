"use client"

import * as React from "react"
import { Area, AreaChart, CartesianGrid, XAxis } from "recharts"

import { useIsMobile } from "@/hooks/use-mobile"
import {
    Card,
    CardAction,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from "@/components/ui/card"
import {
    ChartContainer,
    ChartTooltip,
    ChartTooltipContent,
    type ChartConfig,
} from "@/components/ui/chart"
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select"
import {
    ToggleGroup,
    ToggleGroupItem,
} from "@/components/ui/toggle-group"

export const description = "An interactive area chart"

const chartConfig = {
    kehadiran: {
        label: "Total Kehadiran",
    },
    hadir: {
        label: "Hadir",
        color: "hsl(142.1 76.2% 36.3%)", // Green-600
    },
    tidakHadir: {
        label: "Tidak Hadir",
        color: "hsl(0 84.2% 60.2%)", // Red-500
    },
} satisfies ChartConfig

interface ChartAreaInteractiveProps {
    data: {
        date: string // YYYY-MM-DD
        Hadir: number
        TidakHadir: number
    }[]
}

export function ChartAreaInteractive({ data }: ChartAreaInteractiveProps) {
    const isMobile = useIsMobile()
    const [timeRange, setTimeRange] = React.useState("30d")

    React.useEffect(() => {
        if (isMobile) {
            setTimeRange("7d")
        }
    }, [isMobile])

    // Map incoming data to chart format
    const formattedData = React.useMemo(() => {
        return data.map(item => ({
            date: item.date,
            hadir: item.Hadir,
            tidakHadir: item.TidakHadir
        }))
    }, [data])

    const filteredData = formattedData.filter((item) => {
        const date = new Date(item.date)
        const referenceDate = new Date() // Use today as reference
        let daysToSubtract = 90
        if (timeRange === "30d") {
            daysToSubtract = 30
        } else if (timeRange === "7d") {
            daysToSubtract = 7
        }
        const startDate = new Date(referenceDate)
        startDate.setDate(startDate.getDate() - daysToSubtract)
        return date >= startDate
    })

    return (
        <Card className="@container/card">
            <CardHeader>
                <CardTitle>Overview Kehadiran</CardTitle>
                <CardDescription>
                    <span className="hidden @[540px]/card:block">
                        Menampilkan tren kehadiran siswa
                    </span>
                    <span className="@[540px]/card:hidden">Tren kehadiran</span>
                </CardDescription>
                <CardAction>
                    <ToggleGroup
                        type="single"
                        value={timeRange}
                        onValueChange={setTimeRange}
                        variant="outline"
                        className="hidden *:data-[slot=toggle-group-item]:!px-4 @[767px]/card:flex"
                    >
                        <ToggleGroupItem value="90d">3 Bulan</ToggleGroupItem>
                        <ToggleGroupItem value="30d">30 Hari</ToggleGroupItem>
                        <ToggleGroupItem value="7d">7 Hari</ToggleGroupItem>
                    </ToggleGroup>
                    <Select value={timeRange} onValueChange={setTimeRange}>
                        <SelectTrigger
                            className="flex w-40 **:data-[slot=select-value]:block **:data-[slot=select-value]:truncate @[767px]/card:hidden"
                            size="sm"
                            aria-label="Select a value"
                        >
                            <SelectValue placeholder="30 Hari Terakhir" />
                        </SelectTrigger>
                        <SelectContent className="rounded-xl">
                            <SelectItem value="90d" className="rounded-lg">
                                3 Bulan Terakhir
                            </SelectItem>
                            <SelectItem value="30d" className="rounded-lg">
                                30 Hari Terakhir
                            </SelectItem>
                            <SelectItem value="7d" className="rounded-lg">
                                7 Hari Terakhir
                            </SelectItem>
                        </SelectContent>
                    </Select>
                </CardAction>
            </CardHeader>
            <CardContent className="px-2 pt-4 sm:px-6 sm:pt-6">
                <ChartContainer
                    config={chartConfig}
                    className="aspect-auto h-[250px] w-full"
                >
                    <AreaChart data={filteredData}>
                        <defs>
                            <linearGradient id="fillHadir" x1="0" y1="0" x2="0" y2="1">
                                <stop
                                    offset="5%"
                                    stopColor="var(--color-hadir)"
                                    stopOpacity={1.0}
                                />
                                <stop
                                    offset="95%"
                                    stopColor="var(--color-hadir)"
                                    stopOpacity={0.1}
                                />
                            </linearGradient>
                            <linearGradient id="fillTidakHadir" x1="0" y1="0" x2="0" y2="1">
                                <stop
                                    offset="5%"
                                    stopColor="var(--color-tidakHadir)"
                                    stopOpacity={0.8}
                                />
                                <stop
                                    offset="95%"
                                    stopColor="var(--color-tidakHadir)"
                                    stopOpacity={0.1}
                                />
                            </linearGradient>
                        </defs>
                        <CartesianGrid vertical={false} />
                        <XAxis
                            dataKey="date"
                            tickLine={false}
                            axisLine={false}
                            tickMargin={8}
                            minTickGap={32}
                            tickFormatter={(value) => {
                                const date = new Date(value)
                                return date.toLocaleDateString("id-ID", {
                                    month: "short",
                                    day: "numeric",
                                })
                            }}
                        />
                        <ChartTooltip
                            cursor={false}
                            content={
                                <ChartTooltipContent
                                    labelFormatter={(value) => {
                                        return new Date(value).toLocaleDateString("id-ID", {
                                            month: "short",
                                            day: "numeric",
                                        })
                                    }}
                                    indicator="dot"
                                />
                            }
                        />
                        <Area
                            dataKey="tidakHadir"
                            type="natural"
                            fill="url(#fillTidakHadir)"
                            stroke="var(--color-tidakHadir)"
                            stackId="a"
                        />
                        <Area
                            dataKey="hadir"
                            type="natural"
                            fill="url(#fillHadir)"
                            stroke="var(--color-hadir)"
                            stackId="a"
                        />
                    </AreaChart>
                </ChartContainer>
            </CardContent>
        </Card>
    )
}
