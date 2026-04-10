import { useEffect, useState } from 'react';
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

  useEffect(() => {
    setIsLoaded(true);
  }, []);

  const stats = [
    { label: 'Total Kehadiran', value: '18/22', icon: Clock, color: 'text-blue-600', bg: 'bg-blue-100' },
    { label: 'Tugas Selesai', value: '12', icon: ClipboardCheck, color: 'text-emerald-600', bg: 'bg-emerald-100' },
    { label: 'Sisa Hari PKL', value: '45', icon: Calendar, color: 'text-purple-600', bg: 'bg-purple-100' },
  ];

  const recentActivities = [
    { title: 'Presensi Masuk', time: '07:30 AM', status: 'Tepat Waktu', date: 'Hari ini' },
    { title: 'Update Jurnal', time: '04:00 PM', status: 'Pending', date: 'Kemarin' },
    { title: 'Bimbingan Guru', time: '10:00 AM', status: 'Selesai', date: '2 hari lalu' },
  ];

  return (
    <div className={`min-h-screen bg-slate-50 p-4 md:p-8 space-y-8 transition-opacity duration-700 ${isLoaded ? 'opacity-100' : 'opacity-0'}`}>
      
      {/* Top Header Card */}
      <div className="bg-white/90 backdrop-blur-xl rounded-[2rem] shadow-sm border border-slate-200 p-6">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 tracking-tight">Halo, Selamat Pagi! 👋</h1>
            <p className="text-slate-500 text-sm mt-1">Sistem Informasi PKL SMKN 1 Garut</p>
          </div>
          
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
            <div className="relative w-full sm:w-80">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
              <input
                type="text"
                placeholder="Cari fitur atau data..."
                className="w-full rounded-full border border-slate-200 bg-slate-50 py-2.5 pl-10 pr-4 text-sm text-slate-700 outline-none transition focus:border-blue-400 focus:ring-4 focus:ring-blue-100"
              />
            </div>
            <button className="relative inline-flex items-center justify-center rounded-full border border-slate-200 bg-white p-3 text-slate-500 transition hover:bg-slate-50 hover:text-blue-600">
              <Bell size={20} />
              <span className="absolute top-1 right-1 h-3 w-3 rounded-full bg-red-500 border-2 border-white" />
            </button>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid gap-6 md:grid-cols-3">
        {stats.map((stat, idx) => (
          <div key={idx} className="flex items-center gap-5 rounded-3xl border border-slate-100 bg-white p-6 shadow-sm transition hover:shadow-md hover:-translate-y-1 duration-300">
            <div className={`${stat.bg} ${stat.color} rounded-2xl p-4`}>
              <stat.icon size={28} />
            </div>
            <div>
              <p className="text-sm font-semibold text-slate-400 uppercase tracking-wider">{stat.label}</p>
              <p className="mt-1 text-2xl font-black text-slate-900">{stat.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Main Content Grid */}
      <div className="grid gap-8 lg:grid-cols-3">
        
        {/* Left Column (Activities & Company Info) */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Active Placement Card */}
          <div className="relative overflow-hidden rounded-[2.5rem] bg-gradient-to-br from-blue-600 to-indigo-700 p-8 text-white shadow-xl shadow-blue-200/50">
            <div className="relative z-10">
              <div className="mb-4 inline-flex items-center gap-2 rounded-full bg-white/20 px-4 py-1.5 text-xs font-bold uppercase tracking-[0.2em] text-white backdrop-blur-md border border-white/30">
                <Building2 size={16} />
                Tempat PKL Aktif
              </div>
              <h2 className="text-3xl font-extrabold tracking-tight">PT. Teknologi Masa Depan</h2>
              <p className="mt-3 flex items-center gap-2 text-blue-10/80 font-medium">
                <MapPin size={18} className="text-blue-200" /> Jl. Raya Garut - Tasik No. 123, Garut
              </p>
              <div className="mt-10 flex flex-wrap gap-4">
                <button className="rounded-2xl bg-white px-8 py-3.5 text-sm font-black text-blue-700 transition hover:bg-blue-50 active:scale-95 shadow-lg shadow-blue-900/20">
                  Lihat Detail Kantor
                </button>
                <button className="rounded-2xl border-2 border-white/30 bg-white/10 px-8 py-3.5 text-sm font-black text-white transition hover:bg-white/20 active:scale-95">
                  Kontak Mentor
                </button>
              </div>
            </div>
            
            {/* Abstract Background Shapes */}
            <div className="absolute -top-20 -right-20 h-80 w-80 rounded-full bg-white/10 blur-3xl" />
            <div className="absolute -bottom-10 left-1/4 h-40 w-40 rounded-full bg-blue-400/20 blur-2xl" />
          </div>

          {/* Activity List */}
          <div className="overflow-hidden rounded-[2rem] border border-slate-100 bg-white shadow-sm">
            <div className="flex items-center justify-between border-b border-slate-50 px-8 py-6">
              <h3 className="text-xl font-bold text-slate-900">Aktivitas Terbaru</h3>
              <button className="text-sm font-bold text-blue-600 hover:text-blue-700 transition flex items-center gap-1">
                Lihat Semua <Plus size={14} />
              </button>
            </div>
            <div className="divide-y divide-slate-50">
              {recentActivities.map((activity, idx) => (
                <div key={idx} className="group flex items-center justify-between gap-4 px-8 py-6 transition hover:bg-slate-50/80">
                  <div className="flex items-center gap-5">
                    <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-100 text-slate-400 transition group-hover:bg-blue-100 group-hover:text-blue-600">
                      <Plus size={20} />
                    </div>
                    <div>
                      <p className="font-bold text-slate-800 text-lg">{activity.title}</p>
                      <p className="text-sm text-slate-400 font-medium">{activity.date} • {activity.time}</p>
                    </div>
                  </div>
                  <span className={`rounded-xl px-4 py-2 text-xs font-black uppercase tracking-wider ${
                    activity.status === 'Tepat Waktu' ? 'bg-emerald-100 text-emerald-700' :
                    activity.status === 'Selesai' ? 'bg-blue-100 text-blue-700' :
                    'bg-amber-100 text-amber-700'
                  }`}>
                    {activity.status}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right Column (Sidebar Cards) */}
        <div className="space-y-6">
          
          {/* Announcements */}
          <div className="rounded-[2rem] border border-slate-100 bg-white p-6 shadow-sm">
            <div className="flex items-center gap-2 mb-6">
              <Bell className="text-amber-500" size={20} />
              <h3 className="text-lg font-bold text-slate-900 uppercase tracking-tight">Pengumuman</h3>
            </div>
            <div className="space-y-4">
              {[1, 2].map((item) => (
                <div key={item} className="rounded-2xl border border-amber-100 bg-amber-50/50 p-5 group cursor-pointer hover:bg-amber-50 transition">
                  <p className="text-sm font-extrabold text-amber-900 mb-1 group-hover:text-amber-600 transition">Upload Laporan Bulanan</p>
                  <p className="text-xs text-amber-700 leading-relaxed font-medium">Paling lambat tanggal 25 setiap bulannya dalam format PDF ke sistem.</p>
                </div>
              ))}
            </div>
          </div>

          {/* Virtual ID Card */}
          <div className="group relative overflow-hidden rounded-[2.5rem] bg-slate-900 p-8 text-white shadow-2xl transition hover:scale-[1.02] duration-500">
            <div className="relative z-10">
              <div className="mb-8 flex items-start justify-between">
                <div>
                  <p className="text-[10px] uppercase font-black tracking-[0.3em] text-slate-500 mb-1">ID CARD VIRTUAL</p>
                  <p className="text-lg font-black tracking-tight">SISWA PKL</p>
                </div>
                <GraduationCap className="text-blue-500 group-hover:rotate-12 transition-transform duration-500" size={32} />
              </div>
              
              <div className="space-y-6">
                <div className="h-10 w-full rounded-xl bg-gradient-to-r from-slate-800 to-slate-700 border border-slate-700/50" />
                <div className="flex justify-between items-end">
                  <div>
                    <p className="text-[9px] uppercase tracking-[0.25em] text-slate-500 font-bold mb-1">Nama Lengkap</p>
                    <p className="font-black text-lg tracking-tight">MUHAMMAD REZA</p>
                    <p className="text-[10px] text-blue-400 font-bold mt-1">SMKN 1 GARUT</p>
                  </div>
                  <div className="text-right">
                    <p className="text-[9px] uppercase tracking-[0.25em] text-slate-500 font-bold mb-1">NISN</p>
                    <p className="font-mono font-bold text-slate-300">005412399</p>
                  </div>
                </div>
              </div>
            </div>
            
            {/* Background Decorative Elements */}
            <div className="absolute top-0 right-0 w-32 h-32 bg-blue-600/10 blur-[60px]" />
            <div className="absolute bottom-0 left-0 w-24 h-24 bg-indigo-600/20 blur-[40px]" />
          </div>

          {/* Quick Support Link */}
          <div className="bg-white rounded-[2rem] p-6 border border-slate-100 shadow-sm flex items-center justify-between group cursor-pointer hover:border-blue-200 transition">
            <div className="flex items-center gap-4">
              <div className="bg-slate-50 p-3 rounded-2xl group-hover:bg-blue-50 transition">
                <Settings className="text-slate-400 group-hover:text-blue-600 group-hover:rotate-45 transition-all duration-500" size={20} />
              </div>
              <div>
                <p className="font-bold text-slate-800">Butuh Bantuan?</p>
                <p className="text-xs text-slate-400 font-medium">Hubungi Admin PKL</p>
              </div>
            </div>
            <Plus className="text-slate-300 group-hover:text-blue-600 transition" />
          </div>

        </div>
      </div>
      
      {/* Footer Branding */}
      <footer className="pt-8 pb-4 text-center">
        <p className="text-[10px] font-black text-slate-300 uppercase tracking-[0.5em]">
          &copy; 2026 E-PKL | SMKN 1 GARUT
        </p>
      </footer>
    </div>
  );
};