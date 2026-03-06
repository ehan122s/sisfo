import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

interface StatusDistributionChartProps {
    data: {
        Hadir: number
        Terlambat: number
        Izin: number
        Sakit: number
        'Belum Hadir': number
    }
}

export function StatusDistributionChart({ data }: StatusDistributionChartProps) {
    const chartData = [
        { name: 'Hadir', value: data.Hadir, color: '#16a34a' }, // green-600
        { name: 'Terlambat', value: data.Terlambat, color: '#f59e0b' }, // amber-500
        { name: 'Izin', value: data.Izin, color: '#2563eb' }, // blue-600
        { name: 'Sakit', value: data.Sakit, color: '#9333ea' }, // purple-600
        { name: 'Belum Hadir', value: data['Belum Hadir'], color: '#9ca3af' }, // gray-400
    ].filter(item => item.value > 0)

    return (
        <Card className="transition-all duration-300 hover:shadow-lg hover:shadow-emerald-500/10 hover:-translate-y-0.5">
            <CardHeader>
                <CardTitle>Distribusi Kehadiran Hari Ini</CardTitle>
            </CardHeader>
            <CardContent>
                <div className="h-[300px]">
                    <ResponsiveContainer width="100%" height="100%">
                        <PieChart>
                            <Pie
                                data={chartData}
                                cx="50%"
                                cy="50%"
                                innerRadius={60}
                                outerRadius={80}
                                paddingAngle={5}
                                dataKey="value"
                            >
                                {chartData.map((entry, index) => (
                                    <Cell key={`cell-${index}`} fill={entry.color} />
                                ))}
                            </Pie>
                            <Tooltip />
                            <Legend />
                        </PieChart>
                    </ResponsiveContainer>
                </div>
            </CardContent>
        </Card>
    )
}
