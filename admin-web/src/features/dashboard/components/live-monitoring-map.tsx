import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { GoogleMap, useJsApiLoader, Marker, InfoWindow } from '@react-google-maps/api'
import { useState, useCallback } from 'react'
import { Loader2 } from 'lucide-react'

const mapContainerStyle = {
    width: '100%',
    height: '600px', // Increased height for better visibility
}

// Default center (Indonesia)
const defaultCenter = {
    lat: -6.9175,
    lng: 107.6191,
}

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

import { GOOGLE_MAPS_LIBRARIES } from '@/lib/google-maps'

export function LiveMonitoringMap() {
    const [selectedMarker, setSelectedMarker] = useState<MapMarker | null>(null)

    const { isLoaded } = useJsApiLoader({
        id: 'google-map-script',
        googleMapsApiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY || '',
        libraries: GOOGLE_MAPS_LIBRARIES,
    })

    const { data: markers = [], isLoading } = useQuery({
        queryKey: ['liveMonitoring'],
        queryFn: async () => {
            // Get all active students with placements
            const { data: students } = await supabase
                .from('profiles')
                .select('id, full_name, class_name, status, placements(companies(id, name, latitude, longitude))')
                .eq('status', 'active')

            // Get today's attendance
            const now = new Date()
            const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString()
            const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59).toISOString()

            const { data: attendanceLogs } = await supabase
                .from('attendance_logs')
                .select('student_id, check_in_lat, check_in_long, check_in_time, status')
                .eq('status', 'Hadir')
                .gte('created_at', startOfDay)
                .lte('created_at', endOfDay)

            const groupedMarkers: Record<string, MapMarker> = {}

            // Helper to calculate distance in meters
            const getDistanceFromLatLonInKm = (lat1: number, lon1: number, lat2: number, lon2: number) => {
                const R = 6371 // Radius of the earth in km
                const dLat = deg2rad(lat2 - lat1)
                const dLon = deg2rad(lon2 - lon1)
                const a =
                    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
                    Math.sin(dLon / 2) * Math.sin(dLon / 2)
                const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
                const d = R * c // Distance in km
                return d * 1000 // Distance in meters
            }

            const deg2rad = (deg: number) => {
                return deg * (Math.PI / 180)
            }

            students?.forEach((student) => {
                const attendance = attendanceLogs?.find((log) => log.student_id === student.id)
                const placements = student.placements as unknown as { companies: { id: number; name: string; latitude: number; longitude: number } | null }[] | null

                if (attendance && attendance.check_in_lat && attendance.check_in_long) {
                    // Student is present - group by proximity (e.g., 50 meters)
                    let foundGroup = false

                    // Try to find an existing green group nearby
                    for (const key in groupedMarkers) {
                        const marker = groupedMarkers[key]
                        if (marker.status === 'Hadir') {
                            const distance = getDistanceFromLatLonInKm(
                                marker.lat, marker.lng,
                                attendance.check_in_lat, attendance.check_in_long
                            )
                            if (distance < 50) { // 50 meters threshold
                                groupedMarkers[key].students.push({
                                    id: student.id,
                                    name: student.full_name,
                                    status: 'Hadir',
                                    time: attendance.check_in_time,
                                    className: student.class_name
                                })
                                groupedMarkers[key].count += 1
                                groupedMarkers[key].label = 'Area Check-in' // Change label to generic when clustering
                                foundGroup = true
                                break
                            }
                        }
                    }

                    if (!foundGroup) {
                        const key = `checkin-${student.id}`
                        groupedMarkers[key] = {
                            id: key,
                            lat: attendance.check_in_lat,
                            lng: attendance.check_in_long,
                            students: [{
                                id: student.id,
                                name: student.full_name,
                                status: 'Hadir',
                                time: attendance.check_in_time,
                                className: student.class_name
                            }],
                            count: 1,
                            status: 'Hadir',
                            color: 'green',
                            label: student.full_name // Use student name for single marker
                        }
                    }

                } else if (placements && placements.length > 0 && placements[0].companies) {
                    const company = placements[0].companies
                    if (company.latitude && company.longitude) {
                        // Student is absent - show at expected company location (Red)
                        // Group by Company ID
                        const key = `company-${company.id}`

                        if (!groupedMarkers[key]) {
                            groupedMarkers[key] = {
                                id: key,
                                lat: company.latitude,
                                lng: company.longitude,
                                students: [],
                                count: 0,
                                status: 'Belum Hadir',
                                color: 'red',
                                label: company.name
                            }
                        }

                        groupedMarkers[key].students.push({
                            id: student.id,
                            name: student.full_name,
                            status: 'Belum Hadir',
                            className: student.class_name
                        })
                        groupedMarkers[key].count += 1
                    }
                }
            })

            return Object.values(groupedMarkers)
        },
        refetchInterval: 30000,
    })

    const onLoad = useCallback((map: google.maps.Map) => {
        if (markers.length > 0) {
            const bounds = new google.maps.LatLngBounds()
            markers.forEach((marker) => {
                bounds.extend({ lat: marker.lat, lng: marker.lng })
            })
            map.fitBounds(bounds)
        }
    }, [markers])

    if (!isLoaded || isLoading) {
        return (
            <Card>
                <CardHeader>
                    <CardTitle>Live Monitoring</CardTitle>
                </CardHeader>
                <CardContent className="h-[600px] flex items-center justify-center">
                    <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                </CardContent>
            </Card>
        )
    }

    const presentCount = markers.reduce((acc, m) => acc + (m.status === 'Hadir' ? m.count : 0), 0)
    // Note: This logic assumes markers are either fully Hadir or fully Belum Hadir. 
    // Since we separated check-ins (single) and company absentees (grouped), this holds true.
    const absentCount = markers.reduce((acc, m) => acc + (m.status === 'Belum Hadir' ? m.count : 0), 0)

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
                <GoogleMap
                    mapContainerStyle={mapContainerStyle}
                    center={defaultCenter}
                    zoom={10}
                    onLoad={onLoad}
                >
                    {markers.map((marker) => (
                        <Marker
                            key={marker.id}
                            position={{ lat: marker.lat, lng: marker.lng }}
                            icon={{
                                path: google.maps.SymbolPath.CIRCLE,
                                scale: 10 + Math.min(marker.count * 2, 20), // Scale size based on count
                                fillColor: marker.color === 'green' ? '#22c55e' : '#ef4444',
                                fillOpacity: 0.8,
                                strokeColor: '#ffffff',
                                strokeWeight: 2,
                            }}
                            label={marker.count > 1 ? {
                                text: marker.count.toString(),
                                color: 'white',
                                fontWeight: 'bold',
                                fontSize: '12px'
                            } : undefined}
                            onClick={() => setSelectedMarker(marker)}
                        />
                    ))}

                    {selectedMarker && (
                        <InfoWindow
                            position={{ lat: selectedMarker.lat, lng: selectedMarker.lng }}
                            onCloseClick={() => setSelectedMarker(null)}
                        >
                            <div className="p-2 max-w-[300px] max-h-[400px] overflow-y-auto">
                                <h3 className="font-bold mb-2 text-base border-b pb-1">
                                    {selectedMarker.label || selectedMarker.students[0].name}
                                </h3>
                                <div className="space-y-2">
                                    {selectedMarker.students.map((student, idx) => (
                                        <div key={idx} className="flex justify-between items-start text-sm border-b border-gray-100 pb-1 last:border-0 hover:bg-muted/50 transition-colors p-1 rounded">
                                            <div>
                                                <div className="font-medium">
                                                    {student.name}
                                                </div>
                                                <div className="text-xs text-muted-foreground">{student.className}</div>
                                                {student.time && (
                                                    <div className="text-xs text-green-600">
                                                        Check-in: {new Date(student.time).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}
                                                    </div>
                                                )}
                                            </div>
                                            <span className={`text-xs px-2 py-0.5 rounded-full ${student.status === 'Hadir'
                                                ? 'bg-green-100 text-green-700'
                                                : 'bg-red-100 text-red-700'
                                                }`}>
                                                {student.status}
                                            </span>
                                        </div>
                                    ))}
                                </div>
                                <div className="mt-2 pt-2 border-t text-xs text-gray-500 font-medium text-right">
                                    Total: {selectedMarker.count} Siswa
                                </div>
                            </div>
                        </InfoWindow>
                    )}
                </GoogleMap>
            </CardContent>
        </Card>
    )
}
