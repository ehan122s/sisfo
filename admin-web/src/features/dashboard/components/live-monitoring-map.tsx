import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useState } from 'react'
import { Loader2 } from 'lucide-react'
import { MapContainer, TileLayer, CircleMarker, Popup } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'

const defaultCenter: [number, number] = [-6.9175, 107.6191]

interface StudentInfo {
    id: string
    name: string
    status: 'Hadir' | 'Belum Hadir'
    time?: string
    className?: string
}

interface MapMarker {
    id: string
    lat: number
    lng: number
    students: StudentInfo[]
    count: number
    status: 'Hadir' | 'Belum Hadir' | 'Campuran'
    color: 'green' | 'red'
    label?: string
}

export function LiveMonitoringMap() {
    const deg2rad = (deg: number) => deg * (Math.PI / 180)
    const getDistance = (lat1: number, lon1: number, lat2: number, lon2: number) => {
        const R = 6371
        const dLat = deg2rad(lat2 - lat1)
        const dLon = deg2rad(lon2 - lon1)
        const a = Math.sin(dLat / 2) ** 2 +
            Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon / 2) ** 2
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 1000
    }

    const { data: markers = [], isLoading } = useQuery({
        queryKey: ['liveMonitoring'],
        queryFn: async () => {
            const { data: students } = await supabase
                .from('profiles')
                .select('id, full_name, class_name, status, placements(companies(id, name, latitude, longitude))')
                .eq('status', 'active')

            const now = new Date()
            const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString()
            const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59).toISOString()

            const { data: attendanceLogs } = await supabase
                .from('attendance_logs')
                .select('student_id, check_in_latitude, check_in_longitude, check_in_time, status')
                .eq('status', 'Hadir')
                .gte('created_at', startOfDay)
                .lte('created_at', endOfDay)

            const groupedMarkers: Record<string, MapMarker> = {}

            students?.forEach((student) => {
                const attendance = attendanceLogs?.find((log) => log.student_id === student.id)
                const placements = student.placements as any[]
                const company = placements?.[0]?.companies

                if (attendance && attendance.check_in_latitude && attendance.check_in_longitude) {
                    let foundGroup = false
                    for (const key in groupedMarkers) {
                        const marker = groupedMarkers[key]
                        if (marker.status === 'Hadir') {
                            const distance = getDistance(marker.lat, marker.lng, attendance.check_in_latitude, attendance.check_in_longitude)
                            if (distance < 50) {
                                marker.students.push({ id: student.id, name: student.full_name, status: 'Hadir', time: attendance.check_in_time, className: student.class_name })
                                marker.count += 1
                                foundGroup = true
                                break
                            }
                        }
                    }
                    if (!foundGroup) {
                        const key = `checkin-${student.id}`
                        groupedMarkers[key] = {
                            id: key,
                            lat: attendance.check_in_latitude,
                            lng: attendance.check_in_longitude,
                            students: [{ id: student.id, name: student.full_name, status: 'Hadir', time: attendance.check_in_time, className: student.class_name }],
                            count: 1, status: 'Hadir', color: 'green', label: student.full_name
                        }
                    }
                } else if (company?.latitude && company?.longitude) {
                    const key = `company-${company.id}`
                    if (!groupedMarkers[key]) {
                        groupedMarkers[key] = {
                            id: key, lat: company.latitude, lng: company.longitude,
                            students: [], count: 0, status: 'Belum Hadir', color: 'red', label: company.name
                        }
                    }
                    groupedMarkers[key].students.push({ id: student.id, name: student.full_name, status: 'Belum Hadir', className: student.class_name })
                    groupedMarkers[key].count += 1
                }
            })

            return Object.values(groupedMarkers)
        },
        refetchInterval: 30000,
    })

    const presentCount = markers.reduce((acc, m) => acc + (m.status === 'Hadir' ? m.count : 0), 0)
    const absentCount = markers.reduce((acc, m) => acc + (m.status === 'Belum Hadir' ? m.count : 0), 0)

    if (isLoading) {
        return (
            <Card>
                <CardHeader><CardTitle>Live Monitoring</CardTitle></CardHeader>
                <CardContent className="h-[600px] flex items-center justify-center">
                    <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                </CardContent>
            </Card>
        )
    }

    return (
        <Card>
            <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle>Live Monitoring</CardTitle>
                <div className="flex gap-4 text-sm">
                    <span className="flex items-center gap-1">
                        <span className="h-3 w-3 rounded-full bg-green-500" />
                        Hadir: {presentCount}
                    </span>
                    <span className="flex items-center gap-1">
                        <span className="h-3 w-3 rounded-full bg-red-500" />
                        Belum Hadir: {absentCount}
                    </span>
                </div>
            </CardHeader>
            <CardContent>
                <div style={{ height: '600px', width: '100%', borderRadius: '0.5rem', overflow: 'hidden' }}>
                    <MapContainer center={defaultCenter} zoom={10} style={{ height: '100%', width: '100%' }}>
                        <TileLayer
                            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                        />
                        {markers.map((marker) => (
                            <CircleMarker
                                key={marker.id}
                                center={[marker.lat, marker.lng]}
                                radius={10 + Math.min(marker.count * 2, 20)}
                                pathOptions={{
                                    fillColor: marker.color === 'green' ? '#22c55e' : '#ef4444',
                                    fillOpacity: 0.8,
                                    color: '#ffffff',
                                    weight: 2,
                                }}
                            >
                                <Popup>
                                    <div className="p-1 max-w-[280px]">
                                        <h3 className="font-bold text-sm mb-2 border-b pb-1">
                                            {marker.label}
                                        </h3>
                                        <div className="space-y-1 max-h-[200px] overflow-y-auto">
                                            {marker.students.map((student, idx) => (
                                                <div key={idx} className="flex justify-between items-center text-xs py-1 border-b last:border-0">
                                                    <div>
                                                        <div className="font-medium">{student.name}</div>
                                                        <div className="text-gray-500">{student.className}</div>
                                                        {student.time && (
                                                            <div className="text-green-600">
                                                                Check-in: {new Date(student.time).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}
                                                            </div>
                                                        )}
                                                    </div>
                                                    <span className={`px-2 py-0.5 rounded-full text-[10px] ${student.status === 'Hadir' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                                                        {student.status}
                                                    </span>
                                                </div>
                                            ))}
                                        </div>
                                        <div className="mt-2 text-xs text-gray-500 text-right font-medium">
                                            Total: {marker.count} Siswa
                                        </div>
                                    </div>
                                </Popup>
                            </CircleMarker>
                        ))}
                    </MapContainer>
                </div>
            </CardContent>
        </Card>
    )
}