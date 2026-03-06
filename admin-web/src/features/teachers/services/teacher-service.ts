import { supabase } from '@/lib/supabase'

export interface Teacher {
    id: string
    full_name: string
    email?: string
    avatar_url?: string
    role: 'teacher'
    status?: string
    assignments?: SupervisorAssignment[]
}

export interface SupervisorAssignment {
    id: string
    company_id: number
    company?: {
        id: number
        name: string
    }
}

export const TeacherService = {
    async getTeachers(page: number = 0, pageSize: number = 10, search?: string) {
        const start = page * pageSize
        const end = start + pageSize - 1

        // Fetch profiles with role 'teacher' and their assignments
        let query = supabase
            .from('profiles')
            .select(`
                *,
                assignments:supervisor_assignments (
                    id,
                    company_id,
                    company:companies (id, name)
                )
            `, { count: 'exact' })
            .eq('role', 'teacher')
            .order('full_name')

        if (search) {
            query = query.ilike('full_name', `%${search}%`)
        }

        const { data, count, error } = await query.range(start, end)

        if (error) throw error
        return { data: data as Teacher[], count: count ?? 0 }
    },

    async createTeacher(payload: { email: string; password: string; fullName: string }) {
        const { data, error } = await supabase.rpc('create_teacher_user', {
            email: payload.email,
            password: payload.password,
            full_name: payload.fullName,
        })

        if (error) throw error
        return data
    },

    async assignToCompany(teacherId: string, companyId: number) {
        const { data, error } = await supabase
            .from('supervisor_assignments')
            .insert({
                teacher_id: teacherId,
                company_id: companyId,
            })
            .select()
            .single()

        if (error) throw error
        return data
    },

    async removeAssignment(assignmentId: string) {
        const { error } = await supabase
            .from('supervisor_assignments')
            .delete()
            .eq('id', assignmentId)

        if (error) throw error
    },

    async deleteTeacher(teacherId: string) {
        // Soft delete: set status to suspended
        const { error } = await supabase
            .from('profiles')
            .update({ status: 'suspended' })
            .eq('id', teacherId)

        if (error) throw error
        return true
    }
}
