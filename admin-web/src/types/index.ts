// Student type based on profiles table
export interface Student {
    id: string
    full_name: string
    email: string
    nisn?: string
    class_name?: string
    avatar_url?: string
    phone_number?: string
    parent_phone_number?: string
    status: 'pending' | 'active' | 'inactive' | 'suspended'
    device_id?: string
    created_at: string
    placements?: Placement[]
    nipd?: string
    gender?: 'L' | 'P'
    birth_place?: string
    birth_date?: string
    nik?: string
    religion?: string
    address?: string
    father_name?: string
    mother_name?: string
}

// Company/DUDI type
export interface Company {
    id: number
    name: string
    address?: string
    latitude?: number
    longitude?: number
    radius_meter?: number
    created_at: string
}

// Placement type
export interface Placement {
    id: number
    student_id: string
    company_id: number
    companies?: Company
    start_date: string
    end_date?: string
}

// Attendance Log type
export interface AttendanceLog {
    id: number
    student_id: string
    status: 'Hadir' | 'Terlambat' | 'Izin' | 'Sakit' | 'Belum Hadir'
    check_in_time?: string
    check_out_time?: string
    check_in_lat?: number
    check_in_long?: number
    check_out_lat?: number
    check_out_long?: number
    check_in_photo_url?: string
    check_out_photo_url?: string
    created_at: string
    profiles?: Student
}

// Daily Journal type
export interface DailyJournal {
    id: number
    student_id: string
    placement_id?: number
    activity_title: string
    description: string
    evidence_photo?: string
    is_approved: boolean
    created_at: string
    profiles?: Student
}

// Live Monitoring Map Data
export interface MapMarkerData {
    id: string
    name: string
    lat: number
    lng: number
    status: 'Hadir' | 'Belum Hadir'
    color: 'green' | 'red'
    time?: string
    company_name?: string
}

// Dashboard Stats
export interface DashboardStats {
    totalStudents: number
    todayAttendance: {
        Hadir: number
        Terlambat: number
        'Belum Hadir': number
        Izin: number
        Sakit: number
    }
    companyDistribution: { name: string; count: number }[]
    cityDistribution: { name: string; count: number }[]
}

// Message Template type
export interface MessageTemplate {
    id: string
    template_key: 'on_time' | 'late' | 'absent' | 'no_journal'
    template_name: string
    message_template: string
    is_active: boolean
    created_at: string
    updated_at: string
}

// Notification Log type
export interface NotificationLog {
    id: string
    student_id: string
    parent_phone_number: string
    notification_type: 'on_time' | 'late' | 'absent' | 'no_journal'
    message_sent: string
    status: 'sent' | 'failed' | 'pending'
    sent_at: string
    created_at: string
    profiles?: Student
}

// App Config type
export interface AppConfig {
    key: string
    value: string
    description?: string
    created_at: string
    updated_at: string
}
