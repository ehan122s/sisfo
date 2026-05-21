import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'

export interface NotificationLog {
    id: string
    user_id: string
    title: string
    message: string
    type: string
    is_read: boolean
    action_link: string | null
    created_at: string
    profiles?: {
        full_name: string
        class_name: string
    }
}

export interface WhatsAppLog {
    id: string
    student_id: string
    notification_type: string
    status: string
    message: string | null
    phone_number: string | null
    sent_at: string
    created_at: string
    profiles?: {
        full_name: string
        class_name: string
    }
}

interface NotificationFilters {
    dateFrom?: string
    dateTo?: string
    notificationType?: string
    status?: string
}

// ==========================================
// 1. RIWAYAT NOTIFIKASI SISTEM (tabel notifications - 166 entri)
// ==========================================
export function useNotificationLogs(filters: NotificationFilters = {}) {
    return useQuery({
        queryKey: ['notification-logs', filters],
        queryFn: async () => {
            let query = supabase
                .from('notifications')
                .select(`
                    *,
                    profiles:user_id (
                        full_name,
                        class_name
                    )
                `, { count: 'exact' })
                .order('created_at', { ascending: false })

            if (filters.dateFrom) query = query.gte('created_at', `${filters.dateFrom}T00:00:00`)
            if (filters.dateTo) query = query.lte('created_at', `${filters.dateTo}T23:59:59`)
            if (filters.notificationType) query = query.eq('type', filters.notificationType)
            if (filters.status === 'read') query = query.eq('is_read', true)
            else if (filters.status === 'unread') query = query.eq('is_read', false)

            const { data, error, count } = await query
            if (error) throw error
            return { data: (data as NotificationLog[]) || [], count: count || 0 }
        }
    })
}

export function useNotificationStats() {
    return useQuery({
        queryKey: ['notification-stats'],
        queryFn: async () => {
            const { data, error } = await supabase
                .from('notifications')
                .select('type, is_read')

            if (error) throw error
            return {
                total: data.length,
                read: data.filter(n => n.is_read === true).length,
                unread: data.filter(n => n.is_read === false).length,
                byType: {
                    info: data.filter(n => n.type === 'info').length,
                    attendance: data.filter(n => n.type === 'attendance').length,
                    journal: data.filter(n => n.type === 'journal').length,
                }
            }
        }
    })
}

// ==========================================
// 2. RIWAYAT PENGIRIMAN WHATSAPP (tabel notification_logs)
// ==========================================
export function useWhatsAppLogs(filters: NotificationFilters = {}) {
    return useQuery({
        queryKey: ['whatsapp-logs', filters],
        queryFn: async () => {
            let query = supabase
                .from('notification_logs')
                .select(`
                    *,
                    profiles:student_id (
                        full_name,
                        class_name
                    )
                `, { count: 'exact' })
                .order('sent_at', { ascending: false })

            if (filters.dateFrom) query = query.gte('sent_at', `${filters.dateFrom}T00:00:00`)
            if (filters.dateTo) query = query.lte('sent_at', `${filters.dateTo}T23:59:59`)
            if (filters.notificationType) query = query.eq('notification_type', filters.notificationType)
            if (filters.status) query = query.eq('status', filters.status)

            const { data, error, count } = await query

            // ✅ DEBUG: Cek di browser console apakah ada error atau data kosong
            console.log('[useWhatsAppLogs] result:', { data, error, count })
            if (error) {
                console.error('[useWhatsAppLogs] Supabase error:', error)
                throw error
            }

            return { data: (data as WhatsAppLog[]) || [], count: count || 0 }
        }
    })
}

// ==========================================
// 3. STATS WHATSAPP LOGS
// ==========================================
export function useWhatsAppStats() {
    return useQuery({
        queryKey: ['whatsapp-stats'],
        queryFn: async () => {
            const { data, error } = await supabase
                .from('notification_logs')
                .select('notification_type, status')

            if (error) throw error
            return {
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
        }
    })
}