import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'

export interface AuditLog {
    id: string
    created_at: string
    action: string
    table_name: string
    record_id: string
    details: any
    actor: {
        full_name: string | null
        email: string | null
    } | null
    actor_id: string
}

export function useAuditLogs() {
    return useQuery({
        queryKey: ['auditLogs'],
        queryFn: async () => {
            const { data, error } = await supabase
                .from('audit_logs')
                .select(`
                    *,
                    actor:profiles!audit_logs_actor_id_fkey (
                        full_name
                    )
                `)
                .order('created_at', { ascending: false })

            if (error) throw error

            // Fix structure if needed, but assuming profiles relation works
            // Note: profiles foreign key on actor_id was created.
            // Supabase JS will return `actor` object.

            return data as unknown as AuditLog[]
        },
    })
}
