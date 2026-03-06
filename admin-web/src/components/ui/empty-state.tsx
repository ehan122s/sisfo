import { type LucideIcon, FileX2 } from "lucide-react"

interface EmptyStateProps {
    title?: string
    description?: string
    icon?: LucideIcon
    action?: React.ReactNode
}

export function EmptyState({
    title = "Tidak ada data",
    description = "Belum ada data yang tersedia untuk ditampilkan.",
    icon: Icon = FileX2,
    action,
}: EmptyStateProps) {
    return (
        <div className="flex flex-col items-center justify-center py-12 text-center p-8 border rounded-lg border-dashed">
            <div className="flex h-20 w-20 items-center justify-center rounded-full bg-muted/50 mb-4">
                <Icon className="h-10 w-10 text-muted-foreground" />
            </div>
            <h3 className="text-lg font-medium tracking-tight mb-1">{title}</h3>
            <p className="text-sm text-muted-foreground max-w-sm mb-6 text-balance">
                {description}
            </p>
            {action && <div>{action}</div>}
        </div>
    )
}
