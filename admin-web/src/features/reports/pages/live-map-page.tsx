import { LiveMapView } from '../components/live-map-view'

export function LiveMapPage() {
    return (
        <div className="h-full flex flex-col space-y-4">
            <div>
                <h1 className="text-3xl font-bold">Live Monitoring Map</h1>
                <p className="text-muted-foreground">
                    Pantau sebaran dan kehadiran siswa PKL secara real-time.
                </p>
            </div>
            <div className="flex-1 min-h-0">
                <LiveMapView />
            </div>
        </div>
    )
}
