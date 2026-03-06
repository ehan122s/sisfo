import { useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select'
import { getActiveTeachers, upsertHomeroom } from '../services/homeroom-service'

interface AssignHomeroomDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    className: string
    currentTeacherId?: string
}

export function AssignHomeroomDialog({
    open,
    onOpenChange,
    className,
    currentTeacherId,
}: AssignHomeroomDialogProps) {
    const queryClient = useQueryClient()
    const [selectedTeacherId, setSelectedTeacherId] = useState(currentTeacherId ?? '')

    // Reset selection when dialog reopens with different class
    useEffect(() => {
        setSelectedTeacherId(currentTeacherId ?? '')
    }, [currentTeacherId, open])

    const { data: teachers = [], isLoading: loadingTeachers } = useQuery({
        queryKey: ['active-teachers'],
        queryFn: getActiveTeachers,
        staleTime: 1000 * 60 * 5,
    })

    const { mutate: save, isPending } = useMutation({
        mutationFn: () => upsertHomeroom(className, selectedTeacherId),
        onSuccess: () => {
            toast.success(`Wali kelas untuk ${className} berhasil disimpan.`)
            queryClient.invalidateQueries({ queryKey: ['homeroom-assignments'] })
            onOpenChange(false)
        },
        onError: (err: Error) => {
            toast.error(err.message ?? 'Gagal menyimpan wali kelas.')
        },
    })

    const isEdit = Boolean(currentTeacherId)

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="sm:max-w-md">
                <DialogHeader>
                    <DialogTitle>{isEdit ? 'Ganti Wali Kelas' : 'Tugaskan Wali Kelas'}</DialogTitle>
                    <DialogDescription>
                        {isEdit
                            ? `Ubah wali kelas untuk ${className}.`
                            : `Pilih guru yang akan menjadi wali kelas ${className}.`}
                    </DialogDescription>
                </DialogHeader>

                <div className="space-y-4 py-2">
                    <div className="space-y-2">
                        <Label>Kelas / Rombel</Label>
                        <div className="rounded-md border bg-muted px-3 py-2 text-sm font-medium">
                            {className}
                        </div>
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="teacher-select">Guru Wali Kelas</Label>
                        <Select
                            value={selectedTeacherId}
                            onValueChange={setSelectedTeacherId}
                            disabled={loadingTeachers}
                        >
                            <SelectTrigger id="teacher-select">
                                <SelectValue
                                    placeholder={
                                        loadingTeachers ? 'Memuat daftar guru...' : 'Pilih guru...'
                                    }
                                />
                            </SelectTrigger>
                            <SelectContent>
                                {teachers.map((t) => (
                                    <SelectItem key={t.id} value={t.id}>
                                        {t.full_name}
                                    </SelectItem>
                                ))}
                            </SelectContent>
                        </Select>
                    </div>
                </div>

                <DialogFooter>
                    <Button variant="outline" onClick={() => onOpenChange(false)} disabled={isPending}>
                        Batal
                    </Button>
                    <Button
                        onClick={() => save()}
                        disabled={!selectedTeacherId || isPending}
                    >
                        {isPending ? 'Menyimpan...' : 'Simpan'}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    )
}
