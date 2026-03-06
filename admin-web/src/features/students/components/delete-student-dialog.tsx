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
import type { Student } from '@/types'

interface DeleteStudentDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    student: Student | null
}

export function DeleteStudentDialog({ open, onOpenChange, student }: DeleteStudentDialogProps) {
    const queryClient = useQueryClient()

    // Soft delete mutation (status -> suspended)
    const suspendMutation = useMutation({
        mutationFn: async () => {
            if (!student) throw new Error('No student selected')

            const { error } = await supabase
                .from('profiles')
                .update({ status: 'suspended' })
                .eq('id', student.id)

            if (error) throw new Error(error.message)

            // Log action
            await AuditLogService.logAction(
                'SUSPEND_STUDENT',
                'profiles',
                student.id,
                { reason: 'Soft delete via dialog' }
            )

            return true
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['students'] })
            onOpenChange(false)
            toast.success('Siswa berhasil dinonaktifkan (Suspended)')
        },
        onError: (error) => {
            console.error('Suspend student error:', error)
            toast.error(error instanceof Error ? error.message : 'Gagal menonaktifkan siswa')
        },
    })

    // Hard delete mutation (permanent removal)
    const hardDeleteMutation = useMutation({
        mutationFn: async () => {
            if (!student) throw new Error('No student selected')

            // Hard delete
            const { error } = await supabase
                .from('profiles')
                .delete()
                .eq('id', student.id)

            if (error) throw new Error(error.message)

            // Log action
            await AuditLogService.logAction(
                'DELETE_STUDENT_PERMANENT',
                'profiles',
                student.id,
                { name: student.full_name, nisn: student.nisn }
            )

            return true
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['students'] })
            onOpenChange(false)
            toast.success('Siswa berhasil dihapus secara permanen')
        },
        onError: (error) => {
            console.error('Hard delete student error:', error)
            toast.error(error instanceof Error ? error.message : 'Gagal menghapus siswa permanen')
        },
    })

    const isSuspended = student?.status === 'suspended'
    const isPending = suspendMutation.isPending || hardDeleteMutation.isPending

    const handleDelete = () => {
        if (isSuspended) {
            hardDeleteMutation.mutate()
        } else {
            suspendMutation.mutate()
        }
    }

    return (
        <AlertDialog open={open} onOpenChange={onOpenChange}>
            <AlertDialogContent>
                <AlertDialogHeader>
                    <AlertDialogTitle>
                        {isSuspended ? 'Hapus Siswa Permanen?' : 'Nonaktifkan Siswa?'}
                    </AlertDialogTitle>
                    <AlertDialogDescription>
                        {isSuspended ? (
                            <span className="block text-red-600 font-medium">
                                PERINGATAN: Tindakan ini tidak dapat dibatalkan.
                                <br />
                                Semua data siswa termasuk riwayat absensi dan jurnal akan DIHAPUS PERMANEN.
                            </span>
                        ) : (
                            <span>
                                Apakah Anda yakin ingin menonaktifkan <strong>{student?.full_name}</strong>?
                                <br /><br />
                                Status siswa akan diubah menjadi <strong>Suspended</strong>. Siswa tidak akan bisa login, namun data tidak dihapus. Anda dapat menghapus permanen jika status sudah suspended.
                            </span>
                        )}
                    </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                    <AlertDialogCancel disabled={isPending}>
                        Batal
                    </AlertDialogCancel>
                    <AlertDialogAction
                        onClick={(e) => {
                            e.preventDefault()
                            handleDelete()
                        }}
                        disabled={isPending}
                        className={buttonVariants({ variant: "destructive" })}
                    >
                        {isPending && (
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        )}
                        {isSuspended ? 'Hapus Permanen' : 'Nonaktifkan'}
                    </AlertDialogAction>
                </AlertDialogFooter>
            </AlertDialogContent>
        </AlertDialog>
    )
}
