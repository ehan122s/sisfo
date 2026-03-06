import { supabase } from '@/lib/supabase'

export interface HomeroomAssignment {
    id: number
    class_name: string
    teacher_id: string
    teacher_name: string
    created_at: string
    updated_at: string
}

/** Semua kelas unik dari tabel profiles siswa */
export async function getAllClasses(): Promise<string[]> {
    const { data, error } = await supabase
        .from('profiles')
        .select('class_name')
        .eq('role', 'student')
        .not('class_name', 'is', null)
        .order('class_name')

    if (error) throw error

    const unique = [...new Set((data ?? []).map((r) => r.class_name as string))]
    return unique
}

/** Semua assignment wali kelas beserta nama guru */
export async function getHomeroomAssignments(): Promise<HomeroomAssignment[]> {
    const { data, error } = await supabase
        .from('class_homeroom_teachers')
        .select(`
            id,
            class_name,
            teacher_id,
            created_at,
            updated_at,
            teacher:profiles!teacher_id (full_name)
        `)
        .order('class_name')

    if (error) throw error

    return (data ?? []).map((row: any) => ({
        id: row.id,
        class_name: row.class_name,
        teacher_id: row.teacher_id,
        teacher_name: row.teacher?.full_name ?? '-',
        created_at: row.created_at,
        updated_at: row.updated_at,
    }))
}

/** Wali kelas untuk satu kelas (null jika belum ditugaskan) */
export async function getHomeroomByClass(className: string): Promise<HomeroomAssignment | null> {
    const { data, error } = await supabase
        .from('class_homeroom_teachers')
        .select(`
            id,
            class_name,
            teacher_id,
            created_at,
            updated_at,
            teacher:profiles!teacher_id (full_name)
        `)
        .eq('class_name', className)
        .maybeSingle()

    if (error) throw error
    if (!data) return null

    return {
        id: data.id,
        class_name: data.class_name,
        teacher_id: data.teacher_id,
        teacher_name: (data as any).teacher?.full_name ?? '-',
        created_at: data.created_at,
        updated_at: data.updated_at,
    }
}

/** Tugaskan / ganti wali kelas (upsert by class_name) */
export async function upsertHomeroom(className: string, teacherId: string): Promise<void> {
    const { error } = await supabase
        .from('class_homeroom_teachers')
        .upsert(
            { class_name: className, teacher_id: teacherId, updated_at: new Date().toISOString() },
            { onConflict: 'class_name' }
        )

    if (error) throw error
}

/** Hapus assignment wali kelas */
export async function removeHomeroom(className: string): Promise<void> {
    const { error } = await supabase
        .from('class_homeroom_teachers')
        .delete()
        .eq('class_name', className)

    if (error) throw error
}

/** Semua guru aktif untuk dropdown */
export async function getActiveTeachers(): Promise<{ id: string; full_name: string }[]> {
    const { data, error } = await supabase
        .from('profiles')
        .select('id, full_name')
        .eq('role', 'teacher')
        .neq('status', 'suspended')
        .order('full_name')

    if (error) throw error
    return data ?? []
}
