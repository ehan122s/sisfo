import { cn } from '@/lib/utils'

interface AnimatedBackgroundProps {
    className?: string
}

export function AnimatedBackground({ className }: AnimatedBackgroundProps) {
    return (
        <div className={cn("fixed inset-0 z-[-1] overflow-hidden bg-slate-50 dark:bg-slate-950", className)}>
            {/* Abstract Tech SVG Pattern */}
            <div className="absolute inset-0 opacity-[0.15] dark:opacity-20 pointer-events-none">
                <svg className="h-full w-full" xmlns="http://www.w3.org/2000/svg">
                    <defs>
                        <pattern id="grid-pattern-main" width="40" height="40" patternUnits="userSpaceOnUse">
                            <path d="M0 40L40 0H20L0 20M40 40V20L20 40" stroke="currentColor" strokeWidth="1" fill="none" className="text-emerald-500/30" />
                        </pattern>
                        <radialGradient id="glow-main-1" cx="0.5" cy="0.5" r="0.5">
                            <stop offset="0%" stopColor="#10b981" />
                            <stop offset="100%" stopColor="transparent" />
                        </radialGradient>
                        <radialGradient id="glow-main-2" cx="0.5" cy="0.5" r="0.5">
                            <stop offset="0%" stopColor="#3b82f6" />
                            <stop offset="100%" stopColor="transparent" />
                        </radialGradient>
                    </defs>
                    <rect width="100%" height="100%" fill="url(#grid-pattern-main)" />
                    <circle cx="10%" cy="20%" r="300" fill="url(#glow-main-1)" className="animate-pulse opacity-20" />
                    <circle cx="90%" cy="80%" r="400" fill="url(#glow-main-2)" className="animate-pulse opacity-20 delay-1000" />
                </svg>
            </div>

            {/* Ambient Gradients specifically for Dashboard Area */}
            <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-gradient-to-br from-emerald-500/5 to-transparent blur-3xl pointer-events-none" />
            <div className="absolute bottom-0 left-0 w-[500px] h-[500px] bg-gradient-to-tr from-cyan-500/5 to-transparent blur-3xl pointer-events-none" />
        </div>
    )
}
