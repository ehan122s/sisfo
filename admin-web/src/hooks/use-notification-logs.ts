import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import type { NotificationLog } from '@/types'

interface NotificationFilters {
    dateFrom?: string
    dateTo?: string
    studentId?: string
    notificationType?: string
    status?: string
}

export function useNotificationLogs(filters: NotificationFilters = {}) {
    return useQuery({
        queryKey: ['notification-logs', filters],
        queryFn: async () => {
            let query = supabase
                .from('notification_logs')
                .select(`
                    *,
                    profiles:student_id (
                        id,
                        full_name,
                        class_name,
                        nisn
                    )
                `)
                .order('sent_at', { ascending: false })

            // Apply filters
            if (filters.dateFrom) {
                query = query.gte('sent_at', filters.dateFrom)
            }
            if (filters.dateTo) {
                query = query.lte('sent_at', filters.dateTo)
            }
            if (filters.studentId) {
                query = query.eq('student_id', filters.studentId)
            }
            if (filters.notificationType) {
                query = query.eq('notification_type', filters.notificationType)
            }
            if (filters.status) {
                query = query.eq('status', filters.status)
            }

            const { data, error } = await query

            if (error) throw error
            return data as NotificationLog[]
        }
    })
}

export function useNotificationStats() {
    return useQuery({
        queryKey: ['notification-stats'],
        queryFn: async () => {
            const today = new Date().toISOString().split('T')[0]

            const { data, error } = await supabase
                .from('notification_logs')
                .select('notification_type, status')
                .gte('sent_at', today + 'T00:00:00')

            if (error) throw error

            const stats = {
                total: data.length,
                sent: data.filter(n => n.status === 'sent').length,
                failed: data.filter(n => n.status === 'failed').length,
                pending: data.filter(n => n.status === 'pending').length,
                byType: {
                    on_time: data.filter(n => n.notification_type === 'on_time').length,
                    late: data.filter(n => n.notification_type === 'late').length,
                    absent: data.filter(n => n.notification_type === 'absent').length,
                    no_journal: data.filter(n => n.notification_type === 'no_journal').length,
                }
            }

            return stats
        }
    })
}
