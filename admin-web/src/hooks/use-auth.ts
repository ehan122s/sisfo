import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import type { User, Session } from '@supabase/supabase-js'

export function useAuth() {
    const [user, setUser] = useState<User | null>(null)
    const [session, setSession] = useState<Session | null>(null)
    const [role, setRole] = useState<string | null>(null)
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        let mounted = true

        const getSession = async () => {
            try {
                const { data: { session }, error } = await supabase.auth.getSession()
                if (error) throw error

                if (mounted) {
                    setSession(session)
                    setUser(session?.user ?? null)
                    // Read role directly from Custom Claims (App Metadata)
                    // This is instant and requires no database query
                    const appMetadata = session?.user?.app_metadata
                    setRole(appMetadata?.role ?? null)
                }
            } catch (error) {
                console.error('Error getting session:', error)
            } finally {
                if (mounted) setLoading(false)
            }
        }

        getSession()

        const {
            data: { subscription },
        } = supabase.auth.onAuthStateChange((_event, session) => {
            if (mounted) {
                setSession(session)
                setUser(session?.user ?? null)
                // Sync role from metadata on auth change
                const appMetadata = session?.user?.app_metadata
                setRole(appMetadata?.role ?? null)
                setLoading(false)
            }
        })

        return () => {
            mounted = false
            subscription.unsubscribe()
        }
    }, [])

    const signIn = async (email: string, password: string) => {
        const { error } = await supabase.auth.signInWithPassword({
            email,
            password,
        })
        if (error) throw error
    }

    const signOut = async () => {
        const { error } = await supabase.auth.signOut()
        if (error) throw error
    }

    return {
        user,
        session,
        role,
        loading,
        signIn,
        signOut,
    }
}
