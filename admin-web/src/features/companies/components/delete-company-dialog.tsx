import { useMutation, useQueryClient } from '@tanstack/react-query'
import { AuditLogService } from '@/features/audit-logs/services/audit-log-service'
import { toast } from "sonner"
import { supabase } from '@/lib/supabase'
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { Loader2 } from 'lucide-react'
import { buttonVariants } from '@/components/ui/button'
import type { Company } from '@/types'

interface DeleteCompanyDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    company: Company | null
}

export function DeleteCompanyDialog({ open, onOpenChange, company }: DeleteCompanyDialogProps) {
    const queryClient = useQueryClient()

    const mutation = useMutation({
        mutationFn: async () => {
            if (!company) throw new Error('No company selected')

            const { error } = await supabase
                .from('companies')
                .delete()
                .eq('id', company.id)

            if (error) throw error

            // Log action
            await AuditLogService.logAction(
                'DELETE_COMPANY',
                'companies',
                company.id.toString(),
                { name: company.name }
            )
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['companies'] })
            toast.success('DUDI berhasil dihapus')
            onOpenChange(false)
        },
        onError: (error) => {
            console.error('Delete company error:', error)
            toast.error(error instanceof Error ? error.message : 'Gagal menghapus DUDI')
        },
    })

    return (
        <AlertDialog open={open} onOpenChange={onOpenChange}>
            <AlertDialogContent>
                <AlertDialogHeader>
                    <AlertDialogTitle>Hapus DUDI?</AlertDialogTitle>
                    <AlertDialogDescription>
                        Apakah Anda yakin ingin menghapus <strong>{company?.name}</strong>?
                        <br /><br />
                        Tindakan ini tidak dapat dibatalkan. Pastikan tidak ada siswa yang sedang aktif magang di perusahaan ini.
                    </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                    <AlertDialogCancel disabled={mutation.isPending}>Batal</AlertDialogCancel>
                    <AlertDialogAction
                        onClick={(e) => {
                            e.preventDefault()
                            mutation.mutate()
                        }}
                        className={buttonVariants({ variant: "destructive" })}
                        disabled={mutation.isPending}
                    >
                        {mutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Hapus
                    </AlertDialogAction>
                </AlertDialogFooter>
            </AlertDialogContent>
        </AlertDialog>
    )
}
