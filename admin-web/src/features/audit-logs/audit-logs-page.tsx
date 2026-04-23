import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Activity, Search, Calendar, User, ShieldCheck, ChevronLeft, ChevronRight } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

export function AuditLogsPage() {
  const [searchTerm, setSearchTerm] = useState("");

  const logs = [
    { id: 1, actor: "Admin SIP SMKN 1 Garut", action: "UPDATE_STUDENT", target: "PROFILES", targetId: "a753fb77-683c-4345-9db2-f4a504b9f1e1", details: '{"updates":{"nik":"","nipd":"","nisn":"827213..."}}', time: "22 Apr 07:37" },
    { id: 2, actor: "admin", action: "SUSPEND_TEACHER", target: "PROFILES", targetId: "2691cbdd-ce6c-4e0b-9dc3-9dae1f46a788", details: '{"reason":"Soft delete via dialog"}', time: "22 Apr 08:54" },
    { id: 3, actor: "Admin SIP SMKN 1 Garut", action: "SUSPEND_TEACHER", target: "PROFILES", targetId: "2691cbdd-ce6c-4e0b-9dc3-9dae1f46a788", details: '{"reason":"Soft delete via dialog"}', time: "22 Apr 07:24" },
  ];

  return (
    <div className="p-4 md:p-8 space-y-6 min-h-screen transition-colors duration-300 dark:bg-[#020617] bg-slate-50">
      {/* Header Section */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 animate-in fade-in slide-in-from-top-4 duration-500">
        <div className="space-y-1">
          <h1 className="text-3xl font-extrabold tracking-tight dark:text-white text-slate-900">
            Audit <span className="text-blue-500">Logs</span>
          </h1>
          <p className="dark:text-slate-400 text-slate-500 text-sm">Riwayat aktivitas dan perubahan data sistem SMKN 1 Garut.</p>
        </div>

        <div className="relative group">
          <div className="absolute -inset-0.5 bg-blue-500 rounded-xl blur opacity-10 group-hover:opacity-30 transition duration-300"></div>
          <div className="relative flex items-center bg-white dark:bg-[#1e293b]/50 backdrop-blur-md rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden shadow-sm">
            <Search className="ml-3 h-4 w-4 text-slate-400" />
            <Input placeholder="Cari aktivitas..." className="border-none bg-transparent focus-visible:ring-0 w-[200px] md:w-[300px] dark:text-white" value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
          </div>
        </div>
      </div>

      {/* Main Card */}
      <Card className="border-none shadow-2xl dark:bg-[#0f172a]/80 bg-white/90 backdrop-blur-xl rounded-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-700">
        <CardHeader className="border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-[#1e293b]/30">
          <CardTitle className="text-[11px] font-bold flex items-center gap-2 dark:text-blue-400 text-blue-600 tracking-widest uppercase">
            <Activity className="h-4 w-4" />
            Aktivitas Sistem Terbaru
          </CardTitle>
        </CardHeader>

        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-xs text-left border-collapse">
              <thead className="dark:text-slate-400 text-slate-500 font-bold uppercase tracking-wider bg-slate-50/30 dark:bg-slate-900/20">
                <tr className="border-b border-slate-100 dark:border-slate-800">
                  <th className="px-6 py-5">Waktu</th>
                  <th className="px-6 py-5">Actor</th>
                  <th className="px-6 py-5">Action</th>
                  <th className="px-6 py-5">Target</th>
                  <th className="px-6 py-5">Details</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                {logs.map((log) => (
                  <tr key={log.id} className="group hover:bg-blue-500/5 transition-all duration-150">
                    <td className="px-6 py-5 whitespace-nowrap dark:text-slate-300 text-slate-600">
                      <div className="flex items-center gap-2">
                        <Calendar className="h-3.5 w-3.5 text-blue-500/50" />
                        {log.time}
                      </div>
                    </td>
                    <td className="px-6 py-5 font-bold dark:text-white text-slate-800">{log.actor}</td>
                    <td className="px-6 py-5">
                      <span className="px-3 py-1 rounded-full text-[9px] font-black border dark:bg-slate-800 bg-slate-100 dark:text-slate-300 text-slate-600 border-slate-200 dark:border-slate-700 uppercase">{log.action}</span>
                    </td>
                    <td className="px-6 py-5">
                      <div className="space-y-1">
                        <div className="font-bold dark:text-slate-200 text-slate-700 flex items-center gap-1">
                          <ShieldCheck className="h-3 w-3 text-blue-500" />
                          {log.target}
                        </div>
                        <div className="text-[10px] text-slate-500 font-mono truncate w-32 opacity-60">{log.targetId}</div>
                      </div>
                    </td>
                    <td className="px-6 py-5">
                      <div className="max-w-[200px] truncate px-3 py-2 rounded-lg bg-slate-100/50 dark:bg-slate-800/50 dark:text-slate-400 text-slate-500 font-mono text-[10px]">{log.details}</div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Tombol Pagination yang tadi hilang */}
          <div className="px-6 py-5 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between bg-slate-50/20 dark:bg-slate-900/20">
            <div className="text-[11px] font-medium text-slate-500 dark:text-slate-400">
              Menampilkan <span className="dark:text-white text-slate-900 font-bold">1-3</span> dari <span className="dark:text-white text-slate-900 font-bold">3</span> aktivitas
            </div>
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                className="h-8 gap-1 rounded-lg border-slate-200 dark:border-slate-800 dark:text-slate-300 hover:bg-blue-500 hover:text-white transition-all text-[10px] font-bold uppercase tracking-tighter"
              >
                <ChevronLeft className="h-3 w-3" /> Previous
              </Button>
              <div className="px-3 py-1 rounded-md bg-blue-500 text-white text-[10px] font-bold">Page 1 of 1</div>
              <Button
                variant="outline"
                size="sm"
                className="h-8 gap-1 rounded-lg border-slate-200 dark:border-slate-800 dark:text-slate-300 hover:bg-blue-500 hover:text-white transition-all text-[10px] font-bold uppercase tracking-tighter"
              >
                Next <ChevronRight className="h-3 w-3" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="text-center">
        <p className="text-[9px] text-slate-400 dark:text-slate-600 tracking-[0.3em] font-black uppercase">SMKN 1 GARUT • E-PKL SYSTEM v2.0</p>
      </div>
    </div>
  );
}
