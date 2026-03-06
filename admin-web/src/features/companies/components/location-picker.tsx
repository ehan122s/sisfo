import { useState, useCallback, useMemo, useEffect } from 'react'
import { GoogleMap, Marker, useJsApiLoader } from '@react-google-maps/api'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Search, Loader2, MapPin } from 'lucide-react'

interface Location {
    lat: number
    lng: number
    address?: string
}

import { GOOGLE_MAPS_LIBRARIES } from '@/lib/google-maps'

interface LocationPickerProps {
    initialLocation?: { lat: number; lng: number } | null
    onLocationSelect: (location: Location) => void
    height?: string
}

export function LocationPicker({ initialLocation, onLocationSelect, height = "300px" }: LocationPickerProps) {
    const { isLoaded } = useJsApiLoader({
        id: 'google-map-script',
        googleMapsApiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY,
        libraries: GOOGLE_MAPS_LIBRARIES,
    })

    const [map, setMap] = useState<google.maps.Map | null>(null)
    const [marker, setMarker] = useState<{ lat: number; lng: number } | null>(initialLocation || null)
    const [searchValue, setSearchValue] = useState('')
    const [isSearching, setIsSearching] = useState(false)

    // Center of map (default to Bandung or initial location)
    const center = useMemo(() => {
        return initialLocation || { lat: -6.9175, lng: 107.6191 } // Bandung coordinates
    }, [initialLocation])

    const onLoad = useCallback(function callback(map: google.maps.Map) {
        setMap(map)
    }, [])

    const onUnmount = useCallback(function callback() {
        setMap(null)
    }, [])

    const handleMapClick = useCallback(async (e: google.maps.MapMouseEvent) => {
        if (!e.latLng) return

        const lat = e.latLng.lat()
        const lng = e.latLng.lng()

        setMarker({ lat, lng })

        // Reverse geocoding (basic implementation)
        // In a real app, we would use Geocoding service here
        onLocationSelect({ lat, lng })
    }, [onLocationSelect])

    const handleSearch = async () => {
        if (!searchValue.trim() || !map) return
        setIsSearching(true)

        try {
            const geocoder = new google.maps.Geocoder()
            geocoder.geocode({ address: searchValue }, (results, status) => {
                if (status === 'OK' && results && results[0] && results[0].geometry?.location) {
                    const location = results[0].geometry.location
                    const lat = location.lat()
                    const lng = location.lng()

                    map.panTo(location)
                    map.setZoom(15)
                    setMarker({ lat, lng })
                    onLocationSelect({ lat, lng })
                } else {
                    console.error("Geocode failed:", status)
                    alert("Lokasi tidak ditemukan atau API Error. Pastikan 'Geocoding API' aktif di Google Cloud Console.")
                }
                setIsSearching(false)
            })
        } catch (error) {
            console.error("Search error:", error)
            setIsSearching(false)
        }
    }

    useEffect(() => {
        if (initialLocation) {
            setMarker(initialLocation)
        }
    }, [initialLocation])

    if (!isLoaded) {
        return (
            <div className="flex items-center justify-center bg-gray-100 rounded-md" style={{ height }}>
                <Loader2 className="h-8 w-8 animate-spin text-gray-400" />
            </div>
        )
    }

    return (
        <div className="space-y-2">
            <div className="flex gap-2">
                <Input
                    placeholder="Cari lokasi (contoh: Alun-alun Bandung)"
                    value={searchValue}
                    onChange={(e) => setSearchValue(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                />
                <Button variant="secondary" onClick={handleSearch} disabled={isSearching} type="button">
                    {isSearching ? <Loader2 className="h-4 w-4 animate-spin" /> : <Search className="h-4 w-4" />}
                </Button>
            </div>

            <div className="relative rounded-md overflow-hidden border">
                <GoogleMap
                    mapContainerStyle={{ width: '100%', height }}
                    center={center}
                    zoom={13}
                    onLoad={onLoad}
                    onUnmount={onUnmount}
                    onClick={handleMapClick}
                    options={{
                        streetViewControl: false,
                        mapTypeControl: false,
                        fullscreenControl: false,
                    }}
                >
                    {marker && <Marker position={marker} />}
                </GoogleMap>
                {!marker && (
                    <div className="absolute top-2 left-1/2 -translate-x-1/2 bg-white/80 backdrop-blur-sm px-3 py-1 rounded-full text-xs font-medium shadow-sm flex items-center gap-1">
                        <MapPin className="h-3 w-3" />
                        Klik peta untuk memilih lokasi
                    </div>
                )}
            </div>

            {marker && (
                <div className="text-xs text-muted-foreground flex gap-4">
                    <span>Lat: {marker.lat.toFixed(6)}</span>
                    <span>Lng: {marker.lng.toFixed(6)}</span>
                </div>
            )}
        </div>
    )
}
