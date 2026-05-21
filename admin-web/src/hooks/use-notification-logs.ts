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

interface NotificationFilters {
    dateFrom?: string
    dateTo?: string
    notificationType?: string
    status?: string 
}

// ==========================================
// 1. HALAMAN SEKARANG (RIWAYAT NOTIFIKASI SISTEM - 166 ENTRI)
// ==========================================
export function useNotificationLogs(filters: NotificationFilters = {}) {
    return useQuery({
        queryKey: ['notification-logs', filters],
        queryFn: async () => {
            let query = supabase
                .from('notifications') // Tetap pakai notifications untuk 166 entri
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
// 2. HALAMAN DULU (KHUSUS RIWAYAT PENGIRIMAN WHATSAPP)
// ==========================================
export function useWhatsAppLogs(filters: NotificationFilters = {}) {
    return useQuery({
        queryKey: ['whatsapp-logs', filters],
        queryFn: async () => {
            let query = supabase
                .from('notification_logs') // Ganti ke nama tabel khusus log WhatsApp kelompokmu
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

            const { data, error, count } = await query
            if (error) throw error
            return { data: data || [], count: count || 0 }
        }
    })
}