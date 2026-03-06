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
import type { Teacher } from '../services/teacher-service'

interface DeleteTeacherDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    teacher: Teacher | null
}

export function DeleteTeacherDialog({ open, onOpenChange, teacher }: DeleteTeacherDialogProps) {
    const queryClient = useQueryClient()

    // Delete mutation (soft delete - set status to inactive)
    const deleteMutation = useMutation({
        mutationFn: async () => {
            if (!teacher) throw new Error('No teacher selected')

            // Soft delete: set status to suspended
            const { error } = await supabase
                .from('profiles')
                .update({ status: 'suspended' })
                .eq('id', teacher.id)

            if (error) throw new Error(error.message)

            // Log action
            await AuditLogService.logAction(
                'SUSPEND_TEACHER',
                'profiles',
                teacher.id,
                { reason: 'Soft delete via dialog' }
            )

            return true
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['teachers'] })
            onOpenChange(false)
            toast.success('Pembimbing berhasil dinonaktifkan')
        },
        onError: (error) => {
            console.error('Delete teacher error:', error)
            toast.error(error instanceof Error ? error.message : 'Gagal menghapus pembimbing')
        },
    })

    const handleDelete = () => {
        deleteMutation.mutate()
    }

    return (
        <AlertDialog open={open} onOpenChange={onOpenChange}>
            <AlertDialogContent>
                <AlertDialogHeader>
                    <AlertDialogTitle>Hapus Pembimbing</AlertDialogTitle>
                    <AlertDialogDescription>
                        Apakah Anda yakin ingin menghapus pembimbing <strong>{teacher?.full_name}</strong>?
                        <br /><br />
                        {teacher?.assignments && teacher.assignments.length > 0 && (
                            <>
                                Pembimbing ini sedang mengawasi <strong>{teacher.assignments.length} DUDI</strong>.
                                <br />
                            </>
                        )}
                        Data pembimbing akan dinonaktifkan (soft delete). Anda dapat mengaktifkannya kembali melalui menu Edit.
                    </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                    <AlertDialogCancel disabled={deleteMutation.isPending}>
                        Batal
                    </AlertDialogCancel>
                    <AlertDialogAction
                        onClick={handleDelete}
                        disabled={deleteMutation.isPending}
                        className={buttonVariants({ variant: "destructive" })}
                    >
                        {deleteMutation.isPending && (
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        )}
                        Hapus
                    </AlertDialogAction>
                </AlertDialogFooter>
            </AlertDialogContent>
        </AlertDialog>
    )
}
