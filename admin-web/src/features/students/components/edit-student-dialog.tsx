import { useState, useEffect } from 'react'
import { AuditLogService } from '@/features/audit-logs/services/audit-log-service'
import { toast } from "sonner"
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog'
import {
    Tabs,
    TabsContent,
    TabsList,
    TabsTrigger,
} from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select'
import { Loader2, CheckCircle } from 'lucide-react'
import type { Student } from '@/types'

interface EditStudentDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    student: Student | null
}

export function EditStudentDialog({ open, onOpenChange, student }: EditStudentDialogProps) {
    const [formData, setFormData] = useState({
        full_name: '',
        nisn: '',
        class_name: '',
        status: 'active',
        phone_number: '',
        parent_phone_number: '',
        nipd: '',
        gender: 'L',
        birth_place: '',
        birth_date: '',
        nik: '',
        religion: '',
        address: '',
        father_name: '',
        mother_name: '',
    })
    const [errors, setErrors] = useState<Record<string, string>>({})
    const [isSuccess, setIsSuccess] = useState(false)
    const queryClient = useQueryClient()

    // Reset form when student changes
    useEffect(() => {
        if (student) {
            setFormData({
                full_name: student.full_name || '',
                nisn: student.nisn || '',
                class_name: student.class_name || '',
                status: student.status || 'active',
                phone_number: student.phone_number || '',
                parent_phone_number: student.parent_phone_number || '',
                nipd: student.nipd || '',
                gender: student.gender || 'L',
                birth_place: student.birth_place || '',
                birth_date: student.birth_date || '',
                nik: student.nik || '',
                religion: student.religion || '',
                address: student.address || '',
                father_name: student.father_name || '',
                mother_name: student.mother_name || '',
            })
        }
    }, [student])

    // Update mutation
    const updateMutation = useMutation({
        mutationFn: async () => {
            if (!student) throw new Error('No student selected')

            // Validate
            const newErrors: Record<string, string> = {}
            if (!formData.full_name.trim()) newErrors.full_name = 'Nama wajib diisi'
            if (!formData.nisn.trim()) newErrors.nisn = 'NISN wajib diisi'
            if (!formData.class_name.trim()) newErrors.class_name = 'Kelas wajib diisi'

            if (Object.keys(newErrors).length > 0) {
                setErrors(newErrors)
                throw new Error('Validasi gagal')
            }

            // Update profile
            const { error } = await supabase
                .from('profiles')
                .update({
                    full_name: formData.full_name.trim(),
                    nisn: formData.nisn.trim(),
                    class_name: formData.class_name.trim(),
                    status: formData.status,
                    phone_number: formData.phone_number.trim(),
                    parent_phone_number: formData.parent_phone_number.trim(),
                    nipd: formData.nipd.trim() || null,
                    gender: formData.gender,
                    birth_place: formData.birth_place.trim() || null,
                    birth_date: formData.birth_date || null,
                    nik: formData.nik.trim() || null,
                    religion: formData.religion.trim() || null,
                    address: formData.address.trim() || null,
                    father_name: formData.father_name.trim() || null,
                    mother_name: formData.mother_name.trim() || null,
                })
                .eq('id', student.id)

            if (error) throw new Error(error.message)

            // Log action
            await AuditLogService.logAction(
                'UPDATE_STUDENT',
                'profiles',
                student.id,
                { updates: formData }
            )

            return true
        },
        onSuccess: () => {
            // Refresh students list
            queryClient.invalidateQueries({ queryKey: ['students'] })
            setIsSuccess(true)

            // Close after delay
            setTimeout(() => {
                setIsSuccess(false)
                setErrors({})
                onOpenChange(false)
                toast.success('Data siswa berhasil diperbarui')
            }, 1500)
        },
        onError: (error) => {
            console.error('Update student error:', error)
            toast.error(error instanceof Error ? error.message : 'Gagal memperbarui data siswa')
        },
    })

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault()
        setErrors({})
        updateMutation.mutate()
    }

    const handleChange = (field: string, value: string) => {
        setFormData(prev => ({ ...prev, [field]: value }))
        if (errors[field]) {
            setErrors(prev => {
                const newErrors = { ...prev }
                delete newErrors[field]
                return newErrors
            })
        }
    }

    // Get current placement info
    const currentPlacement = student?.placements?.[0]?.companies?.name

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="sm:max-w-[500px]">
                <DialogHeader>
                    <DialogTitle>Edit Siswa</DialogTitle>
                    <DialogDescription>
                        Ubah data siswa. Email tidak dapat diubah.
                    </DialogDescription>
                </DialogHeader>

                {isSuccess ? (
                    <div className="flex flex-col items-center justify-center py-8 animate-in fade-in zoom-in duration-300">
                        <div className="rounded-full bg-green-100 p-3 mb-4">
                            <CheckCircle className="h-12 w-12 text-green-600" />
                        </div>
                        <h3 className="text-xl font-semibold text-green-700">Berhasil!</h3>
                        <p className="text-muted-foreground text-center mt-2">
                            Data siswa berhasil diperbarui.
                        </p>
                    </div>
                ) : (
                    <form onSubmit={handleSubmit} className="space-y-4">
                        <Tabs defaultValue="account" className="w-full">
                            <TabsList className="grid w-full grid-cols-3 mb-4">
                                <TabsTrigger value="account">Akun & Sekolah</TabsTrigger>
                                <TabsTrigger value="personal">Data Pribadi</TabsTrigger>
                                <TabsTrigger value="parents">Orang Tua</TabsTrigger>
                            </TabsList>

                            <TabsContent value="account" className="space-y-4">
                                <div className="space-y-2">
                                    <Label htmlFor="email">Email</Label>
                                    <Input
                                        id="email"
                                        value={student?.nisn ? `${student.nisn}@pkl.com` : '-'}
                                        disabled
                                        className="bg-muted"
                                    />
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="full_name">Nama Lengkap *</Label>
                                    <Input
                                        id="full_name"
                                        value={formData.full_name}
                                        onChange={(e) => handleChange('full_name', e.target.value)}
                                        placeholder="Nama lengkap siswa"
                                    />
                                    {errors.full_name && <p className="text-sm text-red-600">{errors.full_name}</p>}
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="nisn">NISN *</Label>
                                    <Input
                                        id="nisn"
                                        value={formData.nisn}
                                        onChange={(e) => {
                                            const value = e.target.value.replace(/[^0-9]/g, '')
                                            handleChange('nisn', value)
                                        }}
                                        placeholder="NISN"
                                        maxLength={10}
                                    />
                                    {errors.nisn && <p className="text-sm text-red-600">{errors.nisn}</p>}
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="nipd">NIPD</Label>
                                    <Input
                                        id="nipd"
                                        value={formData.nipd}
                                        onChange={(e) => handleChange('nipd', e.target.value)}
                                        placeholder="NIPD"
                                    />
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="class_name">Kelas *</Label>
                                    <Input
                                        id="class_name"
                                        value={formData.class_name}
                                        onChange={(e) => handleChange('class_name', e.target.value)}
                                        placeholder="Contoh: XI TEI 1"
                                    />
                                    {errors.class_name && <p className="text-sm text-red-600">{errors.class_name}</p>}
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="status">Status</Label>
                                    <Select
                                        value={formData.status}
                                        onValueChange={(value) => handleChange('status', value)}
                                    >
                                        <SelectTrigger>
                                            <SelectValue />
                                        </SelectTrigger>
                                        <SelectContent>
                                            <SelectItem value="active">Aktif</SelectItem>
                                            <SelectItem value="pending">Pending</SelectItem>
                                            <SelectItem value="suspended">Nonaktif (Suspended)</SelectItem>
                                        </SelectContent>
                                    </Select>
                                </div>

                                {currentPlacement && (
                                    <div className="space-y-2">
                                        <Label>DUDI</Label>
                                        <Input value={currentPlacement} disabled className="bg-muted" />
                                        <p className="text-xs text-muted-foreground">
                                            Ubah DUDI melalui tombol "Assign DUDI" di tabel
                                        </p>
                                    </div>
                                )}
                            </TabsContent>

                            <TabsContent value="personal" className="space-y-4">
                                <div className="space-y-2">
                                    <Label htmlFor="nik">NIK</Label>
                                    <Input
                                        id="nik"
                                        value={formData.nik}
                                        onChange={(e) => handleChange('nik', e.target.value)}
                                        placeholder="NIK (16 digit)"
                                        maxLength={16}
                                    />
                                </div>

                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <Label htmlFor="gender">Jenis Kelamin</Label>
                                        <Select
                                            value={formData.gender}
                                            onValueChange={(value) => handleChange('gender', value)}
                                        >
                                            <SelectTrigger>
                                                <SelectValue />
                                            </SelectTrigger>
                                            <SelectContent>
                                                <SelectItem value="L">Laki-laki</SelectItem>
                                                <SelectItem value="P">Perempuan</SelectItem>
                                            </SelectContent>
                                        </Select>
                                    </div>
                                    <div className="space-y-2">
                                        <Label htmlFor="religion">Agama</Label>
                                        <Input
                                            id="religion"
                                            value={formData.religion}
                                            onChange={(e) => handleChange('religion', e.target.value)}
                                            placeholder="Agama"
                                        />
                                    </div>
                                </div>

                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <Label htmlFor="birth_place">Tempat Lahir</Label>
                                        <Input
                                            id="birth_place"
                                            value={formData.birth_place}
                                            onChange={(e) => handleChange('birth_place', e.target.value)}
                                            placeholder="Kota Lahir"
                                        />
                                    </div>
                                    <div className="space-y-2">
                                        <Label htmlFor="birth_date">Tanggal Lahir</Label>
                                        <Input
                                            id="birth_date"
                                            type="date"
                                            value={formData.birth_date}
                                            onChange={(e) => handleChange('birth_date', e.target.value)}
                                        />
                                    </div>
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="address">Alamat</Label>
                                    <Input
                                        id="address"
                                        value={formData.address}
                                        onChange={(e) => handleChange('address', e.target.value)}
                                        placeholder="Alamat Lengkap"
                                    />
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="phone_number">No. HP Siswa</Label>
                                    <Input
                                        id="phone_number"
                                        value={formData.phone_number}
                                        onChange={(e) => {
                                            const value = e.target.value.replace(/[^0-9]/g, '')
                                            handleChange('phone_number', value)
                                        }}
                                        placeholder="Contoh: 08123456789"
                                        maxLength={15}
                                    />
                                </div>
                            </TabsContent>

                            <TabsContent value="parents" className="space-y-4">
                                <div className="space-y-2">
                                    <Label htmlFor="father_name">Nama Ayah</Label>
                                    <Input
                                        id="father_name"
                                        value={formData.father_name}
                                        onChange={(e) => handleChange('father_name', e.target.value)}
                                        placeholder="Nama Ayah"
                                    />
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="mother_name">Nama Ibu</Label>
                                    <Input
                                        id="mother_name"
                                        value={formData.mother_name}
                                        onChange={(e) => handleChange('mother_name', e.target.value)}
                                        placeholder="Nama Ibu"
                                    />
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="parent_phone_number">No. HP Orang Tua</Label>
                                    <Input
                                        id="parent_phone_number"
                                        value={formData.parent_phone_number}
                                        onChange={(e) => {
                                            const value = e.target.value.replace(/[^0-9]/g, '')
                                            handleChange('parent_phone_number', value)
                                        }}
                                        placeholder="Contoh: 08123456789"
                                        maxLength={15}
                                    />
                                </div>
                            </TabsContent>
                        </Tabs>

                        {updateMutation.isError && (
                            <div className="bg-red-50 border border-red-200 rounded-md p-3">
                                <p className="text-sm text-red-600">
                                    {updateMutation.error instanceof Error
                                        ? updateMutation.error.message
                                        : 'Terjadi kesalahan saat memperbarui data'}
                                </p>
                            </div>
                        )}

                        <div className="flex justify-end gap-2">
                            <Button
                                type="button"
                                variant="outline"
                                onClick={() => onOpenChange(false)}
                                disabled={updateMutation.isPending}
                            >
                                Batal
                            </Button>
                            <Button type="submit" disabled={updateMutation.isPending}>
                                {updateMutation.isPending && (
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                )}
                                Simpan
                            </Button>
                        </div>
                    </form>
                )}
            </DialogContent>
        </Dialog>
    )
}
