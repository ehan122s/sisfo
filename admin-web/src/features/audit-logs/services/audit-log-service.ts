import { supabase } from '@/lib/supabase'

export const AuditLogService = {
    logAction: async (
        action: string,
        tableName: string,
        recordId: string,
        details: Record<string, any>
    ) => {
        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) return

            await supabase.from('audit_logs').insert({
                actor_id: user.id,
                action,
                table_name: tableName,
                record_id: recordId,
                details
            })
        } catch (error) {
            console.error('Failed to create audit log:', error)
            // Don't block the main action if logging fails
        }
    }
}
