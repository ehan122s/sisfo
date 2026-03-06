import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useAuthContext } from '@/contexts/auth-context'

export type Notification = {
    id: string
    user_id: string
    title: string
    message: string
    type: 'alert' | 'info' | 'success' | 'warning'
    is_read: boolean
    action_link?: string
    created_at: string
}

export function useNotifications() {
    const { user } = useAuthContext()
    const [notifications, setNotifications] = useState<Notification[]>([])
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        if (!user) return

        const fetchNotifications = async () => {
            setLoading(true)
            const { data, error } = await supabase
                .from('notifications')
                .select('*')
                .eq('user_id', user.id)
                .order('created_at', { ascending: false })

            if (error) {
                console.error('Error fetching notifications:', error)
            } else {
                setNotifications(data as Notification[])
            }
            setLoading(false)
        }

        fetchNotifications()

        // Realtime subscription
        const subscription = supabase
            .channel('notifications_channel')
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'notifications',
                    filter: `user_id=eq.${user.id}`,
                },
                (payload) => {
                    if (payload.eventType === 'INSERT') {
                        setNotifications((prev) => [payload.new as Notification, ...prev])
                    } else if (payload.eventType === 'UPDATE') {
                        setNotifications((prev) =>
                            prev.map((n) => (n.id === payload.new.id ? (payload.new as Notification) : n))
                        )
                    }
                }
            )
            .subscribe()

        return () => {
            subscription.unsubscribe()
        }
    }, [user])

    const unreadCount = notifications.filter((n) => !n.is_read).length

    const markAsRead = async (id: string) => {
        // Optimistic update
        setNotifications((prev) =>
            prev.map((n) => (n.id === id ? { ...n, is_read: true } : n))
        )

        const { error } = await supabase
            .from('notifications')
            .update({ is_read: true })
            .eq('id', id)

        if (error) {
            console.error('Error marking as read:', error)
            // Revert if error? (Optional, usually fine to ignore for read status)
        }
    }

    const markAllAsRead = async () => {
        // Optimistic update
        setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })))

        const { error } = await supabase
            .from('notifications')
            .update({ is_read: true })
            .eq('user_id', user?.id)
            .eq('is_read', false)

        if (error) {
            console.error('Error marking all as read:', error)
        }
    }

    return {
        notifications,
        loading,
        unreadCount,
        markAsRead,
        markAllAsRead
    }
}
