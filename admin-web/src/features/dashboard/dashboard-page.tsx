import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAuthContext } from '@/contexts/auth-context';
import {
  Bell, Building2, Calendar, Clock, ClipboardCheck,
  GraduationCap, MapPin, Plus, Search, Settings,
  TrendingUp, BookOpen, CheckCircle2, AlertCircle,
  Phone, Edit2, Save, X, ChevronRight, Zap,
} from 'lucide-react';

export default function DashboardPage() {
  const [isLoaded, setIsLoaded] = useState(false);
  const [editingPhone, setEditingPhone] = useState(false);
  const [phoneInput, setPhoneInput] = useState('');
  const navigate = useNavigate();
  const { user } = useAuthContext();
  const queryClient = useQueryClient();

  useEffect(() => { setIsLoaded(true); }, []);

  // ── Fetch student profile + placement ──────────────────────────────────────
  const { data: profile } = useQuery({
    queryKey: ['dashboard-profile', user?.id],
    queryFn: async () => {
      if (!user?.id) return null;
      const { data } = await supabase
        .from('profiles')
        .select('*, placements(*, companies(id, name, address, phone, latitude, longitude))')
        .eq('id', user.id)
        .single();
      return data;
    },
    enabled: !!user?.id,
  });

  const company = profile?.placements?.[0]?.companies;
  const mentorPhone = company?.phone || '';

  // ── Fetch attendance stats ──────────────────────────────────────────────────
  const { data: attendanceStats } = useQuery({
    queryKey: ['dashboard-attendance', user?.id],
    queryFn: async () => {
      if (!user?.id) return { present: 0, total: 0 };
      const { data } = await supabase
        .from('attendance_logs')
        .select('status')
        .eq('student_id', user.id);
      const present = data?.filter(d => d.status === 'Hadir' || d.status === 'Terlambat').length || 0;
      return { present, total: data?.length || 0 };
    },
    enabled: !!user?.id,
  });

  // ── Fetch journals count ────────────────────────────────────────────────────
  const { data: journalCount } = useQuery({
    queryKey: ['dashboard-journals', user?.id],
    queryFn: async () => {
      if (!user?.id) return 0;
      const { count } = await supabase
        .from('daily_journals')
        .select('*', { count: 'exact', head: true })
        .eq('student_id', user.id)
        .eq('is_approved', true);
      return count || 0;
    },
    enabled: !!user?.id,
  });

  // ── Fetch announcements ─────────────────────────────────────────────────────
  const { data: announcements = [] } = useQuery({
    queryKey: ['dashboard-announcements'],
    queryFn: async () => {
      const { data } = await supabase
        .from('announcements')
        .select('id, title, content, created_at')
        .order('created_at', { ascending: false })
        .limit(3);
      return data || [];
    },
  });

  // ── Fetch recent activities (attendance logs) ───────────────────────────────
  const { data: recentLogs = [] } = useQuery({
    queryKey: ['dashboard-recent', user?.id],
    queryFn: async () => {
      if (!user?.id) return [];
      const { data } = await supabase
        .from('attendance_logs')
        .select('id, status, check_in_time, check_out_time, created_at')
        .eq('student_id', user.id)
        .order('created_at', { ascending: false })
        .limit(4);
      return data || [];
    },
    enabled: !!user?.id,
  });

  // ── Update mentor phone ─────────────────────────────────────────────────────
  const updatePhone = useMutation({
    mutationFn: async (phone: string) => {
      if (!company?.id) return;
      const { error } = await supabase
        .from('companies')
        .update({ phone })
        .eq('id', company.id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dashboard-profile'] });
      setEditingPhone(false);
    },
  });

  const handleKontakMentor = () => {
    const phone = mentorPhone.replace(/\D/g, '');
    const msg = encodeURIComponent('Halo Mentor, saya ingin bertanya terkait kegiatan PKL saya.');
    window.open(`https://wa.me/${phone}?text=${msg}`, '_blank');
  };

  const getStatusStyle = (status: string) => {
    if (status === 'Hadir') return { bg: '#E8F5E9', color: '#2E7D32' };
    if (status === 'Terlambat') return { bg: '#FFF3E0', color: '#E65100' };
    if (status === 'Izin') return { bg: '#E3F2FD', color: '#1565C0' };
    return { bg: '#FFEBEE', color: '#C62828' };
  };

  const formatTime = (t?: string) => t ? new Date(t).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-';
  const formatDate = (t: string) => {
    const d = new Date(t);
    const now = new Date();
    const diff = Math.floor((now.getTime() - d.getTime()) / 86400000);
    if (diff === 0) return 'Hari ini';
    if (diff === 1) return 'Kemarin';
    return `${diff} hari lalu`;
  };

  const attendanceRate = attendanceStats?.total
    ? Math.round((attendanceStats.present / attendanceStats.total) * 100)
    : 0;

  return (
    <div style={{
      minHeight: '100vh',
      background: 'var(--background)',
      padding: '24px',
      fontFamily: "'Plus Jakarta Sans', sans-serif",
      opacity: isLoaded ? 1 : 0,
      transition: 'opacity 0.5s ease',
    }}>

      {/* ── HERO BANNER ── */}
      <div style={{
        background: 'linear-gradient(135deg, #0D47A1 0%, #1565C0 50%, #1E88E5 100%)',
        borderRadius: 20,
        padding: '28px 32px',
        marginBottom: 24,
        position: 'relative',
        overflow: 'hidden',
        boxShadow: '0 8px 32px rgba(13,71,161,0.3)',
      }}>
        {/* Decorative circles */}
        <div style={{ position: 'absolute', top: -60, right: 80, width: 200, height: 200, background: 'rgba(255,255,255,0.06)', borderRadius: '50%' }} />
        <div style={{ position: 'absolute', bottom: -40, right: -20, width: 150, height: 150, background: 'rgba(255,255,255,0.04)', borderRadius: '50%' }} />
        {/* Dot grid */}
        <div style={{ position: 'absolute', inset: 0, backgroundImage: 'radial-gradient(rgba(255,255,255,0.08) 1px, transparent 1px)', backgroundSize: '24px 24px' }} />

        <div style={{ position: 'relative', zIndex: 1, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 16 }}>
          <div>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, background: 'rgba(255,255,255,0.15)', borderRadius: 20, padding: '4px 12px', marginBottom: 10 }}>
              <Zap size={12} color="#FCD34D" />
              <span style={{ fontSize: 11, fontWeight: 700, color: '#FCD34D', letterSpacing: '0.05em' }}>SISTEM AKTIF</span>
            </div>
            <h1 style={{ fontSize: 26, fontWeight: 800, color: '#fff', marginBottom: 4 }}>
              Halo, {profile?.full_name?.split(' ')[0] || 'Siswa'}! 👋
            </h1>
            <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.7)' }}>Sistem Informasi PKL SMKN 1 Garut</p>
          </div>
          <div style={{ display: 'flex', gap: 10 }}>
            <div style={{ background: 'rgba(255,255,255,0.12)', border: '1px solid rgba(255,255,255,0.2)', borderRadius: 12, padding: '10px 16px', textAlign: 'center' }}>
              <p style={{ fontSize: 22, fontWeight: 800, color: '#fff' }}>{attendanceStats?.present || 0}/{attendanceStats?.total || 0}</p>
              <p style={{ fontSize: 10, color: 'rgba(255,255,255,0.6)', fontWeight: 600 }}>KEHADIRAN</p>
            </div>
            <div style={{ background: 'rgba(255,255,255,0.12)', border: '1px solid rgba(255,255,255,0.2)', borderRadius: 12, padding: '10px 16px', textAlign: 'center' }}>
              <p style={{ fontSize: 22, fontWeight: 800, color: '#fff' }}>{attendanceRate}%</p>
              <p style={{ fontSize: 10, color: 'rgba(255,255,255,0.6)', fontWeight: 600 }}>PERSENTASE</p>
            </div>
          </div>
        </div>
      </div>

      {/* ── STATS ROW ── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 14, marginBottom: 20 }}>
        {[
          { label: 'Total Kehadiran', value: `${attendanceStats?.present || 0}/${attendanceStats?.total || 0}`, icon: Clock, color: '#1565C0', bg: '#E3F2FD', sub: 'Hari masuk' },
          { label: 'Jurnal Disetujui', value: String(journalCount || 0), icon: BookOpen, color: '#2E7D32', bg: '#E8F5E9', sub: 'Entri jurnal' },
          { label: 'Tingkat Kehadiran', value: `${attendanceRate}%`, icon: TrendingUp, color: '#6A1B9A', bg: '#F3E5F5', sub: 'Dari total hari' },
        ].map((s, i) => (
          <div key={i} style={{
            background: 'var(--card)', borderRadius: 14, padding: '18px 20px',
            display: 'flex', alignItems: 'center', gap: 14,
            boxShadow: '0 2px 8px rgba(0,0,0,0.05)', border: '1px solid var(--border)',
          }}>
            <div style={{ width: 48, height: 48, borderRadius: 12, background: s.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <s.icon size={22} color={s.color} />
            </div>
            <div>
              <p style={{ fontSize: 10, fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{s.label}</p>
              <p style={{ fontSize: 26, fontWeight: 800, color: s.color, lineHeight: 1.1 }}>{s.value}</p>
              <p style={{ fontSize: 10, color: 'var(--muted-foreground)' }}>{s.sub}</p>
            </div>
          </div>
        ))}
      </div>

      {/* ── MAIN GRID ── */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 320px', gap: 16, marginBottom: 16 }}>

        {/* DUDI CARD */}
        <div style={{
          background: 'linear-gradient(135deg, #0D47A1 0%, #1565C0 60%, #1E88E5 100%)',
          borderRadius: 16, padding: 26, position: 'relative', overflow: 'hidden',
          boxShadow: '0 4px 20px rgba(13,71,161,0.25)',
        }}>
          <div style={{ position: 'absolute', top: -30, right: -30, width: 160, height: 160, background: 'rgba(255,255,255,0.06)', borderRadius: '50%' }} />
          <div style={{ position: 'relative', zIndex: 1 }}>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, background: 'rgba(255,255,255,0.15)', border: '1px solid rgba(255,255,255,0.2)', borderRadius: 20, padding: '4px 12px', fontSize: 10.5, fontWeight: 700, color: '#fff', textTransform: 'uppercase', marginBottom: 14 }}>
              <Building2 size={12} /> Tempat PKL Aktif
            </div>
            <h2 style={{ fontSize: 22, fontWeight: 800, color: '#fff', marginBottom: 8 }}>
              {company?.name || 'Belum Ada Penempatan'}
            </h2>
            {company?.address && (
              <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.7)', display: 'flex', alignItems: 'center', gap: 5, marginBottom: 8 }}>
                <MapPin size={13} /> {company.address}
              </p>
            )}

            {/* Phone edit section */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 20 }}>
              <Phone size={13} color="rgba(255,255,255,0.6)" />
              {editingPhone ? (
                <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                  <input
                    value={phoneInput}
                    onChange={e => setPhoneInput(e.target.value)}
                    placeholder="62812xxxxxxx"
                    style={{ background: 'rgba(255,255,255,0.15)', border: '1px solid rgba(255,255,255,0.3)', borderRadius: 6, padding: '4px 10px', fontSize: 12, color: '#fff', outline: 'none', width: 160 }}
                  />
                  <button onClick={() => updatePhone.mutate(phoneInput)} style={{ background: '#fff', border: 'none', borderRadius: 6, padding: '4px 10px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, fontWeight: 700, color: '#1565C0' }}>
                    <Save size={12} /> Simpan
                  </button>
                  <button onClick={() => setEditingPhone(false)} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'rgba(255,255,255,0.6)' }}>
                    <X size={16} />
                  </button>
                </div>
              ) : (
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span style={{ fontSize: 12, color: 'rgba(255,255,255,0.7)' }}>
                    {mentorPhone || 'Nomor belum diset'}
                  </span>
                  <button onClick={() => { setPhoneInput(mentorPhone); setEditingPhone(true); }} style={{ background: 'rgba(255,255,255,0.15)', border: 'none', borderRadius: 5, padding: '3px 8px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4, fontSize: 10, color: '#fff' }}>
                    <Edit2 size={10} /> Edit
                  </button>
                </div>
              )}
            </div>

            <div style={{ display: 'flex', gap: 10 }}>
              <button
                onClick={() => company && navigate('/companies', { state: { searchName: company.name } })}
                style={{ background: '#fff', color: '#1565C0', border: 'none', borderRadius: 8, padding: '9px 16px', fontSize: 12.5, fontWeight: 700, cursor: 'pointer', transition: 'transform 0.2s' }}
                onMouseOver={e => e.currentTarget.style.transform = 'scale(1.03)'}
                onMouseOut={e => e.currentTarget.style.transform = 'scale(1)'}
              >Lihat Detail Kantor</button>
              {mentorPhone && (
                <button
                  onClick={handleKontakMentor}
                  style={{ background: 'transparent', color: '#fff', border: '2px solid rgba(255,255,255,0.35)', borderRadius: 8, padding: '9px 16px', fontSize: 12.5, fontWeight: 700, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}
                >
                  <Phone size={13} /> Kontak Mentor
                </button>
              )}
            </div>
          </div>
        </div>

        {/* ANNOUNCEMENTS */}
        <div style={{ background: 'var(--card)', borderRadius: 14, padding: '18px', border: '1px solid var(--border)', display: 'flex', flexDirection: 'column' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginBottom: 14 }}>
            <div style={{ background: '#FEF3C7', padding: 7, borderRadius: 8 }}>
              <Bell size={15} color="#D97706" />
            </div>
            <span style={{ fontSize: 13, fontWeight: 800, color: '#1565C0' }}>Pengumuman</span>
          </div>
          {announcements.length === 0 ? (
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--muted-foreground)', fontSize: 12 }}>
              Tidak ada pengumuman
            </div>
          ) : announcements.map((a: any) => (
            <div key={a.id} style={{ background: '#FFFBEB', borderLeft: '3px solid #F59E0B', borderRadius: '0 8px 8px 0', padding: '10px 12px', marginBottom: 8, cursor: 'pointer' }}
              onClick={() => navigate(`/announcements/${a.id}`)}>
              <p style={{ fontSize: 12.5, fontWeight: 700, color: '#92400E', marginBottom: 2 }}>{a.title}</p>
              <p style={{ fontSize: 11, color: '#78716C', overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' }}>{a.content}</p>
            </div>
          ))}
        </div>
      </div>

      {/* ── BOTTOM GRID ── */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 320px', gap: 16 }}>

        {/* RECENT ACTIVITY */}
        <div style={{ background: 'var(--card)', borderRadius: 14, padding: '18px', border: '1px solid var(--border)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
            <span style={{ fontSize: 13, fontWeight: 800, color: '#1565C0' }}>Aktivitas Terbaru</span>
            <button onClick={() => navigate('/history')} style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 3, fontSize: 12, color: '#1976D2', fontWeight: 600 }}>
              Lihat Semua <ChevronRight size={14} />
            </button>
          </div>
          {recentLogs.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '20px 0', color: 'var(--muted-foreground)', fontSize: 12 }}>Belum ada aktivitas</div>
          ) : recentLogs.map((log: any, i: number) => {
            const st = getStatusStyle(log.status);
            return (
              <div key={log.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: i < recentLogs.length - 1 ? '1px solid var(--border)' : 'none' }}>
                <div style={{ width: 36, height: 36, background: st.bg, borderRadius: 9, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  {log.status === 'Hadir' ? <CheckCircle2 size={16} color={st.color} /> : <AlertCircle size={16} color={st.color} />}
                </div>
                <div style={{ flex: 1 }}>
                  <p style={{ fontSize: 12.5, fontWeight: 600 }}>Absensi — {log.status}</p>
                  <p style={{ fontSize: 10.5, color: 'var(--muted-foreground)' }}>
                    {formatDate(log.created_at)} • Masuk: {formatTime(log.check_in_time)}
                    {log.check_out_time && ` • Pulang: ${formatTime(log.check_out_time)}`}
                  </p>
                </div>
                <span style={{ background: st.bg, color: st.color, padding: '3px 10px', borderRadius: 20, fontSize: 10, fontWeight: 700 }}>
                  {log.status.toUpperCase()}
                </span>
              </div>
            );
          })}
        </div>

        {/* ID CARD VIRTUAL */}
        <div style={{
          background: 'linear-gradient(145deg, #0A1628 0%, #0D47A1 50%, #1565C0 100%)',
          borderRadius: 16, padding: '22px', position: 'relative', overflow: 'hidden',
          boxShadow: '0 8px 32px rgba(13,71,161,0.35)',
        }}>
          {/* Card decorations */}
          <div style={{ position: 'absolute', top: -30, right: -30, width: 130, height: 130, background: 'rgba(255,255,255,0.04)', borderRadius: '50%' }} />
          <div style={{ position: 'absolute', bottom: -20, left: -20, width: 100, height: 100, background: 'rgba(255,255,255,0.03)', borderRadius: '50%' }} />
          <div style={{ position: 'absolute', inset: 0, backgroundImage: 'radial-gradient(rgba(255,255,255,0.04) 1px, transparent 1px)', backgroundSize: '18px 18px' }} />

          <div style={{ position: 'relative', zIndex: 1 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <div>
                <p style={{ fontSize: 9, fontWeight: 700, letterSpacing: '2px', color: 'rgba(255,255,255,0.4)', marginBottom: 2 }}>ID CARD VIRTUAL</p>
                <p style={{ fontSize: 13, fontWeight: 800, color: '#fff' }}>SISWA PKL</p>
              </div>
              <div style={{ background: 'rgba(255,255,255,0.1)', padding: 8, borderRadius: 10 }}>
                <GraduationCap size={20} color="#93C5FD" />
              </div>
            </div>

            {/* Avatar placeholder */}
            <div style={{ width: 56, height: 56, borderRadius: 14, background: 'rgba(255,255,255,0.1)', border: '2px solid rgba(255,255,255,0.15)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 14, fontSize: 22 }}>
              {profile?.full_name?.[0] || '?'}
            </div>

            <p style={{ fontSize: 15, fontWeight: 800, color: '#fff', marginBottom: 2 }}>
              {profile?.full_name || 'Nama Siswa'}
            </p>
            <p style={{ fontSize: 11, color: 'rgba(255,255,255,0.55)', marginBottom: 12 }}>
              {profile?.class_name || '-'}
            </p>

            <div style={{ height: 1, background: 'rgba(255,255,255,0.1)', marginBottom: 12 }} />

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
              <div>
                <p style={{ fontSize: 9, color: 'rgba(255,255,255,0.35)', fontWeight: 600, letterSpacing: '1px', marginBottom: 2 }}>NISN</p>
                <p style={{ fontSize: 13, fontWeight: 700, color: '#93C5FD', letterSpacing: '1px' }}>
                  {profile?.nisn || '—'}
                </p>
              </div>
              <div style={{ textAlign: 'right' }}>
                <p style={{ fontSize: 9, color: 'rgba(255,255,255,0.35)', fontWeight: 600, letterSpacing: '1px', marginBottom: 2 }}>SEKOLAH</p>
                <p style={{ fontSize: 10, fontWeight: 700, color: 'rgba(255,255,255,0.6)' }}>SMKN 1 GARUT</p>
              </div>
            </div>

            {company?.name && (
              <div style={{ marginTop: 12, background: 'rgba(255,255,255,0.07)', borderRadius: 8, padding: '8px 10px' }}>
                <p style={{ fontSize: 9, color: 'rgba(255,255,255,0.35)', fontWeight: 600, letterSpacing: '1px', marginBottom: 2 }}>TEMPAT PKL</p>
                <p style={{ fontSize: 11, fontWeight: 700, color: '#93C5FD' }}>{company.name}</p>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ── BANTUAN ── */}
      <div
        onClick={() => window.open('https://wa.me/6281234567890', '_blank')}
        style={{ background: 'var(--card)', borderRadius: 12, padding: '14px 18px', border: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 16, cursor: 'pointer', transition: 'box-shadow 0.2s' }}
        onMouseOver={e => (e.currentTarget.style.boxShadow = '0 4px 16px rgba(21,101,192,0.1)')}
        onMouseOut={e => (e.currentTarget.style.boxShadow = 'none')}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ background: '#EEF4FC', padding: 10, borderRadius: 9 }}>
            <Settings size={17} color="#1565C0" />
          </div>
          <div>
            <p style={{ fontSize: 13, fontWeight: 700 }}>Butuh Bantuan?</p>
            <p style={{ fontSize: 11, color: 'var(--muted-foreground)' }}>Hubungi Admin PKL via WhatsApp</p>
          </div>
        </div>
        <ChevronRight size={16} color="#1565C0" />
      </div>

      <footer style={{ textAlign: 'center', paddingTop: 24, paddingBottom: 4 }}>
        <p style={{ fontSize: 10, fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.4em' }}>
          © 2026 E-PKL | SMKN 1 GARUT
        </p>
      </footer>
    </div>
  );
}