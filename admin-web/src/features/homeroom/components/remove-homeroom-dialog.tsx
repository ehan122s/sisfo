import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
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
import { buttonVariants } from '@/components/ui/button'
import { removeHomeroom } from '../services/homeroom-service'

interface RemoveHomeroomDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    className: string
    teacherName: string
}

export function RemoveHomeroomDialog({
    open,
    onOpenChange,
    className,
    teacherName,
}: RemoveHomeroomDialogProps) {
    const queryClient = useQueryClient()

    const { mutate: doRemove, isPending } = useMutation({
        mutationFn: () => removeHomeroom(className),
        onSuccess: () => {
            toast.success(`Wali kelas ${className} berhasil dihapus.`)
            queryClient.invalidateQueries({ queryKey: ['homeroom-assignments'] })
            onOpenChange(false)
        },
        onError: (err: Error) => {
            toast.error(err.message ?? 'Gagal menghapus wali kelas.')
        },
    })

    return (
        <AlertDialog open={open} onOpenChange={onOpenChange}>
            <AlertDialogContent>
                <AlertDialogHeader>
                    <AlertDialogTitle>Hapus Wali Kelas</AlertDialogTitle>
                    <AlertDialogDescription>
                        Apakah Anda yakin ingin menghapus{' '}
                        <strong>{teacherName}</strong> sebagai wali kelas{' '}
                        <strong>{className}</strong>? Kelas ini akan menjadi kosong.
                    </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                    <AlertDialogCancel disabled={isPending}>Batal</AlertDialogCancel>
                    <AlertDialogAction
                        className={buttonVariants({ variant: 'destructive' })}
                        onClick={() => doRemove()}
                        disabled={isPending}
                    >
                        {isPending ? 'Menghapus...' : 'Hapus'}
                    </AlertDialogAction>
                </AlertDialogFooter>
            </AlertDialogContent>
        </AlertDialog>
    )
}
