import { useState } from "react";
import { IconDeviceFloppy, IconClock, IconInfoCircle } from "@tabler/icons-react";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

export function AttendanceTimeSettings() {
  const [loading, setLoading] = useState(false);
  const [times, setTimes] = useState({
    tepatWaktu: "08:00",
    deadline: "08:30",
    mulaiPulang: "16:00",
    akhirPulang: "18:00",
  });

  const handleSave = async () => {
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      toast.success("Pengaturan waktu absen berhasil disimpan.");
    }, 800);
  };

  return (
    <Card className="border border-slate-200/80 dark:border-slate-800 shadow-sm rounded-2xl overflow-hidden bg-white dark:bg-slate-950">
      <CardHeader className="bg-slate-50/50 dark:bg-slate-900/50 border-b border-slate-100 dark:border-slate-800 p-6 space-y-1">
        <CardTitle className="text-base font-bold tracking-tight text-slate-900 dark:text-white">Pengaturan Waktu Absen Global</CardTitle>
        <CardDescription className="text-sm text-slate-500 dark:text-slate-400 font-normal">Atur batas waktu absen datang dan pulang default untuk semua DUDI.</CardDescription>
      </CardHeader>

      <CardContent className="p-6 space-y-6 bg-white dark:bg-slate-950">
        <div className="space-y-6">
          {/* GRID UTAMA: 2 Kolom Sejajar Rapi */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-6">
            {/* Input Tepat Waktu */}
            <div className="space-y-1.5">
              <label className="text-sm font-semibold text-slate-800 dark:text-slate-200">Batas Waktu Tepat Waktu</label>
              <div className="relative">
                <Input
                  type="text"
                  value={times.tepatWaktu}
                  onChange={(e) => setTimes({ ...times, tepatWaktu: e.target.value })}
                  className="w-full px-4 py-2.5 rounded-xl border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-slate-100 focus-visible:ring-blue-500 bg-slate-50/30 dark:bg-slate-900/30 pr-10"
                />
                <IconClock className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 dark:text-slate-500" />
              </div>
            </div>

            {/* Input Deadline */}
            <div className="space-y-1.5">
              <label className="text-sm font-semibold text-slate-800 dark:text-slate-200">Batas Absen Datang (Deadline)</label>
              <div className="relative">
                <Input
                  type="text"
                  value={times.deadline}
                  onChange={(e) => setTimes({ ...times, deadline: e.target.value })}
                  className="w-full px-4 py-2.5 rounded-xl border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-slate-100 focus-visible:ring-blue-500 bg-slate-50/30 dark:bg-slate-900/30 pr-10"
                />
                <IconClock className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 dark:text-slate-500" />
              </div>
            </div>

            {/* Waktu Mulai Pulang */}
            <div className="space-y-1.5">
              <label className="text-sm font-semibold text-slate-800 dark:text-slate-200">Waktu Mulai Pulang</label>
              <div className="relative">
                <Input
                  type="text"
                  value={times.mulaiPulang}
                  onChange={(e) => setTimes({ ...times, mulaiPulang: e.target.value })}
                  className="w-full px-4 py-2.5 rounded-xl border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-slate-100 focus-visible:ring-blue-500 bg-slate-50/30 dark:bg-slate-900/30 pr-10"
                />
                <IconClock className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 dark:text-slate-500" />
              </div>
            </div>

            {/* Batas Akhir Pulang */}
            <div className="space-y-1.5">
              <label className="text-sm font-semibold text-slate-800 dark:text-slate-200">Batas Akhir Pulang</label>
              <div className="relative">
                <Input
                  type="text"
                  value={times.akhirPulang}
                  onChange={(e) => setTimes({ ...times, akhirPulang: e.target.value })}
                  className="w-full px-4 py-2.5 rounded-xl border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-slate-100 focus-visible:ring-blue-500 bg-slate-50/30 dark:bg-slate-900/30 pr-10"
                />
                <IconClock className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 dark:text-slate-500" />
              </div>
            </div>
          </div>

          {/* Kotak Info Amber Polos */}
          <div className="p-4 bg-amber-50/50 dark:bg-amber-950/20 border border-amber-100 dark:border-amber-900/50 rounded-xl flex items-start gap-3">
            <IconInfoCircle className="w-5 h-5 text-amber-600 dark:text-amber-500 shrink-0 mt-0.5" />
            <div className="space-y-1">
              <p className="text-xs font-bold text-amber-800 dark:text-amber-400 uppercase">Catatan:</p>
              <ul className="list-disc list-inside text-xs text-amber-700/90 dark:text-amber-400/90 space-y-1 font-medium">
                <li>Setting ini berlaku untuk semua DUDI secara default.</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Tombol Simpan */}
        <div className="pt-6 mt-4 border-t border-slate-100 dark:border-slate-800 flex justify-start">
          <Button onClick={handleSave} disabled={loading} className="bg-blue-600 hover:bg-blue-700 dark:bg-blue-600 dark:hover:bg-blue-700 text-white text-xs font-bold px-6 py-3 rounded-xl flex items-center gap-2">
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <IconDeviceFloppy className="h-4 w-4" />}
            Simpan Perubahan
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
