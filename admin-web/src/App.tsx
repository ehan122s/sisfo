import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AuthProvider } from '@/contexts/auth-context'
import { ThemeProvider } from '@/components/theme-provider'
import { ProtectedRoute } from '@/components/protected-route'
import { AppLayout } from '@/components/layout/app-layout'
import { LoginPage } from '@/features/auth/login-page'
import { DashboardPage } from '@/features/dashboard/dashboard-page'
import { PklDashboardPage } from '@/features/pkl-dashboard/pkl-dashboard-page'
import { StudentsPage } from '@/features/students/students-page'
import { CompaniesPage } from '@/features/companies/companies-page'
import { AttendancePage } from '@/features/attendance/attendance-page'
import { JournalsPage } from '@/features/journals/journals-page'
import { MonthlyRecapPage } from '@/features/reports/pages/monthly-recap-page'
import { StudentMonitoringPage } from '@/features/reports/pages/student-monitoring-page'
import { StudentDetailPage } from '@/features/reports/pages/student-detail-page'
import { StudentReportPage } from '@/features/reports/pages/student-report-page'
import { TeachersPage } from '@/features/teachers/pages/teachers-page'
import { TeacherAttendancePage } from '@/features/teacher-attendance/teacher-attendance-page'
import { AuditLogsPage } from '@/features/audit-logs/audit-logs-page'
import { AnnouncementsPage } from '@/features/announcements/announcements-page'
import { SettingsPage } from '@/features/settings/settings-page'
import { MessageTemplatesPage } from '@/features/settings/message-templates-page'
import { NotificationHistoryPage } from '@/features/notifications/notification-history-page'
import { LiveMapPage } from '@/features/reports/pages/live-map-page'
import { HomeroomPage } from '@/features/homeroom/pages/homeroom-page'
import { Toaster } from "@/components/ui/sonner"

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      retry: 1,
    },
  },
})

function App() {
  return (
    <ThemeProvider defaultTheme="light" storageKey="e-pkl-theme">
      <Toaster />
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>
          <AuthProvider>
            <Routes>
              {/* Public Routes */}
              <Route path="/login" element={<LoginPage />} />

              {/* Protected Routes */}
              <Route
                element={
                  <ProtectedRoute>
                    <AppLayout />
                  </ProtectedRoute>
                }
              >
                <Route path="/" element={<DashboardPage />} />
                <Route path="/students" element={<StudentsPage />} />
                <Route path="/companies" element={<CompaniesPage />} />
                <Route path="/pkl-dashboard" element={<PklDashboardPage />} />
                <Route path="/attendance" element={<AttendancePage />} />
                <Route path="/teacher-attendance" element={<TeacherAttendancePage />} />
                <Route path="/journals" element={<JournalsPage />} />
                <Route path="/teachers" element={<TeachersPage />} />
                <Route path="/teachers" element={<TeachersPage />} />
                <Route path="/monitoring" element={<StudentMonitoringPage />} />
                <Route path="/live-map" element={<LiveMapPage />} />
                <Route path="/monitoring/:studentId" element={<StudentDetailPage />} />
                <Route path="/monitoring/:studentId/report/:year" element={<StudentReportPage />} />
                <Route path="/reports" element={<MonthlyRecapPage />} />
                <Route path="/audit-logs" element={<AuditLogsPage />} />
                <Route path="/announcements" element={<AnnouncementsPage />} />
                <Route path="/notifications" element={<NotificationHistoryPage />} />
                <Route path="/settings" element={<SettingsPage />} />
                <Route path="/settings/templates" element={<MessageTemplatesPage />} />
                <Route path="/wali-kelas" element={<HomeroomPage />} />
              </Route>
            </Routes>
          </AuthProvider>
        </BrowserRouter>
      </QueryClientProvider>
    </ThemeProvider>
  )
}

export default App
