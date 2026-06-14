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
  const [typedText, setTypedText] = useState('');
  const navigate = useNavigate();
  const today = format(new Date(), 'yyyy-MM-dd');

  const fullText = 'Selamat Datang, Admin!';

  useEffect(() => {
    setIsLoaded(true);
    let i = 0;
    const interval = setInterval(() => {
      setTypedText(fullText.slice(0, i + 1));
      i++;
      if (i >= fullText.length) clearInterval(interval);
    }, 50);
    return () => clearInterval(interval);
  }, []);

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
    if (status === 'Hadir') return { bg: 'rgba(16,185,129,0.15)', color: '#10B981', border: 'rgba(16,185,129,0.3)' };
    if (status === 'Terlambat') return { bg: 'rgba(245,158,11,0.15)', color: '#F59E0B', border: 'rgba(245,158,11,0.3)' };
    if (status === 'Izin') return { bg: 'rgba(37,99,235,0.15)', color: '#2563EB', border: 'rgba(37,99,235,0.3)' };
    if (status === 'Sakit') return { bg: 'rgba(168,85,247,0.15)', color: '#A855F7', border: 'rgba(168,85,247,0.3)' };
    return { bg: 'rgba(239,68,68,0.15)', color: '#EF4444', border: 'rgba(239,68,68,0.3)' };
  };

  const formatTime = (t?: string) => t ? new Date(t).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-';

  const statCards = [
    { label: 'TOTAL SISWA', value: totalStudents, icon: Users, accent: '#2563EB', bar: '#2563EB', sub: '100% dari total', href: '/students', pct: 100 },
    { label: 'TOTAL DUDI', value: totalCompanies, icon: Building2, accent: '#06B6D4', bar: '#06B6D4', sub: 'Mitra industri', href: '/companies', pct: 80 },
    { label: 'HADIR HARI INI', value: todayAttendance?.hadir || 0, icon: CheckCircle2, accent: '#10B981', bar: '#10B981', sub: `${attendanceRate}% dari total`, href: '/attendance', pct: attendanceRate },
    { label: 'JURNAL PENDING', value: pendingJournals, icon: FileText, accent: pendingJournals > 0 ? '#F59E0B' : '#10B981', bar: pendingJournals > 0 ? '#F59E0B' : '#10B981', sub: 'Menunggu approval', href: '/journals', pct: pendingJournals > 0 ? 60 : 0 },
  ];

  const styles = `
    .epkl-dash {
      min-height: 100vh;
      background: var(--background);
      padding: 24px;
      font-family: inherit;
      opacity: 0;
      transition: opacity 0.5s ease;
      color: var(--foreground);
    }
    .epkl-dash.loaded { opacity: 1; }

    /* ── HERO WRAPPER (di luar banner) ── */
    .dash-hero-wrapper {
      margin-bottom: 20px;
    }

    /* garis aksen + judul di atas banner */
    .dash-hero-header {
      margin-bottom: 12px;
    }
    .dash-hero-accent-bars {
      display: flex; gap: 4px; margin-bottom: 8px;
    }
    .dash-hero-accent-bar1 {
      height: 4px; width: 32px; border-radius: 99px; background: #2563EB;
    }
    .dash-hero-accent-bar2 {
      height: 4px; width: 16px; border-radius: 99px; background: #93C5FD;
    }
    .dash-hero-title {
      font-size: 40px; font-weight: 900; font-style: italic;
      text-transform: uppercase; letter-spacing: -0.03em;
      color: #0F172A; margin-bottom: 2px; min-height: 48px; line-height: 1;
    }
    .dark .dash-hero-title { color: #F8FAFC; }
    .dash-hero-title em { color: #2563EB; font-style: italic; }
    .dash-hero-cursor {
      border-right: 2px solid #0F172A; margin-left: 2px;
      animation: blink 0.7s step-end infinite;
    }
    .dark .dash-hero-cursor { border-right-color: #F8FAFC; }
    @keyframes blink { 50% { opacity: 0; } }

    /* banner biru */
    .dash-hero-banner {
      background: linear-gradient(135deg, #1D4ED8 0%, #2563EB 50%, #0EA5E9 100%);
      border-radius: 20px;
      padding: 20px 28px;
      position: relative;
      overflow: hidden;
      box-shadow: 0 8px 40px rgba(13,71,161,0.35);
      display: flex; align-items: center;
      justify-content: space-between; flex-wrap: wrap; gap: 16px;
    }
    .dash-hero-banner::before {
      content: '';
      position: absolute; inset: 0;
      background-image: radial-gradient(rgba(255,255,255,0.06) 1px, transparent 1px);
      background-size: 22px 22px;
    }
    .dash-hero-banner-circle1 {
      position: absolute; top: -50px; right: 80px;
      width: 200px; height: 200px;
      background: rgba(255,255,255,0.06); border-radius: 50%;
    }
    .dash-hero-banner-circle2 {
      position: absolute; bottom: -40px; right: -20px;
      width: 160px; height: 160px;
      background: rgba(6,182,212,0.12); border-radius: 50%;
    }
    .dash-hero-banner-inner {
      position: relative; z-index: 1;
      display: flex; align-items: center;
      justify-content: space-between; flex-wrap: wrap;
      gap: 16px; width: 100%;
    }
    .dash-hero-banner-badge {
      display: inline-flex; align-items: center; gap: 6px;
      background: rgba(255,255,255,0.15);
      border: 1px solid rgba(255,255,255,0.2);
      border-radius: 20px; padding: 4px 12px; margin-bottom: 6px;
    }
    .dash-hero-banner-sub {
      font-size: 12px; color: rgba(255,255,255,0.7); font-weight: 500; margin-top: 2px;
    }

    .dash-hero-pills {
      display: flex; gap: 10px; align-items: center;
    }
    .dash-hero-pill {
      background: rgba(255,255,255,0.12);
      border: 1px solid rgba(255,255,255,0.2);
      border-radius: 14px; padding: 10px 18px;
      text-align: center; cursor: pointer;
      transition: all 0.2s ease; min-width: 76px;
    }
    .dash-hero-pill:hover {
      background: rgba(255,255,255,0.22);
      transform: translateY(-3px);
    }
    .dash-hero-pill-val { font-size: 24px; font-weight: 900; line-height: 1; font-style: italic; }
    .dash-hero-pill-lbl {
      font-size: 9px; font-weight: 700;
      letter-spacing: 0.08em; color: rgba(255,255,255,0.6);
      margin-top: 4px;
    }

    /* ── STAT CARDS ── */
    .dash-stat-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 14px; margin-bottom: 18px;
    }
    .dash-stat-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px; padding: 20px;
      cursor: pointer; position: relative; overflow: hidden;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .dark .dash-stat-card {
      background: #1E293B;
      border-color: rgba(255,255,255,0.08);
    }
    .dash-stat-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 16px 40px rgba(13,71,161,0.18);
    }
    .dash-stat-card-top {
      display: flex; align-items: flex-start;
      justify-content: space-between; margin-bottom: 14px;
    }
    .dash-stat-icon {
      width: 44px; height: 44px; border-radius: 12px;
      display: flex; align-items: center; justify-content: center;
    }
    .dash-stat-val {
      font-size: 36px; font-weight: 900; font-style: normal;
      letter-spacing: -0.03em; line-height: 1; margin-bottom: 2px;
    }
    .dash-stat-lbl {
      font-size: 10px; font-weight: 900;
      letter-spacing: 0.1em; text-transform: uppercase;
      color: var(--muted-foreground); margin-bottom: 10px;
    }
    .dash-stat-sub { font-size: 10px; color: var(--muted-foreground); margin-top: 4px; }
    .dash-stat-bar-track {
      height: 4px; border-radius: 99px; margin-top: 10px; overflow: hidden;
    }
    .dash-stat-bar-fill {
      height: 100%; border-radius: 99px;
      transition: width 1.2s cubic-bezier(0.4,0,0.2,1);
    }

    /* ── MID ROW ── */
    .dash-mid-grid {
      display: grid;
      grid-template-columns: 1fr 300px;
      gap: 14px; margin-bottom: 14px;
    }

    /* ── SHARED CARD ── */
    .dash-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px; padding: 20px;
    }
    .dark .dash-card {
      background: #1E293B;
      border-color: rgba(255,255,255,0.08);
    }
    .dash-card-header {
      display: flex; align-items: center;
      justify-content: space-between; margin-bottom: 16px;
    }
    .dash-card-title {
      display: flex; align-items: center; gap: 8px;
    }
    .dash-card-icon {
      width: 34px; height: 34px; border-radius: 9px;
      display: flex; align-items: center; justify-content: center;
    }
    .dash-card-label {
      font-size: 13px; font-weight: 800; font-style: italic;
      letter-spacing: -0.2px;
    }
    .dash-link-btn {
      background: none; border: none; cursor: pointer;
      display: flex; align-items: center; gap: 3px;
      font-size: 11px; font-weight: 700;
      font-family: inherit;
    }

    /* kehadiran breakdown boxes */
    .dash-attend-grid {
      display: grid; grid-template-columns: repeat(4,1fr); gap: 10px;
    }
    .dash-attend-box {
      border-radius: 12px; padding: 16px; text-align: center;
      border: 1px solid transparent;
    }
    .dash-attend-val {
      font-size: 30px; font-weight: 800; font-style: italic;
      line-height: 1; margin-bottom: 4px;
    }
    .dash-attend-lbl {
      font-size: 10px; font-weight: 700; letter-spacing: 0.04em;
    }

    /* absent alert */
    .dash-absent-alert {
      margin-top: 12px; border-radius: 12px; padding: 12px 16px;
      display: flex; align-items: center; justify-content: space-between;
      border: 1px solid rgba(239,68,68,0.3);
      background: rgba(239,68,68,0.1);
    }
    .dark .dash-absent-alert { background: rgba(239,68,68,0.12); }

    /* announcement card */
    .dash-ann-item {
      border-left: 3px solid #F59E0B;
      border-radius: 0 10px 10px 0;
      padding: 10px 12px; margin-bottom: 8px;
      cursor: pointer; transition: transform 0.15s ease;
      background: rgba(245,158,11,0.08);
      border-top: 1px solid rgba(245,158,11,0.15);
      border-right: 1px solid rgba(245,158,11,0.15);
      border-bottom: 1px solid rgba(245,158,11,0.15);
    }
    .dark .dash-ann-item { background: rgba(245,158,11,0.07); }
    .dash-ann-item:hover { transform: translateX(4px); }

    /* recent logs grid */
    .dash-logs-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
      gap: 10px;
    }
    .dash-log-item {
      display: flex; align-items: center; gap: 10px;
      padding: 10px 12px; border-radius: 12px;
      border: 1px solid var(--border);
      background: var(--background);
      transition: all 0.15s ease; cursor: default;
    }
    .dark .dash-log-item {
      background: rgba(15,23,42,0.6);
      border-color: rgba(255,255,255,0.07);
    }
    .dash-log-item:hover {
      transform: translateX(3px);
      border-color: rgba(37,99,235,0.3);
    }

    /* quick actions */
    .dash-qa-grid {
      display: grid; grid-template-columns: repeat(4,1fr); gap: 12px;
    }
    .dash-qa-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px; padding: 20px;
      cursor: pointer; position: relative; overflow: hidden;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .dark .dash-qa-card {
      background: #1E293B;
      border-color: rgba(255,255,255,0.08);
    }
    .dash-qa-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 14px 36px rgba(13,71,161,0.18);
    }
    .dash-qa-icon {
      width: 42px; height: 42px; border-radius: 12px;
      display: flex; align-items: center; justify-content: center;
      margin-bottom: 12px;
    }
    .dash-qa-label { font-size: 12.5px; font-weight: 700; color: var(--foreground); }
    .dash-qa-bottom-bar {
      position: absolute; bottom: 0; left: 0; right: 0; height: 3px;
    }
    .dash-badge {
      position: absolute; top: 10px; right: 10px;
      background: #EF4444; color: #fff;
      border-radius: 99px; padding: 2px 8px;
      font-size: 10px; font-weight: 800;
    }

    /* progress bar */
    .dash-progress-track {
      height: 6px; border-radius: 99px; overflow: hidden;
      background: rgba(37,99,235,0.15); margin-bottom: 16px;
    }
    .dark .dash-progress-track { background: rgba(37,99,235,0.1); }
    .dash-progress-fill {
      height: 100%; border-radius: 99px;
      background: linear-gradient(90deg, #2563EB, #0EA5E9);
      box-shadow: 0 0 10px rgba(37,99,235,0.5);
      transition: width 1.2s cubic-bezier(0.4,0,0.2,1);
    }

    /* footer */
    .dash-footer { text-align: center; padding-top: 24px; padding-bottom: 4px; }
    .dash-footer p {
      font-size: 10px; font-weight: 700; text-transform: uppercase;
      letter-spacing: 0.4em; color: var(--muted-foreground);
    }

    /* ── LIGHT MODE ── */
    :root:not(.dark) .dash-stat-card,
    :root:not(.dark) .dash-card,
    :root:not(.dark) .dash-qa-card {
      background: #FFFFFF;
      border-color: #E2E8F0;
      box-shadow: 0 2px 12px rgba(0,0,0,0.06);
    }
    :root:not(.dark) .dash-log-item { background: #F8FAFF; border-color: #E2E8F0; }
    :root:not(.dark) .dash-stat-lbl   { color: #475569; }
    :root:not(.dark) .dash-stat-sub   { color: #64748B; }
    :root:not(.dark) .dash-stat-val   { color: inherit; }
    :root:not(.dark) .dash-qa-label   { color: #0F172A; }
    :root:not(.dark) .dash-attend-val { color: inherit; }
    :root:not(.dark) .dash-attend-lbl { color: inherit; }
    :root:not(.dark) .dash-card-label { color: #2563EB; }
    :root:not(.dark) .dash-link-btn   { color: #2563EB; }
    :root:not(.dark) .dash-footer p   { color: #94A3B8; }

    /* ── DARK MODE ── */
    .dark .dash-stat-lbl   { color: #94A3B8; }
    .dark .dash-stat-sub   { color: #64748B; }
    .dark .dash-qa-label   { color: #F1F5F9; }
    .dark .dash-card-label { color: #60A5FA; }
    .dark .dash-link-btn   { color: #60A5FA; }
  `;

  return (
    <>
      <style>{styles}</style>
      <div className={`epkl-dash${isLoaded ? ' loaded' : ''}`}>

        {/* HERO: judul di atas + banner biru di bawah */}
        <div className="dash-hero-wrapper">

          {/* Judul gaya manajemen siswa */}
          <div className="dash-hero-header">
            <div className="dash-hero-accent-bars">
              <div className="dash-hero-accent-bar1" />
              <div className="dash-hero-accent-bar2" />
            </div>
            <h1 className="dash-hero-title">
              {typedText.split('Admin!')[0]}
              {typedText.includes('Admin') && <em>Admin!</em>}
              {typedText.length < fullText.length && <span className="dash-hero-cursor"> </span>}
              {typedText === fullText && ' '}
            </h1>
          </div>

          {/* Banner biru */}
          <div className="dash-hero-banner">
            <div className="dash-hero-banner-circle1" />
            <div className="dash-hero-banner-circle2" />
            <div className="dash-hero-banner-inner">
              <div>
                <div className="dash-hero-banner-badge">
                  <Zap size={11} color="#FCD34D" />
                  <span style={{ fontSize: 10, fontWeight: 700, color: '#FCD34D', letterSpacing: '0.07em' }}>ADMIN PANEL AKTIF</span>
                </div>
                <p className="dash-hero-banner-sub">
                  {format(new Date(), "EEEE, d MMMM yyyy", { locale: idLocale })} • Sistem Informasi PKL SMKN 1 Garut
                </p>
              </div>
              <div className="dash-hero-pills">
                {[
                  { label: 'HADIR', value: todayAttendance?.hadir || 0, color: '#6EE7B7' },
                  { label: 'BELUM', value: absentCount, color: '#FCA5A5' },
                  { label: 'TERLAMBAT', value: todayAttendance?.terlambat || 0, color: '#FCD34D' },
                ].map((item, i) => (
                  <div key={i} className="dash-hero-pill" onClick={() => navigate('/attendance')}>
                    <p className="dash-hero-pill-val" style={{ color: item.color }}>{item.value}</p>
                    <p className="dash-hero-pill-lbl">{item.label}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* STAT CARDS */}
        <div className="dash-stat-grid">
          {statCards.map((s, i) => (
            <div key={i} className="dash-stat-card" onClick={() => navigate(s.href)}>
              <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: `linear-gradient(90deg, ${s.accent}, transparent)`, borderRadius: '16px 16px 0 0' }} />
              <div className="dash-stat-card-top">
                <div>
                  <p className="dash-stat-lbl">{s.label}</p>
                  <p className="dash-stat-val" style={{ color: s.accent }}>{s.value}</p>
                </div>
                <div className="dash-stat-icon" style={{ background: `${s.accent}1A` }}>
                  <s.icon size={20} color={s.accent} />
                </div>
              </div>
              <div className="dash-stat-bar-track" style={{ background: `${s.accent}1A` }}>
                <div className="dash-stat-bar-fill" style={{ width: `${s.pct}%`, background: s.bar }} />
              </div>
              <p className="dash-stat-sub">{s.sub}</p>
            </div>
          ))}
        </div>

        {/* KEHADIRAN + PENGUMUMAN */}
        <div className="dash-mid-grid">
          <div className="dash-card">
            <div className="dash-card-header">
              <div className="dash-card-title">
                <div className="dash-card-icon" style={{ background: 'rgba(37,99,235,0.12)' }}>
                  <Activity size={16} color="#2563EB" />
                </div>
                <span className="dash-card-label" style={{ color: '#2563EB' }}>Kehadiran Hari Ini</span>
              </div>
              <button className="dash-link-btn" style={{ color: '#2563EB' }} onClick={() => navigate('/attendance')}>
                Kelola <ChevronRight size={13} />
              </button>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
              <span style={{ fontSize: 11, color: 'var(--muted-foreground)', fontWeight: 600 }}>Tingkat Kehadiran</span>
              <span style={{ fontSize: 13, fontWeight: 800, color: '#2563EB' }}>{attendanceRate}%</span>
            </div>
            <div className="dash-progress-track">
              <div className="dash-progress-fill" style={{ width: `${attendanceRate}%` }} />
            </div>
            <div className="dash-attend-grid">
              {[
                { label: 'Hadir', value: todayAttendance?.hadir || 0, color: '#10B981', bg: 'rgba(16,185,129,0.1)', border: 'rgba(16,185,129,0.25)' },
                { label: 'Terlambat', value: todayAttendance?.terlambat || 0, color: '#F59E0B', bg: 'rgba(245,158,11,0.1)', border: 'rgba(245,158,11,0.25)' },
                { label: 'Izin', value: todayAttendance?.izin || 0, color: '#2563EB', bg: 'rgba(37,99,235,0.1)', border: 'rgba(37,99,235,0.25)' },
                { label: 'Sakit', value: todayAttendance?.sakit || 0, color: '#A855F7', bg: 'rgba(168,85,247,0.1)', border: 'rgba(168,85,247,0.25)' },
              ].map((item, i) => (
                <div key={i} className="dash-attend-box" style={{ background: item.bg, borderColor: item.border }}>
                  <p className="dash-attend-val" style={{ color: item.color }}>{item.value}</p>
                  <p className="dash-attend-lbl" style={{ color: item.color }}>{item.label}</p>
                </div>
              ))}
            </div>
            <div className="dash-absent-alert">
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <AlertCircle size={15} color="#EF4444" />
                <span style={{ fontSize: 12, fontWeight: 700, color: '#EF4444' }}>Belum Absen Hari Ini</span>
              </div>
              <span style={{ fontSize: 24, fontWeight: 800, fontStyle: 'italic', color: '#EF4444' }}>{absentCount}</span>
            </div>
          </div>

          <div className="dash-card" style={{ display: 'flex', flexDirection: 'column' }}>
            <div className="dash-card-header">
              <div className="dash-card-title">
                <div className="dash-card-icon" style={{ background: 'rgba(245,158,11,0.12)' }}>
                  <Bell size={15} color="#F59E0B" />
                </div>
                <span className="dash-card-label" style={{ color: '#F59E0B' }}>Pengumuman</span>
              </div>
              <button className="dash-link-btn" style={{ color: '#F59E0B' }} onClick={() => navigate('/announcements')}>
                + Buat
              </button>
            </div>
            {announcements.length === 0 ? (
              <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--muted-foreground)', fontSize: 12 }}>Tidak ada pengumuman</div>
            ) : announcements.map((a: any) => (
              <div key={a.id} className="dash-ann-item" onClick={() => navigate(`/announcements/${a.id}`)}>
                <p style={{ fontSize: 12.5, fontWeight: 700, color: '#F59E0B', marginBottom: 3 }}>{a.title}</p>
                <p style={{ fontSize: 11, color: 'var(--muted-foreground)', overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' as any }}>{a.content}</p>
              </div>
            ))}
          </div>
        </div>

        {/* ABSENSI TERBARU */}
        <div className="dash-card" style={{ marginBottom: 14 }}>
          <div className="dash-card-header">
            <div className="dash-card-title">
              <div className="dash-card-icon" style={{ background: 'rgba(6,182,212,0.12)' }}>
                <Clock size={16} color="#06B6D4" />
              </div>
              <span className="dash-card-label" style={{ color: '#06B6D4' }}>Absensi Masuk Hari Ini</span>
            </div>
            <button className="dash-link-btn" style={{ color: '#06B6D4' }} onClick={() => navigate('/attendance')}>
              Lihat Semua <ChevronRight size={13} />
            </button>
          </div>
          {recentLogs.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '24px 0', color: 'var(--muted-foreground)', fontSize: 12 }}>Belum ada absensi hari ini</div>
          ) : (
            <div className="dash-logs-grid">
              {recentLogs.map((log: any) => {
                const st = getStatusStyle(log.status);
                return (
                  <div key={log.id} className="dash-log-item">
                    <div style={{ width: 36, height: 36, background: st.bg, border: `1px solid ${st.border}`, borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      {log.status === 'Hadir' ? <CheckCircle2 size={15} color={st.color} /> : <AlertCircle size={15} color={st.color} />}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <p style={{ fontSize: 12.5, fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: 'var(--foreground)' }}>
                        {(log.profiles as any)?.full_name || 'Unknown'}
                      </p>
                      <p style={{ fontSize: 10, color: 'var(--muted-foreground)' }}>
                        {(log.profiles as any)?.class_name || '-'} • {formatTime(log.check_in_time)}
                      </p>
                    </div>
                    <span style={{ background: st.bg, color: st.color, border: `1px solid ${st.border}`, padding: '3px 8px', borderRadius: 20, fontSize: 9, fontWeight: 700, whiteSpace: 'nowrap' }}>
                      {log.status}
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* QUICK ACTIONS */}
        <div className="dash-qa-grid">
          {[
            { label: 'Manajemen Siswa', icon: Users, accent: '#2563EB', href: '/students' },
            { label: 'Input Absensi', icon: CheckCircle2, accent: '#10B981', href: '/attendance' },
            { label: 'Approval Jurnal', icon: BookOpen, accent: '#F59E0B', href: '/journals', badge: pendingJournals },
            { label: 'Buat Pengumuman', icon: Bell, accent: '#A855F7', href: '/announcements' },
          ].map((item, i) => (
            <div key={i} className="dash-qa-card" onClick={() => navigate(item.href)}>
              <div className="dash-qa-bottom-bar" style={{ background: `${item.accent}25` }} />
              {(item as any).badge > 0 && (
                <div className="dash-badge">{(item as any).badge}</div>
              )}
              <div className="dash-qa-icon" style={{ background: `${item.accent}18` }}>
                <item.icon size={20} color={item.accent} />
              </div>
              <p className="dash-qa-label">{item.label}</p>
              <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 4 }}>
                <span style={{ fontSize: 11, color: item.accent, fontWeight: 700 }}>Buka</span>
                <ArrowUpRight size={12} color={item.accent} />
              </div>
            </div>
          ))}
        </div>

        <div className="dash-footer">
          <p>© 2026 E-PKL | SMKN 1 Garut</p>
        </div>
      </div>
    </>
  );
}