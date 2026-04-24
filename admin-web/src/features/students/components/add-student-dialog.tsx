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

interface AddStudentDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
}

const emptyForm = {
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
}

export function AddStudentDialog({ open, onOpenChange }: AddStudentDialogProps) {
    const [formData, setFormData] = useState(emptyForm)
    const [errors, setErrors] = useState<Record<string, string>>({})
    const [isSuccess, setIsSuccess] = useState(false)
    const queryClient = useQueryClient()

    const resetForm = () => {
        setFormData(emptyForm)
        setErrors({})
        setIsSuccess(false)
    }

    // Fetch companies
    const { data: companies = [] } = useQuery({
        queryKey: ['companies'],
        queryFn: async () => {
            const { data } = await supabase.from('companies').select('*').order('name')
            return (data ?? []) as Company[]
        },
    })

    // Fetch class list
    const { data: classList = [] } = useQuery({
        queryKey: ['class-list'],
        queryFn: async () => {
            const { data } = await supabase.rpc('get_distinct_classes')
            return (data || []).map((d: any) => d.class_name).filter(Boolean) as string[]
        },
    })

    const addStudentMutation = useMutation({
        mutationFn: async () => {
            // Validasi
            const newErrors: Record<string, string> = {}
            if (!formData.nama.trim()) newErrors.nama = 'Nama wajib diisi'
            if (!formData.nisn.trim()) newErrors.nisn = 'NISN wajib diisi'
            if (!formData.kelas.trim()) newErrors.kelas = 'Kelas wajib diisi'
            if (formData.password && formData.password.length < 6) {
                newErrors.password = 'Password minimal 6 karakter'
            }

            if (Object.keys(newErrors).length > 0) {
                setErrors(newErrors)
                throw new Error('Validasi gagal')
            }

            // Siapkan payload — field kosong tidak dikirim
            const payload: Record<string, unknown> = {
                nama: formData.nama.trim(),
                nisn: formData.nisn.trim(),
                kelas: formData.kelas.trim(),
            }
            if (formData.password) payload.password = formData.password.trim()
            if (formData.company_id) payload.company_id = parseInt(formData.company_id)
            if (formData.phone_number) payload.phone_number = formData.phone_number.trim()
            if (formData.parent_phone_number) payload.parent_phone_number = formData.parent_phone_number.trim()
            if (formData.nipd) payload.nipd = formData.nipd.trim()
            if (formData.gender) payload.gender = formData.gender
            if (formData.birth_place) payload.birth_place = formData.birth_place.trim()
            if (formData.birth_date) payload.birth_date = formData.birth_date
            if (formData.nik) payload.nik = formData.nik.trim()
            if (formData.religion) payload.religion = formData.religion.trim()
            if (formData.address) payload.address = formData.address.trim()
            if (formData.father_name) payload.father_name = formData.father_name.trim()
            if (formData.mother_name) payload.mother_name = formData.mother_name.trim()

            // Pakai supabase.functions.invoke — token otomatis dikirim
            const { data: result, error } = await supabase.functions.invoke('import-students', {
                body: { students: [payload] },
            })

            if (error) throw new Error(error.message || 'Gagal menambahkan siswa')

            // Edge Function mengembalikan array results — cek hasil siswa pertama
            const studentResult = result?.results?.[0]
            if (studentResult && !studentResult.success) {
                throw new Error(studentResult.error || 'Gagal menambahkan siswa')
            }

            return result
        },

        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['students'] })
            setIsSuccess(true)
            setTimeout(() => {
                resetForm()
                onOpenChange(false)
                toast.success(`Siswa ${formData.nama} berhasil ditambahkan!`)
            }, 1500)
        },
        onError: (error) => {
            if (error.message !== 'Validasi gagal') {
                toast.error(error instanceof Error ? error.message : 'Gagal menambahkan siswa')
            }
        },
    })

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault()
        setErrors({})
        addStudentMutation.mutate()
    }

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value } = e.target
        let val = value
        if (name === 'nisn') val = value.replace(/\D/g, '').slice(0, 10)
        if (name === 'phone_number' || name === 'parent_phone_number') val = value.replace(/\D/g, '').slice(0, 15)
        setFormData(prev => ({ ...prev, [name]: val }))
        if (errors[name]) setErrors(prev => { const n = { ...prev }; delete n[name]; return n })
    }

    return (
        <Dialog open={open} onOpenChange={(v) => { if (!v) resetForm(); onOpenChange(v); }}>
            <DialogContent className="sm:max-w-[500px]">
                <DialogHeader>
                    <DialogTitle>Tambah Siswa</DialogTitle>
                    <DialogDescription>
                        Tambahkan siswa baru. Status awal: Pending (belum bisa login sampai diaktifkan).
                    </DialogDescription>
                </DialogHeader>

                {isSuccess ? (
                    <div className="flex flex-col items-center justify-center py-8">
                        <div className="rounded-full bg-green-100 p-3 mb-4">
                            <CheckCircle className="h-12 w-12 text-green-600" />
                        </div>
                        <h3 className="text-xl font-semibold text-green-700">Berhasil!</h3>
                        <p className="text-muted-foreground text-center mt-2">
                            Siswa <strong>{formData.nama}</strong> berhasil ditambahkan.
                        </p>
                    </div>
                ) : (
                    <form onSubmit={handleSubmit}>
                        <Tabs defaultValue="account" className="w-full">
                            <TabsList className="grid w-full grid-cols-3 mb-4">
                                <TabsTrigger value="account">Akun & Sekolah</TabsTrigger>
                                <TabsTrigger value="personal">Data Pribadi</TabsTrigger>
                                <TabsTrigger value="parents">Orang Tua</TabsTrigger>
                            </TabsList>

                            {/* TAB 1 */}
                            <TabsContent value="account" className="space-y-4">
                                <div className="space-y-2">
                                    <Label>Nama Lengkap *</Label>
                                    <Input name="nama" value={formData.nama} onChange={handleChange} placeholder="Contoh: Renzo Lioren" />
                                    {errors.nama && <p className="text-sm text-red-600">{errors.nama}</p>}
                                </div>
                                <div className="space-y-2">
                                    <Label>NISN *</Label>
                                    <Input name="nisn" value={formData.nisn} onChange={handleChange} placeholder="10 digit" maxLength={10} />
                                    {errors.nisn && <p className="text-sm text-red-600">{errors.nisn}</p>}
                                </div>
                                <div className="space-y-2">
                                    <Label>NIPD</Label>
                                    <Input name="nipd" value={formData.nipd} onChange={handleChange} placeholder="NIPD" />
                                </div>
                                <div className="space-y-2">
                                    <Label>Kelas *</Label>
                                    <Select value={formData.kelas} onValueChange={(v) => setFormData(p => ({ ...p, kelas: v }))}>
                                        <SelectTrigger>
                                            <SelectValue placeholder="Pilih kelas..." />
                                        </SelectTrigger>
                                        <SelectContent>
                                            {classList.map((c) => (
                                                <SelectItem key={c} value={c}>{c}</SelectItem>
                                            ))}
                                        </SelectContent>
                                    </Select>
                                    {errors.kelas && <p className="text-sm text-red-600">{errors.kelas}</p>}
                                </div>
                                <div className="space-y-2">
                                    <Label>DUDI (opsional)</Label>
                                    <Select value={formData.company_id || 'none'} onValueChange={(v) => setFormData(p => ({ ...p, company_id: v === 'none' ? '' : v }))}>
                                        <SelectTrigger>
                                            <SelectValue placeholder="Pilih DUDI..." />
                                        </SelectTrigger>
                                        <SelectContent>
                                            <SelectItem value="none">Tanpa DUDI</SelectItem>
                                            {companies.map((c) => (
                                                <SelectItem key={c.id} value={c.id.toString()}>{c.name}</SelectItem>
                                            ))}
                                        </SelectContent>
                                    </Select>
                                </div>
                                <div className="space-y-2">
                                    <Label>Password (opsional)</Label>
                                    <Input name="password" value={formData.password} onChange={handleChange} placeholder="Kosongkan = NISN + Sip" />
                                    {errors.password && <p className="text-sm text-red-600">{errors.password}</p>}
                                    <p className="text-xs text-muted-foreground">Default: NISNSip (contoh: 0012345678Sip)</p>
                                </div>
                            </TabsContent>

                            {/* TAB 2 */}
                            <TabsContent value="personal" className="space-y-4">
                                <div className="space-y-2">
                                    <Label>NIK</Label>
                                    <Input name="nik" value={formData.nik} onChange={handleChange} placeholder="16 digit" maxLength={16} />
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <Label>Jenis Kelamin</Label>
                                        <Select value={formData.gender} onValueChange={(v) => setFormData(p => ({ ...p, gender: v }))}>
                                            <SelectTrigger><SelectValue /></SelectTrigger>
                                            <SelectContent>
                                                <SelectItem value="L">Laki-laki</SelectItem>
                                                <SelectItem value="P">Perempuan</SelectItem>
                                            </SelectContent>
                                        </Select>
                                    </div>
                                    <div className="space-y-2">
                                        <Label>Agama</Label>
                                        <Input name="religion" value={formData.religion} onChange={handleChange} placeholder="Agama" />
                                    </div>
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <Label>Tempat Lahir</Label>
                                        <Input name="birth_place" value={formData.birth_place} onChange={handleChange} placeholder="Kota" />
                                    </div>
                                    <div className="space-y-2">
                                        <Label>Tanggal Lahir</Label>
                                        <Input name="birth_date" type="date" value={formData.birth_date} onChange={handleChange} />
                                    </div>
                                </div>
                                <div className="space-y-2">
                                    <Label>Alamat</Label>
                                    <Input name="address" value={formData.address} onChange={handleChange} placeholder="Alamat lengkap" />
                                </div>
                                <div className="space-y-2">
                                    <Label>No. HP Siswa</Label>
                                    <Input name="phone_number" value={formData.phone_number} onChange={handleChange} placeholder="08xxxxxxxxx" maxLength={15} />
                                </div>
                            </TabsContent>

                            {/* TAB 3 */}
                            <TabsContent value="parents" className="space-y-4">
                                <div className="space-y-2">
                                    <Label>Nama Ayah</Label>
                                    <Input name="father_name" value={formData.father_name} onChange={handleChange} placeholder="Nama Ayah" />
                                </div>
                                <div className="space-y-2">
                                    <Label>Nama Ibu</Label>
                                    <Input name="mother_name" value={formData.mother_name} onChange={handleChange} placeholder="Nama Ibu" />
                                </div>
                                <div className="space-y-2">
                                    <Label>No. HP Orang Tua</Label>
                                    <Input name="parent_phone_number" value={formData.parent_phone_number} onChange={handleChange} placeholder="08xxxxxxxxx" maxLength={15} />
                                </div>
                            </TabsContent>
                        </Tabs>

                        {addStudentMutation.isError && addStudentMutation.error?.message !== 'Validasi gagal' && (
                            <div className="mt-4 bg-red-50 border border-red-200 rounded-md p-3">
                                <p className="text-sm text-red-600">{addStudentMutation.error?.message}</p>
                            </div>
                        )}

                        <div className="flex justify-end gap-2 mt-6">
                            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={addStudentMutation.isPending}>
                                Batal
                            </Button>
                            <Button type="submit" disabled={addStudentMutation.isPending}>
                                {addStudentMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                Tambah Siswa
                            </Button>
                        </div>
                    </form>
                )}
            </DialogContent>
        </Dialog>
    )
}