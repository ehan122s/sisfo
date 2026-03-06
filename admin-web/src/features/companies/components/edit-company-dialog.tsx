import { useState, useEffect } from 'react'
import { AuditLogService } from '@/features/audit-logs/services/audit-log-service'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from "sonner"
import { supabase } from '@/lib/supabase'
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogFooter,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { LocationPicker } from './location-picker'
import { Loader2 } from 'lucide-react'
import type { Company } from '@/types'

interface EditCompanyDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    company: Company | null
}

export function EditCompanyDialog({ open, onOpenChange, company }: EditCompanyDialogProps) {
    const queryClient = useQueryClient()
    const [formData, setFormData] = useState({
        name: '',
        address: '',
        latitude: '',
        longitude: '',
        radius_meter: '100',
        custom_on_time_limit: '',
        custom_deadline: '',
        custom_check_out_start: '',
        custom_check_out_end: '',
    })

    useEffect(() => {
        if (company) {
            setFormData({
                name: company.name,
                address: company.address || '',
                latitude: company.latitude?.toString() || '',
                longitude: company.longitude?.toString() || '',
                radius_meter: company.radius_meter?.toString() || '100',
                custom_on_time_limit: (company as any).custom_on_time_limit || '',
                custom_deadline: (company as any).custom_deadline || '',
                custom_check_out_start: (company as any).custom_check_out_start || '',
                custom_check_out_end: (company as any).custom_check_out_end || '',
            })
        }
    }, [company])

    const mutation = useMutation({
        mutationFn: async () => {
            if (!company) throw new Error('No company selected')
            if (!formData.name.trim()) throw new Error('Nama perusahaan wajib diisi')

            const payload = {
                name: formData.name,
                address: formData.address,
                latitude: formData.latitude ? parseFloat(formData.latitude) : null,
                longitude: formData.longitude ? parseFloat(formData.longitude) : null,
                radius_meter: formData.radius_meter ? parseInt(formData.radius_meter) : 100,
                custom_on_time_limit: formData.custom_on_time_limit || null,
                custom_deadline: formData.custom_deadline || null,
                custom_check_out_start: formData.custom_check_out_start || null,
                custom_check_out_end: formData.custom_check_out_end || null,
            }

            const { error } = await supabase
                .from('companies')
                .update(payload)
                .eq('id', company.id)

            if (error) throw error

            // Log action
            await AuditLogService.logAction(
                'UPDATE_COMPANY',
                'companies',
                company.id.toString(),
                { updates: payload }
            )
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['companies'] })
            toast.success('Data DUDI berhasil diperbarui')
            onOpenChange(false)
        },
        onError: (error) => {
            console.error('Update company error:', error)
            toast.error(error instanceof Error ? error.message : 'Gagal memperbarui DUDI')
        },
    })

    const handleLocationSelect = (loc: { lat: number; lng: number }) => {
        setFormData(prev => ({
            ...prev,
            latitude: loc.lat.toString(),
            longitude: loc.lng.toString()
        }))
    }

    const initialLocation = company?.latitude && company?.longitude
        ? { lat: company.latitude, lng: company.longitude }
        : null

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="max-w-xl max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                    <DialogTitle>Edit DUDI - {company?.name}</DialogTitle>
                </DialogHeader>

                <div className="space-y-4 py-4">
                    <div className="space-y-2">
                        <Label htmlFor="name">Nama Perusahaan *</Label>
                        <Input
                            id="name"
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            placeholder="PT. Contoh Indonesia"
                        />
                    </div>

                    <div className="space-y-2">
                        <Label>Lokasi (Pilih di Peta atau Manual)</Label>
                        {/* Key helps reset map when company changes */}
                        <LocationPicker
                            key={`map-${company?.id}`}
                            initialLocation={initialLocation}
                            onLocationSelect={handleLocationSelect}
                            height="250px"
                        />
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <Label htmlFor="lat">Latitude</Label>
                            <Input
                                id="lat"
                                type="number"
                                step="any"
                                value={formData.latitude}
                                onChange={(e) => setFormData({ ...formData, latitude: e.target.value })}
                                placeholder="-6.xxx"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="lng">Longitude</Label>
                            <Input
                                id="lng"
                                type="number"
                                step="any"
                                value={formData.longitude}
                                onChange={(e) => setFormData({ ...formData, longitude: e.target.value })}
                                placeholder="107.xxx"
                            />
                        </div>
                    </div>

                    <div className="space-y-2">
                        <Label htmlFor="address">Alamat Lengkap</Label>
                        <Input
                            id="address"
                            value={formData.address}
                            onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                            placeholder="Jl. Contoh No. 123..."
                        />
                    </div>

                    <div className="space-y-2">
                        <Label htmlFor="radius">Radius Geofence (meter)</Label>
                        <Input
                            id="radius"
                            type="number"
                            value={formData.radius_meter}
                            onChange={(e) => setFormData({ ...formData, radius_meter: e.target.value })}
                            placeholder="100"
                        />
                    </div>

                    <div className="border-t pt-4 space-y-4">
                        <div>
                            <Label className="text-sm font-medium">Pengaturan Waktu Absen (Opsional)</Label>
                            <p className="text-xs text-muted-foreground mt-1">
                                Kosongkan untuk menggunakan waktu global
                            </p>
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label htmlFor="onTimeLimit">Batas Tepat Waktu</Label>
                                <Input
                                    id="onTimeLimit"
                                    type="time"
                                    value={formData.custom_on_time_limit}
                                    onChange={(e) => setFormData({ ...formData, custom_on_time_limit: e.target.value })}
                                    placeholder="08:00"
                                />
                                <p className="text-xs text-muted-foreground">Default: 08:00</p>
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="deadline">Batas Deadline</Label>
                                <Input
                                    id="deadline"
                                    type="time"
                                    value={formData.custom_deadline}
                                    onChange={(e) => setFormData({ ...formData, custom_deadline: e.target.value })}
                                    placeholder="08:30"
                                />
                                <p className="text-xs text-muted-foreground">Default: 08:30</p>
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="checkOutStart">Mulai Pulang</Label>
                                <Input
                                    id="checkOutStart"
                                    type="time"
                                    value={formData.custom_check_out_start}
                                    onChange={(e) => setFormData({ ...formData, custom_check_out_start: e.target.value })}
                                    placeholder="16:00"
                                />
                                <p className="text-xs text-muted-foreground">Default: 16:00</p>
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="checkOutEnd">Batas Akhir Pulang</Label>
                                <Input
                                    id="checkOutEnd"
                                    type="time"
                                    value={formData.custom_check_out_end}
                                    onChange={(e) => setFormData({ ...formData, custom_check_out_end: e.target.value })}
                                    placeholder="18:00"
                                />
                                <p className="text-xs text-muted-foreground">Default: 18:00</p>
                            </div>
                        </div>
                    </div>
                </div>

                <DialogFooter>
                    <Button variant="outline" onClick={() => onOpenChange(false)} disabled={mutation.isPending}>
                        Batal
                    </Button>
                    <Button onClick={() => mutation.mutate()} disabled={mutation.isPending}>
                        {mutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Simpan
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    )
}
