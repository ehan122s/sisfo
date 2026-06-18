import { useMutation, useQueryClient } from '@tanstack/react-query'
import { AuditLogService } from '@/features/audit-logs/services/audit-log-service'
import { toast } from "sonner"
import { TeacherService } from '../services/teacher-service'
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

    const deleteMutation = useMutation({
        mutationFn: async () => {
            if (!teacher) throw new Error('No teacher selected')

            await TeacherService.deleteTeacher(teacher.id)

            // Log action
            await AuditLogService.logAction(
                'DELETE_TEACHER',
                'profiles',
                teacher.id,
                { reason: 'Hard delete via dialog' }
            )

            return true
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['teachers'] })
            onOpenChange(false)
            toast.success('Pembimbing berhasil dihapus')
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
                                <br /><br />
                            </>
                        )}
                        Data pembimbing akan <strong>dihapus secara permanen</strong> dan tidak dapat dikembalikan.
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