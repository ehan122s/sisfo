import { useState } from 'react'
import { toast } from "sonner"
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
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
import type { Company } from '@/types'
import { AuditLogService } from '@/features/audit-logs/services/audit-log-service'
import { validatePassword } from '@/lib/validators'

interface AddStudentDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
}

export function AddStudentDialog({ open, onOpenChange }: AddStudentDialogProps) {
    const [formData, setFormData] = useState({
        nama: '',
        nisn: '',
        kelas: '',
        password: '',
        company_id: '',
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

    const resetForm = () => {
        setFormData({
            nama: '',
            nisn: '',
            kelas: '',
            password: '',
            company_id: '',
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
        setErrors({})
        setIsSuccess(false)
    }

    // Fetch companies for dropdown
    const { data: companies = [] } = useQuery({
        queryKey: ['companies'],
        queryFn: async () => {
            const { data } = await supabase
                .from('companies')
                .select('*')
                .order('name')
            return (data ?? []) as Company[]
        },
    })

    // Add student mutation
    const addStudentMutation = useMutation({
        mutationFn: async () => {
            // Validate
            const newErrors: Record<string, string> = {}
            if (!formData.nama.trim()) newErrors.nama = 'Nama wajib diisi'
            if (!formData.nisn.trim()) newErrors.nisn = 'NISN wajib diisi'
            if (!formData.kelas.trim()) newErrors.kelas = 'Kelas wajib diisi'

            if (formData.password.trim()) {
                const passwordValidation = validatePassword(formData.password.trim())
                if (!passwordValidation.isValid) {
                    newErrors.password = passwordValidation.message || 'Password tidak memenuhi syarat'
                }
            }

            if (Object.keys(newErrors).length > 0) {
                setErrors(newErrors)
                throw new Error('Validasi gagal')
            }

            // Get session
            const { data: { session }, error: sessionError } = await supabase.auth.getSession()
            if (sessionError || !session) {
                throw new Error('Anda belum login')
            }

            // Call Edge Function with single student
            const response = await supabase.functions.invoke('import-students', {
                body: {
                    students: [
                        {
                            nama: formData.nama.trim(),
                            nisn: formData.nisn.trim(),
                            kelas: formData.kelas.trim(),
                            password: formData.password.trim() || undefined,
                            company_id: formData.company_id ? parseInt(formData.company_id, 10) : undefined,
                            phone_number: formData.phone_number.trim() || undefined,
                            parent_phone_number: formData.parent_phone_number.trim() || undefined,
                            nipd: formData.nipd.trim() || undefined,
                            gender: formData.gender as "L" | "P",
                            birth_place: formData.birth_place.trim() || undefined,
                            birth_date: formData.birth_date || undefined,
                            nik: formData.nik.trim() || undefined,
                            religion: formData.religion.trim() || undefined,
                            address: formData.address.trim() || undefined,
                            father_name: formData.father_name.trim() || undefined,
                            mother_name: formData.mother_name.trim() || undefined,
                        },
                    ],
                },
                headers: {
                    Authorization: `Bearer ${session.access_token}`,
                },
            })

            if (response.error) {
                throw new Error(response.error.message || 'Gagal menambahkan siswa')
            }

            // Check if student creation was successful
            const result = response.data?.results?.[0]
            if (!result?.success) {
                throw new Error(result?.error || 'Gagal menambahkan siswa')
            }

            // Log action
            await AuditLogService.logAction(
                'CREATE_STUDENT',
                'profiles',
                result.id || 'unknown',
                { nisn: formData.nisn, name: formData.nama }
            )

            return response.data
        },

        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['students'] })
            setIsSuccess(true)

            setTimeout(() => {
                resetForm()
                onOpenChange(false)
                toast.success('Siswa berhasil ditambahkan')
            }, 1500)
        },
        onError: (error) => {
            console.error('Add student error:', error)
            toast.error(error instanceof Error ? error.message : 'Gagal menambahkan siswa')
        },
    })

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault()
        setErrors({})
        addStudentMutation.mutate()
    }

    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
        const { name, value } = e.target;
        let processedValue = value;

        if (name === 'phone_number' || name === 'parent_phone_number' || name === 'nisn') {
            processedValue = value.replace(/\D/g, '').slice(0, 15); // Apply digit-only and max length
            if (name === 'nisn') {
                processedValue = value.replace(/\D/g, '').slice(0, 10); // NISN specific max length
            }
        }

        setFormData(prev => ({ ...prev, [name]: processedValue }));

        // Clear error for this field
        if (errors[name]) {
            setErrors(prev => {
                const newErrors = { ...prev }
                delete newErrors[name]
                return newErrors
            })
        }
    }

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="sm:max-w-[500px]">
                <DialogHeader>
                    <DialogTitle>Tambah Siswa</DialogTitle>
                    <DialogDescription>
                        Tambahkan siswa baru secara manual. Email akan dibuat otomatis: NISN@siswa.com. Password default: NISN + Sip.
                    </DialogDescription>
                </DialogHeader>

                {isSuccess ? (
                    <div className="flex flex-col items-center justify-center py-8 animate-in fade-in zoom-in duration-300">
                        <div className="rounded-full bg-green-100 p-3 mb-4">
                            <CheckCircle className="h-12 w-12 text-green-600" />
                        </div>
                        <h3 className="text-xl font-semibold text-green-700">Berhasil!</h3>
                        <p className="text-muted-foreground text-center mt-2">
                            Siswa {formData.nama} berhasil ditambahkan.
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
                                    <Label htmlFor="nama">Nama Lengkap *</Label>
                                    <Input
                                        id="nama"
                                        name="nama"
                                        value={formData.nama}
                                        onChange={handleChange}
                                        placeholder="Contoh: AHMAD ZAKI"
                                    />
                                    {errors.nama && <p className="text-sm text-red-600">{errors.nama}</p>}
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="nisn">NISN *</Label>
                                    <Input
                                        id="nisn"
                                        name="nisn"
                                        value={formData.nisn}
                                        onChange={handleChange}
                                        placeholder="Contoh: 0012345678"
                                        maxLength={10}
                                    />
                                    {errors.nisn && <p className="text-sm text-red-600">{errors.nisn}</p>}
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="nipd">NIPD</Label>
                                    <Input
                                        id="nipd"
                                        name="nipd"
                                        value={formData.nipd}
                                        onChange={handleChange}
                                        placeholder="NIPD"
                                    />
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="kelas">Kelas *</Label>
                                    <Input
                                        id="kelas"
                                        name="kelas"
                                        value={formData.kelas}
                                        onChange={handleChange}
                                        placeholder="Contoh: XI TEI 1"
                                    />
                                    {errors.kelas && <p className="text-sm text-red-600">{errors.kelas}</p>}
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="company">DUDI (opsional)</Label>
                                    <Select
                                        value={formData.company_id || 'none'}
                                        onValueChange={(value) => setFormData(prev => ({ ...prev, company_id: value === 'none' ? '' : value }))}
                                    >
                                        <SelectTrigger>
                                            <SelectValue placeholder="Pilih DUDI..." />
                                        </SelectTrigger>
                                        <SelectContent>
                                            <SelectItem value="none">Tanpa DUDI</SelectItem>
                                            {companies.map((company) => (
                                                <SelectItem key={company.id} value={company.id.toString()}>
                                                    {company.name}
                                                </SelectItem>
                                            ))}
                                        </SelectContent>
                                    </Select>
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="password">Password (opsional)</Label>
                                    <Input
                                        id="password"
                                        name="password"
                                        type="text"
                                        value={formData.password}
                                        onChange={handleChange}
                                        placeholder="Default: NISN"
                                    />
                                    {errors.password && <p className="text-sm text-red-600">{errors.password}</p>}
                                    <p className="text-xs text-muted-foreground">
                                        Default: NISN + Sip (Contoh: 0012345678Sip). Min 8 karakter.
                                    </p>
                                </div>
                            </TabsContent>

                            <TabsContent value="personal" className="space-y-4">
                                <div className="space-y-2">
                                    <Label htmlFor="nik">NIK</Label>
                                    <Input
                                        id="nik"
                                        name="nik"
                                        value={formData.nik}
                                        onChange={handleChange}
                                        placeholder="NIK (16 digit)"
                                        maxLength={16}
                                    />
                                </div>

                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <Label htmlFor="gender">Jenis Kelamin</Label>
                                        <Select
                                            value={formData.gender}
                                            onValueChange={(value) => setFormData(prev => ({ ...prev, gender: value }))}
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
                                            name="religion"
                                            value={formData.religion}
                                            onChange={handleChange}
                                            placeholder="Agama"
                                        />
                                    </div>
                                </div>

                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <Label htmlFor="birth_place">Tempat Lahir</Label>
                                        <Input
                                            id="birth_place"
                                            name="birth_place"
                                            value={formData.birth_place}
                                            onChange={handleChange}
                                            placeholder="Kota Lahir"
                                        />
                                    </div>
                                    <div className="space-y-2">
                                        <Label htmlFor="birth_date">Tanggal Lahir</Label>
                                        <Input
                                            id="birth_date"
                                            name="birth_date"
                                            type="date"
                                            value={formData.birth_date}
                                            onChange={handleChange}
                                        />
                                    </div>
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="address">Alamat</Label>
                                    <Input
                                        id="address"
                                        name="address"
                                        value={formData.address}
                                        onChange={handleChange}
                                        placeholder="Alamat Lengkap"
                                    />
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="phone_number">No. HP Siswa</Label>
                                    <Input
                                        id="phone_number"
                                        name="phone_number"
                                        value={formData.phone_number}
                                        onChange={handleChange}
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
                                        name="father_name"
                                        value={formData.father_name}
                                        onChange={handleChange}
                                        placeholder="Nama Ayah"
                                    />
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="mother_name">Nama Ibu</Label>
                                    <Input
                                        id="mother_name"
                                        name="mother_name"
                                        value={formData.mother_name}
                                        onChange={handleChange}
                                        placeholder="Nama Ibu"
                                    />
                                </div>

                                <div className="space-y-2">
                                    <Label htmlFor="parent_phone_number">No. HP Orang Tua</Label>
                                    <Input
                                        id="parent_phone_number"
                                        name="parent_phone_number"
                                        value={formData.parent_phone_number}
                                        onChange={handleChange}
                                        placeholder="Contoh: 08123456789"
                                        maxLength={15}
                                    />
                                </div>
                            </TabsContent>
                        </Tabs>

                        {addStudentMutation.isError && (
                            <div className="bg-red-50 border border-red-200 rounded-md p-3">
                                <p className="text-sm text-red-600">
                                    {addStudentMutation.error instanceof Error
                                        ? addStudentMutation.error.message
                                        : 'Terjadi kesalahan saat menambahkan siswa'}
                                </p>
                            </div>
                        )}

                        <div className="flex justify-end gap-2">
                            <Button
                                type="button"
                                variant="outline"
                                onClick={() => onOpenChange(false)}
                                disabled={addStudentMutation.isPending}
                            >
                                Batal
                            </Button>
                            <Button type="submit" disabled={addStudentMutation.isPending}>
                                {addStudentMutation.isPending && (
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                )}
                                Tambah Siswa
                            </Button>
                        </div>
                    </form>
                )}
            </DialogContent>
        </Dialog>
    )
}
