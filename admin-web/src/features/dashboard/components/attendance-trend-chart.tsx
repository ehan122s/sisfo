import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

interface AttendanceTrendChartProps {
    data: {
        date: string
        Hadir: number
        Terlambat: number
        Izin: number
        Sakit: number
    }[]
}

export function AttendanceTrendChart({ data }: AttendanceTrendChartProps) {
    return (
        <Card className="transition-all duration-300 hover:shadow-lg hover:shadow-emerald-500/10 hover:-translate-y-0.5">
            <CardHeader>
                <CardTitle>Tren Kehadiran (7 Hari Terakhir)</CardTitle>
            </CardHeader>
            <CardContent>
                <div className="h-[300px]">
                    <ResponsiveContainer width="100%" height="100%">
                        <BarChart
                            data={data}
                            margin={{
                                top: 20,
                                right: 30,
                                left: 20,
                                bottom: 5,
                            }}
                        >
                            <CartesianGrid strokeDasharray="3 3" vertical={false} />
                            <XAxis dataKey="date" />
                            <YAxis />
                            <Tooltip />
                            <Legend />
                            <Bar dataKey="Hadir" stackId="a" fill="#16a34a" />
                            <Bar dataKey="Terlambat" stackId="a" fill="#f59e0b" />
                            <Bar dataKey="Izin" stackId="a" fill="#2563eb" />
                            <Bar dataKey="Sakit" stackId="a" fill="#9333ea" />
                        </BarChart>
                    </ResponsiveContainer>
                </div>
            </CardContent>
        </Card>
    )
}
