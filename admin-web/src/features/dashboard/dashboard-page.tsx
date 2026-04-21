import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom'; // Import useNavigate
import {
  Bell,
  Building2,
  Calendar,
  Clock,
  ClipboardCheck,
  GraduationCap,
  MapPin,
  Plus,
  Search,
  Settings,
} from 'lucide-react';

export default function DashboardPage() {
  const [isLoaded, setIsLoaded] = useState(false);
  const navigate = useNavigate(); // Inisialisasi navigasi

  useEffect(() => {
    setIsLoaded(true);
  }, []);

  // Fungsi untuk handle klik
  const handleDetailKantor = () => {
    // Mengarah ke route yang merender CompaniesPage
   navigate('/companies', { state: { searchName: 'PT. Teknologi Masa Depan' } });
};

  const handleKontakMentor = () => {
    // Membuka WhatsApp dengan pesan otomatis
    const phoneNumber = "6281234567890"; // Ganti dengan nomor asli mentor
    const message = encodeURIComponent("Halo Mentor, saya ingin bertanya terkait kegiatan PKL saya hari ini.");
    window.open(`https://wa.me/${phoneNumber}?text=${message}`, '_blank');
  };

  const stats = [
    { label: 'Total Kehadiran', value: '18/22', icon: Clock, color: '#1565C0', bg: '#E3F2FD' },
    { label: 'Tugas Selesai', value: '12', icon: ClipboardCheck, color: '#2E7D32', bg: '#E8F5E9' },
    { label: 'Sisa Hari PKL', value: '45', icon: Calendar, color: '#6A1B9A', bg: '#F3E5F5' },
  ];

  const recentActivities = [
    { title: 'Presensi Masuk', time: '07:30 AM', status: 'Tepat Waktu', date: 'Hari ini' },
    { title: 'Update Jurnal', time: '04:00 PM', status: 'Pending', date: 'Kemarin' },
    { title: 'Bimbingan Guru', time: '10:00 AM', status: 'Selesai', date: '2 hari lalu' },
  ];

  const getStatusStyle = (status: string) => {
    if (status === 'Tepat Waktu') return { background: '#E8F5E9', color: '#2E7D32' };
    if (status === 'Selesai') return { background: '#E3F2FD', color: '#1565C0' };
    return { background: '#FFF3E0', color: '#E65100' };
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        background: 'var(--background)',
        padding: '20px 24px',
        fontFamily: "'Plus Jakarta Sans', sans-serif",
        opacity: isLoaded ? 1 : 0,
        transition: 'opacity 0.7s, background 0.3s ease',
      }}
    >
      {/* BANNER UTAMA */}
      <div
        style={{
          background: 'linear-gradient(135deg, #1565C0 0%, #1976D2 40%, #42A5F5 100%)',
          borderRadius: 14,
          padding: '26px 32px',
          marginBottom: 22,
          boxShadow: '0 4px 20px rgba(21,101,192,0.28)',
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        <div style={{ position: 'absolute', top: -40, right: 60, width: 180, height: 180, background: 'rgba(255,255,255,0.07)', borderRadius: '50%' }} />
        <div style={{ position: 'relative', zIndex: 1, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 16 }}>
          <div>
            <h1 style={{ fontSize: 24, fontWeight: 800, color: '#fff', marginBottom: 4 }}>Halo, Selamat Pagi! 👋</h1>
            <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.75)' }}>Sistem Informasi PKL SMKN 1 Garut</p>
          </div>
          <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
            <Search size={16} style={{ position: 'absolute', left: 12, color: 'rgba(255,255,255,0.6)' }} />
            <input
              type="text"
              placeholder="Cari fitur..."
              style={{
                background: 'rgba(255,255,255,0.15)',
                border: '1px solid rgba(255,255,255,0.25)',
                borderRadius: 8,
                padding: '8px 14px 8px 34px',
                fontSize: 12,
                color: '#fff',
                outline: 'none',
                width: 210,
              }}
            />
          </div>
        </div>
      </div>

      {/* STATS */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 14, marginBottom: 22 }}>
        {stats.map((s, i) => (
          <div
            key={i}
            style={{
              background: 'var(--card)',
              borderRadius: 10,
              padding: '18px 20px',
              display: 'flex',
              alignItems: 'center',
              gap: 14,
              boxShadow: '0 1px 6px rgba(0,0,0,0.05)',
              border: '1px solid var(--border)',
            }}
          >
            <div style={{ width: 46, height: 46, borderRadius: 11, background: s.bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <s.icon size={22} color={s.color} />
            </div>
            <div>
              <p style={{ fontSize: 10, fontWeight: 600, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>{s.label}</p>
              <p style={{ fontSize: 24, fontWeight: 800, color: '#1565C0' }}>{s.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* MAIN GRID */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 310px', gap: 16, marginBottom: 16 }}>
        {/* TEMPAT PKL (DENGAN KONTAK MENTOR) */}
        <div
          style={{
            background: 'linear-gradient(135deg, #1565C0 0%, #1976D2 50%, #42A5F5 100%)',
            borderRadius: 14,
            padding: 26,
            position: 'relative',
            overflow: 'hidden',
          }}
        >
          <div style={{ position: 'absolute', top: -25, right: -25, width: 150, height: 150, background: 'rgba(255,255,255,0.07)', borderRadius: '50%' }} />
          <div style={{ position: 'relative', zIndex: 1 }}>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, background: 'rgba(255,255,255,0.18)', border: '1px solid rgba(255,255,255,0.25)', borderRadius: 20, padding: '4px 12px', fontSize: 10.5, fontWeight: 700, color: '#fff', textTransform: 'uppercase', marginBottom: 12 }}>
              <Building2 size={13} /> Tempat PKL Aktif
            </div>
            <h2 style={{ fontSize: 20, fontWeight: 800, color: '#fff', marginBottom: 8 }}>PT. Teknologi Masa Depan</h2>
            <p style={{ fontSize: 12, color: 'rgba(255,255,255,0.72)', display: 'flex', alignItems: 'center', gap: 5, marginBottom: 20 }}>
              <MapPin size={14} /> Jl. Raya Garut - Tasik No. 123, Garut
            </p>
            
            {/* TOMBOL BERDERET */}
            <div style={{ display: 'flex', gap: 10 }}>
              <button 
                onClick={handleDetailKantor}
                style={{ background: '#fff', color: '#1565C0', border: 'none', borderRadius: 8, padding: '9px 16px', fontSize: 12.5, fontWeight: 700, cursor: 'pointer', transition: 'all 0.2s' }}
                onMouseOver={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
                onMouseOut={(e) => e.currentTarget.style.transform = 'scale(1)'}
              >
                Lihat Detail Kantor
              </button>
              <button 
                onClick={handleKontakMentor}
                style={{ background: 'transparent', color: '#fff', border: '2px solid rgba(255,255,255,0.4)', borderRadius: 8, padding: '9px 16px', fontSize: 12.5, fontWeight: 700, cursor: 'pointer', transition: 'all 0.2s' }}
                onMouseOver={(e) => e.currentTarget.style.background = 'rgba(255,255,255,0.1)'}
                onMouseOut={(e) => e.currentTarget.style.background = 'transparent'}
              >
                Kontak Mentor
              </button>
            </div>
          </div>
        </div>

        {/* PENGUMUMAN */}
        <div style={{ background: 'var(--card)', borderRadius: 10, padding: '16px 18px', border: '1px solid var(--border)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginBottom: 14 }}>
            <Bell size={16} color="#F59E0B" />
            <span style={{ fontSize: 13, fontWeight: 800, color: '#1565C0', textTransform: 'uppercase' }}>Pengumuman</span>
          </div>
          {[1, 2].map((i) => (
            <div key={i} style={{ background: '#FFFDE7', borderLeft: '3px solid #FBC02D', borderRadius: '0 7px 7px 0', padding: '9px 11px', marginBottom: 9 }}>
              <p style={{ fontSize: 12.5, fontWeight: 700, color: '#F57F17', marginBottom: 2 }}>Upload Laporan Bulanan</p>
              <p style={{ fontSize: 11, color: '#64748b' }}>Paling lambat tanggal 25 setiap bulan.</p>
            </div>
          ))}
        </div>
      </div>

      {/* BOTTOM GRID */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 310px', gap: 16 }}>
        {/* AKTIVITAS TERBARU */}
        <div style={{ background: 'var(--card)', borderRadius: 10, padding: '16px 18px', border: '1px solid var(--border)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
            <span style={{ fontSize: 13, fontWeight: 800, color: '#1565C0' }}>Aktivitas Terbaru</span>
            <span style={{ fontSize: 12, color: '#1976D2', fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4 }}>
              Lihat Semua <Plus size={13} />
            </span>
          </div>
          {recentActivities.map((a, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '9px 0', borderBottom: i < recentActivities.length - 1 ? '1px solid var(--border)' : 'none' }}>
              <div style={{ width: 32, height: 32, background: '#EEF4FC', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Plus size={15} color="#1565C0" />
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ fontSize: 12.5, fontWeight: 600 }}>{a.title}</p>
                <p style={{ fontSize: 10.5, color: 'var(--muted-foreground)' }}>{a.date} • {a.time}</p>
              </div>
              <span style={{ ...getStatusStyle(a.status), padding: '3px 10px', borderRadius: 20, fontSize: 10.5, fontWeight: 700 }}>
                {a.status.toUpperCase()}
              </span>
            </div>
          ))}
        </div>

        {/* ID CARD */}
        <div style={{ background: 'linear-gradient(135deg, #0D1B2A 0%, #1565C0 60%, #1976D2 100%)', borderRadius: 14, padding: '20px', position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: -18, right: -18, width: 110, height: 110, background: 'rgba(255,255,255,0.05)', borderRadius: '50%' }} />
          <div style={{ position: 'relative', zIndex: 1 }}>
            <p style={{ fontSize: 9.5, fontWeight: 700, letterSpacing: '1.3px', color: 'rgba(255,255,255,0.45)' }}>ID CARD VIRTUAL</p>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
              <p style={{ fontSize: 14, fontWeight: 800, color: '#fff' }}>SISWA PKL</p>
              <GraduationCap size={22} color="#60A5FA" />
            </div>
            <div style={{ width: '100%', height: 60, background: 'rgba(255,255,255,0.08)', borderRadius: 8, marginBottom: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 26 }}>
            </div>
            <p style={{ fontSize: 14, fontWeight: 800, color: '#fff' }}>MUHAMMAD REZA</p>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginTop: 12 }}>
              <p style={{ fontSize: 10, color: 'rgba(255,255,255,0.45)' }}>SMKN 1 GARUT</p>
              <p style={{ fontSize: 11, fontWeight: 700, color: '#fff' }}>005412399</p>
            </div>
          </div>
        </div>
      </div>

      {/* BUTUH BANTUAN SECTION */}
      <div style={{ background: 'var(--card)', borderRadius: 10, padding: '14px 18px', border: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 16, cursor: 'pointer' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ background: '#EEF4FC', padding: 10, borderRadius: 8 }}>
            <Settings size={18} color="#1565C0" />
          </div>
          <div>
            <p style={{ fontSize: 13, fontWeight: 700 }}>Butuh Bantuan?</p>
            <p style={{ fontSize: 11, color: 'var(--muted-foreground)' }}>Hubungi Admin PKL</p>
          </div>
        </div>
        <Plus size={16} color="#1565C0" />
      </div>

      <footer style={{ textAlign: 'center', paddingTop: 24, paddingBottom: 8 }}>
        <p style={{ fontSize: 10, fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.4em' }}>
          © 2026 E-PKL | SMKN 1 GARUT
        </p>
      </footer>
    </div>
  );
}