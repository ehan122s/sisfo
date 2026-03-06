import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import type { MessageTemplate } from '@/types'
import { toast } from 'sonner'

export function useMessageTemplates() {
    return useQuery({
        queryKey: ['message-templates'],
        queryFn: async () => {
            const { data, error } = await supabase
                .from('message_templates')
                .select('*')
                .order('template_key')

            if (error) throw error
            return data as MessageTemplate[]
        }
    })
}

export function useUpdateTemplate() {
    const queryClient = useQueryClient()

    return useMutation({
        mutationFn: async ({ id, updates }: { id: string, updates: Partial<MessageTemplate> }) => {
            const { data, error } = await supabase
                .from('message_templates')
                .update({ ...updates, updated_at: new Date().toISOString() })
                .eq('id', id)
                .select()
                .single()

            if (error) throw error
            return data
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['message-templates'] })
            toast.success('Template berhasil diupdate')
        },
        onError: (error) => {
            toast.error('Gagal update template: ' + error.message)
        }
    })
}
