import { useAuditLogs } from "./hooks/use-audit-logs";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { format } from "date-fns";
import { id } from "date-fns/locale";
import { ChevronLeft, ChevronRight, ClipboardList, Clock, Users, Search, Download } from "lucide-react";
import { TableRowsSkeleton } from "@/components/ui/table-skeleton";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";

export function AuditLogsPage() {
  const { data: logs, isLoading } = useAuditLogs();

  const [page, setPage] = useState(0);
  const [search, setSearch] = useState("");
  const pageSize = 10;

  const filteredLogs = logs?.filter((log) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      // @ts-ignore
      log.actor?.full_name?.toLowerCase().includes(q) || log.action?.toLowerCase().includes(q) || log.table_name?.toLowerCase().includes(q) || log.record_id?.toLowerCase().includes(q)
    );
  });

  const totalPages = Math.ceil((filteredLogs?.length || 0) / pageSize);
  const paginatedLogs = filteredLogs?.slice(page * pageSize, (page + 1) * pageSize);

  const getActionBadgeClass = (action: string) => {
    switch (action.toUpperCase()) {
      case "CREATE":
        return "bg-emerald-50 text-emerald-700 dark:bg-[#EAF3DE] dark:text-[#3B6D11] hover:bg-emerald-100 dark:hover:bg-[#d8edbc] border-transparent";
      case "UPDATE":
        return "bg-blue-50 text-blue-700 dark:bg-[#E6F1FB] dark:text-[#185FA5] hover:bg-blue-100 dark:hover:bg-[#cce3f7] border-transparent";
      case "DELETE":
        return "bg-rose-50 text-rose-700 dark:bg-[#FCEBEB] dark:text-[#A32D2D] hover:bg-rose-100 dark:hover:bg-[#f9d4d4] border-transparent";
      default:
        return "bg-gray-100 text-gray-700 dark:bg-zinc-800 dark:text-zinc-300 border-transparent";
    }
  };

  const getActionDotColor = (action: string) => {
    switch (action.toUpperCase()) {
      case "CREATE":
        return "bg-emerald-600 dark:bg-[#3B6D11]";
      case "UPDATE":
        return "bg-blue-600 dark:bg-[#185FA5]";
      case "DELETE":
        return "bg-rose-600 dark:bg-[#A32D2D]";
      default:
        return "bg-gray-400";
    }
  };

  const getInitials = (name: string) => {
    if (!name) return "?";
    return name
      .split(" ")
      .slice(0, 2)
      .map((n) => n[0])
      .join("")
      .toUpperCase();
  };

  const handleExport = () => {
    const dataToExport = filteredLogs;
    if (!dataToExport || dataToExport.length === 0) return;

    const headers = ["Waktu", "Actor", "Action", "Target Table", "Record ID", "Details"];

    const csvRows = dataToExport.map((log) => {
      const waktu = format(new Date(log.created_at), "yyyy-MM-dd HH:mm:ss");
      // @ts-ignore
      const actor = log.actor?.full_name || "Unknown";
      const action = log.action;
      const target = log.table_name;
      const recordId = log.record_id;
      const details = log.details ? JSON.stringify(log.details).replace(/"/g, '""') : "";

      return `"${waktu}","${actor}","${action}","${target}","${recordId}","${details}"`;
    });

    const csvContent = [headers.join(","), ...csvRows].join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");

    link.setAttribute("href", url);
    link.setAttribute("download", `Audit_Logs_${format(new Date(), "yyyyMMdd_HHmmss")}.csv`);
    link.style.visibility = "hidden";

    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const totalCount = logs?.length || 0;
  const todayCount =
    logs?.filter((log) => {
      const today = new Date();
      const logDate = new Date(log.created_at);
      return logDate.toDateString() === today.toDateString();
    }).length || 0;
  const uniqueActors = new Set(logs?.map((log) => (log as any).actor?.full_name)).size || 0;

  return (
    <div className="space-y-6 p-1">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 text-xs text-muted-foreground">
        <span>E-PKL</span>
        <ChevronRight className="h-3 w-3" />
        <span className="text-foreground font-medium">Audit Logs</span>
      </div>

      {/* Page Header */}
      <div className="flex items-start justify-between">
        <div>
          <p className="text-[10px] font-bold text-blue-600 dark:text-[#3b82f6] uppercase tracking-widest flex items-center gap-1.5 mb-1">ACTIVITY MONITOR</p>
          <h1 className="text-3xl font-extrabold italic tracking-wide text-slate-800 dark:text-slate-100 uppercase">
            AUDIT <span className="text-blue-600 dark:text-[#3b82f6]">LOGS</span>
          </h1>
          <p className="text-slate-500 dark:text-slate-400 text-xs mt-1">Riwayat perubahan data dan aktivitas sistem.</p>
        </div>

        {/* Tombol EXPORT LOG */}
        <Button
          onClick={handleExport}
          disabled={isLoading || !filteredLogs?.length}
          className="bg-blue-50 dark:bg-blue-950/40 hover:bg-blue-100 dark:hover:bg-blue-900/40 text-blue-600 dark:text-[#3b82f6] font-bold rounded-xl gap-2 border border-blue-200 dark:border-blue-900/50 shadow-sm disabled:opacity-50 text-xs px-4 h-9 tracking-wider uppercase"
        >
          <Download className="h-3.5 w-3.5 text-blue-600 dark:text-[#3b82f6]" />
          EXPORT LOG
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* CARD 1: TOTAL AKTIVITAS */}
        <div className="bg-white dark:bg-[#141b2b] border border-slate-200 dark:border-slate-800/80 rounded-2xl p-5 flex items-center gap-4 relative overflow-hidden shadow-sm dark:shadow-md">
          <div className="w-12 h-12 rounded-[14px] flex items-center justify-center flex-shrink-0 bg-blue-50 dark:bg-blue-950/40 border border-blue-100 dark:border-blue-900/30">
            <ClipboardList className="h-5 w-5 text-blue-600 dark:text-[#3b82f6]" />
          </div>
          <div>
            <p className="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Total Aktivitas</p>
            <p className="text-2xl font-extrabold text-slate-800 dark:text-slate-100 mt-0.5">{isLoading ? "—" : totalCount}</p>
          </div>
          {/* Garis Bawah: Berwarna di Light Mode, Gelap/Samar di Dark Mode */}
          <div className="absolute bottom-0 left-0 right-0 h-1 bg-blue-600 dark:bg-slate-800/40" />
        </div>

        {/* CARD 2: HARI INI */}
        <div className="bg-white dark:bg-[#141b2b] border border-slate-200 dark:border-slate-800/80 rounded-2xl p-5 flex items-center gap-4 relative overflow-hidden shadow-sm dark:shadow-md">
          <div className="w-12 h-12 rounded-[14px] flex items-center justify-center flex-shrink-0 bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-100 dark:border-emerald-900/30">
            <Clock className="h-5 w-5 text-emerald-600 dark:text-emerald-400" />
          </div>
          <div>
            <p className="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Hari Ini</p>
            <p className="text-2xl font-extrabold text-slate-800 dark:text-slate-100 mt-0.5">{isLoading ? "—" : todayCount}</p>
          </div>
          {/* Garis Bawah: Berwarna di Light Mode, Gelap/Samar di Dark Mode */}
          <div className="absolute bottom-0 left-0 right-0 h-1 bg-emerald-500 dark:bg-slate-800/40" />
        </div>

        {/* CARD 3: PENGGUNA AKTIF */}
        <div className="bg-white dark:bg-[#141b2b] border border-slate-200 dark:border-slate-800/80 rounded-2xl p-5 flex items-center gap-4 relative overflow-hidden shadow-sm dark:shadow-md">
          <div className="w-12 h-12 rounded-[14px] flex items-center justify-center flex-shrink-0 bg-blue-50 dark:bg-blue-950/40 border border-blue-100 dark:border-blue-900/30">
            <Users className="h-5 w-5 text-blue-600 dark:text-[#3b82f6]" />
          </div>
          <div>
            <p className="text-[10px] font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Pengguna Aktif</p>
            <p className="text-2xl font-extrabold text-slate-800 dark:text-slate-100 mt-0.5">{isLoading ? "—" : uniqueActors}</p>
          </div>
          {/* Garis Bawah: Berwarna di Light Mode, Gelap/Samar di Dark Mode */}
          <div className="absolute bottom-0 left-0 right-0 h-1 bg-blue-600 dark:bg-slate-800/40" />
        </div>
      </div>

      {/* Table Area */}
      <Card className="rounded-2xl border-slate-200 dark:border-slate-800/80 bg-white dark:bg-[#11151f]/40 overflow-hidden shadow-md dark:shadow-lg">
        <CardHeader className="bg-blue-50 dark:bg-[#14233c] border-b border-slate-200 dark:border-slate-800 px-6 py-4 flex flex-row items-center justify-between space-y-0">
          <CardTitle className="text-blue-700 dark:text-blue-400 text-sm font-semibold tracking-wide">Aktivitas Sistem</CardTitle>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400 dark:text-slate-400" />
            <Input
              placeholder="Cari aktivitas..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(0);
              }}
              className="pl-8 h-8 text-xs w-56 rounded-lg border-slate-300 dark:border-slate-700/60 focus-visible:ring-blue-500 dark:focus-visible:ring-[#3b82f6] bg-white dark:bg-[#0f131c] text-slate-800 dark:text-slate-200 placeholder:text-slate-400 dark:placeholder:text-slate-500"
            />
          </div>
        </CardHeader>

        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow className="border-b border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#14233c]/30 hover:bg-transparent">
                <TableHead className="text-slate-500 dark:text-slate-400 text-[11px] font-bold uppercase tracking-wider px-6 h-11">Waktu</TableHead>
                <TableHead className="text-slate-500 dark:text-slate-400 text-[11px] font-bold uppercase tracking-wider h-11">Actor</TableHead>
                <TableHead className="text-slate-500 dark:text-slate-400 text-[11px] font-bold uppercase tracking-wider h-11">Action</TableHead>
                <TableHead className="text-slate-500 dark:text-slate-400 text-[11px] font-bold uppercase tracking-wider h-11">Target</TableHead>
                <TableHead className="text-slate-500 dark:text-slate-400 text-[11px] font-bold uppercase tracking-wider h-11">Details</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                <TableRowsSkeleton columnCount={5} rowCount={10} />
              ) : (
                paginatedLogs?.map((log) => (
                  <TableRow key={log.id} className="border-b border-slate-200 dark:border-slate-800/60 bg-transparent hover:bg-slate-50 dark:hover:bg-slate-800/20 transition-colors">
                    {/* Waktu */}
                    <TableCell className="px-6 whitespace-nowrap py-3">
                      <div className="text-xs text-slate-500 dark:text-slate-400">{format(new Date(log.created_at), "dd MMM", { locale: id })}</div>
                      <div className="text-xs font-semibold text-blue-600 dark:text-blue-400 mt-0.5">{format(new Date(log.created_at), "HH:mm", { locale: id })}</div>
                    </TableCell>

                    {/* Actor */}
                    <TableCell className="py-3">
                      <div className="flex items-center gap-2.5">
                        <div className="w-6 h-6 rounded-full flex items-center justify-center text-white text-[10px] font-bold flex-shrink-0" style={{ background: "linear-gradient(135deg, #3b82f6, #1d4ed8)" }}>
                          {/* @ts-ignore */}
                          {getInitials(log.actor?.full_name || "")}
                        </div>
                        <span className="text-xs font-medium text-slate-700 dark:text-slate-200">
                          {/* @ts-ignore */}
                          {log.actor?.full_name || "admin"}
                        </span>
                      </div>
                    </TableCell>

                    {/* Action */}
                    <TableCell className="py-3">
                      <Badge className={`${getActionBadgeClass(log.action)} text-[10px] font-bold gap-1.5 px-2 py-0.5 rounded-md uppercase`} variant="outline">
                        <span className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${getActionDotColor(log.action)}`} />
                        {log.action}
                      </Badge>
                    </TableCell>

                    {/* Target */}
                    <TableCell className="py-3">
                      <div className="flex flex-col">
                        <span className="text-[11px] font-bold uppercase text-blue-600 dark:text-blue-400/90 tracking-wide">{log.table_name}</span>
                        <span className="text-xs text-slate-400 dark:text-slate-500 font-mono tracking-tight mt-0.5">{log.record_id}</span>
                      </div>
                    </TableCell>

                    {/* Details */}
                    <TableCell className="py-3">
                      <span className="inline-block max-w-[220px] truncate text-[11px] font-mono bg-slate-50 dark:bg-slate-900/60 text-slate-600 dark:text-slate-400 border border-slate-200 dark:border-slate-800 px-2 py-1 rounded-md">
                        {JSON.stringify(log.details)}
                      </span>
                    </TableCell>
                  </TableRow>
                ))
              )}

              {!isLoading && filteredLogs?.length === 0 && (
                <TableRow>
                  <TableCell colSpan={5} className="text-center h-24 text-slate-400 dark:text-slate-500 text-sm">
                    Tidak ada aktivitas ditemukan.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>

          {/* Pagination */}
          {!isLoading && (filteredLogs?.length || 0) > 0 && (
            <div className="flex items-center justify-between px-6 py-3 border-t border-slate-200 dark:border-slate-800 bg-transparent">
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Menampilkan{" "}
                <span className="font-semibold text-slate-700 dark:text-slate-200">
                  {page * pageSize + 1}–{Math.min((page + 1) * pageSize, filteredLogs?.length || 0)}
                </span>{" "}
                dari <span className="font-semibold text-slate-700 dark:text-slate-200">{filteredLogs?.length}</span> entri
              </p>

              <div className="flex items-center gap-1.5">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setPage((p) => Math.max(0, p - 1))}
                  disabled={page === 0}
                  className="h-8 px-3 rounded-lg border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 hover:text-slate-800 dark:hover:text-white disabled:opacity-30 text-xs gap-1 bg-transparent"
                >
                  <ChevronLeft className="h-3.5 w-3.5" />
                  Previous
                </Button>

                {Array.from({ length: totalPages }, (_, i) => (
                  <Button
                    key={i}
                    variant="outline"
                    size="sm"
                    onClick={() => setPage(i)}
                    className={`h-8 w-8 p-0 rounded-lg text-xs font-semibold ${
                      i === page
                        ? "bg-blue-600 dark:bg-[#3b82f6] text-white border-blue-600 dark:border-[#3b82f6] hover:bg-blue-700 dark:hover:bg-blue-600"
                        : "border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 hover:text-slate-800 dark:hover:text-white bg-transparent"
                    }`}
                  >
                    {i + 1}
                  </Button>
                ))}

                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
                  disabled={page >= totalPages - 1}
                  className="h-8 px-3 rounded-lg border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 hover:text-slate-800 dark:hover:text-white disabled:opacity-30 text-xs gap-1 bg-transparent"
                >
                  Next
                  <ChevronRight className="h-3.5 w-3.5" />
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
