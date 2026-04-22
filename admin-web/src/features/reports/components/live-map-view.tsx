import { useRef, useState, useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { MapContainer, TileLayer, CircleMarker, Circle, Popup, useMap } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Input } from '@/components/ui/input'
import { MapPin, Users, Building2, BookOpen, Search } from 'lucide-react'

// Types
interface StudentInfo {
    id: string
    name: string
    status: 'Hadir' | 'Belum Hadir'
    time?: string
    className?: string
    avatar_url?: string | null
    company_name?: string
    company_id?: number
}

interface MapMarker {
    id: string
    lat: number
    lng: number
    students: StudentInfo[]
    count: number
    status: 'Hadir' | 'Belum Hadir'
    color: 'green' | 'red'
    label?: string
    company_name?: string
}

interface CompanyStats {
    id: number
    name: string
    total_students: number
    present_count: number
    absent_count: number
    lat: number
    lng: number
}

const defaultCenter: [number, number] = [-6.903444, 107.618774]

// Helper to pan map when clicking company in sidebar
function MapPanner({ target }: { target: { lat: number; lng: number } | null }) {
    const map = useMap()
    if (target) {
        map.panTo([target.lat, target.lng])
        map.setZoom(16)
    }
    return null
}

export function LiveMapView() {
    const [searchQuery, setSearchQuery] = useState('')
    const [panTarget, setPanTarget] = useState<{ lat: number; lng: number } | null>(null)

    const deg2rad = (deg: number) => deg * (Math.PI / 180)
    const getDistance = (lat1: number, lon1: number, lat2: number, lon2: number) => {
        const R = 6371
        const dLat = deg2rad(lat2 - lat1)
        const dLon = deg2rad(lon2 - lon1)
        const a = Math.sin(dLat / 2) ** 2 +
            Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon / 2) ** 2
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 1000
    }

    // Main Data Query
    const { data: markers = [], isLoading, isRefetching } = useQuery({
        queryKey: ['live-map-full-data'],
        queryFn: async () => {
            const { data: students } = await supabase
                .from('profiles')
                .select('id, full_name, class_name, avatar_url, status, placements(companies(id, name, latitude, longitude, radius_meter))')
                .eq('status', 'active')
                .eq('role', 'student')

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
                const placementData = student.placements as any[]
                const company = placementData?.[0]?.companies

                if (attendance && attendance.check_in_latitude && attendance.check_in_longitude) {
                    let foundGroup = false
                    for (const key in groupedMarkers) {
                        const marker = groupedMarkers[key]
                        if (marker.status === 'Hadir') {
                            const distance = getDistance(marker.lat, marker.lng, attendance.check_in_latitude, attendance.check_in_longitude)
                            if (distance < 50) {
                                marker.students.push({
                                    id: student.id, name: student.full_name, status: 'Hadir',
                                    time: attendance.check_in_time, className: student.class_name,
                                    avatar_url: student.avatar_url, company_name: company?.name, company_id: company?.id
                                })
                                marker.count += 1
                                foundGroup = true
                                break
                            }
                        }
                    }
                    if (!foundGroup) {
                        const key = `checkin-${student.id}`
                        groupedMarkers[key] = {
                            id: key, lat: attendance.check_in_latitude, lng: attendance.check_in_longitude,
                            students: [{
                                id: student.id, name: student.full_name, status: 'Hadir',
                                time: attendance.check_in_time, className: student.class_name,
                                avatar_url: student.avatar_url, company_name: company?.name, company_id: company?.id
                            }],
                            count: 1, status: 'Hadir', color: 'green',
                            label: company?.name || 'Area Check-in', company_name: company?.name
                        }
                    }
                } else if (company?.latitude && company?.longitude) {
                    const key = `company-${company.id}`
                    if (!groupedMarkers[key]) {
                        groupedMarkers[key] = {
                            id: key, lat: company.latitude, lng: company.longitude,
                            students: [], count: 0, status: 'Belum Hadir', color: 'red',
                            label: company.name, company_name: company.name
                        }
                    }
                    groupedMarkers[key].students.push({
                        id: student.id, name: student.full_name, status: 'Belum Hadir',
                        className: student.class_name, avatar_url: student.avatar_url,
                        company_name: company.name, company_id: company.id
                    })
                    groupedMarkers[key].count += 1
                }
            })

            return Object.values(groupedMarkers)
        },
        refetchInterval: 30000
    })

    const { data: companyZones = [] } = useQuery({
        queryKey: ['map-zones'],
        queryFn: async () => {
            const { data } = await supabase
                .from('companies')
                .select('id, name, latitude, longitude, radius_meter')
                .not('latitude', 'is', null)
            return data || []
        }
    })

    const { data: journalCount = 0 } = useQuery({
        queryKey: ['journals-today-count'],
        queryFn: async () => {
            const now = new Date()
            const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString()
            const { count } = await supabase
                .from('daily_journals')
                .select('*', { count: 'exact', head: true })
                .gte('created_at', startOfDay)
            return count || 0
        }
    })

    const companyStats = useMemo(() => {
        const stats: Record<string, CompanyStats> = {}
        markers.flatMap(m => m.students).forEach(student => {
            if (student.company_name && student.company_id) {
                const id = student.company_id
                if (!stats[id]) {
                    const zone = companyZones.find((z: any) => z.id === id)
                    stats[id] = { id, name: student.company_name, total_students: 0, present_count: 0, absent_count: 0, lat: zone?.latitude || 0, lng: zone?.longitude || 0 }
                }
                stats[id].total_students++
                if (student.status === 'Hadir') stats[id].present_count++
                else stats[id].absent_count++
            }
        })
        return Object.values(stats).sort((a, b) => b.total_students - a.total_students)
    }, [markers, companyZones])

    const filteredStats = useMemo(() => {
        if (!searchQuery) return companyStats
        return companyStats.filter(stat => stat.name.toLowerCase().includes(searchQuery.toLowerCase()))
    }, [companyStats, searchQuery])

    const totalStudents = markers.reduce((acc, m) => acc + m.count, 0)
    const activeCompanies = companyZones.length

    return (
        <div className="w-full h-[calc(100vh-140px)] min-h-[600px] flex flex-col lg:flex-row gap-6">
            {/* Sidebar */}
            <div className="lg:w-80 flex flex-col gap-4 h-full shrink-0">
                <div className="bg-card border text-card-foreground rounded-xl shadow-sm flex-1 flex flex-col overflow-hidden h-full">
                    <div className="p-4 border-b shrink-0 bg-white z-10 space-y-3">
                        <div className="flex justify-between items-center">
                            <h3 className="font-bold text-sm">Daftar DUDI</h3>
                            {isRefetching && <span className="text-[10px] text-muted-foreground animate-pulse">Updating...</span>}
                        </div>
                        <div className="relative">
                            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
                            <Input placeholder="Cari DUDI..." className="h-8 pl-8 text-xs" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
                        </div>
                    </div>
                    <div className="flex-1 min-h-0 relative">
                        <ScrollArea className="h-full">
                            <div className="p-2 space-y-2">
                                {isLoading ? (
                                    <p className="text-sm text-center py-4 text-muted-foreground">Memuat data...</p>
                                ) : filteredStats.length === 0 ? (
                                    <p className="text-sm text-center py-4 text-muted-foreground">
                                        {searchQuery ? "DUDI tidak ditemukan" : "Tidak ada data DUDI"}
                                    </p>
                                ) : filteredStats.map(stat => (
                                    <div
                                        key={stat.id}
                                        className="flex flex-col gap-1 p-3 rounded-lg border bg-card hover:bg-slate-50 transition-colors cursor-pointer"
                                        onClick={() => stat.lat && stat.lng && setPanTarget({ lat: stat.lat, lng: stat.lng })}
                                    >
                                        <div className="flex justify-between items-start">
                                            <div className="flex items-center gap-2 font-bold text-sm truncate">
                                                <Building2 className="w-4 h-4 text-muted-foreground shrink-0" />
                                                <span className="truncate">{stat.name}</span>
                                            </div>
                                            <span className="text-xs bg-slate-100 px-1.5 py-0.5 rounded font-medium text-slate-600 shrink-0">{stat.total_students}</span>
                                        </div>
                                        <div className="flex items-center gap-3 mt-1 text-xs">
                                            <span className="flex items-center gap-1 text-emerald-600 font-medium">
                                                <div className="w-1.5 h-1.5 rounded-full bg-emerald-500" />{stat.present_count} Hadir
                                            </span>
                                            <span className="flex items-center gap-1 text-red-500 font-medium">
                                                <div className="w-1.5 h-1.5 rounded-full bg-red-500" />{stat.absent_count} Belum
                                            </span>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </ScrollArea>
                    </div>
                </div>
            </div>

            {/* Map */}
            <div className="flex-1 h-full relative rounded-xl overflow-hidden border bg-background shadow-sm flex flex-col">
                {/* Header */}
                <div className="absolute top-0 left-0 right-0 z-[1000] flex items-center justify-between px-5 py-3 border-b bg-background/90 backdrop-blur-sm shadow-sm pointer-events-none">
                    <div className="flex items-center gap-3">
                        <div className="flex items-center justify-center size-8 rounded-full bg-slate-100 text-slate-600">
                            <MapPin className="w-4 h-4" />
                        </div>
                        <div>
                            <h4 className="text-xs font-bold text-muted-foreground uppercase tracking-wider">Live Map</h4>
                            <p className="text-sm font-bold">Monitoring Sebaran PKL</p>
                        </div>
                    </div>
                    <div className="flex items-center gap-2 pointer-events-auto">
                        <span className="relative flex h-2.5 w-2.5">
                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-500 opacity-75"></span>
                            <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
                        </span>
                        <span className="text-xs font-bold text-emerald-600">Live Update</span>
                    </div>
                </div>

                <div className="flex-1 relative" style={{ paddingTop: '56px' }}>
                    <MapContainer center={defaultCenter} zoom={9} style={{ height: '100%', width: '100%' }}>
                        <TileLayer
                            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                        />
                        {panTarget && <MapPanner target={panTarget} />}

                        {/* Zones */}
                        {companyZones.map((zone: any) => (
                            <Circle
                                key={`zone-${zone.id}`}
                                center={[zone.latitude, zone.longitude]}
                                radius={zone.radius_meter || 100}
                                pathOptions={{ color: '#10b981', fillColor: '#10b981', fillOpacity: 0.05, weight: 1, opacity: 0.5 }}
                            />
                        ))}

                        {/* Markers */}
                        {markers.map((marker) => (
                            <CircleMarker
                                key={marker.id}
                                center={[marker.lat, marker.lng]}
                                radius={8 + Math.min(marker.count, 10)}
                                pathOptions={{
                                    fillColor: marker.color === 'green' ? '#10b981' : '#ef4444',
                                    fillOpacity: 0.9, color: '#ffffff', weight: 2
                                }}
                            >
                                <Popup>
                                    <div className="p-1 min-w-[200px] max-w-[250px]">
                                        <h4 className="font-bold text-sm mb-2 pb-1 border-b">{marker.label}</h4>
                                        <div className="max-h-[200px] overflow-y-auto space-y-2">
                                            {marker.students.map(student => (
                                                <div key={student.id} className="flex items-center gap-2">
                                                    <div className={`size-2 rounded-full shrink-0 ${student.status === 'Hadir' ? 'bg-green-500' : 'bg-red-500'}`} />
                                                    <div className="flex-1 min-w-0">
                                                        <p className="text-xs font-semibold truncate">{student.name}</p>
                                                        <p className="text-[10px] text-gray-500 truncate">{student.className}</p>
                                                        {student.time && (
                                                            <p className="text-[10px] text-green-600">
                                                                {new Date(student.time).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}
                                                            </p>
                                                        )}
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                </Popup>
                            </CircleMarker>
                        ))}
                    </MapContainer>
                </div>

                {/* Footer Stats */}
                <div className="bg-white border-t p-4 z-10 grid grid-cols-3 divide-x divide-slate-100">
                    <div className="flex flex-col items-center justify-center gap-1">
                        <div className="flex items-center gap-2 text-muted-foreground">
                            <Users className="w-4 h-4" />
                            <span className="text-xs font-medium uppercase tracking-wide">Total Siswa</span>
                        </div>
                        <span className="text-xl font-bold text-slate-900">{totalStudents}</span>
                    </div>
                    <div className="flex flex-col items-center justify-center gap-1">
                        <div className="flex items-center gap-2 text-muted-foreground">
                            <Building2 className="w-4 h-4" />
                            <span className="text-xs font-medium uppercase tracking-wide">Industri Aktif</span>
                        </div>
                        <span className="text-xl font-bold text-emerald-600">{activeCompanies}</span>
                    </div>
                    <div className="flex flex-col items-center justify-center gap-1">
                        <div className="flex items-center gap-2 text-muted-foreground">
                            <BookOpen className="w-4 h-4" />
                            <span className="text-xs font-medium uppercase tracking-wide">Jurnal Masuk</span>
                        </div>
                        <span className="text-xl font-bold text-blue-600">{journalCount}</span>
                    </div>
                </div>
            </div>
        </div>
    )
}