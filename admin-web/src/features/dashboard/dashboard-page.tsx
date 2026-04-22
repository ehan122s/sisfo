import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import {
  Bell, Building2, Users, BookOpen, CheckCircle2,
  AlertCircle, ChevronRight, Zap, Activity,
  Clock, FileText, ArrowUpRight,
} from 'lucide-react';
import { format } from 'date-fns';
import { id as idLocale } from 'date-fns/locale';

export default function DashboardPage() {
  const [isLoaded, setIsLoaded] = useState(false);
  const navigate = useNavigate();
  const today = format(new Date(), 'yyyy-MM-dd');

  useEffect(() => { setIsLoaded(true); }, []);

  const { data: totalStudents = 0 } = useQuery({
    queryKey: ['dash-total-students'],
    queryFn: async () => {
      const { count } = await supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'student').eq('status', 'active');
      return count || 0;
    },
  });

  const { data: totalCompanies = 0 } = useQuery({
    queryKey: ['dash-total-companies'],
    queryFn: async () => {
      const { count } = await supabase.from('companies').select('*', { count: 'exact', head: true });
      return count || 0;
    },
  });

  const { data: todayAttendance } = useQuery({
    queryKey: ['dash-today-attendance', today],
    queryFn: async () => {
      const { data } = await supabase
        .from('attendance_logs')
        .select('status')
        .gte('created_at', `${today}T00:00:00`)
        .lte('created_at', `${today}T23:59:59`);
      return {
        hadir: data?.filter(d => d.status === 'Hadir').length || 0,
        terlambat: data?.filter(d => d.status === 'Terlambat').length || 0,
        izin: data?.filter(d => d.status === 'Izin').length || 0,
        sakit: data?.filter(d => d.status === 'Sakit').length || 0,
        total: data?.length || 0,
      };
    },
  });

  const { data: pendingJournals = 0 } = useQuery({
    queryKey: ['dash-pending-journals'],
    queryFn: async () => {
      const { count } = await supabase.from('daily_journals').select('*', { count: 'exact', head: true }).eq('is_approved', false);
      return count || 0;
    },
  });

  const { data: announcements = [] } = useQuery({
    queryKey: ['dash-announcements'],
    queryFn: async () => {
      const { data } = await supabase.from('announcements').select('id, title, content, created_at').order('created_at', { ascending: false }).limit(3);
      return data || [];
    },
  });

  const { data: recentLogs = [] } = useQuery({
    queryKey: ['dash-recent-logs', today],
    queryFn: async () => {
      const { data } = await supabase
        .from('attendance_logs')
        .select('id, status, check_in_time, created_at, profiles(full_name, class_name)')
        .gte('created_at', `${today}T00:00:00`)
        .lte('created_at', `${today}T23:59:59`)
        .order('created_at', { ascending: false })
        .limit(6);
      return data || [];
    },
  });

  const absentCount = Math.max(0, totalStudents - (todayAttendance?.total || 0));
  const attendanceRate = totalStudents > 0 ? Math.round(((todayAttendance?.hadir || 0) / totalStudents) * 100) : 0;

  const getStatusStyle = (status: string) => {
    if (status === 'Hadir') return { bg: '#E8F5E9', color: '#2E7D32' };
    if (status === 'Terlambat') return { bg: '#FFF3E0', color: '#E65100' };
    if (status === 'Izin') return { bg: '#E3F2FD', color: '#1565C0' };
    if (status === 'Sakit') return { bg: '#F3E5F5', color: '#6A1B9A' };
    return { bg: '#FFEBEE', color: '#C62828' };
  };

  const formatTime = (t?: string) => t ? new Date(t).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-';

  const statCards = [
    { label: 'Total Siswa', value: totalStudents, icon: Users, color: '#1565C0', bg: '#E3F2FD', sub: 'Siswa aktif', href: '/students' },
    { label: 'Total DUDI', value: totalCompanies, icon: Building2, color: '#0277BD', bg: '#E1F5FE', sub: 'Mitra industri', href: '/companies' },
    { label: 'Hadir Hari Ini', value: todayAttendance?.hadir || 0, icon: CheckCircle2, color: '#2E7D32', bg: '#E8F5E9', sub: `${attendanceRate}% dari total`, href: '/attendance' },
    { label: 'Jurnal Pending', value: pendingJournals, icon: FileText, color: pendingJournals > 0 ? '#E65100' : '#2E7D32', bg: pendingJournals > 0 ? '#FFF3E0' : '#E8F5E9', sub: 'Menunggu approval', href: '/journals' },
  ];

  return (
    <div style={{ minHeight: '100vh', background: 'var(--background)', padding: '24px', fontFamily: "'Plus Jakarta Sans', sans-serif", opacity: isLoaded ? 1 : 0, transition: 'opacity 0.5s ease' }}>

      {/* HERO BANNER */}
      <div style={{ background: 'linear-gradient(135deg, #0D47A1 0%, #1565C0 50%, #1E88E5 100%)', borderRadius: 20, padding: '28px 32px', marginBottom: 24, position: 'relative', overflow: 'hidden', boxShadow: '0 8px 32px rgba(13,71,161,0.3)' }}>
        <div style={{ position: 'absolute', top: -60, right: 80, width: 220, height: 220, background: 'rgba(255,255,255,0.05)', borderRadius: '50%' }} />
        <div style={{ position: 'absolute', bottom: -50, right: -30, width: 180, height: 180, background: 'rgba(255,255,255,0.04)', borderRadius: '50%' }} />
        <div style={{ position: 'absolute', inset: 0, backgroundImage: 'radial-gradient(rgba(255,255,255,0.07) 1px, transparent 1px)', backgroundSize: '24px 24px' }} />
        <div style={{ position: 'relative', zIndex: 1, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 16 }}>
          <div>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, background: 'rgba(255,255,255,0.15)', borderRadius: 20, padding: '4px 12px', marginBottom: 12 }}>
              <Zap size={12} color="#FCD34D" />
              <span style={{ fontSize: 11, fontWeight: 700, color: '#FCD34D', letterSpacing: '0.05em' }}>ADMIN PANEL AKTIF</span>
            </div>
            <h1 style={{ fontSize: 28, fontWeight: 800, color: '#fff', marginBottom: 6 }}>Selamat Datang, Admin! 👋</h1>
            <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.7)' }}>
              {format(new Date(), "EEEE, d MMMM yyyy", { locale: idLocale })} • Sistem Informasi PKL SMKN 1 Garut
            </p>
          </div>
          <div style={{ display: 'flex', gap: 10 }}>
            {[
              { label: 'HADIR', value: todayAttendance?.hadir || 0, color: '#A7F3D0' },
              { label: 'BELUM', value: absentCount, color: '#FCA5A5' },
              { label: 'TERLAMBAT', value: todayAttendance?.terlambat || 0, color: '#FCD34D' },
            ].map((item, i) => (
              <div key={i} onClick={() => navigate('/attendance')} style={{ background: 'rgba(255,255,255,0.12)', border: '1px solid rgba(255,255,255,0.2)', borderRadius: 12, padding: '10px 18px', textAlign: 'center', cursor: 'pointer' }}>
                <p style={{ fontSize: 24, fontWeight: 800, color: item.color }}>{item.value}</p>
                <p style={{ fontSize: 9, color: 'rgba(255,255,255,0.6)', fontWeight: 700, letterSpacing: '0.08em' }}>{item.label}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* STAT CARDS */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 14, marginBottom: 20 }}>
        {statCards.map((s, i) => (
          <div key={i} onClick={() => navigate(s.href)}
            style={{ background: 'var(--card)', borderRadius: 14, padding: '18px 20px', display: 'flex', alignItems: 'center', gap: 14, boxShadow: '0 2px 8px rgba(0,0,0,0.05)', border: '1px solid var(--border)', cursor: 'pointer', transition: 'all 0.2s' }}
            onMouseOver={e => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 8px 24px rgba(13,71,161,0.1)'; }}
            onMouseOut={e => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = '0 2px 8px rgba(0,0,0,0.05)'; }}
          >
            <div style={{ width: 48, height: 48, borderRadius: 12, background: s.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <s.icon size={22} color={s.color} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <p style={{ fontSize: 10, fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{s.label}</p>
              <p style={{ fontSize: 28, fontWeight: 800, color: s.color, lineHeight: 1.1 }}>{s.value}</p>
              <p style={{ fontSize: 10, color: 'var(--muted-foreground)' }}>{s.sub}</p>
            </div>
            <ArrowUpRight size={16} color={s.color} style={{ opacity: 0.5, flexShrink: 0 }} />
          </div>
        ))}
      </div>

      {/* KEHADIRAN DETAIL + PENGUMUMAN */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 320px', gap: 16, marginBottom: 16 }}>

        {/* Kehadiran breakdown */}
        <div style={{ background: 'var(--card)', borderRadius: 14, padding: '20px', border: '1px solid var(--border)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 18 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{ background: '#E3F2FD', padding: 8, borderRadius: 9 }}><Activity size={16} color="#1565C0" /></div>
              <span style={{ fontSize: 14, fontWeight: 800, color: '#1565C0' }}>Kehadiran Hari Ini</span>
            </div>
            <button onClick={() => navigate('/attendance')} style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 3, fontSize: 12, color: '#1976D2', fontWeight: 600 }}>
              Kelola <ChevronRight size={14} />
            </button>
          </div>
          <div style={{ marginBottom: 18 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
              <span style={{ fontSize: 11, color: 'var(--muted-foreground)', fontWeight: 600 }}>Tingkat Kehadiran</span>
              <span style={{ fontSize: 13, fontWeight: 800, color: '#1565C0' }}>{attendanceRate}%</span>
            </div>
            <div style={{ height: 8, background: '#E3F2FD', borderRadius: 99, overflow: 'hidden' }}>
              <div style={{ height: '100%', width: `${attendanceRate}%`, background: 'linear-gradient(90deg, #1565C0, #42A5F5)', borderRadius: 99, transition: 'width 1s ease' }} />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10 }}>
            {[
              { label: 'Hadir', value: todayAttendance?.hadir || 0, color: '#2E7D32', bg: '#E8F5E9' },
              { label: 'Terlambat', value: todayAttendance?.terlambat || 0, color: '#E65100', bg: '#FFF3E0' },
              { label: 'Izin', value: todayAttendance?.izin || 0, color: '#1565C0', bg: '#E3F2FD' },
              { label: 'Sakit', value: todayAttendance?.sakit || 0, color: '#6A1B9A', bg: '#F3E5F5' },
            ].map((item, i) => (
              <div key={i} style={{ background: item.bg, borderRadius: 10, padding: '14px', textAlign: 'center' }}>
                <p style={{ fontSize: 26, fontWeight: 800, color: item.color }}>{item.value}</p>
                <p style={{ fontSize: 10, fontWeight: 700, color: item.color, opacity: 0.8 }}>{item.label}</p>
              </div>
            ))}
          </div>
          <div style={{ marginTop: 12, background: '#FFEBEE', borderRadius: 10, padding: '12px 16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <AlertCircle size={16} color="#C62828" />
              <span style={{ fontSize: 12, fontWeight: 700, color: '#C62828' }}>Belum Absen Hari Ini</span>
            </div>
            <span style={{ fontSize: 22, fontWeight: 800, color: '#C62828' }}>{absentCount}</span>
          </div>
        </div>

        {/* Announcements */}
        <div style={{ background: 'var(--card)', borderRadius: 14, padding: '18px', border: '1px solid var(--border)', display: 'flex', flexDirection: 'column' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
              <div style={{ background: '#FEF3C7', padding: 7, borderRadius: 8 }}><Bell size={15} color="#D97706" /></div>
              <span style={{ fontSize: 13, fontWeight: 800, color: '#1565C0' }}>Pengumuman</span>
            </div>
            <button onClick={() => navigate('/announcements')} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 11, color: '#1976D2', fontWeight: 600 }}>+ Buat</button>
          </div>
          {announcements.length === 0 ? (
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--muted-foreground)', fontSize: 12 }}>Tidak ada pengumuman</div>
          ) : announcements.map((a: any) => (
            <div key={a.id} style={{ background: '#FFFBEB', borderLeft: '3px solid #F59E0B', borderRadius: '0 8px 8px 0', padding: '10px 12px', marginBottom: 8, cursor: 'pointer' }}
              onClick={() => navigate(`/announcements/${a.id}`)}>
              <p style={{ fontSize: 12.5, fontWeight: 700, color: '#92400E', marginBottom: 2 }}>{a.title}</p>
              <p style={{ fontSize: 11, color: '#78716C', overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' as any }}>{a.content}</p>
            </div>
          ))}
        </div>
      </div>

      {/* ABSENSI TERBARU */}
      <div style={{ background: 'var(--card)', borderRadius: 14, padding: '18px', border: '1px solid var(--border)', marginBottom: 16 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ background: '#E3F2FD', padding: 8, borderRadius: 9 }}><Clock size={16} color="#1565C0" /></div>
            <span style={{ fontSize: 14, fontWeight: 800, color: '#1565C0' }}>Absensi Masuk Hari Ini</span>
          </div>
          <button onClick={() => navigate('/attendance')} style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 3, fontSize: 12, color: '#1976D2', fontWeight: 600 }}>
            Lihat Semua <ChevronRight size={14} />
          </button>
        </div>
        {recentLogs.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '24px 0', color: 'var(--muted-foreground)', fontSize: 12 }}>Belum ada absensi hari ini</div>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))', gap: 10 }}>
            {recentLogs.map((log: any) => {
              const st = getStatusStyle(log.status);
              return (
                <div key={log.id} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px', background: 'var(--background)', borderRadius: 10, border: '1px solid var(--border)' }}>
                  <div style={{ width: 36, height: 36, background: st.bg, borderRadius: 9, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    {log.status === 'Hadir' ? <CheckCircle2 size={16} color={st.color} /> : <AlertCircle size={16} color={st.color} />}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <p style={{ fontSize: 12.5, fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{(log.profiles as any)?.full_name || 'Unknown'}</p>
                    <p style={{ fontSize: 10, color: 'var(--muted-foreground)' }}>{(log.profiles as any)?.class_name || '-'} • {formatTime(log.check_in_time)}</p>
                  </div>
                  <span style={{ background: st.bg, color: st.color, padding: '3px 8px', borderRadius: 20, fontSize: 9, fontWeight: 700, whiteSpace: 'nowrap' }}>{log.status}</span>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* QUICK ACTIONS */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
        {[
          { label: 'Manajemen Siswa', icon: Users, color: '#1565C0', bg: '#E3F2FD', href: '/students' },
          { label: 'Input Absensi', icon: CheckCircle2, color: '#2E7D32', bg: '#E8F5E9', href: '/attendance' },
          { label: 'Approval Jurnal', icon: BookOpen, color: '#E65100', bg: '#FFF3E0', href: '/journals', badge: pendingJournals },
          { label: 'Buat Pengumuman', icon: Bell, color: '#6A1B9A', bg: '#F3E5F5', href: '/announcements' },
        ].map((item, i) => (
          <div key={i} onClick={() => navigate(item.href)}
            style={{ background: 'var(--card)', borderRadius: 12, padding: '16px', border: '1px solid var(--border)', cursor: 'pointer', transition: 'all 0.2s', position: 'relative' }}
            onMouseOver={e => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 6px 20px rgba(13,71,161,0.1)'; }}
            onMouseOut={e => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = 'none'; }}
          >
            {(item as any).badge > 0 && (
              <div style={{ position: 'absolute', top: 10, right: 10, background: '#EF4444', color: '#fff', borderRadius: 99, padding: '2px 7px', fontSize: 10, fontWeight: 800 }}>{(item as any).badge}</div>
            )}
            <div style={{ width: 40, height: 40, borderRadius: 10, background: item.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 10 }}>
              <item.icon size={20} color={item.color} />
            </div>
            <p style={{ fontSize: 12.5, fontWeight: 700 }}>{item.label}</p>
          </div>
        ))}
      </div>

      <footer style={{ textAlign: 'center', paddingTop: 24, paddingBottom: 4 }}>
        <p style={{ fontSize: 10, fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.4em' }}>© 2026 E-PKL | SMKN 1 GARUT</p>
      </footer>
    </div>
  );
}