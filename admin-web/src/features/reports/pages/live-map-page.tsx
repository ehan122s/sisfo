import { LiveMapView } from '../components/live-map-view'

export function LiveMapPage() {
    return (
        <div className="h-full flex flex-col space-y-4">
            <div>
                <div className="flex gap-1 mb-3">
                    <div className="h-1 w-8 rounded-full bg-blue-500" />
                    <div className="h-1 w-4 rounded-full bg-blue-800" />
                </div>
                <h1 className="text-4xl md:text-5xl font-black italic tracking-tight text-slate-900 dark:text-white uppercase">
                    LIVE{" "}
                    <span className="text-blue-600 dark:text-blue-400">MONITORING MAP</span>
                </h1>
                <p className="text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
                    Pantau sebaran dan kehadiran siswa PKL secara real-time.
                </p>
            </div>
            <div className="flex-1 min-h-0">
                <LiveMapView />
            </div>
        </div>
    )
}