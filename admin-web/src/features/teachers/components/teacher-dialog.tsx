import { useState, useEffect } from 'react'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { TeacherService, type Teacher } from '../services/teacher-service'
import { supabase } from '@/lib/supabase'
import { Check } from "lucide-react"
import { validatePassword } from '@/lib/validators'

// Simple Company Interface
interface Company {
    id: number
    name: string
}

interface TeacherDialogProps {
    teacher?: Teacher
    onSuccess: () => void
    open?: boolean
    onOpenChange?: (open: boolean) => void
}

export function TeacherDialog({ teacher, onSuccess, open: controlledOpen, onOpenChange: setControlledOpen }: TeacherDialogProps) {
    const [internalOpen, setInternalOpen] = useState(false)
    const [loading, setLoading] = useState(false)
    const [companies, setCompanies] = useState<Company[]>([])

    const isControlled = controlledOpen !== undefined
    const open = isControlled ? controlledOpen : internalOpen
    const setOpen = isControlled ? setControlledOpen! : setInternalOpen

    // Form States
    const [fullName, setFullName] = useState('')
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [selectedCompanyIds, setSelectedCompanyIds] = useState<number[]>([])

    useEffect(() => {
        if (open) {
            fetchCompanies()
            if (teacher) {
                setFullName(teacher.full_name)
                setEmail(teacher.email || '')
                // Pre-fill assignments
                const assigned = teacher.assignments?.map(a => a.company_id) || []
                setSelectedCompanyIds(assigned)
            } else {
                // Reset form
                setFullName('')
                setEmail('')
                setPassword('')
                setSelectedCompanyIds([])
            }
        }
    }, [open, teacher])

    const fetchCompanies = async () => {
        const { data } = await supabase.from('companies').select('id, name').order('name')
        if (data) setCompanies(data)
    }

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setLoading(true)
        try {
            let teacherId = teacher?.id

            if (!teacherId) {
                // Validate Password
                const passwordValidation = validatePassword(password)
                if (!passwordValidation.isValid) {
                    alert(passwordValidation.message)
                    setLoading(false)
                    return
                }

                // Create New
                const result = await TeacherService.createTeacher({
                    email,
                    password,
                    fullName,
                })
                // Result is UUID string directly because RPC returns uuid
                teacherId = result as unknown as string
            } else {
                // Update existing (Name only for now, as Auth update requires specific permissions or different API)
                // For MVP we might skip name update if complex. Profile update is easy though.
                await supabase.from('profiles').update({ full_name: fullName }).eq('id', teacherId)
            }

            // Handle Assignments
            // 1. Get current assignments
            const currentAssignments = teacher?.assignments || []
            const currentIds = currentAssignments.map(a => a.company_id)

            // 2. Determine to Add
            const toAdd = selectedCompanyIds.filter(id => !currentIds.includes(id))

            // 3. Determine to Remove
            const toRemove = currentAssignments
                .filter(a => !selectedCompanyIds.includes(a.company_id))
                .map(a => a.id) // We need assignment ID to delete

            // Execute Updates
            // Add
            for (const companyId of toAdd) {
                await TeacherService.assignToCompany(teacherId!, companyId)
            }
            // Remove
            for (const assignmentId of toRemove) {
                await TeacherService.removeAssignment(assignmentId)
            }

            setOpen(false)
            onSuccess()
        } catch (error: any) {
            alert(error.message || 'Terjadi kesalahan')
        } finally {
            setLoading(false)
        }
    }

    const toggleCompany = (id: number) => {
        if (selectedCompanyIds.includes(id)) {
            setSelectedCompanyIds(prev => prev.filter(c => c !== id))
        } else {
            setSelectedCompanyIds(prev => [...prev, id])
        }
    }

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            {!isControlled && (
                <DialogTrigger asChild>
                    <Button variant={teacher ? "outline" : "default"}>
                        {teacher ? "Edit" : "Tambah Pembimbing"}
                    </Button>
                </DialogTrigger>
            )}
            <DialogContent className="sm:max-w-[500px] max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                    <DialogTitle>{teacher ? "Edit Pembimbing" : "Tambah Pembimbing Baru"}</DialogTitle>
                    <DialogDescription>
                        {teacher ? "Edit informasi pembimbing dan penempatan DUDI." : "Buat akun pembimbing baru dan tentukan DUDI yang dibimbing."}
                    </DialogDescription>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4">
                    <div className="space-y-2">
                        <Label>Nama Lengkap</Label>
                        <Input
                            value={fullName}
                            onChange={e => setFullName(e.target.value)}
                            required
                        />
                    </div>

                    <div className="space-y-2">
                        <Label>Email</Label>
                        <Input
                            type="email"
                            value={email}
                            onChange={e => setEmail(e.target.value)}
                            required
                            disabled={!!teacher} // Disable email edit for now
                        />
                    </div>

                    {!teacher && (
                        <div className="space-y-2">
                            <Label>Password</Label>
                            <Input
                                type="password"
                                value={password}
                                onChange={e => setPassword(e.target.value)}
                                required
                            />
                            <p className="text-xs text-muted-foreground">
                                Min 8 karakter, huruf besar, huruf kecil, angka.
                            </p>
                        </div>
                    )}

                    <div className="space-y-2">
                        <Label>Perusahaan Binaan (DUDI)</Label>
                        <div className="border rounded-md p-2 h-48 overflow-y-auto space-y-1">
                            {companies.map(company => (
                                <div
                                    key={company.id}
                                    className={`flex items-center space-x-2 p-2 rounded cursor-pointer hover:bg-slate-100 ${selectedCompanyIds.includes(company.id) ? 'bg-slate-50' : ''}`}
                                    onClick={() => toggleCompany(company.id)}
                                >
                                    <div className={`w-4 h-4 border rounded flex items-center justify-center ${selectedCompanyIds.includes(company.id) ? 'bg-primary border-primary' : 'border-gray-300'}`}>
                                        {selectedCompanyIds.includes(company.id) && <Check className="h-3 w-3 text-white" />}
                                    </div>
                                    <span className="text-sm">{company.name}</span>
                                </div>
                            ))}
                        </div>
                        <p className="text-xs text-muted-foreground">{selectedCompanyIds.length} Perusahaan dipilih</p>
                    </div>

                    <div className="flex justify-end pt-4">
                        <Button type="submit" disabled={loading}>
                            {loading ? "Menyimpan..." : "Simpan"}
                        </Button>
                    </div>
                </form>
            </DialogContent>
        </Dialog>
    )
}
